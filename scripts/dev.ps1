# 一键开发：在关联仓库中启动（不内嵌前后端代码）
param(
    [switch]$DockerOnly,
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

$Root = Split-Path $PSScriptRoot -Parent
$Backend = & (Join-Path $PSScriptRoot 'resolve-repos.ps1') -Repo backend
$Frontend = & (Join-Path $PSScriptRoot 'resolve-repos.ps1') -Repo frontend

if (-not (Test-Path $Backend)) { throw "Backend repo not found: $Backend" }
if (-not (Test-Path $Frontend)) { throw "Frontend repo not found: $Frontend" }

if (-not $BackendOnly -and -not $FrontendOnly) {
    Write-Host "[1/3] Starting pgvector in backend repo..." -ForegroundColor Cyan
    Push-Location $Backend
    docker compose up -d
    Pop-Location
}

if ($DockerOnly) { exit 0 }

if (-not $FrontendOnly) {
    Write-Host "[2/3] Start backend (in associated repo):" -ForegroundColor Yellow
    Write-Host "  cd `"$Backend`""
    Write-Host "  `$env:POSTGRES_JDBC_URL='jdbc:postgresql://127.0.0.1:5432/agenthub'"
    Write-Host "  `$env:POSTGRES_USERNAME='postgres'; `$env:POSTGRES_PASSWORD='secret'"
    Write-Host "  mvn spring-boot:run"
}

if (-not $BackendOnly) {
    Write-Host "[3/3] Start frontend (in associated repo):" -ForegroundColor Yellow
    Write-Host "  cd `"$Frontend`""
    Write-Host "  npm install; npm run dev"
}

Write-Host ""
Write-Host "AetherStack governance (openspec/.aetherstack) works offline in: $Root" -ForegroundColor Green
