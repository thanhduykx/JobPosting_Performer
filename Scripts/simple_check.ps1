$ErrorActionPreference = "Continue"
$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$h = @{ Authorization = "Bearer " + $tokens.access_token }
$base = "https://api.canva.com/rest/v1"
$tid = "EAHHPNsPR2M"
$out = ""

$out += "=== BRAND TEMPLATE ===`r`n"
try {
    $r = Invoke-RestMethod -Uri ($base + "/brand-templates/" + $tid) -Headers $h -Method GET
    $out += ($r | ConvertTo-Json -Depth 5) + "`r`n"
} catch {
    $out += "ERROR: " + $_.Exception.Message + "`r`n"
    if ($_.ErrorDetails) { $out += "DETAIL: " + $_.ErrorDetails.Message + "`r`n" }
}

$out += "`r`n=== DATASET ===`r`n"
try {
    $r = Invoke-RestMethod -Uri ($base + "/brand-templates/" + $tid + "/dataset") -Headers $h -Method GET
    $out += ($r | ConvertTo-Json -Depth 5) + "`r`n"
} catch {
    $out += "ERROR: " + $_.Exception.Message + "`r`n"
    if ($_.ErrorDetails) { $out += "DETAIL: " + $_.ErrorDetails.Message + "`r`n" }
}

[System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\api_result.txt", $out)
Write-Host "Done. Results in Data\Temp\api_result.txt"
