# Cursor beforeShellExecution — 阻断未通过 gate 的 openspec 归档 mv
$ErrorActionPreference = 'SilentlyContinue'
$stdin = [Console]::In.ReadToEnd()
if (-not $stdin) {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

try {
    $payload = $stdin | ConvertFrom-Json
} catch {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

$command = [string]$payload.command
if (-not $command) {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

if ($command -notmatch 'openspec[/\\]changes[/\\][^/\\]+[/\\]archive|openspec[/\\]changes[/\\]archive') {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

$change = $null
if ($command -match 'openspec[/\\]changes[/\\]([^/\\]+)[/\\]archive') {
    $change = $Matches[1]
}
if ($command -match 'mv\s+[^\s]*openspec[/\\]changes[/\\]([^/\\\s]+)') {
    $change = $Matches[1]
}
if (-not $change -or $change -eq 'archive') {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

$gateScript = Join-Path (Get-Location) '.aetherstack/scripts/completion-gate.ps1'
if (-not (Test-Path $gateScript)) {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $gateScript -Change $change -CheckOnly 2>$null
if ($LASTEXITCODE -eq 0) {
    '{"permission":"allow"}' | Write-Output
    exit 0
}

$deny = @{
    permission     = 'deny'
    user_message   = "归档被阻断：请先 make completion-gate CHANGE=$change（见 completion-gate.md）"
    agent_message  = "Run: make completion-gate CHANGE=$change after /opsx-verify, cr, and record scripts."
} | ConvertTo-Json -Compress
Write-Output $deny
exit 2
