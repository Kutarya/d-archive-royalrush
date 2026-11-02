$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskReleaseDir = Join-Path $taskRoot 'releases'
New-Item -ItemType Directory -Path $taskReleaseDir -Force | Out-Null
$taskName = 'RoyalRush-0.1.0-offline'
$taskZipPath = Join-Path $taskReleaseDir "$taskName.zip"
if (Test-Path -LiteralPath $taskZipPath) {
    $taskName += '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    $taskZipPath = Join-Path $taskReleaseDir "$taskName.zip"
}
$taskManifest = Get-Content -LiteralPath (Join-Path $taskRoot 'evidence\build-manifest.json') -Raw | ConvertFrom-Json
foreach ($taskArtifact in $taskManifest.Files) {
    $taskActual = (Get-FileHash -LiteralPath (Join-Path $taskRoot $taskArtifact.Path) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($taskActual -ne $taskArtifact.SHA256) { throw "Build changed after verification: $($taskArtifact.Path)" }
}
$taskFiles = @(
    @('README.md','SES-KURULUMU.md','AGENTS.md','.gitignore','default.project.json','package.json','BUILD.cmd','TEST.cmd','AC-STUDIO.cmd','RoyalRush.rbxl','RoyalRush.rbxlx') | ForEach-Object { Get-Item -LiteralPath (Join-Path $taskRoot $_) }
    @('src','content','tools','scripts','tests','docs','.tools') | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $taskRoot $_) -Recurse -File | Where-Object { $_.Extension -notin @('.zip','.pyc') } }
    Get-ChildItem -LiteralPath (Join-Path $taskRoot 'evidence') -File | Where-Object { $_.Name -notlike 'package-*' }
) | Sort-Object FullName -Unique
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskEntries = @()
$taskFileStream = [IO.File]::Open($taskZipPath, [IO.FileMode]::CreateNew)
$taskZip = [IO.Compression.ZipArchive]::new($taskFileStream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($taskItem in $taskFiles) {
        $taskRelative = $taskItem.FullName.Substring($taskRoot.Length + 1).Replace([IO.Path]::DirectorySeparatorChar, '/')
        $taskEntryName = "RoyalRush/$taskRelative"
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($taskZip, $taskItem.FullName, $taskEntryName, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        $taskEntries += [ordered]@{ Path = $taskEntryName; Bytes = $taskItem.Length; SHA256 = (Get-FileHash -LiteralPath $taskItem.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
} finally { $taskZip.Dispose(); $taskFileStream.Dispose() }
$taskReadZip = [IO.Compression.ZipFile]::OpenRead($taskZipPath)
try {
    if ($taskReadZip.Entries.Count -ne $taskEntries.Count) { throw 'Archive entry count mismatch' }
    foreach ($taskExpected in $taskEntries) {
        $taskEntry = $taskReadZip.GetEntry($taskExpected.Path)
        $taskReadStream = $taskEntry.Open()
        $taskSHA = [Security.Cryptography.SHA256]::Create()
        try { $taskDigest = [BitConverter]::ToString($taskSHA.ComputeHash($taskReadStream)).Replace('-', '').ToLowerInvariant() }
        finally { $taskReadStream.Dispose(); $taskSHA.Dispose() }
        if ($taskDigest -ne $taskExpected.SHA256 -or $taskEntry.Length -ne $taskExpected.Bytes) { throw "Archive content mismatch: $($taskExpected.Path)" }
    }
} finally { $taskReadZip.Dispose() }
$taskZipItem = Get-Item -LiteralPath $taskZipPath
[ordered]@{
    Version = '0.1.0-offline'; PackagedAtUTC = [DateTime]::UtcNow.ToString('o')
    Zip = $taskZipItem.Name; Bytes = $taskZipItem.Length
    SHA256 = (Get-FileHash -LiteralPath $taskZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    VerifiedEntries = $taskEntries.Count; Entries = $taskEntries
    RuntimeTested = $false; Published = $false
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskReleaseDir "$taskName.manifest.json") -Encoding UTF8
Write-Host "Packaged and SHA-256 verified $($taskEntries.Count) entries: $taskZipPath"
