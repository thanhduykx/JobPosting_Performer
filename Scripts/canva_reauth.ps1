
[CmdletBinding()]
param(
    [string] $ClientId,
    [System.Security.SecureString] $ClientSecret,
    [string] $RedirectUri = "http://127.0.0.1:8080/callback",
    [string] $TokenFile
)

# --- Resolve ClientId ---
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = [Environment]::GetEnvironmentVariable('CANVA_CLIENT_ID')
}
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "Canva Client ID"
}
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    Write-Host "ERROR: Client ID is required." -ForegroundColor Red; exit 1
}

# --- Resolve ClientSecret (kept as SecureString until the HTTP call) ---
if ($null -eq $ClientSecret -or $ClientSecret.Length -eq 0) {
    $envSecret = [Environment]::GetEnvironmentVariable('CANVA_CLIENT_SECRET')
    if (-not [string]::IsNullOrWhiteSpace($envSecret)) {
        $ClientSecret = ConvertTo-SecureString $envSecret -AsPlainText -Force
    }
}
if ($null -eq $ClientSecret -or $ClientSecret.Length -eq 0) {
    $ClientSecret = Read-Host "Canva Client Secret" -AsSecureString
}
if ($null -eq $ClientSecret -or $ClientSecret.Length -eq 0) {
    Write-Host "ERROR: Client Secret is required." -ForegroundColor Red; exit 1
}

# --- Defaults ---
if ([string]::IsNullOrWhiteSpace($TokenFile)) {
    $TokenFile = Join-Path $PSScriptRoot "..\Data\Temp\canva_tokens.json"
}
$redirectUri = $RedirectUri
$tokenFile   = $TokenFile
$clientId    = $ClientId
$scopes       = "design:content:read design:content:write design:meta:read design:permission:read design:permission:write asset:read asset:write folder:read folder:write folder:permission:read folder:permission:write brandtemplate:content:read brandtemplate:content:write brandtemplate:meta:read comment:read comment:write profile:read app:read app:write"

# --- Step 1: Generate PKCE code_verifier & code_challenge ---
Add-Type -AssemblyName System.Security
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes)
$codeVerifier = [Convert]::ToBase64String($bytes) -replace '\+','-' -replace '/','_' -replace '=',''

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($codeVerifier))
$codeChallenge = [Convert]::ToBase64String($hashBytes) -replace '\+','-' -replace '/','_' -replace '=',''

$state = [System.Guid]::NewGuid().ToString("N")

# --- Step 2: Build authorization URL ---
$authUrl = "https://www.canva.com/api/oauth/authorize" +
    "?client_id=$clientId" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&response_type=code" +
    "&scope=$([Uri]::EscapeDataString($scopes))" +
    "&state=$state" +
    "&code_challenge=$codeChallenge" +
    "&code_challenge_method=S256"

Write-Host "=== Canva OAuth Re-Authorization ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening browser for authorization..." -ForegroundColor Yellow
Start-Process $authUrl

# --- Step 3: Start local HTTP listener for callback ---
Write-Host "Waiting for callback on $redirectUri ..." -ForegroundColor Yellow
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8080/")
$listener.Start()

$context = $listener.GetContext()
$rawUrl  = $context.Request.RawUrl
$response = $context.Response
$responseHtml = "<html><body><h2 style='font-family:sans-serif;color:green'>Authorization successful! You may close this window.</h2></body></html>"
$responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseHtml)
$response.ContentLength64 = $responseBytes.Length
$response.OutputStream.Write($responseBytes, 0, $responseBytes.Length)
$response.OutputStream.Close()
$listener.Stop()

# --- Step 4: Extract code from callback URL ---
$queryString = $rawUrl -replace '^/callback\?', ''
$params = @{}
foreach ($pair in $queryString.Split('&')) {
    $kv = $pair.Split('=', 2)
    if ($kv.Count -eq 2) { $params[$kv[0]] = [Uri]::UnescapeDataString($kv[1]) }
}

if ($params["state"] -ne $state) {
    Write-Host "ERROR: State mismatch! Possible CSRF attack." -ForegroundColor Red
    exit 1
}

$code = $params["code"]
if ([string]::IsNullOrEmpty($code)) {
    Write-Host "ERROR: No authorization code received. URL: $rawUrl" -ForegroundColor Red
    exit 1
}

Write-Host "Authorization code received. Exchanging for tokens..." -ForegroundColor Yellow

# --- Step 5: Exchange code for tokens ---
# Unwrap SecureString -> plain ONLY for the duration of the HTTP call.
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
try {
    $plainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    $creds   = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${clientId}:${plainSecret}"))
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Variable plainSecret -ErrorAction SilentlyContinue
}
$headers  = @{ Authorization = "Basic $creds" }
$body     = "grant_type=authorization_code&code=$([Uri]::EscapeDataString($code))&redirect_uri=$([Uri]::EscapeDataString($redirectUri))&code_verifier=$codeVerifier"

try {
    $r = Invoke-RestMethod -Uri "https://api.canva.com/rest/v1/oauth/token" `
        -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -Headers $headers

    $tokenObj = [PSCustomObject]@{
        access_token  = $r.access_token
        token_type    = "Bearer"
        created_at    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        expires_in    = $r.expires_in
        refresh_token = $r.refresh_token
        expires_at    = (Get-Date).AddSeconds($r.expires_in).ToString("yyyy-MM-dd HH:mm:ss")
    }

    # Ensure directory exists
    $dir = Split-Path $tokenFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    $tokenObj | ConvertTo-Json | Set-Content $tokenFile -Encoding UTF8
    Write-Host ""
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "Token saved to: $tokenFile" -ForegroundColor Green
    Write-Host "Access token expires at: $($tokenObj.expires_at)" -ForegroundColor Green
    Write-Host "Has refresh_token: $(-not [string]::IsNullOrEmpty($r.refresh_token))" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "ERROR exchanging code for token: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "API response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
    exit 1
}

