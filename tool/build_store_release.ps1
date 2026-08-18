# Builds the Google Play release artifact (.aab), refusing configurations
# that must never reach the store: bundled test archives, dev tooling
# compiled in, or a debug-signed artifact.
#
# Usage: .\tool\build_store_release.ps1 [-AllowEmptySentryDsn]

param(
    [switch]$AllowEmptySentryDsn
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = 'D:\Program Files\flutter_sdk\flutter\bin\flutter.bat' }
if (-not (Test-Path $flutter)) { Write-Error 'flutter not found on PATH.' }

# 1. The test-archive asset directory is bundled into ALL builds; a store
#    build must not ship it.
$testArchive = Get-ChildItem 'assets\test_archive' -File |
    Where-Object { $_.Name -ne '.gitkeep' }
if ($testArchive) {
    Write-Error ("assets/test_archive contains: " +
        ($testArchive.Name -join ', ') +
        " - remove these files before building a store release.")
}

# 2. Store define file: dev tools must be off, no test archive URL.
$defineFile = 'build_settings.store.json'
$defines = Get-Content $defineFile -Raw | ConvertFrom-Json
if ($defines.DEV_TOOLS -ne 'false') {
    Write-Error "DEV_TOOLS must be 'false' in $defineFile."
}
if ($defines.PSObject.Properties.Name -contains 'test_archive_url' -and
    $defines.test_archive_url) {
    Write-Error "test_archive_url must not be set in $defineFile."
}
if (-not $defines.SENTRY_DSN -and -not $AllowEmptySentryDsn) {
    Write-Error ("SENTRY_DSN is empty in $defineFile - the release ships " +
        "without crash reporting. Set it, or pass -AllowEmptySentryDsn " +
        "to build anyway.")
}

# 3. Upload-key signing must be configured (Play rejects debug-signed
#    bundles). See tool/generate_upload_keystore.ps1.
if (-not (Test-Path 'android\key.properties')) {
    Write-Error 'android/key.properties not found - run tool/generate_upload_keystore.ps1 first.'
}

& $flutter build appbundle --release "--dart-define-from-file=$defineFile"
if ($LASTEXITCODE -ne 0) { Write-Error 'flutter build appbundle failed.' }

$aab = 'build\app\outputs\bundle\release\app-release.aab'
Write-Host ''
Write-Host "Store artifact: $aab"
Write-Host 'Upload via Play Console (versionCode must exceed the last upload).'
