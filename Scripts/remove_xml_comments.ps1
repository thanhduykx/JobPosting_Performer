$files = Get-ChildItem "c:\UiPath\JobPosting_FINAL\Workflows" -Recurse -Filter "*.xaml"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    
    # Remove all XML comments <!-- ... -->
    $content = [regex]::Replace($content, '<!--.*?-->', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Clean up empty lines left behind
    $content = [regex]::Replace($content, '(\r?\n\s*){3,}', "`r`n`r`n")
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "CLEANED: $($file.Name)" -ForegroundColor Green
    }
}
Write-Host "Done!" -ForegroundColor Cyan
