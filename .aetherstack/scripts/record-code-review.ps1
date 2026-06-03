param(
    [Parameter(Mandatory = $true)]
    [string]$Change,
    [Parameter(Mandatory = $true)]
    [ValidateSet('backend', 'frontend')]
    [string]$Scope,
    [Parameter(Mandatory = $true)]
    [ValidateSet('approved', 'waived')]
    [string]$Status,
    [string]$PrUrl,
    [string]$Note
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$changeDir = Join-Path $Root "openspec\changes\$Change"
if (-not (Test-Path $changeDir)) {
    throw "Change not found: $changeDir"
}

$gatePath = Join-Path $changeDir '.completion-gate.json'
$gateObj = [ordered]@{
    version = 1
    change  = $Change
    checks  = [ordered]@{ codeReview = [ordered]@{} }
}
if (Test-Path $gatePath) {
    $gateObj = Get-Content $gatePath -Raw -Encoding UTF8 | ConvertFrom-Json
}
if (-not $gateObj.checks) { $gateObj | Add-Member -NotePropertyName checks -NotePropertyValue ([pscustomobject]@{}) -Force }
if (-not $gateObj.checks.codeReview) { $gateObj.checks | Add-Member -NotePropertyName codeReview -NotePropertyValue ([pscustomobject]@{}) -Force }

$gateObj.checks.codeReview | Add-Member -NotePropertyName $Scope -NotePropertyValue ([pscustomobject]@{
    status = $Status
    prUrl  = $PrUrl
    note   = $Note
    at     = (Get-Date).ToString('o')
}) -Force

$gateObj | Add-Member -NotePropertyName updatedAt -NotePropertyValue (Get-Date).ToString('o') -Force
$gateObj | ConvertTo-Json -Depth 10 | Set-Content $gatePath -Encoding UTF8
Write-Host "Recorded code review [$Scope]=$Status on $gatePath"
