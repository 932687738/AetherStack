$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Backend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo backend
$Frontend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo frontend

Write-Host "=== AetherStack verify (associated repos) ==="
Write-Host "backend:  $Backend"
Write-Host "frontend: $Frontend"

if (Test-Path $Backend) {
    Push-Location $Backend
    mvn -B -q test
    Pop-Location
    foreach ($script in @(
            'check-spring-ai-tools.ps1',
            'check-spring-ai-rag.ps1',
            'check-spring-ai-react-graph.ps1'
        )) {
        $path = Join-Path $Root ".aetherstack\scripts\$script"
        if (Test-Path $path) { & $path }
    }
} else {
    Write-Warning "Backend repo not found"
}

if (Test-Path $Frontend) {
    Push-Location $Frontend
    npm run lint
    npm run build
    Pop-Location
} else {
    Write-Warning "Frontend repo not found"
}

Write-Host "verify completed"
