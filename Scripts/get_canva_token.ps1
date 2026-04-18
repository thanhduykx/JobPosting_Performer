# ============================================
# Canva Connect API - OAuth Token Generator
# Uses PKCE (Proof Key for Code Exchange)
# Usage: .\get_canva_token.ps1 -Secret "your_client_secret"
# ============================================
param(
    [Parameter(Mandatory=$true)]
    [string]$Secret
)

$ClientId = "OC-AZ2iLEHXVW41"
$ClientSecret = $Secret
$RedirectUri = "http://127.0.0.1:8080/callback"
$TokenEndpoint = "https://api.canva.com/rest/v1/oauth/token"
$AuthEndpoint = "https://www.canva.com/api/oauth/authorize"

$Scopes = @(
    "app:write",
    "folder:read",
    "brandtemplate:content:read",
    "folder:permission:write",
    "comment:write",
    "design:content:write",
    "brandtemplate:meta:read",
    "asset:read",
    "profile:read",
    "folder:write",
    "design:permission:write",
    "brandtemplate:content:write",
    "design:permission:read",
    "design:meta:read",
    "app:read",
    "asset:write",
    "folder:permission:read",
    "design:content:read",
    "comment:read"
) -join " "

# --- Step 1: Generate PKCE code_verifier and code_challenge ---
Write-Host "`n=== Canva OAuth Token Generator ===" -ForegroundColor Cyan
Write-Host "Step 1: Generating PKCE parameters..." -ForegroundColor Yellow

# Generate code_verifier (43-128 chars, URL-safe)
$RandomBytes = New-Object byte[] 64
[System.Security.Cryptography.RandomNumberGenerator]::Fill($RandomBytes)
$CodeVerifier = [Convert]::ToBase64String($RandomBytes) -replace '\+','-' -replace '/','_' -replace '='

# Generate code_challenge = Base64URL(SHA256(code_verifier))
$Sha256 = [System.Security.Cryptography.SHA256]::Create()
$ChallengeBytes = $Sha256.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($CodeVerifier))
$CodeChallenge = [Convert]::ToBase64String($ChallengeBytes) -replace '\+','-' -replace '/','_' -replace '='

Write-Host "  code_verifier: $($CodeVerifier.Substring(0,20))..." -ForegroundColor Gray
Write-Host "  code_challenge: $($CodeChallenge.Substring(0,20))..." -ForegroundColor Gray

# --- Step 2: Build Authorization URL ---
Write-Host "`nStep 2: Building authorization URL..." -ForegroundColor Yellow

$ScopesEncoded = [System.Uri]::EscapeDataString($Scopes)
$RedirectUriEncoded = [System.Uri]::EscapeDataString($RedirectUri)

$AuthUrl = "$AuthEndpoint" +
    "?code_challenge_method=s256" +
    "&response_type=code" +
    "&client_id=$ClientId" +
    "&redirect_uri=$RedirectUriEncoded" +
    "&scope=$ScopesEncoded" +
    "&code_challenge=$CodeChallenge"

# --- Step 3: Start local HTTP listener ---
Write-Host "`nStep 3: Starting local HTTP listener on port 8080..." -ForegroundColor Yellow

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://127.0.0.1:8080/")
try {
    $Listener.Start()
} catch {
    Write-Host "ERROR: Port 8080 is in use. Close any app using it and try again." -ForegroundColor Red
    exit 1
}

Write-Host "  Listener started on http://127.0.0.1:8080/" -ForegroundColor Green

# --- Step 4: Open browser ---
Write-Host "`nStep 4: Opening browser for authorization..." -ForegroundColor Yellow
Write-Host "  If browser doesn't open, copy this URL manually:" -ForegroundColor Gray
Write-Host "  $AuthUrl" -ForegroundColor Gray
Start-Process $AuthUrl

Write-Host "`n  Waiting for authorization callback..." -ForegroundColor Cyan
Write-Host "  (Click 'Allow' in the Canva page that opened)" -ForegroundColor Cyan

# --- Step 5: Wait for callback ---
$Context = $Listener.GetContext()
$Request = $Context.Request
$QueryString = $Request.Url.Query

# Parse authorization code from callback
$Code = ""
if ($QueryString -match "code=([^&]+)") {
    $Code = $Matches[1]
}

# Send response to browser
$Response = $Context.Response
$ResponseHtml = "<html><body><h1 style='color:green;font-family:sans-serif;text-align:center;margin-top:100px;'>Authorization successful!</h1><p style='text-align:center;font-family:sans-serif;'>You can close this tab now.</p></body></html>"
$Buffer = [System.Text.Encoding]::UTF8.GetBytes($ResponseHtml)
$Response.ContentLength64 = $Buffer.Length
$Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
$Response.Close()
$Listener.Stop()

if ([string]::IsNullOrEmpty($Code)) {
    Write-Host "`nERROR: No authorization code received!" -ForegroundColor Red
    Write-Host "  Full callback URL: $($Request.Url)" -ForegroundColor Red
    exit 1
}

Write-Host "`n  Authorization code received!" -ForegroundColor Green
Write-Host "  Code: $($Code.Substring(0, [Math]::Min(20, $Code.Length)))..." -ForegroundColor Gray

# --- Step 6: Exchange code for tokens ---
Write-Host "`nStep 5: Exchanging code for access token + refresh token..." -ForegroundColor Yellow

$TokenBody = @{
    grant_type    = "authorization_code"
    code          = $Code
    code_verifier = $CodeVerifier
    redirect_uri  = $RedirectUri
}

$TokenHeaders = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Build Basic auth header: Base64(client_id:client_secret)
$BasicAuth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${ClientId}:${ClientSecret}"))
$TokenHeaders["Authorization"] = "Basic $BasicAuth"

try {
    $TokenResponse = Invoke-RestMethod -Uri $TokenEndpoint -Method POST -Body $TokenBody -Headers $TokenHeaders
    
    Write-Host "`n=== TOKEN RECEIVED ===" -ForegroundColor Green
    Write-Host "  access_token:  $($TokenResponse.access_token.Substring(0, 50))..." -ForegroundColor Green
    Write-Host "  refresh_token: $($TokenResponse.refresh_token.Substring(0, 30))..." -ForegroundColor Green
    Write-Host "  expires_in:    $($TokenResponse.expires_in) seconds" -ForegroundColor Green
    Write-Host "  token_type:    $($TokenResponse.token_type)" -ForegroundColor Green
    
    # --- Step 7: Save tokens ---
    $TokenFile = Join-Path $PSScriptRoot "..\Data\Temp\canva_tokens.json"
    $TokenData = @{
        access_token  = $TokenResponse.access_token
        refresh_token = $TokenResponse.refresh_token
        expires_in    = $TokenResponse.expires_in
        token_type    = $TokenResponse.token_type
        created_at    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        expires_at    = (Get-Date).AddSeconds($TokenResponse.expires_in).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $TokenData | ConvertTo-Json | Out-File -FilePath $TokenFile -Encoding UTF8
    
    Write-Host "`n  Tokens saved to: $TokenFile" -ForegroundColor Cyan
    Write-Host "`n=== DONE ===" -ForegroundColor Cyan
    Write-Host "  Use refresh_token in your UiPath workflow to get new access_tokens." -ForegroundColor White
    Write-Host "  Access token expires in $($TokenResponse.expires_in) seconds." -ForegroundColor White
    
} catch {
    Write-Host "`nERROR exchanging code for token:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}
