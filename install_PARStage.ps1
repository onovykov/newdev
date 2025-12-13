Write-Host "=== STEP 1: Removing old PARStage__mdt metadata ===" -ForegroundColor Cyan

if (Test-Path "force-app\main\default\objects\PARStage__mdt") {
    Remove-Item -Recurse -Force "force-app\main\default\objects\PARStage__mdt"
}

if (Test-Path "force-app\main\default\customMetadata\PARStage__mdt*") {
    Remove-Item -Recurse -Force "force-app\main\default\customMetadata\PARStage__mdt*"
}

Write-Host "Old CMDT removed.`n" -ForegroundColor Green



Write-Host "=== STEP 2: Creating CMDT object via SF CLI ===" -ForegroundColor Cyan
sf cmdt generate object --type-name PARStage --label "PAR Stage"
Write-Host "CMDT object created.`n" -ForegroundColor Green



Write-Host "=== STEP 3: Creating fields directory & XML files ===" -ForegroundColor Cyan

$fieldsPath = "force-app\main\default\objects\PARStage__mdt\fields"
if (!(Test-Path $fieldsPath)) {
    New-Item -ItemType Directory -Path $fieldsPath | Out-Null
}

# FIELD: Code__c
@"
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Code__c</fullName>
    <label>Code</label>
    <type>Text</type>
    <length>10</length>
</CustomField>
"@ | Out-File "$fieldsPath\Code__c.field-meta.xml" -Encoding UTF8

# FIELD: StageName__c
@"
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>StageName__c</fullName>
    <label>Stage Name</label>
    <type>Text</type>
    <length>255</length>
</CustomField>
"@ | Out-File "$fieldsPath\StageName__c.field-meta.xml" -Encoding UTF8

# FIELD: ProcessName__c
@"
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>ProcessName__c</fullName>
    <label>Process Name</label>
    <type>Text</type>
    <length>255</length>
</CustomField>
"@ | Out-File "$fieldsPath\ProcessName__c.field-meta.xml" -Encoding UTF8

# FIELD: IsApprovalRequired__c
@"
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>IsApprovalRequired__c</fullName>
    <label>Is Approval Required</label>
    <type>Checkbox</type>
    <defaultValue>false</defaultValue>
</CustomField>
"@ | Out-File "$fieldsPath\IsApprovalRequired__c.field-meta.xml" -Encoding UTF8

Write-Host "XML fields created.`n" -ForegroundColor Green



Write-Host "=== STEP 4: Deploy CMDT structure to newdev ===" -ForegroundColor Cyan
sf project deploy start -o newdev
Write-Host "CMDT structure deployed.`n" -ForegroundColor Green



Write-Host "=== STEP 5: Extracting PARStage_cmdt_records.zip with overwrite support ===" -ForegroundColor Cyan

$zip = "PARStage_cmdt_records.zip"
$dest = "force-app\main\default\customMetadata"

if (!(Test-Path $zip)) {
    Write-Host "ERROR: ZIP file not found: $zip" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipFile = [System.IO.Compression.ZipFile]::OpenRead($zip)

foreach ($entry in $zipFile.Entries) {

    if ($entry.FullName.Trim().Length -eq 0) { continue }

    $targetFile = Join-Path $dest $entry.FullName

    # ensure folder exists
    $targetDir = Split-Path $targetFile
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # remove if exists
    if (Test-Path $targetFile) {
        Remove-Item $targetFile -Force
    }

    # extract file
    $entryStream = $entry.Open()
    $fileStream = [System.IO.File]::Open($targetFile, "Create")
    $entryStream.CopyTo($fileStream)

    $fileStream.Close()
    $entryStream.Close()
}

$zipFile.Dispose()

Write-Host "ZIP extracted.`n" -ForegroundColor Green



Write-Host "=== STEP 6: Deploying CMDT records ===" -ForegroundColor Cyan
sf project deploy start -o newdev
Write-Host "CMDT records deployed successfully!`n" -ForegroundColor Green


Write-Host "=== ALL DONE SUCCESSFULLY ===" -ForegroundColor Magenta