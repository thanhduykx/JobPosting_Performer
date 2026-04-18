$folder = "c:\UiPath\JobPosting_FINAL\Workflows\CanvaPoster"
$files = Get-ChildItem "$folder\*.xaml"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    
    # Replace all <Comment ... /> tags (including multiline with singleline flag)
    # Capture DisplayName for the replacement
    $regex = [regex]::new('<Comment\s+DisplayName="([^"]*)"[^>]*/>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    $content = $regex.Replace($content, {
        param($match)
        $dn = $match.Groups[1].Value
        '<!-- ' + $dn + ' -->'
    })
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
        $removed = $regex.Matches($original).Count
        Write-Host "FIXED: $($file.Name) - removed $removed Comment tags" -ForegroundColor Green
    } else {
        Write-Host "SKIP: $($file.Name)" -ForegroundColor Gray
    }
}

Write-Host "Done!" -ForegroundColor Cyan
