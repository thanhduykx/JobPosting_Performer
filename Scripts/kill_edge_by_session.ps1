# Kill any msedge.exe process whose command line contains the given session marker.
# Used by the Canva Poster workflow to reliably close --app Edge windows even
# when window title detection is unreliable (e.g. Teams screen share reparents).
param(
    [Parameter(Mandatory = $true)]
    [string] $Session
)

$ErrorActionPreference = 'SilentlyContinue'

# Win32_Process gives us CommandLine which includes the ?session=<id> fragment.
$marker = "session=$Session"
try {
    $procs = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and ($_.CommandLine.Contains($marker)) }

    foreach ($p in $procs) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        } catch {
            # swallow per-process errors
        }
    }
    "Killed $($procs.Count) msedge processes for session=$Session" | Write-Output
} catch {
    "Helper failed: $($_.Exception.Message)" | Write-Output
    exit 0  # Never fail; caller treats this as best-effort.
}
