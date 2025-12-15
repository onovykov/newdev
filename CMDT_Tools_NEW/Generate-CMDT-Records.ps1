[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath,

    [Parameter(Mandatory=$true)]
    [string]$TypeName,      # WITHOUT __mdt

    [Parameter(Mandatory=$true)]
    [string]$TargetOrgAlias,

    [switch]$Deploy,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ==========================================================
# Helpers
# ==========================================================

function Escape-Xml {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    return [System.Security.SecurityElement]::Escape($Value)
}

function Detect-XsdType {
    param([object[]]$Values)

    $vals = @()
    foreach ($v in $Values) {
        if ($v -ne $null -and $v -ne '') {
            $vals += $v.ToString()
        }
    }

    if ($vals.Count -eq 0) { return 'xsd:string' }

    if (($vals | Where-Object { $_ -notmatch '^(?i:true|false)$' }).Count -eq 0) {
        return 'xsd:boolean'
    }

    if (($vals | Where-Object { $_ -notmatch '^\d{4}-\d{2}-\d{2}$' }).Count -eq 0) {
        return 'xsd:date'
    }

    if (($vals | Where-Object { $_ -notmatch '^\d{4}-\d{2}-\d{2}T' }).Count -eq 0) {
        return 'xsd:dateTime'
    }

    if (($vals | Where-Object { $_ -notmatch '^-?\d+(\.\d+)?$' }).Count -eq 0) {
        return 'xsd:double'
    }

    return 'xsd:string'
}

# ==========================================================
# Load CSV
# ==========================================================

if (-not (Test-Path $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

$csv = Import-Csv $CsvPath
if (-not $csv -or $csv.Count -eq 0) {
    throw "CSV is empty!"
}

$cols = $csv[0].PSObject.Properties.Name

if ('DeveloperName' -notin $cols) { throw "CSV missing DeveloperName" }
if ('MasterLabel'  -notin $cols) { throw "CSV missing MasterLabel" }

$fieldNames = $cols | Where-Object { $_ -notin @('DeveloperName','MasterLabel') }

Write-Host "Fields from CSV:" ($fieldNames -join ", ")
Write-Host ""

# ==========================================================
# Detect XSD types
# ==========================================================

$fieldXsdMap = @{}
foreach ($f in $fieldNames) {
    $vals = $csv | ForEach-Object { $_.$f }
    $fieldXsdMap[$f] = Detect-XsdType $vals
}

Write-Host "Detected XSD types:"
foreach ($kv in $fieldXsdMap.GetEnumerator()) {
    Write-Host "  $($kv.Key) => $($kv.Value)"
}
Write-Host ""

# ==========================================================
# Prepare MDAPI folder structure
# ==========================================================

$guid = [guid]::NewGuid().ToString("N")
$root = Join-Path (Get-Location) "cmdt_mdapi_$guid"

$customMetadataDir = Join-Path $root "customMetadata"
New-Item -ItemType Directory -Force -Path $customMetadataDir | Out-Null

$objectApi = "${TypeName}__mdt"

Write-Host "Generating MDAPI CustomMetadata into:"
Write-Host "  $customMetadataDir"
Write-Host ""

# ==========================================================
# Generate CustomMetadata XML files
# ==========================================================

$members = @()

foreach ($row in $csv) {

    $dev   = $row.DeveloperName
    if ([string]::IsNullOrWhiteSpace($dev)) {
        throw "DeveloperName cannot be empty"
    }

    $label = $row.MasterLabel
    if ([string]::IsNullOrWhiteSpace($label)) { $label = $dev }

    $members += "$objectApi.$dev"

    $fileName = "$objectApi.$dev.md-meta.xml"
    $filePath = Join-Path $customMetadataDir $fileName

    $valuesXml = ""

    foreach ($f in $fieldNames) {
        $xsd = $fieldXsdMap[$f]
        $raw = $row.$f
        if ($raw -eq $null) { $raw = '' }

        if ($xsd -eq 'xsd:string') {
            $val = Escape-Xml $raw
        } else {
            $val = $raw
        }

        $valuesXml += @"
    <values>
        <field>$f</field>
        <value xsi:type='$xsd'>$val</value>
    </values>

"@
    }

$xml = @"
<?xml version='1.0' encoding='UTF-8'?>
<CustomMetadata
    xmlns='http://soap.sforce.com/2006/04/metadata'
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
    xmlns:xsd='http://www.w3.org/2001/XMLSchema'>

    <label>$label</label>
    <fullName>$objectApi.$dev</fullName>

$valuesXml</CustomMetadata>
"@

    $xml | Out-File -Encoding UTF8 $filePath
    Write-Host "  generated $fileName"
}

# ==========================================================
# Generate package.xml (NO WILDCARDS!)
# ==========================================================

$membersXml = $members | Sort-Object -Unique | ForEach-Object {
    "        <members>$_</members>"
}

$packageXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
$($membersXml -join "`n")
        <name>CustomMetadata</name>
    </types>
    <version>59.0</version>
</Package>
"@

$packagePath = Join-Path $root "package.xml"
$packageXml | Out-File -Encoding UTF8 $packagePath

Write-Host ""
Write-Host "MDAPI package prepared at:"
Write-Host "  $root"
Write-Host ""

# ==========================================================
# DryRun
# ==========================================================

if ($DryRun) {
    Write-Host "*** DRY RUN: No deployment executed ***"
    Write-Host "Folder kept: $root"
    exit 0
}

# ==========================================================
# DEPLOY (MDAPI-SAFE)
# ==========================================================

if ($Deploy) {
    Write-Host "DEPLOYING CMDT RECORDS (MDAPI)..."

    sf project deploy start `
        --metadata-dir "$root" `
        --target-org "$TargetOrgAlias"

    if ($LASTEXITCODE -ne 0) {
        throw "CMDT records deploy failed."
    }

    Write-Host ""
    Write-Host "DEPLOY DONE."
}
else {
    Write-Host "Deploy skipped (use -Deploy to enable)."
}

Write-Host "DONE"
exit 0