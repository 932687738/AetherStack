# Initialize CodeGraph indexes for AetherStack governance + linked repos.
# Paths resolve from .aetherstack/context/repos.yaml (see repo-paths.ps1).

param(
    [switch]$Verbose,
    [switch]$StatusOnly
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $Root

. (Join-Path $Root 'scripts\repo-paths.ps1')

$repos = Get-AetherAllRepos -Root $Root
$targets = @(
    @{ Label = 'governance'; Path = $Root }
    @{ Label = 'backend'; Path = $repos.backend.local }
    @{ Label = 'frontend'; Path = $repos.frontend.local }
)

function Invoke-CodegraphStatus {
    param([string]$Path)
    & codegraph status $Path
    if ($LASTEXITCODE -ne 0) { throw "codegraph status failed for $Path" }
}

if ($StatusOnly) {
    foreach ($t in $targets) {
        Write-Host "`n=== $($t.Label): $($t.Path) ===" -ForegroundColor Cyan
        Invoke-CodegraphStatus -Path $t.Path
    }
    exit 0
}

foreach ($t in $targets) {
    if (-not (Test-Path $t.Path)) {
        throw "Repo path not found ($($t.Label)): $($t.Path)"
    }
    Write-Host "`n=== Initializing CodeGraph: $($t.Label) ($($t.Path)) ===" -ForegroundColor Cyan
    $args = @('init', $t.Path)
    if ($Verbose) { $args += '-v' }
    & codegraph @args
    if ($LASTEXITCODE -ne 0) { throw "codegraph init failed for $($t.Path)" }
}

Write-Host "`n=== Final status ===" -ForegroundColor Green
foreach ($t in $targets) {
    Write-Host "`n--- $($t.Label) ---" -ForegroundColor Cyan
    Invoke-CodegraphStatus -Path $t.Path
}

Write-Host "`nCodeGraph init completed. MCP config: .cursor/mcp.json (run make sync-config to refresh paths)." -ForegroundColor Green
