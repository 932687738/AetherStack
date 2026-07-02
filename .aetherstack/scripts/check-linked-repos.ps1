# 检查关联仓 ai / ai_react 是否可用于 make verify / completion-gate 全量门禁
param(
    [switch]$RequireBoth
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $Root 'scripts\repo-paths.ps1')

$backendCfg = Get-AetherRepoConfig -Name backend -Root $Root
$frontendCfg = Get-AetherRepoConfig -Name frontend -Root $Root
$backendPath = $backendCfg.local
$frontendPath = $frontendCfg.local

$backendOk = Test-Path $backendPath
$frontendOk = Test-Path $frontendPath
$bothOk = $backendOk -and $frontendOk

$status = 'pass'
$issues = @()
if ($RequireBoth -and -not $bothOk) {
    $status = 'fail'
    if (-not $backendOk) { $issues += "backend missing: $backendPath" }
    if (-not $frontendOk) { $issues += "frontend missing: $frontendPath" }
} elseif (-not $backendOk -and -not $frontendOk) {
    $status = 'warn'
    $issues += 'backend and frontend paths missing'
} elseif (-not $bothOk) {
    $status = 'warn'
    if (-not $backendOk) { $issues += "backend missing: $backendPath" }
    if (-not $frontendOk) { $issues += "frontend missing: $frontendPath" }
}

@{
    status          = $status
    backend         = @{ path = $backendPath; available = $backendOk }
    frontend        = @{ path = $frontendPath; available = $frontendOk }
    bothAvailable   = $bothOk
    envOverride     = @{
        backend  = [bool][Environment]::GetEnvironmentVariable('AETHER_BACKEND_REPO')
        frontend = [bool][Environment]::GetEnvironmentVariable('AETHER_FRONTEND_REPO')
    }
    issues          = $issues
} | ConvertTo-Json -Depth 6
