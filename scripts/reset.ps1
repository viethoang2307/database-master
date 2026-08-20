param(
    [switch]$ConfirmReset
)

$ErrorActionPreference = 'Stop'

if (-not $ConfirmReset) {
    throw 'This removes the local PostgreSQL volume. Re-run with -ConfirmReset if that is intentional.'
}

docker compose down -v
Write-Output 'Local PostgreSQL volume removed. Run ./scripts/bootstrap.ps1 to recreate the lab database.'

