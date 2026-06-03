param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeDir
)

$ErrorActionPreference = 'Stop'
$openspecYaml = Join-Path $ChangeDir '.openspec.yaml'
$mode = 'auto'
if (Test-Path $openspecYaml) {
    $raw = Get-Content $openspecYaml -Raw -Encoding UTF8
    if ($raw -match 'uiCraftMode:\s*(\w+)') { $mode = $Matches[1].Trim() }
}

if ($mode -eq 'disabled') {
    @{ status = 'skip'; issues = @() } | ConvertTo-Json -Compress
    exit 0
}

$tasksPath = Join-Path $ChangeDir 'tasks.md'
if (-not (Test-Path $tasksPath)) {
    @{ status = 'skip'; issues = @('no tasks.md') } | ConvertTo-Json -Compress
    exit 0
}

$lines = Get-Content $tasksPath -Encoding UTF8
$u1Lines = $lines | Where-Object { $_ -match 'UI-CRAFT|UI-AUDIT' }
if ($u1Lines.Count -eq 0 -and $mode -eq 'auto') {
    @{ status = 'skip'; issues = @('no U1 tasks') } | ConvertTo-Json -Compress
    exit 0
}

$issues = @()
foreach ($line in $u1Lines) {
    if ($line -notmatch '\[x\]') {
        if ($line -match '\[ \]') {
            $issues += "U1 任务未完成: $($line.Trim())"
        }
        continue
    }
    if ($line -notmatch 'impeccable:\s*\S+|Impeccable:\s*\S+') {
        $issues += "U1 已勾选但缺少 impeccable: 验收标记（如 impeccable: shape+craft）: $($line.Trim())"
    }
}

$status = 'pass'
if ($issues.Count -gt 0) { $status = 'fail' }

@{ status = $status; uiCraftMode = $mode; issues = $issues } | ConvertTo-Json -Depth 5
