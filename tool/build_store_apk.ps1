# Builds a release-signed .apk for sideloading or direct distribution, with
# the same guards as the store bundle: no bundled test archives, no dev
# tooling compiled in, no pre-configured sync account, no debug signing.
#
# Uses the store define files: build_settings.store.json is the closed-testing
# build; build_settings.store.production.json is the public release, which
# ships without crash reporting.
#
# Default output is a single universal APK; -SplitPerAbi emits one smaller
# APK per CPU architecture instead.
#
# Usage: .\tool\build_store_apk.ps1 [-Production] [-SplitPerAbi] [-AllowEmptySentryDsn]

param(
    [switch]$Production,
    [switch]$SplitPerAbi,
    [switch]$AllowEmptySentryDsn
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = 'D:\Program Files\flutter_sdk\flutter\bin\flutter.bat' }
if (-not (Test-Path $flutter)) { Write-Error 'flutter not found on PATH.' }

# 1. The test-archive asset directory is bundled into ALL builds; a
#    distributable APK must not ship it.
$testArchive = Get-ChildItem 'assets\test_archive' -File |
    Where-Object { $_.Name -ne '.gitkeep' }
if ($testArchive) {
    Write-Error ("assets/test_archive contains: " +
        ($testArchive.Name -join ', ') +
        " - remove these files before building a release APK.")
}

# 2. Define file: dev tools must be off. A sample-data archive may be
#    offered (SAMPLE_DATA=true), but only as an https download - a bundled
#    asset path or a dev-machine path has no place in a distributable build.
$defineFile = if ($Production) { 'build_settings.store.production.json' } else { 'build_settings.store.json' }
$defines = Get-Content $defineFile -Raw | ConvertFrom-Json
if ($defines.DEV_TOOLS -ne 'false') {
    Write-Error "DEV_TOOLS must be 'false' in $defineFile."
}
if ($defines.PSObject.Properties.Name -contains 'test_archive_url' -and
    $defines.test_archive_url -and
    -not ($defines.test_archive_url -like 'https://*')) {
    Write-Error "test_archive_url in $defineFile must be an https:// URL."
}
if ($defines.SAMPLE_DATA -eq 'true' -and -not $defines.test_archive_url) {
    Write-Error "SAMPLE_DATA is 'true' in $defineFile but test_archive_url is empty."
}
$seedKeys = $defines.PSObject.Properties.Name | Where-Object { $_ -like 'ftp_seed_*' }
if ($seedKeys) {
    Write-Error ("$defineFile sets " + ($seedKeys -join ', ') +
        " - a distributable build must not ship a pre-configured sync account.")
}
if (-not $Production -and -not $defines.SENTRY_DSN -and -not $AllowEmptySentryDsn) {
    Write-Error ("SENTRY_DSN is empty in $defineFile - the release ships " +
        "without crash reporting. Set it, or pass -AllowEmptySentryDsn " +
        "to build anyway.")
}

# 3. Release signing must be configured; without it Gradle falls back to the
#    debug key. See tool/generate_upload_keystore.ps1.
if (-not (Test-Path 'android\key.properties')) {
    Write-Error 'android/key.properties not found - run tool/generate_upload_keystore.ps1 first.'
}

$buildArgs = @('build', 'apk', '--release', "--dart-define-from-file=$defineFile")
if ($SplitPerAbi) { $buildArgs += '--split-per-abi' }
& $flutter @buildArgs
if ($LASTEXITCODE -ne 0) { Write-Error 'flutter build apk failed.' }

$outDir = 'build\app\outputs\flutter-apk'
Write-Host ''
Write-Host 'APK artifact(s):'
Get-ChildItem $outDir -Filter 'app-*release.apk' | ForEach-Object {
    Write-Host ("  {0} ({1:N1} MB)" -f (Join-Path $outDir $_.Name), ($_.Length / 1MB))
}
Write-Host 'Installing over a build with a higher versionCode requires uninstalling first (wipes app data).'
