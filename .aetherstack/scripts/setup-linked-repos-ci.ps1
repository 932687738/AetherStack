# CI：检出关联仓到 .linked/ 并写入 GITHUB_ENV（AETHER_BACKEND_REPO / AETHER_FRONTEND_REPO）
# 变量：AETHER_AI_REPOSITORY、AETHER_FRONTEND_REPOSITORY（owner/repo）；可选 AETHER_LINKED_REF（默认 main）

$ErrorActionPreference = 'Stop'
$Root = if ($env:AETHERSTACK_ROOT) { $env:AETHERSTACK_ROOT } else { $env:GITHUB_WORKSPACE }
if (-not $Root) { throw 'GITHUB_WORKSPACE or AETHERSTACK_ROOT required' }

$linkedRoot = Join-Path $Root '.linked'
New-Item -ItemType Directory -Force -Path $linkedRoot | Out-Null

$ref = if ($env:AETHER_LINKED_REF) { $env:AETHER_LINKED_REF } else { 'main' }
$token = $env:GH_PAT
if (-not $token) { $token = $env:GITHUB_TOKEN }

function Clone-LinkedRepo {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$TargetDir
    )
    if (Test-Path (Join-Path $TargetDir '.git')) {
        Write-Host "linked repo already present: $TargetDir"
        return
    }
    if (-not $Repository) {
        Write-Host "skip clone (repository not configured): $TargetDir"
        return
    }
    $url = if ($token) {
        "https://x-access-token:${token}@github.com/${Repository}.git"
    } else {
        "https://github.com/${Repository}.git"
    }
    Write-Host "cloning $Repository -> $TargetDir (ref=$ref)"
    git clone --depth 1 --branch $ref $url $TargetDir
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed: $Repository"
    }
}

$backendDir = Join-Path $linkedRoot 'ai'
$frontendDir = Join-Path $linkedRoot 'ai_react'

Clone-LinkedRepo -Repository $env:AETHER_AI_REPOSITORY -TargetDir $backendDir
Clone-LinkedRepo -Repository $env:AETHER_FRONTEND_REPOSITORY -TargetDir $frontendDir

if ($env:GITHUB_ENV) {
    "AETHER_BACKEND_REPO=$backendDir" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    "AETHER_FRONTEND_REPO=$frontendDir" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
}

Write-Host "linked backend:  $backendDir (exists=$(Test-Path $backendDir))"
Write-Host "linked frontend: $frontendDir (exists=$(Test-Path $frontendDir))"
