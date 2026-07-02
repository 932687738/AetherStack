param(
    [switch]$SpringAiStrict
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Backend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo backend
$Frontend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo frontend
$Mvn = & (Join-Path $PSScriptRoot 'resolve-mvn.ps1') -BackendRepo $Backend

function Assert-LastExitCode {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$Step failed (exit $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}

Write-Host "=== AetherStack verify (associated repos) ==="
Write-Host "backend:  $Backend"
Write-Host "frontend: $Frontend"
Write-Host "mvn:      $Mvn"

if (Test-Path $Backend) {
    Push-Location $Backend
    & $Mvn -B -q test
    Assert-LastExitCode 'backend mvn test'
    Pop-Location

    foreach ($script in @(
            'check-spring-ai-tools.ps1',
            'check-spring-ai-rag.ps1',
            'check-spring-ai-react-graph.ps1'
        )) {
        $path = Join-Path $Root ".aetherstack\scripts\$script"
        if (Test-Path $path) {
            if ($SpringAiStrict) { & $path -Strict } else { & $path }
            if ($SpringAiStrict) { Assert-LastExitCode "spring-ai check $script" }
        }
    }
} else {
    Write-Warning "Backend repo not found"
}

if (Test-Path $Frontend) {
    Push-Location $Frontend
    $harness = Join-Path $Frontend 'scripts\harness.mjs'
    if (-not (Test-Path $harness)) {
        Write-Error "Frontend harness CLI not found: $harness"
        exit 1
    }
    Write-Host "[frontend] harness lint"
    node $harness lint
    Assert-LastExitCode 'frontend harness lint'
    Write-Host "[frontend] harness build (max build + playwright e2e)"
    node $harness build
    Assert-LastExitCode 'frontend harness build'
    Pop-Location
} else {
    Write-Warning "Frontend repo not found"
}

Write-Host "verify completed"
