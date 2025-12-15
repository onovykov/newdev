[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$CsvPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TypeName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetOrgAlias
)

$ErrorActionPreference = 'Stop'

# SAFETY: forbid prod-like aliases
if ($TargetOrgAlias -match '(?i)\bprod\b|production|live') {
    throw "CMDT DELETE is forbidden for PROD-like org aliases: $TargetOrgAlias"
}

# Validate CSV
if (-not (Test-Path $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

$rows = Import-Csv $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
    throw "CSV is empty."
}

if (-not ($rows[0].PSObject.Properties.Name -contains 'DeveloperName')) {
    throw "CSV must contain column 'DeveloperName'."
}

$records = $rows |
    Where-Object { $_.DeveloperName -and $_.DeveloperName.Trim() -ne '' } |
    ForEach-Object { $_.DeveloperName.Trim() }

if ($records.Count -eq 0) {
    throw "CSV does not contain valid DeveloperName values."
}

# Normalize CMDT type name
$cmdtType = if ($TypeName.EndsWith('__mdt')) { $TypeName } else { "${TypeName}__mdt" }

# Confirmation
Write-Host ""
Write-Host "YOU ARE ABOUT TO DELETE CUSTOM METADATA RECORDS:" -ForegroundColor Red
$records | ForEach-Object { Write-Host (" - {0}.{1}" -f $cmdtType, $_) }

$confirm = Read-Host "`nType Y to CONFIRM deletion"
if ($confirm.Trim().ToUpper() -ne 'Y') { throw "Aborted by user." }

# Prepare temp folder
$tmpRoot = Join-Path (Get-Location) (".cmdt-delete-{0}" -f $cmdtType)
if (Test-Path $tmpRoot) { Remove-Item $tmpRoot -Recurse -Force }
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

# destructiveChanges.xml (POST destructive)
$membersXml = $records | ForEach-Object { "        <members>$cmdtType.$_</members>" }

$destructiveXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
$($membersXml -join "`n")
        <name>CustomMetadata</name>
    </types>
    <version>59.0</version>
</Package>
"@

$destructivePath = Join-Path $tmpRoot "destructiveChanges.xml"
Set-Content -Path $destructivePath -Value $destructiveXml -Encoding UTF8

# empty package.xml (required)
$packageXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>59.0</version>
</Package>
"@

$manifestPath = Join-Path $tmpRoot "package.xml"
Set-Content -Path $manifestPath -Value $packageXml -Encoding UTF8

# DEBUG: show XML
Write-Host ""
Write-Host "=== POST destructiveChanges.xml ===" -ForegroundColor Cyan
Get-Content $destructivePath | Write-Host

# Deploy
Write-Host ""
Write-Host "DELETING CMDT RECORDS (POST-DESTRUCTIVE DEPLOY)..." -ForegroundColor Yellow

$deployOutput = sf project deploy start `
    --target-org $TargetOrgAlias `
    --manifest $manifestPath `
    --post-destructive-changes $destructivePath `
    --purge-on-delete `
    --wait 10 2>&1

Write-Host $deployOutput

# Interpret result
if ($deployOutput -match 'No CustomMetadata named') {
    throw "DELETE FAILED: CustomMetadata record not found (wrong name)."
}
elseif ($deployOutput -match 'NothingToDeploy') {
    Write-Host "Nothing to delete (records already absent)." -ForegroundColor Yellow
}
elseif ($deployOutput -match '(?i)Deleted|Succeeded|Success') {
    Write-Host "CMDT records delete deploy finished. Verify in org." -ForegroundColor Green
}
else {
    Write-Host "Deploy finished - review output above." -ForegroundColor Yellow
}

# Cleanup
Remove-Item $tmpRoot -Recurse -Force
exit 0