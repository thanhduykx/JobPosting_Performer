$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$BaseUrl = "https://api.canva.com/rest/v1"
$ClientId = "OC-AZ2iLEHXVW41"
$ClientSecret = $args[0]
$TemplateId = "EAHHPNsPR2M"

# Step 1: Refresh token
Write-Host "=== Refreshing Token ===" -ForegroundColor Cyan
$BasicAuth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${ClientId}:${ClientSecret}"))
$refreshBody = @{
    grant_type    = "refresh_token"
    refresh_token = $tokens.refresh_token
}
$refreshHeaders = @{
    "Authorization" = "Basic $BasicAuth"
    "Content-Type"  = "application/x-www-form-urlencoded"
}

try {
    $refreshResult = Invoke-RestMethod -Uri "$BaseUrl/oauth/token" -Method POST -Body $refreshBody -Headers $refreshHeaders
    $AccessToken = $refreshResult.access_token
    Write-Host "Token refreshed OK. Expires in: $($refreshResult.expires_in)s" -ForegroundColor Green
    
    # Save new tokens
    $newTokens = @{
        access_token  = $refreshResult.access_token
        refresh_token = $refreshResult.refresh_token
        expires_in    = $refreshResult.expires_in
        token_type    = $refreshResult.token_type
        created_at    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        expires_at    = (Get-Date).AddSeconds($refreshResult.expires_in).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $newTokens | ConvertTo-Json | Out-File -FilePath "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" -Encoding UTF8
} catch {
    Write-Host "Refresh failed, using existing token" -ForegroundColor Yellow
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
    $AccessToken = $tokens.access_token
}

$headers = @{
    "Authorization" = "Bearer $AccessToken"
}

# Step 2: Check brand template
Write-Host "`n=== Brand Template: $TemplateId ===" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/brand-templates/$TemplateId" -Headers $headers -Method GET
    Write-Host "Status: $($r.StatusCode)" -ForegroundColor Green
    $body = $r.Content
    Write-Host $body
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\bt_info.json", $body, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    $sr = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errBody = $sr.ReadToEnd()
    Write-Host "Error body: $errBody" -ForegroundColor Red
}

# Step 3: Check dataset
Write-Host "`n=== Dataset ===" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/brand-templates/$TemplateId/dataset" -Headers $headers -Method GET
    Write-Host "Status: $($r.StatusCode)" -ForegroundColor Green
    $body = $r.Content
    Write-Host $body
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\bt_dataset.json", $body, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    $sr = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errBody = $sr.ReadToEnd()
    Write-Host "Error body: $errBody" -ForegroundColor Red
}
