param(
    [string]$Subject = $env:APPROVAL_SUBJECT,
    [string]$EmailList = $env:APPROVAL_EMAIL_LIST,
    [string]$ApproverEmail = $env:APPROVER_EMAIL,
    [string]$AttachmentPath = $env:APPROVAL_ATTACHMENT,
    [int]$TimeoutMinutes = 30,
    [int]$PollSeconds = 15
)

$ErrorActionPreference = "Stop"

function To-B64Url([byte[]]$bytes) {
    return ([Convert]::ToBase64String($bytes).TrimEnd("=") -replace "\+","-" -replace "/","_")
}

function Build-Mime {
    param([string]$To,[string]$MailSubject,[string]$Html,[string]$Attach)
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("To: $To") | Out-Null
    $sb.AppendLine("Subject: $MailSubject") | Out-Null
    $sb.AppendLine("MIME-Version: 1.0") | Out-Null
    if(-not [string]::IsNullOrWhiteSpace($Attach) -and (Test-Path -LiteralPath $Attach)){
        $b = "====PART_" + [Guid]::NewGuid().ToString("N")
        $fn = [IO.Path]::GetFileName($Attach)
        $sb.AppendLine("Content-Type: multipart/mixed; boundary=""$b""") | Out-Null
        $sb.AppendLine() | Out-Null
        $sb.AppendLine("--$b") | Out-Null
        $sb.AppendLine('Content-Type: text/html; charset="UTF-8"') | Out-Null
        $sb.AppendLine() | Out-Null
        $sb.AppendLine($Html) | Out-Null
        $sb.AppendLine() | Out-Null
        $sb.AppendLine("--$b") | Out-Null
        $sb.AppendLine("Content-Type: application/octet-stream; name=""$fn""") | Out-Null
        $sb.AppendLine("Content-Disposition: attachment; filename=""$fn""") | Out-Null
        $sb.AppendLine("Content-Transfer-Encoding: base64") | Out-Null
        $sb.AppendLine() | Out-Null
        $b64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($Attach))
        for($i=0;$i -lt $b64.Length;$i+=76){$len=[Math]::Min(76,$b64.Length-$i);$sb.AppendLine($b64.Substring($i,$len))|Out-Null}
        $sb.AppendLine("--$b--") | Out-Null
    } else {
        $sb.AppendLine('Content-Type: text/html; charset="UTF-8"') | Out-Null
        $sb.AppendLine() | Out-Null
        $sb.AppendLine($Html) | Out-Null
    }
    return $sb.ToString()
}

