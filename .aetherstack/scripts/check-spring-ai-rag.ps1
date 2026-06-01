# Static check: RAG @Tool descriptions under knowledgehub/
# Run from governance repo. Exit 0=pass, 1=violations (with -Strict only)

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

$knowledgeDir = Join-Path $Backend 'src\main\java'
if (-not (Test-Path $knowledgeDir)) {
    Write-Warning "No src/main/java under backend"
    exit 0
}

$q = [char]34
$tq = "$q$q$q"
$violations = New-Object System.Collections.Generic.List[string]
$ragKeywords = '检索|搜索|search|FAQ|知识库|RAG|向量|召回'
$kbKeywords = '知识库|FAQ|KB|knowledge'
$returnKeywords = '返回|摘要|条|全文|Top'
$javaFiles = Get-ChildItem -Path $knowledgeDir -Filter '*.java' -Recurse -File |
    Where-Object { $_.FullName -match '\\knowledgehub\\' }

$blockPattern = "@Tool\s*\(\s*description\s*=\s*$tq(.*?)$tq"
$stringPattern = '@Tool\s*\(\s*description\s*=\s*"([^"]*)"'

foreach ($file in $javaFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.UTF8Encoding]::new($false))
    if ($content -notmatch '@Tool\s*\(') { continue }
    if ($content -notmatch $ragKeywords) { continue }

    $descriptions = New-Object System.Collections.Generic.List[string]
    [regex]::Matches($content, $blockPattern, 'Singleline') | ForEach-Object {
        $descriptions.Add($_.Groups[1].Value)
    }
    [regex]::Matches($content, $stringPattern, 'Singleline') | ForEach-Object {
        $descriptions.Add($_.Groups[1].Value)
    }

    $rel = $file.FullName.Substring($Backend.Length).TrimStart('\', '/')

    if ($descriptions.Count -eq 0) {
        $violations.Add("${rel}: RAG @Tool missing parseable description")
        continue
    }

    foreach ($desc in $descriptions) {
        $hasPositive = ($desc -match '适用|场景|关键词|典型')
        $hasNegative = ($desc -match '不适用|反例|不得|不要|禁止')
        $hasKb = ($desc -match $kbKeywords)
        $hasReturn = ($desc -match $returnKeywords)

        if ([string]::IsNullOrWhiteSpace($desc)) {
            $violations.Add("${rel}: RAG @Tool description is empty")
        } elseif (-not $hasPositive) {
            $violations.Add("${rel}: description missing positive scenario hint")
        } elseif (-not $hasNegative) {
            $violations.Add("${rel}: description missing negative scenario hint")
        } elseif (-not $hasKb) {
            $violations.Add("${rel}: description missing knowledge-base name hint")
        } elseif (-not $hasReturn) {
            $violations.Add("${rel}: description missing return-format hint")
        }
    }
}

Write-Host '=== Spring AI RAG @Tool description check ==='
Write-Host "backend: $Backend"
Write-Host "knowledgehub files scanned: $($javaFiles.Count)"

if ($violations.Count -eq 0) {
    Write-Host 'OK: no RAG @Tool description violations'
    exit 0
}

Write-Host "Found $($violations.Count) issue(s):"
foreach ($v in $violations) {
    Write-Host "  - $v"
}

if ($Strict) { exit 1 }
Write-Host '(non-strict mode: exit 0; use -Strict to fail)'
exit 0
