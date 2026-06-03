param(
    [Parameter(Mandatory = $true)]
    [string]$Change,
    [Parameter(Mandatory = $true)]
    [ValidateSet('openspecVerify', 'superpowersVerification')]
    [string]$Step,
    [Parameter(Mandatory = $true)]
    [ValidateSet('pass', 'done', 'pending')]
    [string]$Status,
    [string]$ReportPath,
    [string]$Note
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$changeDir = Join-Path $Root "openspec\changes\$Change"
if (-not (Test-Path $changeDir)) {
    throw "Change not found: $changeDir"
}

$gatePath = Join-Path $changeDir '.completion-gate.json'
$gateObj = [pscustomobject]@{
    version = 1
    change  = $Change
    checks  = [pscustomobject]@{}
}
if (Test-Path $gatePath) {
    $gateObj = Get-Content $gatePath -Raw -Encoding UTF8 | ConvertFrom-Json
}
if (-not $gateObj.checks) { $gateObj | Add-Member -NotePropertyName checks -NotePropertyValue ([pscustomobject]@{}) -Force }

$entry = [pscustomobject]@{ status = $Status; at = (Get-Date).ToString('o'); note = $Note }
if ($ReportPath) { $entry | Add-Member -NotePropertyName reportPath -NotePropertyValue $ReportPath }
$gateObj.checks | Add-Member -NotePropertyName $Step -NotePropertyValue $entry -Force
$gateObj | Add-Member -NotePropertyName updatedAt -NotePropertyValue (Get-Date).ToString('o') -Force

$gateObj | ConvertTo-Json -Depth 10 | Set-Content $gatePath -Encoding UTF8
Write-Host "Recorded $Step=$Status on $gatePath"
