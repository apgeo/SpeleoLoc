# Generates the Play upload keystore and android/key.properties.
# Run once per development machine that produces store builds; both outputs
# are git-ignored. Back the .jks and its passwords up somewhere safe outside
# this machine — losing the upload key requires a reset request with Google.

param(
    # Explicit keytool.exe, for JDK layouts the search below does not cover.
    [string]$KeytoolPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $repoRoot 'android\upload-keystore.jks'
$propsPath = Join-Path $repoRoot 'android\key.properties'

if (Test-Path $keystorePath) {
    Write-Error "Keystore already exists: $keystorePath — refusing to overwrite."
}

# A dev machine that builds this app needs no JAVA_HOME and no Java on PATH:
# Gradle uses the JDK bundled with Android Studio. Find that same JBR (and
# the usual standalone JDK layouts) rather than requiring shell setup.
function Get-KeytoolCandidates {
    if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' }

    $onPath = (Get-Command keytool -ErrorAction SilentlyContinue).Source
    if ($onPath) { $onPath }

    $studioFromRegistry = (
        Get-ItemProperty 'HKLM:\SOFTWARE\Android Studio' -ErrorAction SilentlyContinue
    ).Path
    if ($studioFromRegistry) { Join-Path $studioFromRegistry 'jbr\bin\keytool.exe' }

    $jdkRoots = @()
    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        if ($drive.DriveType -ne 'Fixed' -or -not $drive.IsReady) { continue }
        $programFiles = Join-Path $drive.RootDirectory.FullName 'Program Files'
        $jdkRoots += Join-Path $programFiles 'Android\Android Studio\jbr'
        $jdkRoots += Join-Path $programFiles 'Java\*'
        $jdkRoots += Join-Path $programFiles 'Eclipse Adoptium\*'
        $jdkRoots += Join-Path $programFiles 'Microsoft\jdk*'
    }
    # JetBrains Toolbox installs Android Studio per-user.
    $jdkRoots += Join-Path $env:LOCALAPPDATA 'Programs\Android Studio\jbr'

    foreach ($root in $jdkRoots) {
        Get-Item (Join-Path $root 'bin\keytool.exe') -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName }
    }
}

$keytool = Get-KeytoolCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $keytool) {
    Write-Error (
        "keytool not found. Searched JAVA_HOME, PATH, Android Studio's bundled " +
        "JBR and the standard JDK install locations on every fixed drive. " +
        "Install a JDK (or Android Studio), or pass -KeytoolPath " +
        "'<jdk>\bin\keytool.exe'."
    )
}
Write-Host "Using keytool: $keytool"

$storePassword = Read-Host 'Keystore password (also used as key password)' -AsSecureString
$plainPassword = [System.Net.NetworkCredential]::new('', $storePassword).Password
if ($plainPassword.Length -lt 6) {
    Write-Error 'Password must be at least 6 characters.'
}
# key.properties is parsed by java.util.Properties (backslash = escape
# character) and written as ASCII; restrict the charset so keytool and
# Gradle are guaranteed to see the same password.
if ($plainPassword -match '[^\x21-\x7E]' -or $plainPassword.Contains('\')) {
    Write-Error 'Password must use printable ASCII without spaces or backslashes.'
}

& $keytool -genkey -v `
    -keystore $keystorePath `
    -alias upload `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $plainPassword -keypass $plainPassword `
    -dname 'CN=SpeleoLoc, O=speosilex.ro'
if ($LASTEXITCODE -ne 0) { Write-Error 'keytool failed.' }

@"
storePassword=$plainPassword
keyPassword=$plainPassword
keyAlias=upload
storeFile=../upload-keystore.jks
"@ | Set-Content -Encoding ASCII $propsPath

Write-Host "Created $keystorePath and $propsPath"
Write-Host 'Back up the keystore file and password now (password manager + offline copy).'
