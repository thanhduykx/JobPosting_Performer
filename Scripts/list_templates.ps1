$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$AccessToken = $tokens.access_token
$BaseUrl = "https://api.canva.com/rest/v1"

$headers = @{
    "Authorization" = "Bearer $AccessToken"
}

# 1. List all brand templates
Write-Host "=== List Brand Templates ===" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates" -Headers $headers -Method GET
    $json = $r | ConvertTo-Json -Depth 10
    Write-Host $json
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\brand_templates.txt", $json, [System.Text.Encoding]::UTF8)
} catch {
    $status = $_.Exception.Response.StatusCode
    $errBody = $_.ErrorDetails.Message
    Write-Host "Status: $status" -ForegroundColor Red
    Write-Host "Error: $errBody" -ForegroundColor Red
}

# 2. Try original design as brand template
Write-Host "`n=== Check DAHHPEZJLuo as Brand Template ===" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/DAHHPEZJLuo" -Headers $headers -Method GET
    $r | ConvertTo-Json -Depth 10
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Not a brand template. Status: $status" -ForegroundColor Yellow
}

# 3. Try dataset for original design
Write-Host "`n=== Check Dataset ===" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/DAHHPEZJLuo/dataset" -Headers $headers -Method GET
    $json = $r | ConvertTo-Json -Depth 10
    Write-Host $json
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\dataset.txt", $json, [System.Text.Encoding]::UTF8)
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "No dataset. Status: $status" -ForegroundColor Yellow
    Write-Host "Error: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
}
