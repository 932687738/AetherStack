# 解析关联仓库路径（真源：.aetherstack/context/repos.yaml）
param(
    [ValidateSet('backend', 'frontend')]
    [string]$Repo = 'backend'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'repo-paths.ps1')

$cfg = Get-AetherRepoConfig -Name $Repo
if (-not (Test-Path $cfg.local)) {
    Write-Warning "Repository path does not exist: $($cfg.local)"
}
Write-Output $cfg.local
