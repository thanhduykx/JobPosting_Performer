$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$AccessToken = $tokens.access_token
$BaseUrl = "https://api.canva.com/rest/v1"
$TemplateId = "EAHHPNsPR2M"

$headers = @{
    "Authorization" = "Bearer $AccessToken"
}

# 1. Get brand template info
Write-Host "=== Brand Template Info ===" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/$TemplateId" -Headers $headers -Method GET
    $json = $r | ConvertTo-Json -Depth 10
    Write-Host $json -ForegroundColor Green
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\brand_template_info.txt", $json, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "$($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 2. Get dataset (data fields)
Write-Host "`n=== Dataset (Data Fields) ===" -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "$BaseUrl/brand-templates/$TemplateId/dataset" -Headers $headers -Method GET
    $json = $r | ConvertTo-Json -Depth 10
    Write-Host $json -ForegroundColor Green
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\dataset.txt", $json, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "$($_.ErrorDetails.Message)" -ForegroundColor Red
}
