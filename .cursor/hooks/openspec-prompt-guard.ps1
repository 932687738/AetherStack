# Cursor beforeSubmitPrompt — OpenSpec / Superpowers 编排提醒
$ErrorActionPreference = 'SilentlyContinue'
$stdin = [Console]::In.ReadToEnd()
if (-not $stdin) { exit 0 }

try {
    $payload = $stdin | ConvertFrom-Json
} catch {
    exit 0
}

$prompt = ''
if ($payload.prompt) { $prompt = [string]$payload.prompt }
elseif ($payload.text) { $prompt = [string]$payload.text }
if (-not $prompt) { exit 0 }

$ctx = @()
$root = (Get-Location).Path

if ($prompt -match 'opsx-archive|/opsx:archive|归档.*变更') {
    $ctx += '【完成门禁】归档前须：/opsx-verify → verification-report.md → make completion-gate CHANGE=<id> → record-code-review → /opsx-archive。见 openspec/references/completion-gate.md'
}

if ($prompt -match 'opsx-apply|/opsx:apply') {
    $ctx += '【Harness】实现类 task 须 Analyze→Code→Verify；见 harness-apply/SKILL.md'
}

if ($prompt -match 'design\.md|完成设计|design 完成') {
    $ctx += '【standard】design 后须 brainstorming → design-review.md Status: Reviewed，再 test-cases/tasks'
}

if ($prompt -match 'writing-plans|executing-plans') {
    $ctx += '【计划路由】已有 OpenSpec tasks.md 时用 /opsx-apply，勿 parallel executing-plans。见 workflow-planning-routing.md'
}

if ($prompt -match 'UI-CRAFT|UI-AUDIT|impeccable|Impeccable') {
    $ctx += '【UI-Craft】U1 勾选须含 impeccable: 标记；门禁 check-ui-craft-gate.ps1'
}

if ($ctx.Count -eq 0) { exit 0 }

$msg = ($ctx -join "`n")
# Inject context for agent (fail-open)
@{
    continue           = $true
    additional_context = $msg
} | ConvertTo-Json -Compress | Write-Output
exit 0
