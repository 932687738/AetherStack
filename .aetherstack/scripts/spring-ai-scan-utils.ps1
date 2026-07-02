# Shared helpers for check-spring-ai-*.ps1 (multi-module ai repo)

function Test-ProductionBackendRelativePath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    if ($RelativePath -match 'springai[/\\]|learning[/\\]|ai-langchain[/\\]|[/\\]demo[/\\]') {
        return $false
    }
    return $RelativePath -match 'agents[/\\]|knowledgehub[/\\]|superAgents[/\\]'
}

function Get-BackendJavaSourceFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackendRoot,
        [string]$RelativePathPattern,
        [switch]$ProductionOnly
    )
    if (-not (Test-Path $BackendRoot)) { return @() }
    $files = Get-ChildItem -Path $BackendRoot -Filter '*.java' -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '[\\/]src[\\/]main[\\/]java[\\/]' }
    if ($RelativePathPattern) {
        $files = $files | Where-Object {
            $rel = $_.FullName.Substring($BackendRoot.Length).TrimStart('\', '/')
            $rel -match $RelativePathPattern
        }
    }
    if ($ProductionOnly) {
        $files = $files | Where-Object {
            $rel = $_.FullName.Substring($BackendRoot.Length).TrimStart('\', '/')
            Test-ProductionBackendRelativePath -RelativePath $rel
        }
    }
    return @($files)
}

function Assert-BackendJavaSources {
    param(
        [string]$BackendRoot,
        [System.Collections.IEnumerable]$Files,
        [switch]$Strict
    )
    if (@($Files).Count -gt 0) { return }
    $msg = "No Java sources under backend modules (expected **/src/main/java): $BackendRoot"
    if ($Strict) {
        Write-Error $msg
        exit 1
    }
    Write-Warning $msg
    exit 0
}
