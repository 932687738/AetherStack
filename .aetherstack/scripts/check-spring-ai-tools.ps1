# 静态检查 ai 仓库中 @Tool description 是否符合多 Agent 规范
# 治理仓执行。退出码：0=通过，1=存在违规（仅 -Strict）

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

. (Join-Path $PSScriptRoot 'spring-ai-scan-utils.ps1')
$javaFiles = Get-BackendJavaSourceFiles -BackendRoot $Backend -ProductionOnly
Assert-BackendJavaSources -BackendRoot $Backend -Files $javaFiles -Strict:$Strict

$q = [char]34
$tq = "$q$q$q"
$violations = New-Object System.Collections.Generic.List[string]
$blockPattern = '@Tool\s*\(\s*description\s*=\s*' + $tq + '(.*?)' + $tq
# 排除 Java 17 文本块 """ — 仅匹配单行字符串 description
$stringPattern = '@Tool\s*\(\s*description\s*=\s*"(?!"")([^"]*)"'

function Test-ToolDescription {
    param([string]$Desc)
    # ASCII-only script file: Chinese keywords via \u escapes (PS 5.1 default encoding safe)
    $positivePattern = '\u9002\u7528|\u573a\u666f|\u5173\u952e\u8bcd|\u5178\u578b|When to use|Use when|Typical'
    $negativePattern = '\u4e0d\u9002\u7528|\u53cd\u4f8b|\u4e0d\u5f97|\u4e0d\u8981|\u7981\u6b62|Do not|When not|Avoid|Not for'
    $hasPositive = ($Desc -match $positivePattern)
    $hasNegative = ($Desc -match $negativePattern)
    return @{ positive = $hasPositive; negative = $hasNegative }
}

foreach ($file in $javaFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.UTF8Encoding]::new($false))
    $rel = $file.FullName.Substring($Backend.Length).TrimStart('\', '/')
    if ($rel -match 'devtools[/\\]AetherAgentGenRenderer\.java') { continue }
    if ($content -notmatch '@Tool\s*\(') { continue }

    $descriptions = New-Object System.Collections.Generic.List[string]
    if ($content -match '@Tool\s*\(\s*description\s*=\s*"""') {
        [regex]::Matches($content, $blockPattern, 'Singleline') | ForEach-Object {
            $descriptions.Add($_.Groups[1].Value.Trim())
        }
    } else {
        [regex]::Matches($content, $stringPattern, 'Singleline') | ForEach-Object {
            $descriptions.Add($_.Groups[1].Value.Trim())
        }
    }

    if ($descriptions.Count -eq 0) {
        $violations.Add("${rel}: @Tool 缺少可解析的 description")
        continue
    }

    foreach ($desc in $descriptions) {
        if ([string]::IsNullOrWhiteSpace($desc)) {
            $violations.Add("${rel}: @Tool description 为空")
            continue
        }
        $check = Test-ToolDescription -Desc $desc
        if (-not $check.positive) {
            $violations.Add("${rel}: description 缺少「适用场景/典型问法」类表述")
        } elseif (-not $check.negative) {
            $violations.Add("${rel}: description 缺少「不适用/反例」类表述")
        }
    }
}

Write-Host "=== Spring AI @Tool description check ==="
Write-Host "backend: $Backend"
Write-Host "files scanned: $($javaFiles.Count)"

if ($violations.Count -eq 0) {
    Write-Host "OK: no @Tool description violations"
    exit 0
}

Write-Host "Found $($violations.Count) issue(s):"
foreach ($v in $violations) {
    Write-Host "  - $v"
}

if ($Strict) { exit 1 }
Write-Host "(non-strict mode: exit 0; use -Strict to fail)"
exit 0
