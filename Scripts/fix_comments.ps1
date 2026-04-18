$folder = "c:\UiPath\JobPosting_FINAL\Workflows\CanvaPoster"
$files = Get-ChildItem "$folder\*.xaml"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $original = $content
    
    # Replace <Comment ... /> with <ui:LogMessage ... /> using Trace level
    # Pattern: <Comment DisplayName="xxx" ... Text="yyy" />
    # Replace: <ui:LogMessage DisplayName="xxx" ... Level="Trace" Message="[&quot;TODO: see annotation&quot;]" />
    
    # Simple approach: replace Comment tags entirely
    # Match self-closing Comment tags
    $pattern = '<Comment\s+DisplayName="([^"]*)"[^/]*/>'
    
    $content = [regex]::Replace($content, $pattern, {
        param($match)
        $displayName = $match.Groups[1].Value
        # Extract just the essential parts
        '<ui:LogMessage DisplayName="' + $displayName + '" sap:VirtualizedContainerService.HintSize="483.2,174.4" Level="Trace" Message="[&quot;' + $displayName + '&quot;]" />'
    })
    
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "FIXED: $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "OK: $($file.Name) (no Comment found)" -ForegroundColor Gray
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan
