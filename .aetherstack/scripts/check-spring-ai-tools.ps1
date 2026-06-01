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

$agentsDir = Join-Path $Backend 'src\main\java'
if (-not (Test-Path $agentsDir)) {
    Write-Warning "No src/main/java under backend"
    exit 0
}

$q = [char]34
$tq = "$q$q$q"
$violations = New-Object System.Collections.Generic.List[string]
$javaFiles = Get-ChildItem -Path $agentsDir -Filter '*.java' -Recurse -File
$blockPattern = "@Tool\s*\(\s*description\s*=\s*$tq(.*?)$tq"
$stringPattern = '@Tool\s*\(\s*description\s*=\s*"([^"]*)"'

foreach ($file in $javaFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.UTF8Encoding]::new($false))
    if ($content -notmatch '@Tool\s*\(') { continue }

    $descriptions = New-Object System.Collections.Generic.List[string]
    [regex]::Matches($content, $blockPattern, 'Singleline') | ForEach-Object {
        $descriptions.Add($_.Groups[1].Value)
    }
    [regex]::Matches($content, $stringPattern, 'Singleline') | ForEach-Object {
        $descriptions.Add($_.Groups[1].Value)
    }

    if ($descriptions.Count -eq 0) {
        $rel = $file.FullName.Substring($Backend.Length).TrimStart('\', '/')
        $violations.Add("${rel}: @Tool 缺少可解析的 description")
        continue
    }

    foreach ($desc in $descriptions) {
        $hasPositive = ($desc -match '适用|场景|关键词|典型')
        $hasNegative = ($desc -match '不适用|反例|不得|不要|禁止')
        $rel = $file.FullName.Substring($Backend.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($desc)) {
            $violations.Add("${rel}: @Tool description 为空")
        } elseif (-not $hasPositive) {
            $violations.Add("${rel}: description 缺少「适用场景/典型问法」类表述")
        } elseif (-not $hasNegative) {
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
