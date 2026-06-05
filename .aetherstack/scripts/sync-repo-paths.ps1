# 从 repos.yaml 生成路径衍生配置（由 sync-config.ps1 调用）

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $Root

. (Join-Path $Root 'scripts\repo-paths.ps1')

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Read-Utf8 {
    param([string]$Path)
    [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

$repos = Get-AetherAllRepos -Root $Root
$backend = $repos.backend.local
$frontend = $repos.frontend.local
$backendFs = ConvertTo-ForwardSlashPath $backend
$frontendFs = ConvertTo-ForwardSlashPath $frontend
$backendRel = Get-WorkspaceRelativeRepoPath -AbsolutePath $backend -WorkspaceRoot $Root
$frontendRel = Get-WorkspaceRelativeRepoPath -AbsolutePath $frontend -WorkspaceRoot $Root
$backendWin = $backend -replace '/', '\'
$frontendWin = $frontend -replace '/', '\'

# --- aether-dev.code-workspace (hand-built JSON for stable UTF-8) ---
$workspaceJson = @"
{
  "//": "AUTO-GENERATED from .aetherstack/context/repos.yaml - run: make sync-config",
  "folders": [
    { "name": "AetherStack (governance)", "path": "." },
    { "name": "$($repos.backend.name) (backend)", "path": "$backendRel" },
    { "name": "$($repos.frontend.name) (frontend)", "path": "$frontendRel" }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true,
      "**/target": true
    }
  }
}
"@
Write-Utf8NoBom (Join-Path $Root 'aether-dev.code-workspace') $workspaceJson.Trim()

# --- .cursor/sandbox.json ---
$sandbox = @{
    '//' = 'AUTO-GENERATED from repos.yaml — run: make sync-config'
    type = 'workspace_readwrite'
    additionalReadwritePaths = @($backendFs, $frontendFs)
    enableSharedBuildCache = $true
} | ConvertTo-Json -Depth 4
Write-Utf8NoBom (Join-Path $Root '.cursor\sandbox.json') $sandbox

# --- .cursor/permissions.json ---
$permissions = @"
{
  "//": "AUTO-GENERATED from repos.yaml — run: make sync-config",
  "terminalAllowlist": [
    "git",
    "mvn",
    "npm",
    "pnpm",
    "yarn",
    "make",
    "harness",
    "powershell",
    "pwsh"
  ],
  "autoRun": {
    "allow_instructions": [
      "Read-only git status, diff, log, and file inspection under $($backendFs) and $($frontendFs) are fine without asking.",
      "Build, lint, and test commands for backend (mvn) and frontend (npm) in linked repos are fine without asking.",
      "Harness verify and OpenSpec read-only commands in AetherStack are fine without asking."
    ],
    "block_instructions": [
      "Any command that deletes databases, pushes to remote, or writes secrets to .env must ask for approval.",
      "Any command outside linked repos ($($backendFs), $($frontendFs)) and AetherStack should ask for approval."
    ]
  }
}
"@
Write-Utf8NoBom (Join-Path $Root '.cursor\permissions.json') $permissions.Trim()

# --- LOCALPATH.md ---
$localpathTpl = Join-Path $Root '.aetherstack\templates\LOCALPATH.md.tpl'
$localpath = (Read-Utf8 $localpathTpl) `
    -replace '\{\{BACKEND_NAME\}\}', $repos.backend.name `
    -replace '\{\{FRONTEND_NAME\}\}', $repos.frontend.name `
    -replace '\{\{BACKEND_PATH_WIN\}\}', $backendWin `
    -replace '\{\{FRONTEND_PATH_WIN\}\}', $frontendWin
Write-Utf8NoBom (Join-Path $Root 'LOCALPATH.md') $localpath

# --- api-contracts.yaml (repo 段) ---
$apiContractsPath = Join-Path $Root '.aetherstack\context\api-contracts.yaml'
$apiLines = [System.IO.File]::ReadAllLines($apiContractsPath, [System.Text.UTF8Encoding]::new($false))
$marker = '# --- REPO PATHS (AUTO-GENERATED from repos.yaml'
$cutIndex = -1
for ($i = 0; $i -lt $apiLines.Length; $i++) {
    if ($apiLines[$i] -match '^(frontend_repo:|# --- REPO PATHS)') {
        $cutIndex = $i
        break
    }
}
if ($cutIndex -lt 0) { $cutIndex = $apiLines.Length }

$head = if ($cutIndex -gt 0) { $apiLines[0..($cutIndex - 1)] } else { @() }
# trim trailing blank lines from head
while ($head.Length -gt 0 -and [string]::IsNullOrWhiteSpace($head[-1])) {
    $head = $head[0..($head.Length - 2)]
}

$fe = $frontendFs
$repoBlock = @(
    ''
    "$marker; make sync-config) ---"
    "frontend_repo: $fe"
    "frontend_api_paths: $(Join-RepoPath $frontend @('src','constants','ApiPaths.ts'))"
    'frontend_services:'
    "  chat: $(Join-RepoPath $frontend @('src','services','chatService.ts'))"
    "  conversation: $(Join-RepoPath $frontend @('src','services','conversationService.ts'))"
    "  conversation_persist: $(Join-RepoPath $frontend @('src','services','conversationPersist.ts'))"
    "  knowledge: $(Join-RepoPath $frontend @('src','services','knowledgeService.ts'))"
    "  agent_hub: $(Join-RepoPath $frontend @('src','services','agentHubService.ts'))"
    "  conversation_config: $(Join-RepoPath $frontend @('src','services','conversationConfigService.ts'))"
    "  human_loop: $(Join-RepoPath $frontend @('src','services','humanLoopService.ts'))"
    "  sse: $(Join-RepoPath $frontend @('src','utils','StreamSse.ts'))"
    "legacy_frontend_reference: $(Join-RepoPath $frontend @('legacy-vite'))"
    "backend_repo: $backendFs"
)

$merged = $head + $repoBlock
Write-Utf8NoBom $apiContractsPath (($merged -join "`n") + "`n")

Write-Host "sync-repo-paths: workspace, sandbox, permissions, LOCALPATH, api-contracts (repo section)"
