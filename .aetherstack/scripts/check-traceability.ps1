param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeDir
)

$ErrorActionPreference = 'Stop'
$tasksPath = Join-Path $ChangeDir 'tasks.md'
if (-not (Test-Path $tasksPath)) {
    Write-Output @{ status = 'skip'; issues = @('no tasks.md') } | ConvertTo-Json -Compress
    exit 0
}

$lines = Get-Content $tasksPath -Encoding UTF8
$issues = @()
$checked = 0

foreach ($line in $lines) {
    if ($line -notmatch 'AUTO-UT|AUTO-AI-UT') { continue }
    if ($line -notmatch '\[x\]') { continue }
    $checked++
    $hasTrace = ($line -match 'trace:\s*TC-REQ|TC-REQ\d|→\s*\w+Test\.java')
    if (-not $hasTrace) {
        $issues += "缺少追溯标记（须含 trace: TC-REQ… 或 → XxxTest.java）: $($line.Trim())"
    }
}

$testCases = Join-Path $ChangeDir 'test-cases.md'
if (Test-Path $testCases) {
    $tcContent = Get-Content $testCases -Raw -Encoding UTF8
    $autoCases = [regex]::Matches($tcContent, '\[C\].*?Automation:\s*(AUTO-UT|AUTO-AI-UT)', 'Singleline')
    foreach ($m in $autoCases) {
        if ($tcContent -notmatch 'TC-REQ') {
            $issues += 'test-cases.md 含 AUTO-UT/AUTO-AI-UT 但未发现 TC-REQ 编号'
            break
        }
    }
}

$status = 'pass'
if ($issues.Count -gt 0) {
    $status = 'fail'
}
if ($checked -eq 0 -and $issues.Count -eq 0) {
    $status = 'pass'
}

@{
    status  = $status
    checked = $checked
    issues  = $issues
} | ConvertTo-Json -Depth 5
