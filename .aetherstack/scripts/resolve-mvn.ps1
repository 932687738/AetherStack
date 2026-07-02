# Resolve Maven executable (PATH, MAVEN_HOME/M2_HOME, backend mvnw)
param(
    [string]$BackendRepo
)

$ErrorActionPreference = 'Stop'

function Get-EnvMavenHome {
    foreach ($name in @('MAVEN_HOME', 'M2_HOME')) {
        foreach ($scope in @('Process', 'User', 'Machine')) {
            $val = [Environment]::GetEnvironmentVariable($name, $scope)
            if ($val -and $val -notmatch '%' -and (Test-Path $val)) {
                return $val.TrimEnd('\', '/')
            }
        }
    }
    return $null
}

$mvnCmd = Get-Command mvn -ErrorAction SilentlyContinue
if ($mvnCmd) {
    Write-Output $mvnCmd.Source
    exit 0
}

$mavenHome = Get-EnvMavenHome
if ($mavenHome) {
    $candidate = Join-Path $mavenHome 'bin\mvn.cmd'
    if (Test-Path $candidate) {
        Write-Output $candidate
        exit 0
    }
}

if ($BackendRepo -and (Test-Path $BackendRepo)) {
    $wrapper = Join-Path $BackendRepo 'mvnw.cmd'
    if (Test-Path $wrapper) {
        Write-Output $wrapper
        exit 0
    }
}

Write-Error 'Maven not found: set MAVEN_HOME, add mvn to PATH, or use ai/mvnw.cmd'
exit 1
