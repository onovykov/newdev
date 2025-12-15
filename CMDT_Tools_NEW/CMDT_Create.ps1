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

# ============================================================
# Helpers
# ============================================================

function Fail {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

function Assert-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "File not found: $Path"
    }
}

function Assert-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Fail "Directory not found: $Path"
    }
}

function Run-Script {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [hashtable]$Params
    )

    Write-Host ">> $ScriptPath [$($Params.Keys -join ', ')]" -ForegroundColor Cyan

    & $ScriptPath @Params

    if ($LASTEXITCODE -ne 0) {
        throw "Script failed with exit code $($LASTEXITCODE): $ScriptPath"
    }
}

# ============================================================
# Preconditions
# ============================================================

Assert-File $CsvPath

# ============================================================
# Locate SFDX project root (sfdx-project.json)
# ============================================================

$ProjectRoot = $null
$dir = Get-Item (Get-Location)

while ($dir -and -not (Test-Path (Join-Path $dir.FullName "sfdx-project.json"))) {
    $dir = $dir.Parent
}

if (-not $dir) {
    throw "SFDX project root not found (sfdx-project.json). Run from inside an SFDX project."
}

$ProjectRoot = $dir.FullName

Write-Host "SFDX Project Root: $ProjectRoot" -ForegroundColor DarkGray


# ============================================================
# PROD stopper
# ============================================================

if ($TargetOrgAlias -match '(?i)^prod(uction)?$') {
    $confirm = Read-Host "WARNING: deploy to PROD ($TargetOrgAlias). Type Y to continue"
    if ($confirm.Trim().ToUpper() -ne 'Y') {
        throw "Aborted by user."
    }
}

# ============================================================
# Paths
# ============================================================

$objectsDir        = Join-Path $ProjectRoot ("force-app\main\default\objects\{0}__mdt" -f $TypeName)
$toolsDir          = Split-Path -Parent $PSCommandPath
$genCmdtScript     = Join-Path $toolsDir "Generate-CMDT.ps1"
$genRecordsScript  = Join-Path $toolsDir "Generate-CMDT-Records.ps1"

Assert-File $genCmdtScript
Assert-File $genRecordsScript

# ============================================================
# Execute from SFDX project root
# ============================================================

Push-Location $ProjectRoot
try {

    # --------------------------------------------------------
    # Step 1: Generate CMDT structure (object + fields)
    # --------------------------------------------------------

    $genParams = @{
        CsvPath        = $CsvPath
        TypeName       = $TypeName
        TargetOrgAlias = $TargetOrgAlias
    }

    if ($Force) {
        $genParams.Force = $true
    }

    Run-Script $genCmdtScript $genParams

    # --------------------------------------------------------
    # Step 2: Deploy CMDT object structure
    # --------------------------------------------------------

    Assert-Dir $objectsDir

    Write-Host ">> sf project deploy start" -ForegroundColor Cyan
    sf project deploy start `
        --source-dir $objectsDir `
        --target-org $TargetOrgAlias

    if ($LASTEXITCODE -ne 0) {
        throw "CMDT object deploy failed."
    }

    # --------------------------------------------------------
    # Step 3: Generate and deploy CMDT records
    # --------------------------------------------------------

    $recParams = @{
        CsvPath        = $CsvPath
        TypeName       = $TypeName
        TargetOrgAlias = $TargetOrgAlias
        Deploy         = $true
    }

    Run-Script $genRecordsScript $recParams
}
finally {
    Pop-Location
}

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "CMDT '$TypeName' successfully created and deployed to '$TargetOrgAlias'." -ForegroundColor Green
Write-Host "Setup -> Custom Metadata Types -> $TypeName -> Manage Records"