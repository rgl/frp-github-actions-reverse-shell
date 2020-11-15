Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

mkdir -Force frp | Out-Null
Push-Location frp

if (!(Test-Path frps.exe)) {
    Write-Output 'Downloading frp...'
    (New-Object System.Net.WebClient).DownloadFile(
        'https://github.com/fatedier/frp/releases/download/v0.34.2/frp_0.34.2_windows_amd64.zip',
        "$PWD/frp.zip")
    Write-Output 'Extracting frp...'
    tar xf frp.zip --strip-components=1
}

Pop-Location
