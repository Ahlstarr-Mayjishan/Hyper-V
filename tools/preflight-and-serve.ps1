$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host ""
Write-Host "Running Hyper-V preflight..." -ForegroundColor Cyan
& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\preflight-check.ps1"

if ($LASTEXITCODE -ne 0) {
	Write-Host ""
	Write-Host "Preflight failed. Rojo serve was not started." -ForegroundColor Red
	exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Preflight passed. Starting Rojo..." -ForegroundColor Green
& rojo serve
