$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $taskRoot
try {
    $taskCompiler = Join-Path $taskRoot '.tools\luau\luau-compile.exe'
    $taskLune = Join-Path $taskRoot '.tools\lune\lune.exe'
    foreach ($taskTool in @($taskCompiler, $taskLune)) {
        if (-not (Test-Path -LiteralPath $taskTool -PathType Leaf)) { throw "Missing portable tool: $taskTool" }
    }
    $taskSources = @(@('src', 'tools', 'tests') | ForEach-Object {
        Get-ChildItem -LiteralPath (Join-Path $taskRoot $_) -Recurse -File -Filter '*.luau'
    } | Sort-Object FullName | Select-Object -ExpandProperty FullName)
    & $taskCompiler --null @taskSources
    if ($LASTEXITCODE -ne 0) { throw 'Luau compilation failed' }
    foreach ($taskSuite in @('tests/core.luau', 'tests/data-service.luau', 'tests/service-contracts.luau', 'tools/audit.luau')) {
        & $taskLune run $taskSuite
        if ($LASTEXITCODE -ne 0) { throw "Failed: $taskSuite" }
    }
    Write-Host 'All offline checks passed. Roblox Studio runtime acceptance is still pending.'
} finally { Pop-Location }
