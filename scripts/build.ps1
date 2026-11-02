$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $taskRoot
$taskTranscriptStarted = $false
try {
    New-Item -ItemType Directory -Path (Join-Path $taskRoot 'evidence') -Force | Out-Null
    Start-Transcript -Path (Join-Path $taskRoot 'evidence\build.log') -Force | Out-Null
    $taskTranscriptStarted = $true
    $taskLune = Join-Path $taskRoot '.tools\lune\lune.exe'
    $taskRojo = Join-Path $taskRoot '.tools\rojo\rojo.exe'
    foreach ($taskTool in @($taskLune, $taskRojo)) {
        if (-not (Test-Path -LiteralPath $taskTool -PathType Leaf)) { throw "Missing portable tool: $taskTool" }
    }
    & $taskLune run tools/generate.luau
    if ($LASTEXITCODE -ne 0) { throw 'Map generation failed' }
    foreach ($taskOutput in @('RoyalRush.rbxl', 'RoyalRush.rbxlx')) {
        & $taskRojo build default.project.json -o $taskOutput
        if ($LASTEXITCODE -ne 0) { throw "Place build failed: $taskOutput" }
    }
    & (Join-Path $PSScriptRoot 'test.ps1')
    $taskFiles = @(@('RoyalRush.rbxl', 'RoyalRush.rbxlx') | ForEach-Object {
        $taskItem = Get-Item -LiteralPath (Join-Path $taskRoot $_)
        [ordered]@{ Path = $_; Bytes = $taskItem.Length; SHA256 = (Get-FileHash -LiteralPath $taskItem.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
    $taskSourceManifest = @(Get-ChildItem -LiteralPath (Join-Path $taskRoot 'src') -Recurse -File | Sort-Object FullName | ForEach-Object {
        [ordered]@{ Path = $_.FullName.Substring($taskRoot.Length + 1).Replace([IO.Path]::DirectorySeparatorChar, '/'); SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
    $taskReports = @(@('core-tests', 'data-service-tests', 'service-contracts', 'place-audit') | ForEach-Object {
        $taskReport = Get-Content -LiteralPath (Join-Path $taskRoot "evidence\$_.json") -Raw | ConvertFrom-Json
        [ordered]@{ Report = "evidence/$_.json"; Passed = $taskReport.Passed; Failed = $taskReport.Failed; Kind = $taskReport.Kind }
    })
    $taskManifest = [ordered]@{
        Version = '0.2.0-playtest'; BuiltAtUTC = [DateTime]::UtcNow.ToString('o')
        RuntimeTested = $false; Published = $false
        Files = $taskFiles; Sources = $taskSourceManifest; OfflineChecks = $taskReports
    }
    $taskManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskRoot 'evidence\build-manifest.json') -Encoding UTF8
    Write-Host 'Built RoyalRush.rbxl and RoyalRush.rbxlx. Open with Roblox Studio when installed.'
} finally {
    if ($taskTranscriptStarted) { Stop-Transcript | Out-Null }
    Pop-Location
}
