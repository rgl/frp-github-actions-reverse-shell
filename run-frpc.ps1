Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# when running in CI override the frpc tls files.
if (Test-Path env:FRPC_TLS_CA_CERTIFICATE) {
    Write-Output 'Configuring certificates...'
    mkdir -Force ca | Out-Null
    Set-Content -Encoding Ascii ca/github-key.pem $env:FRPC_TLS_KEY
    Set-Content -Encoding Ascii ca/github.pem $env:FRPC_TLS_CERTIFICATE
    Set-Content -Encoding Ascii ca/ca.pem $env:FRPC_TLS_CA_CERTIFICATE
}

# set password when requested.
if (Test-Path env:RUNNER_PASSWORD) {
    Write-Output "Setting the $env:USERNAME user password..."
    Get-LocalUser $env:USERNAME `
        | Set-LocalUser `
            -Password (
                ConvertTo-SecureString `
                    -AsPlainText `
                    -Force `
                    $env:RUNNER_PASSWORD
            )
}

Write-Output 'Running frpc...'
./frp/frpc -c frpc-windows.ini 2>&1 | Select-Object {$_ -replace '[0-9\.]+:6969','***:6969'}; cmd /c exit 0