function Get-AccessTokenFromCfg {
    param($cfg)
    if(-not [string]::IsNullOrWhiteSpace([string]$cfg.access_token)){ return [string]$cfg.access_token }
    if([string]::IsNullOrWhiteSpace([string]$cfg.refresh_token)){
        throw "Missing both access_token and refresh_token in gmail_api_config.json"
    }
    $clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID","Process")
    if([string]::IsNullOrWhiteSpace($clientId)){ $clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID") }
    $clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET","Process")
    if([string]::IsNullOrWhiteSpace($clientSecret)){ $clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET") }
    if([string]::IsNullOrWhiteSpace($clientId)){ $clientId = [string]$cfg.client_id }
    if([string]::IsNullOrWhiteSpace($clientSecret)){ $clientSecret = [string]$cfg.client_secret }
    if([string]::IsNullOrWhiteSpace($clientId)){ throw "Gmail client_id is missing (Orchestrator/env)." }
    if([string]::IsNullOrWhiteSpace($clientSecret)){ throw "Gmail client_secret is missing (Orchestrator/env)." }
    $form = @{
        client_id = [string]$clientId
        client_secret = [string]$clientSecret
        refresh_token = [string]$cfg.refresh_token
        grant_type = "refresh_token"
    }
    $resp = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -ContentType "application/x-www-form-urlencoded" -Body $form
    if([string]::IsNullOrWhiteSpace([string]$resp.access_token)){ throw "Token endpoint returned empty access_token." }
    return [string]$resp.access_token
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
    } else {
        Add-Member -InputObject $Obj -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Save-CfgJson {
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

function Refresh-AccessToken {
    param(
        [Parameter(Mandatory = $true)][string]$CfgPath,
        [Parameter(Mandatory = $true)]$Cfg
    )
    if([string]::IsNullOrWhiteSpace([string]$Cfg.refresh_token)){
        throw "gmail_api_config: refresh_token is missing."
    }
    $clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID","Process")
    if([string]::IsNullOrWhiteSpace($clientId)){ $clientId = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID") }
    $clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET","Process")
    if([string]::IsNullOrWhiteSpace($clientSecret)){ $clientSecret = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET") }
    if([string]::IsNullOrWhiteSpace($clientId)){ $clientId = [string]$Cfg.client_id }
    if([string]::IsNullOrWhiteSpace($clientSecret)){ $clientSecret = [string]$Cfg.client_secret }
    if([string]::IsNullOrWhiteSpace($clientId)){ throw "Gmail client_id is missing (Orchestrator/env)." }
    if([string]::IsNullOrWhiteSpace($clientSecret)){ throw "Gmail client_secret is missing (Orchestrator/env)." }
    $form = @{
        client_id = [string]$clientId
        client_secret = [string]$clientSecret
        refresh_token = [string]$Cfg.refresh_token
        grant_type = "refresh_token"
    }
    $resp = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -ContentType "application/x-www-form-urlencoded" -Body $form
    $newToken = [string]$resp.access_token
    if([string]::IsNullOrWhiteSpace($newToken)){ throw "Token endpoint returned empty access_token." }
    Set-JsonProp -Obj $Cfg -Name "access_token" -Value $newToken
    Set-JsonProp -Obj $Cfg -Name "last_token_at_utc" -Value ((Get-Date).ToUniversalTime().ToString("o"))
    Save-CfgJson -CfgPath $CfgPath -Cfg $Cfg
    return $newToken
}

function Reauth-IfNeeded {
    param([string]$CfgPath)
    $reauth = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Scripts\\gmail_reauth.ps1"
    if(-not (Test-Path -LiteralPath $reauth)){ throw "Missing re-auth script: $reauth" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $reauth -ConfigPath $CfgPath | Out-Null
    return (Get-Content -LiteralPath $CfgPath -Raw | ConvertFrom-Json)
}

function Invoke-GmailRest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][ref]$TokenRef,
        [Parameter(Mandatory = $true)][ref]$CfgRef,
        [Parameter(Mandatory = $true)][string]$CfgPath,
        [string]$ContentType,
        $Body
    )
    try {
        $headers = @{ Authorization = "Bearer $($TokenRef.Value)" }
        if([string]::IsNullOrWhiteSpace($ContentType)){
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
        } else {
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType $ContentType -Body $Body
        }
    } catch {
        $statusCode = -1
        try {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) { $statusCode = [int]$_.Exception.Response.StatusCode }
        } catch {}
        if($statusCode -ne 401){ throw }

        # Token expired/revoked. Refresh (or re-auth) and retry once.
        try {
            $TokenRef.Value = Refresh-AccessToken -CfgPath $CfgPath -Cfg $CfgRef.Value
        } catch {
            $CfgRef.Value = Reauth-IfNeeded -CfgPath $CfgPath
            $TokenRef.Value = Get-AccessTokenFromCfg -cfg $CfgRef.Value
        }
        $headers = @{ Authorization = "Bearer $($TokenRef.Value)" }
        if([string]::IsNullOrWhiteSpace($ContentType)){
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
        } else {
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType $ContentType -Body $Body
        }
    }
}

function Show-DecisionWindow {
    param(
        [Parameter(Mandatory = $true)][string]$HtmlPath,
        [int]$MaxWaitSeconds = 600
    )
    try {
        if(-not (Test-Path -LiteralPath $HtmlPath)){ return }
        $edgePath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
        if(-not (Test-Path $edgePath)){ $edgePath = "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe" }
        if(-not (Test-Path $edgePath)){ $edgePath = "msedge.exe" }
        $url = "file:///" + ($HtmlPath -replace "\\","/")
        $proc = Start-Process -FilePath $edgePath -ArgumentList "--app=""$url"" --new-window --start-maximized" -WindowStyle Maximized -PassThru
        if($null -eq $proc){ return }
        try { $proc.WaitForExit([Math]::Max(1,$MaxWaitSeconds) * 1000) | Out-Null } catch {}
        try {
            if(-not $proc.HasExited){
                try { $proc.CloseMainWindow() | Out-Null } catch {}
                Start-Sleep -Milliseconds 600
                if(-not $proc.HasExited){
                    try { $proc.Kill($true) } catch { try { $proc.Kill() } catch {} }
                }
            }
        } catch {}
    } catch {}
}

function Write-DecisionMarker {
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][ValidateSet("APPROVED","DENIED")][string]$Decision
    )
    try {
        $tempDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\Temp"
        if(-not (Test-Path $tempDir)){ New-Item -ItemType Directory -Path $tempDir | Out-Null }
        $name = if($Decision -eq "APPROVED"){ "leader_approved_" + $SessionId + ".png" } else { "leader_denied_" + $SessionId + ".png" }
        $path = Join-Path $tempDir $name
        [IO.File]::WriteAllBytes($path,[Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="))
    } catch {}
}

function Cleanup-DecisionMarkers {
    param([string]$SessionId)
    if([string]::IsNullOrWhiteSpace($SessionId)){ return }
    try {
        $tempDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\Temp"
        foreach($f in @("leader_approved_$SessionId.png","leader_denied_$SessionId.png")){
            $p = Join-Path $tempDir $f
            if(Test-Path -LiteralPath $p){ Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
        }
    } catch {}
}

function Close-WaitingWindow {
    param(
        [string]$SessionId,
        $EdgeProc
    )
    # --- Primary mechanism (same as Canva processing): write sentinel PNG.
    if(-not [string]::IsNullOrWhiteSpace($SessionId)){
        try {
            $tempDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\Temp"
            if(-not (Test-Path $tempDir)){ New-Item -ItemType Directory -Path $tempDir | Out-Null }
            $sentinelPath = Join-Path $tempDir ("close_" + $SessionId + ".png")
            [IO.File]::WriteAllBytes($sentinelPath,[Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="))
        } catch {}
    }

    # Give HTML page time to poll sentinel and self-close.
    Start-Sleep -Milliseconds 1800

    # --- Fallback #1: close captured process.
    try {
        if($EdgeProc -and -not $EdgeProc.HasExited){
            try {
                $EdgeProc.CloseMainWindow() | Out-Null
                $EdgeProc.WaitForExit(1000) | Out-Null
            } catch {}
            if(-not $EdgeProc.HasExited){
                try { $EdgeProc.Kill($true) } catch { try { $EdgeProc.Kill() } catch {} }
            }
        }
    } catch {}

    # --- Fallback #2: kill by session marker in command line.
    if(-not [string]::IsNullOrWhiteSpace($SessionId)){
        try {
            $killBySession = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Scripts\\kill_edge_by_session.ps1"
            if(Test-Path -LiteralPath $killBySession){
                & powershell -NoProfile -ExecutionPolicy Bypass -File $killBySession -Session $SessionId | Out-Null
            }
        } catch {}
    }

    # --- Fallback #3: kill by window title (PROCESSING::<session>).
    # This matches CanvaProcessing.html which sets document.title = "PROCESSING::<sid>".
    if(-not [string]::IsNullOrWhiteSpace($SessionId)){
        try {
            $titleMarker = "PROCESSING::" + $SessionId
            Get-Process -Name "msedge" -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $t = $_.MainWindowTitle
                    if(-not [string]::IsNullOrWhiteSpace($t) -and $t.Contains($titleMarker)){
                        try { $_.CloseMainWindow() | Out-Null } catch {}
                        Start-Sleep -Milliseconds 400
                        try {
                            if(-not $_.HasExited){
                                try { $_.Kill($true) } catch { try { $_.Kill() } catch {} }
                            }
                        } catch {}
                    }
                } catch {}
            }
        } catch {}
    }

    # Ensure the waiting window is actually gone before we show Approved/Denied.
    # If we open the decision window too early, the user may see both windows.
    try {
        $deadline = (Get-Date).AddSeconds(12)
        do {
            $stillRunning = $false

            try {
                if($EdgeProc -and -not $EdgeProc.HasExited){ $stillRunning = $true }
            } catch {}

            if(-not $stillRunning -and -not [string]::IsNullOrWhiteSpace($SessionId)){
                try {
                    $marker = "session=$SessionId"
                    $procs = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" -ErrorAction SilentlyContinue |
                        Where-Object { $_.CommandLine -and ($_.CommandLine.Contains($marker)) }
                    if($procs -and $procs.Count -gt 0){ $stillRunning = $true }
                } catch {}
            }

            if(-not $stillRunning -and -not [string]::IsNullOrWhiteSpace($SessionId)){
                try {
                    $titleMarker = "PROCESSING::" + $SessionId
                    $p2 = Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Where-Object {
                        try { $_.MainWindowTitle -and $_.MainWindowTitle.Contains($titleMarker) } catch { $false }
                    }
                    if($p2 -and $p2.Count -gt 0){ $stillRunning = $true }
                } catch {}
            }

            if(-not $stillRunning){ break }
            Start-Sleep -Milliseconds 300
        } while((Get-Date) -lt $deadline)

        # Final hard-stop: if any session-marked Edge remains, kill it directly.
        if(-not [string]::IsNullOrWhiteSpace($SessionId)){
            try {
                $marker = "session=$SessionId"
                $procs = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" -ErrorAction SilentlyContinue |
                    Where-Object { $_.CommandLine -and ($_.CommandLine.Contains($marker)) }
                foreach($p in $procs){
                    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
                }
            } catch {}
        }

        # Final hard-stop by title marker.
        if(-not [string]::IsNullOrWhiteSpace($SessionId)){
            try {
                $titleMarker = "PROCESSING::" + $SessionId
                Get-Process -Name "msedge" -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        if($_.MainWindowTitle -and $_.MainWindowTitle.Contains($titleMarker)){
                            try { $_.Kill($true) } catch { try { $_.Kill() } catch {} }
                        }
                    } catch {}
                }
            } catch {}
        }
    } catch {}

    # --- Cleanup sentinel (same style as Canva processing close logic).
    if(-not [string]::IsNullOrWhiteSpace($SessionId)){
        try {
            $sentinelPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ("Data\\Temp\\close_" + $SessionId + ".png")
            if(Test-Path -LiteralPath $sentinelPath){ Remove-Item -LiteralPath $sentinelPath -Force }
        } catch {}
    }
}

function Get-GmailHeaderValue {
    param(
        $Headers,
        [string]$Name
    )
    try {
        if($null -eq $Headers){ return "" }
        foreach($h in $Headers){
            if($null -eq $h){ continue }
            if([string]::Equals([string]$h.name, $Name, [System.StringComparison]::OrdinalIgnoreCase)){
                return [string]$h.value
            }
        }
    } catch {}
    return ""
}

function Get-DecisionMetaFromMessages {
    param(
        $ListResponse,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][ref]$CfgRef,
        [Parameter(Mandatory = $true)][string]$CfgPath
    )
    $out = [ordered]@{
        actor = ""
        decision_at = ""
        message_id = ""
    }
    try {
        if($null -eq $ListResponse -or $null -eq $ListResponse.messages -or $ListResponse.messages.Count -le 0){ return $out }
        $msgId = [string]$ListResponse.messages[0].id
        if([string]::IsNullOrWhiteSpace($msgId)){ return $out }
        $metaUrl = "https://gmail.googleapis.com/gmail/v1/users/me/messages/$msgId?format=metadata&metadataHeaders=From&metadataHeaders=Date"
        $tok = $Token
        $meta = Invoke-GmailRest -Method "Get" -Uri $metaUrl -TokenRef ([ref]$tok) -CfgRef $CfgRef -CfgPath $CfgPath
        $payload = $meta.payload
        $headers = $null
        if($null -ne $payload){ $headers = $payload.headers }
        $fromVal = Get-GmailHeaderValue -Headers $headers -Name "From"
        $dateVal = Get-GmailHeaderValue -Headers $headers -Name "Date"
        $out.actor = $fromVal
        $out.decision_at = $dateVal
        $out.message_id = $msgId
    } catch {}
    return $out
}

try {
    $cfgPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\Temp\\gmail_api_config.json"
    if(-not (Test-Path -LiteralPath $cfgPath)){ throw "Missing config: $cfgPath" }
    $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json

    $cid = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID","Process")
    if([string]::IsNullOrWhiteSpace($cid)){ $cid = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_ID") }
    if([string]::IsNullOrWhiteSpace($cid)){ $cid = [string]$cfg.client_id }
    $csec = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET","Process")
    if([string]::IsNullOrWhiteSpace($csec)){ $csec = [Environment]::GetEnvironmentVariable("GMAIL_CLIENT_SECRET") }
    if([string]::IsNullOrWhiteSpace($csec)){ $csec = [string]$cfg.client_secret }
    if([string]::IsNullOrWhiteSpace($cid)){ throw "Gmail client_id is missing (Orchestrator/env)." }
    if([string]::IsNullOrWhiteSpace($csec)){ throw "Gmail client_secret is missing (Orchestrator/env)." }

    $approverCandidates = @()
    if(-not [string]::IsNullOrWhiteSpace($ApproverEmail)){
        $approverCandidates = @(
            ($ApproverEmail -split "[;,]") |
            ForEach-Object { "$_".Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique
        )
    }
    if($approverCandidates.Count -eq 0){ throw "ApproverEmail is missing. Please set approver email in Config.xlsx." }
    if($approverCandidates.Count -gt 1){ throw "ApproverEmail must contain only 1 email." }
    $approverRaw = [string]($approverCandidates | Select-Object -First 1)
    $approver = ([System.Net.Mail.MailAddress]$approverRaw).Address

    $token = ""
    try {
        $token = Refresh-AccessToken -CfgPath $cfgPath -Cfg $cfg
    } catch {
        $cfg = Reauth-IfNeeded -CfgPath $cfgPath
        try { $token = Refresh-AccessToken -CfgPath $cfgPath -Cfg $cfg } catch { $token = Get-AccessTokenFromCfg -cfg $cfg }
    }

    $tokenId = [Guid]::NewGuid().ToString("N").Substring(0,8).ToUpperInvariant()

    $listItems = @()
    if(-not [string]::IsNullOrWhiteSpace($EmailList)){
        foreach($part in ($EmailList -split ";")){
            $p = $part.Trim()
            if([string]::IsNullOrWhiteSpace($p)){ continue }
            $email = $p
            $name = ""
            if($p.Contains("|")){
                $arr = $p.Split("|")
                $email = $arr[$arr.Length-1].Trim()
                if($arr.Length -gt 1){ $name = $arr[0].Trim() }
            }
            if([string]::IsNullOrWhiteSpace($email)){ continue }
            if([string]::IsNullOrWhiteSpace($name)){ $listItems += "<li>$email</li>" } else { $listItems += "<li>$name ($email)</li>" }
        }
    }
    $recipientsHtml = if($listItems.Count -gt 0){ "<ul>" + ($listItems -join "") + "</ul>" } else { "<p><i>No recipients.</i></p>" }
    if([string]::IsNullOrWhiteSpace($AttachmentPath) -or -not (Test-Path -LiteralPath $AttachmentPath)){
        throw "Approval email must include a poster attachment. AttachmentPath invalid: $AttachmentPath"
    }

    $mailSubject = "[APPROVAL REQUIRED] $Subject"

    $senderEmail = ""
    try {
        $profile = Invoke-GmailRest -Method "Get" -Uri "https://gmail.googleapis.com/gmail/v1/users/me/profile" -TokenRef ([ref]$token) -CfgRef ([ref]$cfg) -CfgPath $cfgPath
        if($null -ne $profile -and -not [string]::IsNullOrWhiteSpace([string]$profile.emailAddress)){
            $senderEmail = [string]$profile.emailAddress
        }
    } catch {}

    $approveCmd = "APPROVE $tokenId"
    $denyCmd = "DENY $tokenId"
    $approveLink = "#"
    $denyLink = "#"
    if(-not [string]::IsNullOrWhiteSpace($senderEmail)){
        # Gmail web composes more reliably with `to=` query (right-side popup style).
        # Keep command in both subject and body for robust approval matching.
        $approveLink = "mailto:?to=" + [uri]::EscapeDataString($senderEmail) + "&subject=" + [uri]::EscapeDataString($approveCmd) + "&body=" + [uri]::EscapeDataString($approveCmd)
        $denyLink = "mailto:?to=" + [uri]::EscapeDataString($senderEmail) + "&subject=" + [uri]::EscapeDataString($denyCmd) + "&body=" + [uri]::EscapeDataString($denyCmd)
    }

    $mailBody = "<div style='font-family:Calibri,sans-serif;font-size:14px'>" +
                "<p>Please review this campaign before bulk sending.</p>" +
                "<p><b>Reply with one of the commands below:</b></p>" +
                "<ul><li><b>$approveCmd</b> - Approve and send to all recipients</li>" +
                "<li><b>$denyCmd</b> - Reject and stop bulk sending</li></ul>" +
                "<div style='margin:12px 0 16px 0'>" +
                "<a href='$approveLink' style='display:inline-block;padding:9px 14px;border-radius:8px;border:1px solid #15803d;background:#16a34a;color:#ffffff;text-decoration:none;font-weight:700;margin-right:8px'>Approve</a>" +
                "<a href='$denyLink' style='display:inline-block;padding:9px 14px;border-radius:8px;border:1px solid #b91c1c;background:#dc2626;color:#ffffff;text-decoration:none;font-weight:700'>Deny</a>" +
                "</div>" +
                "<p style='margin-top:0;color:#475569'><i>If a popup does not appear, click Reply and send exactly: <b>$approveCmd</b> or <b>$denyCmd</b>.</i></p>" +
                "<p><b>Recipient list:</b></p>$recipientsHtml</div>"

    $mime = Build-Mime -To $approver -MailSubject $mailSubject -Html $mailBody -Attach $AttachmentPath
    $raw = To-B64Url ([Text.Encoding]::UTF8.GetBytes($mime))
    $payload = @{ raw = $raw } | ConvertTo-Json -Compress
    Invoke-GmailRest -Method "Post" -Uri "https://gmail.googleapis.com/gmail/v1/users/me/messages/send" -TokenRef ([ref]$token) -CfgRef ([ref]$cfg) -CfgPath $cfgPath -ContentType "application/json" -Body $payload | Out-Null

    $session = [Guid]::NewGuid().ToString("N")
    $edgeProc = $null
    try {
        # Same as Canva processing launch: clear stale sentinel before opening UI.
        try {
            $tempDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\Temp"
            if(-not (Test-Path $tempDir)){ New-Item -ItemType Directory -Path $tempDir | Out-Null }
            $staleSentinel = Join-Path $tempDir ("close_" + $session + ".png")
            if(Test-Path -LiteralPath $staleSentinel){ Remove-Item -LiteralPath $staleSentinel -Force }
        } catch {}

        $runFile = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Data\\UI\\CanvaProcessing.html"
        $edgePath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
        if(-not (Test-Path $edgePath)){ $edgePath = "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe" }
        if(-not (Test-Path $edgePath)){ $edgePath = "msedge.exe" }
        $url = "file:///" + ($runFile -replace "\\","/") + "?task=Waiting+for+Leader+Approval&session=$session"
        $edgeProc = Start-Process -FilePath $edgePath -ArgumentList "--app=""$url"" --new-window --start-maximized" -WindowStyle Maximized -PassThru
    } catch {}

    $approveQ = [uri]::EscapeDataString("from:$approver newer_than:7d APPROVE $tokenId")
    $denyQ = [uri]::EscapeDataString("from:$approver newer_than:7d DENY $tokenId")
    $approveUrl = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=$approveQ&maxResults=5"
    $denyUrl = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=$denyQ&maxResults=5"

    $approved = $false
    $denied = $false
    $decisionBy = ""
    $decisionAt = ""
    $decisionMsgId = ""
    $started = Get-Date
    while(((Get-Date)-$started).TotalMinutes -lt $TimeoutMinutes){
        Start-Sleep -Seconds ([Math]::Max(1,$PollSeconds))
        $ra = Invoke-GmailRest -Method "Get" -Uri $approveUrl -TokenRef ([ref]$token) -CfgRef ([ref]$cfg) -CfgPath $cfgPath
        if($null -ne $ra.messages -and $ra.messages.Count -gt 0){
            $approved = $true
            $meta = Get-DecisionMetaFromMessages -ListResponse $ra -Token $token -CfgRef ([ref]$cfg) -CfgPath $cfgPath
            $decisionBy = [string]$meta.actor
            $decisionAt = [string]$meta.decision_at
            $decisionMsgId = [string]$meta.message_id
            break
        }
        $rd = Invoke-GmailRest -Method "Get" -Uri $denyUrl -TokenRef ([ref]$token) -CfgRef ([ref]$cfg) -CfgPath $cfgPath
        if($null -ne $rd.messages -and $rd.messages.Count -gt 0){
            $denied = $true
            $meta = Get-DecisionMetaFromMessages -ListResponse $rd -Token $token -CfgRef ([ref]$cfg) -CfgPath $cfgPath
            $decisionBy = [string]$meta.actor
            $decisionAt = [string]$meta.decision_at
            $decisionMsgId = [string]$meta.message_id
            break
        }
    }

    if($approved){
        Write-DecisionMarker -SessionId $session -Decision "APPROVED"
        $metaObj = [ordered]@{
            decision = "APPROVED"
            token = $tokenId
            approver_expected = $approver
            by = $decisionBy
            at = $decisionAt
            message_id = $decisionMsgId
        }
        Write-Output ("APPROVAL_META::" + (($metaObj | ConvertTo-Json -Compress)))
        # Let the waiting window navigate to Approved page in the SAME window.
        try { if($edgeProc){ $edgeProc.WaitForExit(900000) | Out-Null } } catch {}
        Close-WaitingWindow -SessionId $session -EdgeProc $edgeProc
        Cleanup-DecisionMarkers -SessionId $session
        Write-Output "APPROVED"
        exit 0
    }
    if($denied){
        Write-DecisionMarker -SessionId $session -Decision "DENIED"
        $metaObj = [ordered]@{
            decision = "DENIED"
            token = $tokenId
            approver_expected = $approver
            by = $decisionBy
            at = $decisionAt
            message_id = $decisionMsgId
        }
        Write-Output ("APPROVAL_META::" + (($metaObj | ConvertTo-Json -Compress)))
        # Let the waiting window navigate to Denied page in the SAME window.
        try { if($edgeProc){ $edgeProc.WaitForExit(900000) | Out-Null } } catch {}
        Close-WaitingWindow -SessionId $session -EdgeProc $edgeProc
        Cleanup-DecisionMarkers -SessionId $session
        Write-Output "DENIED"
        exit 2
    }
    Close-WaitingWindow -SessionId $session -EdgeProc $edgeProc
    Cleanup-DecisionMarkers -SessionId $session
    Write-Output "TIMEOUT"; exit 3
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}



