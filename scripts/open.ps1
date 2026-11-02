param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskPlace = Join-Path $taskRoot 'RoyalRush.rbxl'
$taskSearchRoots = @('D:\Roblox\Versions', (Join-Path $env:LOCALAPPDATA 'Roblox\Versions')) | Select-Object -Unique
$taskStudios = @($taskSearchRoots | ForEach-Object {
    if (Test-Path -LiteralPath $_ -PathType Container) {
        Get-ChildItem -LiteralPath $_ -File -Recurse -Filter 'RobloxStudioBeta.exe' -ErrorAction SilentlyContinue
    }
} | Sort-Object LastWriteTime -Descending)
if ($CheckOnly) {
    [ordered]@{ StudioFound = ($taskStudios.Count -gt 0); PlaceFound = (Test-Path -LiteralPath $taskPlace -PathType Leaf); Place = $taskPlace } | ConvertTo-Json
    exit 0
}
if (-not (Test-Path -LiteralPath $taskPlace -PathType Leaf)) { throw 'RoyalRush.rbxl is missing; run BUILD.cmd first.' }
if ($taskStudios.Count -eq 0) { Write-Host 'Roblox Studio is not installed. Install Studio, then run AC-STUDIO.cmd again.'; exit 1 }
Start-Process -FilePath $taskStudios[0].FullName -ArgumentList ('"{0}"' -f $taskPlace)
