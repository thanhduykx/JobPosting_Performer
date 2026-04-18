$ErrorActionPreference = "Continue"
$tokens = Get-Content "c:\UiPath\JobPosting_FINAL\Data\Temp\canva_tokens.json" | ConvertFrom-Json
$h = @{ Authorization = "Bearer " + $tokens.access_token; "Content-Type" = "application/json" }
$base = "https://api.canva.com/rest/v1"
$tid = "EAHHPNsPR2M"
$out = ""

# ====== STEP 1: AUTOFILL ======
$out += "=== STEP 1: AUTOFILL ===`r`n"

$body = @{
    brand_template_id = $tid
    title = "Test Poster - Software Engineer"
    data = @{
        Role = @{ type = "text"; text = "Software Engineer" }
        "Career Level" = @{ type = "text"; text = "Senior" }
        "Work Set-up" = @{ type = "text"; text = "Hybrid" }
        "Work Schedule" = @{ type = "text"; text = "Full-time" }
        "Work Location" = @{ type = "text"; text = "Ho Chi Minh City" }
        Headcount = @{ type = "text"; text = "5" }
        Qualifications = @{ type = "text"; text = "3+ years experience in .NET/Java" }
    }
} | ConvertTo-Json -Depth 5

$out += "Request body: $body`r`n"

$autofillJobId = ""
$designId = ""

try {
    $r = Invoke-RestMethod -Uri ($base + "/autofills") -Headers $h -Method POST -Body $body
    $autofillJobId = $r.job.id
    $out += "Autofill Job ID: $autofillJobId`r`n"
    $out += "Status: $($r.job.status)`r`n"
} catch {
    $out += "AUTOFILL ERROR: $($_.Exception.Message)`r`n"
    if ($_.ErrorDetails) { $out += "DETAIL: $($_.ErrorDetails.Message)`r`n" }
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\poster_test.txt", $out)
    Write-Host "Failed at autofill. See Data\Temp\poster_test.txt"
    exit 1
}

# ====== STEP 2: POLL AUTOFILL ======
$out += "`r`n=== STEP 2: POLL AUTOFILL ===`r`n"
$hGet = @{ Authorization = "Bearer " + $tokens.access_token }
$maxPolls = 20
$pollCount = 0
$status = "in_progress"

while ($status -eq "in_progress" -and $pollCount -lt $maxPolls) {
    Start-Sleep -Seconds 3
    $pollCount++
    try {
        $r = Invoke-RestMethod -Uri ($base + "/autofills/" + $autofillJobId) -Headers $hGet -Method GET
        $status = $r.job.status
        $out += "Poll $pollCount/$maxPolls - Status: $status`r`n"
        
        if ($status -eq "success") {
            $designId = $r.job.result.design.id
            $editUrl = $r.job.result.design.urls.edit_url
            $out += "Design ID: $designId`r`n"
            $out += "Edit URL: $editUrl`r`n"
        }
    } catch {
        $out += "Poll error: $($_.Exception.Message)`r`n"
    }
}

if ([string]::IsNullOrEmpty($designId)) {
    $out += "FAILED: Could not get design ID after $maxPolls polls`r`n"
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\poster_test.txt", $out)
    Write-Host "Failed at polling. See Data\Temp\poster_test.txt"
    exit 1
}

# ====== STEP 3: EXPORT ======
$out += "`r`n=== STEP 3: EXPORT ===`r`n"

$exportBody = @{
    design_id = $designId
    format = @{
        type = "png"
        quality = "regular"
        width = 1080
        height = 1080
    }
} | ConvertTo-Json -Depth 5

$exportJobId = ""
try {
    $r = Invoke-RestMethod -Uri ($base + "/exports") -Headers $h -Method POST -Body $exportBody
    $exportJobId = $r.job.id
    $out += "Export Job ID: $exportJobId`r`n"
} catch {
    $out += "EXPORT ERROR: $($_.Exception.Message)`r`n"
    if ($_.ErrorDetails) { $out += "DETAIL: $($_.ErrorDetails.Message)`r`n" }
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\poster_test.txt", $out)
    exit 1
}

# ====== STEP 4: POLL EXPORT ======
$out += "`r`n=== STEP 4: POLL EXPORT ===`r`n"
$pollCount = 0
$status = "in_progress"
$downloadUrl = ""

while ($status -eq "in_progress" -and $pollCount -lt $maxPolls) {
    Start-Sleep -Seconds 3
    $pollCount++
    try {
        $r = Invoke-RestMethod -Uri ($base + "/exports/" + $exportJobId) -Headers $hGet -Method GET
        $status = $r.job.status
        $out += "Poll $pollCount/$maxPolls - Status: $status`r`n"
        
        if ($status -eq "success") {
            $downloadUrl = $r.job.urls[0]
            $out += "Download URL: $($downloadUrl.Substring(0, 80))...`r`n"
        }
    } catch {
        $out += "Poll error: $($_.Exception.Message)`r`n"
    }
}

if ([string]::IsNullOrEmpty($downloadUrl)) {
    $out += "FAILED: Could not get download URL`r`n"
    [System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\poster_test.txt", $out)
    exit 1
}

# ====== STEP 5: DOWNLOAD ======
$out += "`r`n=== STEP 5: DOWNLOAD ===`r`n"

$outputDir = "c:\UiPath\JobPosting_FINAL\Data\Output\Posters"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$outputFile = Join-Path $outputDir ("Test_SoftwareEngineer_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".png")

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile
    $fileSize = (Get-Item $outputFile).Length
    $out += "SAVED: $outputFile`r`n"
    $out += "Size: $fileSize bytes`r`n"
    $out += "`r`n=== ALL DONE - SUCCESS! ===`r`n"
} catch {
    $out += "DOWNLOAD ERROR: $($_.Exception.Message)`r`n"
}

[System.IO.File]::WriteAllText("c:\UiPath\JobPosting_FINAL\Data\Temp\poster_test.txt", $out)
Write-Host "Done! See Data\Temp\poster_test.txt and Data\Output\Posters\"
