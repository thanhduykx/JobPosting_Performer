param(
    [string]$ConfigPath = "Data\Temp\gmail_api_config.json"
)

$ErrorActionPreference = "Stop"

function Get-AbsolutePath {
    param([string]$PathValue)
    if ([System.IO.Path]::IsPathRooted($PathValue)) { return $PathValue }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PathValue))
}

function Get-QueryMap {
    param([string]$Query)
    $map = @{}
    if ([string]::IsNullOrWhiteSpace($Query)) { return $map }
    $q = $Query.TrimStart('?')
    foreach ($pair in $q.Split('&')) {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }
        $kv = $pair.Split('=', 2)
        $k = [System.Uri]::UnescapeDataString($kv[0])
        $v = ""
        if ($kv.Count -gt 1) { $v = [System.Uri]::UnescapeDataString($kv[1]) }
        $map[$k] = $v
    }
    return $map
}

function Set-JsonProp {
    param(
        [Parameter(Mandatory = $true)]$Obj,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )
    $prop = $Obj.PSObject.Properties[$Name]
    if ($null -ne $prop) {
        $prop.Value = $Value
    }
    else {
        Add-Member -InputObject $Obj -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Save-CfgJsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$CfgPath,
        [Parameter(Mandatory = $true)]$Cfg
    )
    $toSave = $Cfg.PSObject.Copy()
    foreach($k in @("client_id","client_secret")){
        try {
            if($null -ne $toSave.PSObject.Properties[$k]){ [void]$toSave.PSObject.Properties.Remove($k) }
        } catch {}
    }
    $toSave | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $CfgPath -Encoding UTF8
}

$cfgPath = Get-AbsolutePath $ConfigPath
if (-not (Test-Path -LiteralPath $cfgPath)) {
    throw "Config file not found: $cfgPath"
}

$cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
$clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID","Process")
if ([string]::IsNullOrWhiteSpace($clientId)) { $clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID") }
if ([string]::IsNullOrWhiteSpace($clientId)) { $clientId = [string]$cfg.client_id }
$clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET","Process")
if ([string]::IsNullOrWhiteSpace($clientSecret)) { $clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET") }
if ([string]::IsNullOrWhiteSpace($clientSecret)) { $clientSecret = [string]$cfg.client_secret }
if ([string]::IsNullOrWhiteSpace($clientId)) { throw "client_id is missing (Orchestrator/env)." }
if ([string]::IsNullOrWhiteSpace($clientSecret)) { throw "client_secret is missing (Orchestrator/env)." }

$tcp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$tcp.Start()
$port = ([System.Net.IPEndPoint]$tcp.LocalEndpoint).Port
$redirectUri = "http://127.0.0.1:$port/callback"

$state = [Guid]::NewGuid().ToString("N")
$scope = [Uri]::EscapeDataString("https://www.googleapis.com/auth/gmail.send https://www.googleapis.com/auth/gmail.readonly")
$authUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=$([Uri]::EscapeDataString($clientId))&redirect_uri=$([Uri]::EscapeDataString($redirectUri))&response_type=code&scope=$scope&access_type=offline&prompt=consent&state=$state"

try {
    Start-Process $authUrl | Out-Null
} catch {
    Write-Host "Open this URL manually in browser:" -ForegroundColor Yellow
    Write-Host $authUrl
}

Write-Host "Waiting for Google consent callback on $redirectUri ..."

$acceptTask = $tcp.AcceptTcpClientAsync()
if (-not $acceptTask.Wait([TimeSpan]::FromMinutes(5))) {
    $tcp.Stop()
    throw "Timeout waiting for OAuth callback."
}

$client = $acceptTask.Result
$stream = $client.GetStream()
$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 8192, $true)
$writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8, 8192, $true)
$writer.NewLine = "`r`n"

$requestLine = $reader.ReadLine()
if ([string]::IsNullOrWhiteSpace($requestLine)) {
    $client.Close(); $tcp.Stop()
    throw "OAuth callback request is empty."
}

# Drain headers
while ($true) {
    $h = $reader.ReadLine()
    if ([string]::IsNullOrEmpty($h)) { break }
}

$parts = $requestLine.Split(' ')
if ($parts.Count -lt 2) {
    $client.Close(); $tcp.Stop()
    throw "Invalid callback request line: $requestLine"
}

$rawPath = $parts[1]
$cbUri = [Uri]("http://127.0.0.1:$port" + $rawPath)
$qs = Get-QueryMap -Query $cbUri.Query
$code = if ($qs.ContainsKey("code")) { [string]$qs["code"] } else { "" }
$retState = if ($qs.ContainsKey("state")) { [string]$qs["state"] } else { "" }
$oauthError = if ($qs.ContainsKey("error")) { [string]$qs["error"] } else { "" }

if (-not [string]::IsNullOrWhiteSpace($oauthError)) {
    $body = "<html><body><h3>Gmail OAuth failed.</h3><p>$oauthError</p></body></html>"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $writer.WriteLine("HTTP/1.1 400 Bad Request")
    $writer.WriteLine("Content-Type: text/html; charset=utf-8")
    $writer.WriteLine("Content-Length: " + $bytes.Length)
    $writer.WriteLine()
    $writer.Flush()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
    $client.Close(); $tcp.Stop()
    throw "OAuth error from Google: $oauthError"
}

if ([string]::IsNullOrWhiteSpace($code)) {
    $client.Close(); $tcp.Stop()
    throw "OAuth callback missing code."
}
if ($retState -ne $state) {
    $client.Close(); $tcp.Stop()
    throw "OAuth state mismatch."
}

$okBody = "<html><body><h3>Gmail OAuth success.</h3><p>You can close this window.</p></body></html>"
$okBytes = [System.Text.Encoding]::UTF8.GetBytes($okBody)
$writer.WriteLine("HTTP/1.1 200 OK")
$writer.WriteLine("Content-Type: text/html; charset=utf-8")
$writer.WriteLine("Content-Length: " + $okBytes.Length)
$writer.WriteLine()
$writer.Flush()
$stream.Write($okBytes, 0, $okBytes.Length)
$stream.Flush()

$client.Close()
$tcp.Stop()

$tokenBody = @{
    code          = $code
    client_id     = $clientId
    client_secret = $clientSecret
    redirect_uri  = $redirectUri
    grant_type    = "authorization_code"
}

$tokenResp = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -ContentType "application/x-www-form-urlencoded" -Body $tokenBody
if ([string]::IsNullOrWhiteSpace([string]$tokenResp.access_token)) {
    throw "Token response missing access_token."
}
if ([string]::IsNullOrWhiteSpace([string]$tokenResp.refresh_token) -and [string]::IsNullOrWhiteSpace([string]$cfg.refresh_token)) {
    throw "Token response missing refresh_token. Ensure OAuth app type supports offline access."
}

$cfgObj = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
Set-JsonProp -Obj $cfgObj -Name "access_token" -Value ([string]$tokenResp.access_token)
if (-not [string]::IsNullOrWhiteSpace([string]$tokenResp.refresh_token)) {
    Set-JsonProp -Obj $cfgObj -Name "refresh_token" -Value ([string]$tokenResp.refresh_token)
}
Set-JsonProp -Obj $cfgObj -Name "redirect_uri" -Value $redirectUri
Set-JsonProp -Obj $cfgObj -Name "last_token_at_utc" -Value ((Get-Date).ToUniversalTime().ToString("o"))

Save-CfgJsonSafe -CfgPath $cfgPath -Cfg $cfgObj
Write-Host "Gmail OAuth completed. Tokens saved to $cfgPath"
