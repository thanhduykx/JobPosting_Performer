$folders = @(
    "c:\UiPath\JobPosting_FINAL\Workflows\InputHandler",
    "c:\UiPath\JobPosting_FINAL\Workflows\CanvaPoster"
)

foreach ($folder in $folders) {
    $files = Get-ChildItem "$folder\*.xaml" -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $original = $content
        
        $regex = [regex]::new('<Comment\s+DisplayName="([^"]*)"[^>]*/>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $content = $regex.Replace($content, {
            param($match)
            $dn = $match.Groups[1].Value
            '<!-- ' + $dn + ' -->'
        })
        
        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $content)
            Write-Host "FIXED: $($file.Name)" -ForegroundColor Green
        }
    }
}
Write-Host "Done!" -ForegroundColor Cyan
