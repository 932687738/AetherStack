# 解析关联仓库路径（读取 .aetherstack/context/repos.yaml）
param(
    [ValidateSet('backend', 'frontend')]
    [string]$Repo = 'backend'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$reposFile = Join-Path $Root '.aetherstack\context\repos.yaml'

function Get-RepoPath {
    param([string]$Name)
    $envKey = if ($Name -eq 'backend') { 'AETHER_BACKEND_REPO' } else { 'AETHER_FRONTEND_REPO' }
    $fromEnv = [Environment]::GetEnvironmentVariable($envKey)
    if ($fromEnv) { return $fromEnv.Trim() }

    if (-not (Test-Path $reposFile)) { throw "Missing $reposFile" }

    $inBlock = $false
    foreach ($line in [System.IO.File]::ReadAllLines($reposFile)) {
        if ($line -match ('^\s*' + [regex]::Escape($Name) + ':\s*$')) {
            $inBlock = $true
            continue
        }
        if ($inBlock -and $line -match '^\s+local:\s*(.+)\s*$') {
            return $matches[1].Trim()
        }
        if ($inBlock -and $line -match '^\S') {
            break
        }
    }
    throw "Cannot resolve path for $Name in repos.yaml"
}

$path = Get-RepoPath $Repo
if (-not (Test-Path $path)) {
    Write-Warning "Repository path does not exist: $path"
}
Write-Output $path
