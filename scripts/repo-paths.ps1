# 从 .aetherstack/context/repos.yaml 解析关联仓库路径（唯一配置真源）
# 被 resolve-repos.ps1、sync-config.ps1 等复用

function Get-AetherStackRoot {
    if ($env:AETHERSTACK_ROOT) {
        return $env:AETHERSTACK_ROOT.TrimEnd('\', '/')
    }
    $caller = $MyInvocation.PSCommandPath
    if ($caller) {
        return (Split-Path (Split-Path $caller -Parent) -Parent)
    }
    return (Get-Location).Path
}

function Get-AetherReposFile {
    param([string]$Root = (Get-AetherStackRoot))
    Join-Path $Root '.aetherstack\context\repos.yaml'
}

function Get-AetherRepoConfig {
    param(
        [ValidateSet('backend', 'frontend')]
        [string]$Name,
        [string]$Root = (Get-AetherStackRoot)
    )

    $envKey = if ($Name -eq 'backend') { 'AETHER_BACKEND_REPO' } else { 'AETHER_FRONTEND_REPO' }
    $fromEnv = [Environment]::GetEnvironmentVariable($envKey)
    if ($fromEnv) {
        return @{
            key  = $Name
            name = if ($Name -eq 'backend') { 'ai' } else { 'ai_react' }
            local = $fromEnv.Trim().TrimEnd('\', '/')
        }
    }

    $reposFile = Get-AetherReposFile -Root $Root
    if (-not (Test-Path $reposFile)) { throw "Missing $reposFile" }

    $inBlock = $false
    $repoName = $null
    $local = $null
    foreach ($line in [System.IO.File]::ReadAllLines($reposFile)) {
        if ($line -match ('^\s*' + [regex]::Escape($Name) + ':\s*$')) {
            $inBlock = $true
            $repoName = $null
            $local = $null
            continue
        }
        if ($inBlock -and $line -match '^\s+name:\s*(.+)\s*$') {
            $repoName = $matches[1].Trim()
            continue
        }
        if ($inBlock -and $line -match '^\s+local:\s*(.+)\s*$') {
            $local = $matches[1].Trim().TrimEnd('\', '/')
            break
        }
        if ($inBlock -and $line -match '^\S') {
            break
        }
    }

    if (-not $local) { throw "Cannot resolve path for $Name in repos.yaml" }

    @{
        key   = $Name
        name  = if ($repoName) { $repoName } else { if ($Name -eq 'backend') { 'ai' } else { 'ai_react' } }
        local = $local
    }
}

function Get-AetherAllRepos {
    param([string]$Root = (Get-AetherStackRoot))
    @{
        backend  = Get-AetherRepoConfig -Name backend -Root $Root
        frontend = Get-AetherRepoConfig -Name frontend -Root $Root
        root     = $Root
    }
}

function ConvertTo-ForwardSlashPath {
    param([string]$Path)
    ($Path -replace '\\', '/').TrimEnd('/')
}

function Get-WorkspaceRelativeRepoPath {
    param(
        [string]$AbsolutePath,
        [string]$WorkspaceRoot = (Get-AetherStackRoot)
    )
    $abs = [System.IO.Path]::GetFullPath($AbsolutePath).TrimEnd('\')
    $ws = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\')
    if ($abs.Equals($ws, [StringComparison]::OrdinalIgnoreCase)) {
        return '.'
    }

    # Compatible with Windows PowerShell 5.1 (no Path.GetRelativePath)
    $absParts = $abs.Split([System.IO.Path]::DirectorySeparatorChar)
    $wsParts = $ws.Split([System.IO.Path]::DirectorySeparatorChar)
    $shared = 0
    for ($i = 0; $i -lt [Math]::Min($absParts.Length, $wsParts.Length); $i++) {
        if ($absParts[$i].Equals($wsParts[$i], [StringComparison]::OrdinalIgnoreCase)) {
            $shared++
        } else {
            break
        }
    }
    $up = @('..') * ($wsParts.Length - $shared)
    $down = $absParts[$shared..($absParts.Length - 1)]
    ($up + $down) -join '/'
}

function Join-RepoPath {
    param(
        [string]$RepoRoot,
        [string[]]$Segments
    )
    $p = $RepoRoot
    foreach ($seg in $Segments) {
        $p = Join-Path $p $seg
    }
    ConvertTo-ForwardSlashPath $p
}
