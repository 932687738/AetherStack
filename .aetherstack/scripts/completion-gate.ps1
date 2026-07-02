param(
    [Parameter(Mandatory = $true)]
    [string]$Change,
    [switch]$SkipVerify,
    [switch]$AllowWarnings,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$changeDir = Join-Path $Root "openspec\changes\$Change"
if (-not (Test-Path $changeDir)) {
    Write-Error "Change directory not found: $changeDir"
    exit 1
}

function Get-UiCraftMode {
    param([string]$Dir)
    $p = Join-Path $Dir '.openspec.yaml'
    if (-not (Test-Path $p)) { return 'auto' }
    $raw = Get-Content $p -Raw -Encoding UTF8
    if ($raw -match 'uiCraftMode:\s*(\w+)') { return $Matches[1].Trim() }
    'auto'
}

function Test-ScopeNeeded {
    param([string]$TasksContent, [string]$Scope)
    switch ($Scope) {
        'backend' { return $TasksContent -match '后端|backend|AUTO-UT|AUTO-AI-UT|mvn\s|\.java|agents/|knowledgehub/' }
        'frontend' { return $TasksContent -match '前端|frontend|ai_react|UI-|npm\s|impeccable' }
    }
    $false
}

function Get-SchemaName {
    try {
        Push-Location $Root
        $json = openspec status --change $Change --json 2>$null
        Pop-Location
        if ($json) {
            $obj = $json | ConvertFrom-Json
            return $obj.schemaName
        }
    } catch { Pop-Location -ErrorAction SilentlyContinue }
    $null
}

$gatePath = Join-Path $changeDir '.completion-gate.json'
$critical = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

if ($CheckOnly) {
    if (-not (Test-Path $gatePath)) {
        Write-Error "No .completion-gate.json — run: make completion-gate CHANGE=$Change"
        exit 1
    }
    $g = Get-Content $gatePath -Raw | ConvertFrom-Json
    if ($g.overall -eq 'ready' -or ($AllowWarnings -and $g.overall -eq 'ready_with_warnings')) {
        Write-Host "Gate OK: $($g.overall)"
        exit 0
    }
    Write-Error "Gate not ready: $($g.overall)"
    exit 1
}

# --- tasks ---
$tasksPath = Join-Path $changeDir 'tasks.md'
$tasksStatus = 'pass'
$incomplete = 0
if (Test-Path $tasksPath) {
    $tasksContent = Get-Content $tasksPath -Raw -Encoding UTF8
    $incomplete = ([regex]::Matches($tasksContent, '- \[ \]')).Count
    if ($incomplete -gt 0) {
        $tasksStatus = 'fail'
        $critical.Add("tasks.md 仍有 $incomplete 项未完成")
    }
} else {
    $tasksStatus = 'warn'
    $warnings.Add('无 tasks.md，跳过任务完成检查')
    $tasksContent = ''
}

# --- design-review (standard only) ---
$schema = Get-SchemaName
$drStatus = 'skip'
if ($schema -eq 'standard-spec-driven') {
    $drPath = Join-Path $changeDir 'design-review.md'
    if (-not (Test-Path $drPath)) {
        $drStatus = 'fail'
        $critical.Add('standard 模式缺少 design-review.md')
    } elseif ((Get-Content $drPath -Raw) -notmatch 'Status:\s*Reviewed') {
        $drStatus = 'fail'
        $critical.Add('design-review.md 须 Status: Reviewed')
    } else {
        $drStatus = 'pass'
    }
}

# --- traceability ---
$traceJson = & (Join-Path $PSScriptRoot 'check-traceability.ps1') -ChangeDir $changeDir | ConvertFrom-Json
$traceStatus = $traceJson.status
foreach ($i in $traceJson.issues) {
    if ($traceStatus -eq 'fail') { $critical.Add("追溯: $i") }
    else { $warnings.Add("追溯: $i") }
}

# --- ui-craft ---
$uiJson = & (Join-Path $PSScriptRoot 'check-ui-craft-gate.ps1') -ChangeDir $changeDir | ConvertFrom-Json
$uiStatus = $uiJson.status
foreach ($i in $uiJson.issues) {
    if ($uiStatus -eq 'fail') { $critical.Add("UI-Craft: $i") }
    else { $warnings.Add("UI-Craft: $i") }
}

# --- openspec verify report ---
$verifyReport = Join-Path $changeDir 'verification-report.md'
$ovStatus = 'pending'
$ovPath = $null
if (Test-Path $verifyReport) {
    $vr = Get-Content $verifyReport -Raw -Encoding UTF8
    $ovPath = $verifyReport
    if ($vr -match 'All checks passed\. Ready for archive\.|Ready for archive \(with noted improvements\)\.') {
        $ovStatus = 'pass'
    } elseif ($vr -match 'critical issue\(s\) found') {
        $ovStatus = 'fail'
        $critical.Add('verification-report.md 含 CRITICAL，须先 /opsx-verify 修复')
    } else {
        $ovStatus = 'fail'
        $critical.Add('verification-report.md 缺少 Ready for archive 结论，请运行 /opsx-verify')
    }
} else {
    $critical.Add('缺少 verification-report.md — 归档前须 /opsx-verify 并保存报告到变更目录')
}

# --- superpowers steps ---
$spJson = & (Join-Path $PSScriptRoot 'check-superpowers-steps.ps1') -ChangeDir $changeDir | ConvertFrom-Json
$spStepsStatus = $spJson.status
foreach ($i in $spJson.issues) {
    if ($spStepsStatus -eq 'fail') { $critical.Add("Superpowers: $i") }
}
foreach ($i in $spJson.warnings) {
    $warnings.Add("Superpowers: $i")
}

# --- code review (from gate file or infer scope) ---
$cr = @{ backend = @{ status = 'pending' }; frontend = @{ status = 'pending' } }
$sp = @{ status = 'pending' }
if (Test-Path $gatePath) {
    $existing = Get-Content $gatePath -Raw | ConvertFrom-Json
    if ($existing.checks.codeReview) {
        if ($existing.checks.codeReview.backend) { $cr.backend = $existing.checks.codeReview.backend }
        if ($existing.checks.codeReview.frontend) { $cr.frontend = $existing.checks.codeReview.frontend }
    }
    if ($existing.checks.superpowersVerification) {
        $sp = $existing.checks.superpowersVerification
    }
}
$spStatus = if ($sp.status) { $sp.status } else { 'pending' }

foreach ($scope in @('backend', 'frontend')) {
    if (-not (Test-ScopeNeeded $tasksContent $scope)) { continue }
    $st = $cr[$scope].status
    if ($st -notin @('approved', 'waived')) {
        $critical.Add("code review [$scope] 须 approved 或 waived — record-code-review.ps1 -Change $Change -Scope $scope -Status approved")
    }
}

# --- harness verify ---
$hvStatus = if ($SkipVerify) { 'skip' } else { 'pending' }
if (-not $SkipVerify) {
    try {
        & (Join-Path $PSScriptRoot 'verify-all.ps1') -SpringAiStrict
        $hvStatus = 'pass'
    } catch {
        $hvStatus = 'fail'
        $critical.Add("make verify 失败: $_")
    }
}

$overall = 'not_ready'
if ($critical.Count -eq 0) {
    $overall = if ($warnings.Count -gt 0) { 'ready_with_warnings' } else { 'ready' }
}

if ($overall -eq 'ready_with_warnings' -and -not $AllowWarnings) {
    $critical.Add('存在 WARNING，归档须 -AllowWarnings 或修复警告项')
    $overall = 'not_ready'
}

$gate = @{
    version   = 1
    change    = $Change
    updatedAt = (Get-Date).ToString('o')
    overall   = $overall
    checks    = @{
        tasks                   = @{ status = $tasksStatus; incomplete = $incomplete }
        designReview            = @{ status = $drStatus; schema = $schema }
        traceability            = @{ status = $traceStatus; issues = @($traceJson.issues) }
        uiCraft                 = @{ status = $uiStatus; issues = @($uiJson.issues) }
        harnessVerify           = @{ status = $hvStatus; skipped = [bool]$SkipVerify }
        openspecVerify          = @{ status = $ovStatus; reportPath = $ovPath }
        codeReview              = $cr
        superpowersVerification = @{ status = $spStatus }
        superpowersSteps        = @{ status = $spStepsStatus; recorded = $spJson.recorded }
    }
    critical = @($critical)
    warnings = @($warnings)
}

$gate | ConvertTo-Json -Depth 12 | Set-Content $gatePath -Encoding UTF8

Write-Host "=== Completion Gate: $Change ==="
Write-Host "Overall: $overall"
if ($critical.Count) { $critical | ForEach-Object { Write-Host "CRITICAL: $_" } }
if ($warnings.Count) { $warnings | ForEach-Object { Write-Host "WARNING: $_" } }
Write-Host "Gate file: $gatePath"

if ($overall -eq 'ready' -or ($AllowWarnings -and $overall -eq 'ready_with_warnings')) {
    exit 0
}
exit 1
