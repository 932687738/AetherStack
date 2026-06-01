# 静态检查 ai 仓库 ReactAgent / CompiledGraph 常见反模式
# 退出码：0=通过，1=存在违规（仅 -Strict）

param(
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Backend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo backend

if (-not (Test-Path $Backend)) {
    Write-Warning "Backend repo not found: $Backend"
    exit 0
}

$srcDir = Join-Path $Backend 'src\main\java'
if (-not (Test-Path $srcDir)) {
    Write-Warning "No src/main/java under backend"
    exit 0
}

function Add-Violation {
    param([string]$Rel, [string]$Message)
    $script:violations.Add($Rel + ': ' + $Message)
}

$violations = New-Object System.Collections.Generic.List[string]
$javaFiles = Get-ChildItem -Path $srcDir -Filter '*.java' -Recurse -File

foreach ($file in $javaFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.UTF8Encoding]::new($false))
    $rel = $file.FullName.Substring($Backend.Length).TrimStart('\', '/')

    if ($rel -match 'graph[/\\]' -and $content -match 'import\s+[\w.]+\.web\.dto') {
        Add-Violation $rel 'Graph node must not import web.dto'
    }

    if ($rel -match 'agents[/\\]' -and $content -match 'while\s*\(' -and $content -match '@Tool|toolCall|ToolCallback') {
        Add-Violation $rel 'Avoid manual while-loop tool orchestration in agents (use ReactAgent/CompiledGraph)'
    }

    $isDemo = $rel -match 'springai[/\\]'
    if (-not $isDemo -and $content -match 'ReactAgent|ToolCallingAgent|ReActAgent') {
        if ($content -notmatch 'maxIterations|max-iterations|max_iterations|MAX_ITERATIONS') {
            Add-Violation $rel 'ReactAgent must configure maxIterations (or equivalent)'
        }
    }

    if ($content -match 'buildLinearGraph\s*\(' -and $content -notmatch '@Bean|@Configuration|ConfigurableGraphBuilder') {
        Add-Violation $rel 'buildLinearGraph should live in @Configuration as singleton CompiledGraph Bean'
    }
}

Write-Host '=== Spring AI ReactAgent / CompiledGraph check ==='
Write-Host "backend: $Backend"
Write-Host "files scanned: $($javaFiles.Count)"

if ($violations.Count -eq 0) {
    Write-Host 'OK: no react/graph pattern violations'
    exit 0
}

Write-Host "Found $($violations.Count) issue(s):"
foreach ($v in $violations) {
    Write-Host "  - $v"
}

if ($Strict) { exit 1 }
Write-Host '(non-strict mode: exit 0; use -Strict to fail)'
exit 0
