# Workflow health check: OpenSpec x Harness x linked repos
param(
    [switch]$SkipVerifySmoke
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$fail = [System.Collections.Generic.List[string]]::new()
$warn = [System.Collections.Generic.List[string]]::new()
$ok = [System.Collections.Generic.List[string]]::new()

function Test-CommandExists {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host '=== AetherStack doctor ==='

if (Test-CommandExists 'openspec') {
    try {
        $ver = (openspec --version 2>&1 | Out-String).Trim()
        $ok.Add("openspec CLI: $ver")
    } catch {
        $warn.Add('openspec CLI present but --version failed')
    }
} else {
    $warn.Add('openspec CLI missing: npm i -g @fission-ai/openspec')
}

$backend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo backend
$frontend = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo frontend

if (Test-Path $backend) { $ok.Add("backend (ai): $backend") }
else { $fail.Add("backend path missing: $backend") }

if (Test-Path $frontend) { $ok.Add("frontend (ai_react): $frontend") }
else { $fail.Add("frontend path missing: $frontend") }

if (Test-CommandExists 'mvn') {
    $ok.Add('mvn: available (PATH)')
} else {
    try {
        $backendForMvn = & (Join-Path $Root 'scripts\resolve-repos.ps1') -Repo backend 2>$null
        $mvnPath = & (Join-Path $PSScriptRoot 'resolve-mvn.ps1') -BackendRepo $backendForMvn 2>$null
        if ($mvnPath) { $ok.Add("mvn: $mvnPath") }
        else { $warn.Add('mvn not resolved; set MAVEN_HOME or PATH') }
    } catch {
        $warn.Add('mvn not resolved; set MAVEN_HOME or PATH')
    }
}

if (Test-CommandExists 'node') { $ok.Add('node: available') }
else { $fail.Add('node not on PATH; required for harness and openspec') }

$harness = Join-Path $frontend 'scripts\harness.mjs'
if (Test-Path $harness) { $ok.Add("harness.mjs: $harness") }
else { $fail.Add("missing frontend harness CLI: $harness") }

foreach ($rel in @(
        '.aetherstack\scripts\verify-all.ps1',
        '.aetherstack\scripts\completion-gate.ps1',
        '.cursor\skills\harness-apply\SKILL.md',
        'harness\harness.config.yaml'
    )) {
    $p = Join-Path $Root $rel
    if (Test-Path $p) { $ok.Add("found: $rel") }
    else { $fail.Add("missing: $rel") }
}

$hooks = Join-Path $Root '.cursor\hooks.json'
if (Test-Path $hooks) { $ok.Add('Cursor hooks.json configured') }
else { $warn.Add('no .cursor/hooks.json; archive shell guard may be off') }

$warn.Add('Superpowers plugin cannot be auto-detected; use /add-plugin superpowers in Cursor')

if (-not $SkipVerifySmoke) {
    Write-Host ''
    Write-Host '--- verify smoke (backend mvn test when available) ---'
    if (Test-Path $backend) {
        try {
            $mvn = & (Join-Path $PSScriptRoot 'resolve-mvn.ps1') -BackendRepo $backend
            Push-Location $backend
            & $mvn -B -q test -DfailIfNoTests=false *> $null
            $code = $LASTEXITCODE
            Pop-Location
            if ($code -eq 0) { $ok.Add('smoke: backend mvn test passed') }
            else { $warn.Add("smoke: backend mvn test failed (exit $code); run make verify") }
        } catch {
            $warn.Add("smoke: skipped ($($_.Exception.Message))")
        }
    }
}

Write-Host ''
foreach ($m in $ok) { Write-Host "OK   $m" }
foreach ($m in $warn) { Write-Host "WARN $m" }
foreach ($m in $fail) { Write-Host "FAIL $m" }

Write-Host ''
if ($fail.Count -gt 0) {
    Write-Host "doctor: NOT READY ($($fail.Count) critical)"
    exit 1
}
Write-Host "doctor: OK ($($warn.Count) warning(s))"
exit 0
