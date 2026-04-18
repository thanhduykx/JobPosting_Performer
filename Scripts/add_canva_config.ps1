$ErrorActionPreference = "Stop"
$configPath = "c:\UiPath\JobPosting_FINAL\Data\Config.xlsx"

Write-Host "=== Adding Canva Poster Config to Config.xlsx ===" -ForegroundColor Cyan

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $workbook = $excel.Workbooks.Open($configPath)
    
    # Check if CanvaPoster sheet already exists
    $sheetExists = $false
    foreach ($sheet in $workbook.Sheets) {
        if ($sheet.Name -eq "CanvaPoster") {
            $sheetExists = $true
            break
        }
    }
    
    if ($sheetExists) {
        Write-Host "Sheet 'CanvaPoster' already exists. Deleting and recreating..." -ForegroundColor Yellow
        $workbook.Sheets.Item("CanvaPoster").Delete()
    }
    
    # Add new sheet
    $newSheet = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $workbook.Sheets.Item($workbook.Sheets.Count))
    $newSheet.Name = "CanvaPoster"
    
    # === HEADER ROW ===
    $newSheet.Cells.Item(1, 1) = "Key"
    $newSheet.Cells.Item(1, 2) = "Value"
    $newSheet.Cells.Item(1, 3) = "Description"
    
    # Format header
    $headerRange = $newSheet.Range("A1:C1")
    $headerRange.Font.Bold = $true
    $headerRange.Interior.Color = 0x8B4513  # Dark blue in BGR
    $headerRange.Font.Color = 0xFFFFFF     # White
    
    # === CONFIG DATA ===
    $row = 2
    $configs = @(
        @("InputFilePath", "Data\Input\Jobs_Local.xlsx", "Path to Excel input file"),
        @("InputSheetName", "Sheet1", "Sheet name containing job data"),
        @("Canva_TokenFilePath", "Data\Temp\canva_tokens.json", "Path to saved Canva tokens (from get_canva_token.ps1)"),
        @("Canva_BrandTemplateId", "EAHHPNsPR2M", "Canva Brand Template ID (verified)"),
        @("Canva_ApiBaseUrl", "https://api.canva.com/rest/v1", "Canva Connect API base URL"),
        @("Canva_ClientId", "OC-AZ2iLEHXVW41", "Canva App Client ID"),
        @("Canva_ExportFormat", "png", "Export format: png / pdf / jpg"),
        @("Canva_ExportWidth", "1080", "Export width in pixels"),
        @("Canva_ExportHeight", "1080", "Export height in pixels"),
        @("Canva_OutputFolder", "Data\Output\Posters", "Folder to save downloaded posters"),
        @("Canva_PollIntervalMs", "3000", "Milliseconds between poll requests"),
        @("Canva_PollMaxAttempts", "20", "Max poll attempts before timeout"),
        @("Canva_DelayBetweenJobsMs", "2000", "Delay between processing each job (rate limit)"),
        @("RetryCount", "3", "Number of retries on API error"),
        @("CleanupTempFiles", "False", "Delete temp files after completion"),
        @("GmailConnectionId", "", "Gmail API Connection ID for sending emails with poster attached")
    )
    
    foreach ($config in $configs) {
        $newSheet.Cells.Item($row, 1) = $config[0]
        $newSheet.Cells.Item($row, 2) = $config[1]
        $newSheet.Cells.Item($row, 3) = $config[2]
        $row++
    }
    
    # Auto-fit columns
    $newSheet.Columns.Item("A:C").AutoFit() | Out-Null
    
    # Add border
    $dataRange = $newSheet.Range("A1:C$($row - 1)")
    $dataRange.Borders.LineStyle = 1
    
    # Save
    $workbook.Save()
    Write-Host "Config added successfully to sheet 'CanvaPoster' ($($configs.Count) settings)" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($workbook) { $workbook.Close($false) }
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

Write-Host "Done!" -ForegroundColor Cyan
