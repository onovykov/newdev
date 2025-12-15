[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TypeName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetOrgAlias,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "DEBUG CsvPath = [$CsvPath]"
Write-Host "DEBUG TypeName = [$TypeName]"
Write-Host "DEBUG TargetOrgAlias = [$TargetOrgAlias]"
Write-Host "DEBUG Force = [$Force]"

$root = Split-Path -Parent $PSCommandPath

$params = @{
    CsvPath        = $CsvPath
    TypeName       = $TypeName
    TargetOrgAlias = $TargetOrgAlias
}

if ($Force) {
    $params.Force = $true
}

& (Join-Path $root "CMDT_Create.ps1") @params