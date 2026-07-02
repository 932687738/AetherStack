# Validate Superpowers / completion-step records for a change directory
param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeDir
)

$ErrorActionPreference = 'Stop'
$issues = @()
$warnings = @()

$gatePath = Join-Path $ChangeDir '.completion-gate.json'
$verifyReport = Join-Path $ChangeDir 'verification-report.md'
$tasksPath = Join-Path $ChangeDir 'tasks.md'

$spRecorded = $false
$spAt = $null
if (Test-Path $gatePath) {
    $gate = Get-Content $gatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($gate.checks.superpowersVerification -and $gate.checks.superpowersVerification.status -eq 'done') {
        $spRecorded = $true
        $spAt = $gate.checks.superpowersVerification.at
    }
}

if (-not $spRecorded) {
    $issues += '未记录 superpowersVerification=done（须 invoke verification-before-completion 后 record-completion-step.ps1）'
}

$hasAiTdd = $false
$hasAutoAiUt = $false
if (Test-Path $tasksPath) {
    $tasksRaw = Get-Content $tasksPath -Raw -Encoding UTF8
    if ($tasksRaw -match 'AUTO-AI-UT') { $hasAutoAiUt = $true }
    if ($tasksRaw -match 'aiTddMode:\s*enabled' -or (Test-Path (Join-Path $ChangeDir '.openspec.yaml'))) {
        $openspec = Join-Path $ChangeDir '.openspec.yaml'
        if (Test-Path $openspec) {
            $os = Get-Content $openspec -Raw -Encoding UTF8
            if ($os -match 'aiTddMode:\s*enabled') { $hasAiTdd = $true }
        }
    }
}

if ($hasAutoAiUt -or $hasAiTdd) {
    if (Test-Path $verifyReport) {
        $vr = Get-Content $verifyReport -Raw -Encoding UTF8
        if ($vr -notmatch 'AUTO-AI-UT|AI-TDD|test-driven|TDD') {
            $warnings += '变更含 AUTO-AI-UT/aiTddMode enabled，verification-report 未提及 TDD/AUTO-AI-UT 覆盖'
        }
    } else {
        $warnings += '含 AI-TDD 任务但尚无 verification-report.md'
    }
}

if (Test-Path $verifyReport) {
    $vr = Get-Content $verifyReport -Raw -Encoding UTF8
    if ($vr -notmatch 'Final Assessment|Ready for archive|critical issue') {
        $warnings += 'verification-report.md 缺少 Final Assessment 结论段'
    }
} elseif ($spRecorded) {
    $warnings += '已记录 superpowersVerification 但缺少 verification-report.md'
}

$status = if ($issues.Count -gt 0) { 'fail' } elseif ($warnings.Count -gt 0) { 'warn' } else { 'pass' }

@{
    status   = $status
    recorded = $spRecorded
    at       = $spAt
    issues   = $issues
    warnings = $warnings
} | ConvertTo-Json -Depth 5
