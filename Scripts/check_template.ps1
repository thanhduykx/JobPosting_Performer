$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$AccessToken = $tokens.access_token
$BaseUrl = "https://api.canva.com/rest/v1"
$TemplateId = "DAHHPEZJLuo"

$headers = @{
    "Authorization" = "Bearer $AccessToken"
}

Write-Host "=== Checking Brand Template ===" -ForegroundColor Cyan

# 1. Try as brand template
Write-Host "`n--- Try: GET /brand-templates/$TemplateId ---" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/$TemplateId" -Headers $headers -Method GET
    Write-Host "SUCCESS - Brand Template found!" -ForegroundColor Green
    $r | ConvertTo-Json -Depth 10
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Status: $status" -ForegroundColor Red
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 2. Try dataset
Write-Host "`n--- Try: GET /brand-templates/$TemplateId/dataset ---" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/$TemplateId/dataset" -Headers $headers -Method GET
    Write-Host "SUCCESS - Dataset found!" -ForegroundColor Green
    $r | ConvertTo-Json -Depth 10
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Status: $status" -ForegroundColor Red
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 3. Try as regular design
Write-Host "`n--- Try: GET /designs/$TemplateId ---" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/designs/$TemplateId" -Headers $headers -Method GET
    Write-Host "SUCCESS - Design found!" -ForegroundColor Green
    $r | ConvertTo-Json -Depth 10
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Status: $status" -ForegroundColor Red
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 4. List brand templates
Write-Host "`n--- List all brand templates ---" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates?query=&continuation=" -Headers $headers -Method GET
    Write-Host "SUCCESS - Brand Templates:" -ForegroundColor Green
    $r | ConvertTo-Json -Depth 10
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Status: $status" -ForegroundColor Red
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
