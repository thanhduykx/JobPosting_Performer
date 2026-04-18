$ErrorActionPreference = "Continue"

# Fix ALL xaml files in Workflows folder
$files = Get-ChildItem "c:\UiPath\JobPosting_FINAL\Workflows" -Recurse -Filter "*.xaml"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    
    # 1. Fix XML comments with -- inside (invalid XML)
    # Replace <!-- ... --> that contain -- with safe versions
    $content = [regex]::Replace($content, '<!--(.*?)-->', {
        param($m)
        $inner = $m.Groups[1].Value
        # Replace -- with == inside comments to make valid XML
        $inner = $inner.Replace('--', '==')
        '<!--' + $inner + '-->'
    }, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # 2. Replace BusinessRuleException in Catch with s:Exception (safer for hand-created XAML)
    # Only in CanvaPoster files
    if ($file.FullName -like "*CanvaPoster*") {
        # Remove the entire BusinessRuleException Catch block and keep only s:Exception catch
        # Replace Catch x:TypeArguments="BusinessRuleException" with nothing - remove the whole block
        $brePattern = '<Catch x:TypeArguments="BusinessRuleException".*?</Catch>'
        $content = [regex]::Replace($content, $brePattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    }
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "FIXED: $($file.Name)" -ForegroundColor Green
    }
}

# 3. Fix the Throw in ReadInput - change BusinessRuleException to Exception
$readInput = "c:\UiPath\JobPosting_FINAL\Workflows\CanvaPoster\1_CanvaPoster_ReadInput.xaml"
if (Test-Path $readInput) {
    $content = [System.IO.File]::ReadAllText($readInput)
    $content = $content.Replace(
        'New BusinessRuleException(&quot;ReadInputFailed&quot;, &quot;Failed to read input: &quot; + ex.Message)',
        'New System.Exception(&quot;ReadInputFailed: &quot; + ex.Message)'
    )
    [System.IO.File]::WriteAllText($readInput, $content)
    Write-Host "FIXED: 1_CanvaPoster_ReadInput.xaml (Throw)" -ForegroundColor Green
}

Write-Host "Done!" -ForegroundColor Cyan
