# Generates the Play upload keystore and android/key.properties.
# Run once per development machine that produces store builds; both outputs
# are git-ignored. Back the .jks and its passwords up somewhere safe outside
# this machine — losing the upload key requires a reset request with Google.

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $repoRoot 'android\upload-keystore.jks'
$propsPath = Join-Path $repoRoot 'android\key.properties'

if (Test-Path $keystorePath) {
    Write-Error "Keystore already exists: $keystorePath — refusing to overwrite."
}

$keytool = 'keytool'
if (-not (Get-Command $keytool -ErrorAction SilentlyContinue)) {
    if ($env:JAVA_HOME) {
        $keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
    }
    if (-not (Test-Path $keytool)) {
        Write-Error 'keytool not found. Ensure a JDK is on PATH or JAVA_HOME is set.'
    }
}

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
