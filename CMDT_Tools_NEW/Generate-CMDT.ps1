param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [string]$TypeName,

    [Parameter(Mandatory = $true)]
    [string]$TargetOrgAlias,

    [switch]$PreferPicklists,
    [switch]$PreferLongText,
    [switch]$SafeNames,
    [switch]$Force,
    [switch]$DryRun
)

# ---------- helpers ----------

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

function Escape-XmlValue {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    return [System.Security.SecurityElement]::Escape($Value)
}

function Detect-XsdType {
    param([object[]]$Values)

    $nonEmpty = @()
    foreach ($v in $Values) {
        if ($null -ne $v -and $v -ne '') {
            $nonEmpty += $v.ToString()
        }
    }

    if ($nonEmpty.Count -eq 0) { return 'xsd:string' }

    # boolean
    $boolMismatch = $false
    foreach ($v in $nonEmpty) {
        if ($v -notmatch '^(?i:true|false)$') { $boolMismatch = $true; break }
    }
    if (-not $boolMismatch) { return 'xsd:boolean' }

    # date (yyyy-MM-dd)
    $dateMismatch = $false
    foreach ($v in $nonEmpty) {
        if ($v -notmatch '^\d{4}-\d{2}-\d{2}$') { $dateMismatch = $true; break }
    }
    if (-not $dateMismatch) { return 'xsd:date' }

    # datetime (yyyy-MM-ddTHH:mm:ssZ / +hh:mm)
    $dtMismatch = $false
    foreach ($v in $nonEmpty) {
        if ($v -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$') { $dtMismatch = $true; break }
    }
    if (-not $dtMismatch) { return 'xsd:dateTime' }

    # number
    $numMismatch = $false
    foreach ($v in $nonEmpty) {
        if ($v -notmatch '^-?\d+(\.\d+)?$') { $numMismatch = $true; break }
    }
    if (-not $numMismatch) { return 'xsd:double' }

    return 'xsd:string'
}

function Infer-SfNumberPrecisionScale {
    param([object[]]$Values)

    $maxScale = 0
    foreach ($v in $Values) {
        if ($null -eq $v -or $v -eq '') { continue }
        $s = $v.ToString()
        if ($s -match '\.') {
            $parts = $s.Split('.')
            $scale = $parts[1].Length
            if ($scale -gt $maxScale) { $maxScale = $scale }
        }
    }

    $precision = 18
    $scale = $maxScale
    if ($scale -gt 8) { $scale = 8 }

    return @{ Precision = $precision; Scale = $scale }
}

# ---------- 1. read CSV ----------

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$csv = Import-Csv -Path $CsvPath
if (-not $csv -or $csv.Count -eq 0) {
    throw 'CSV is empty.'
}

$columns = $csv[0].PSObject.Properties.Name

if ($columns -notcontains 'DeveloperName') {
    throw 'CSV must contain column DeveloperName.'
}
if ($columns -notcontains 'MasterLabel') {
    throw 'CSV must contain column MasterLabel.'
}

$fieldNames = $columns | Where-Object { $_ -ne 'DeveloperName' -and $_ -ne 'MasterLabel' }

if ($fieldNames.Count -eq 0) {
    throw 'CSV must contain at least one additional column for a field (besides DeveloperName and MasterLabel).'
}

# ---------- 2. validate DeveloperName (SafeNames) ----------

$devs = $csv | Select-Object -ExpandProperty DeveloperName
$dupDevs = $devs | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
if ($dupDevs) {
    throw ("Duplicate DeveloperName values: " + ($dupDevs -join ', '))
}

if ($SafeNames) {
    foreach ($d in $devs) {
        if ($d -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            throw "DeveloperName '$d' has invalid characters. Allowed: A-Z, a-z, 0-9, _. First char must be a letter or _."
        }
    }
}

# ---------- 3. detect XSD type per field ----------

$fieldTypeInfo = @{}
foreach ($f in $fieldNames) {
    $vals = @()
    foreach ($row in $csv) { $vals += $row.$f }
    $xsd = Detect-XsdType -Values $vals
    $distinct = ($vals | Where-Object { $_ -ne $null -and $_ -ne '' } | Select-Object -Unique)
    $distinctCount = $distinct.Count

    $fieldTypeInfo[$f] = @{
        XsdType       = $xsd
        DistinctCount = $distinctCount
        Values        = $vals
    }
}

Write-Info 'Detected field types:'
foreach ($kv in $fieldTypeInfo.GetEnumerator()) {
    Write-Info ("  {0} => {1} (distinct={2})" -f $kv.Key, $kv.Value.XsdType, $kv.Value.DistinctCount)
}

# ---------- 4. create CMDT object + fields locally ----------

$projectRoot = Get-Location
$objectsDir = Join-Path $projectRoot 'force-app\main\default\objects'
if (-not (Test-Path $objectsDir)) {
    throw "force-app\main\default\objects not found in current dir. Run script from SFDX project root."
}

$objectApiName = $TypeName + '__mdt'
$objectDir = Join-Path $objectsDir $objectApiName

if (Test-Path $objectDir) {
    if (-not $Force) {
        throw "Directory already exists: $objectDir. Use -Force to overwrite."
    }
    Remove-Item -Recurse -Force $objectDir
}

New-Item -ItemType Directory -Path $objectDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $objectDir 'fields') | Out-Null

# CMDT object XML (важливо: без customSettingsType / metadataType!)
$pluralLabel = $TypeName + 's'
$cmdtPath = Join-Path $objectDir ($objectApiName + '.object-meta.xml')

$cmdtXml = @"
<?xml version='1.0' encoding='UTF-8'?>
<CustomObject xmlns='http://soap.sforce.com/2006/04/metadata'>
    <description>Custom Metadata Type generated from CSV: $CsvPath</description>
    <label>$TypeName</label>
    <pluralLabel>$pluralLabel</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>
"@

$cmdtXml | Out-File -FilePath $cmdtPath -Encoding UTF8
Write-Info ("Generated CMDT object: {0}" -f $cmdtPath)

# ---------- 5. create CustomField XMLs ----------

$fieldsDir = Join-Path $objectDir 'fields'

foreach ($f in $fieldNames) {
    $info = $fieldTypeInfo[$f]
    $xsd = $info.XsdType
    $vals = $info.Values
    $distinctCount = $info.DistinctCount

    $apiName = $f
    if ($apiName -notmatch '__c$') {
        $apiName = $apiName + '__c'
    }

    # Label = колонка без __c в кінці
    $label = $f
    if ($label.EndsWith('__c')) {
        $label = $label.Substring(0, $label.Length - 3)
    }

    $sfType = 'Text'
    $extraXml = ''

    if ($xsd -eq 'xsd:boolean') {
        $sfType = 'Checkbox'
        $extraXml = '    <defaultValue>false</defaultValue>'
    }
    elseif ($xsd -eq 'xsd:date') {
        $sfType = 'Date'
    }
    elseif ($xsd -eq 'xsd:dateTime') {
        $sfType = 'DateTime'
    }
    elseif ($xsd -eq 'xsd:double') {
        $sfType = 'Number'
        $numInfo = Infer-SfNumberPrecisionScale -Values $vals
        $precision = $numInfo.Precision
        $scale = $numInfo.Scale
        $extraXml = @"
    <precision>$precision</precision>
    <scale>$scale</scale>
"@
    }
    else {
        # xsd:string → Text / LongText / Picklist
        if ($PreferPicklists -and $distinctCount -le 50) {
            $sfType = 'Picklist'

            $values = $vals | Where-Object { $_ -ne $null -and $_ -ne '' } | Select-Object -Unique
            $valuesXml = ''
            foreach ($v in $values) {
                $ev = Escape-XmlValue $v
                $valuesXml += "        <value><fullName>$ev</fullName><default>false</default></value>`n"
            }

            $extraXml = @"
    <valueSet>
        <valueSetDefinition>
$valuesXml        <sorted>false</sorted>
        </valueSetDefinition>
    </valueSet>
"@
        }
        elseif ($PreferLongText) {
            $sfType = 'LongTextArea'
            $extraXml = @"
    <length>32768</length>
    <visibleLines>3</visibleLines>
"@
        }
        else {
            $sfType = 'Text'
            $extraXml = '    <length>255</length>'
        }
    }

    $fieldPath = Join-Path $fieldsDir ($apiName + '.field-meta.xml')

    $fieldXml = @"
<?xml version='1.0' encoding='UTF-8'?>
<CustomField xmlns='http://soap.sforce.com/2006/04/metadata'>
    <fullName>$apiName</fullName>
    <label>$label</label>
    <required>false</required>
    <type>$sfType</type>
$extraXml
</CustomField>
"@

    $fieldXml | Out-File -FilePath $fieldPath -Encoding UTF8
    Write-Info ("Generated field: {0} ({1})" -f $fieldPath, $sfType)
}

Write-Info ''
Write-Info 'CMDT files generated.'
Write-Info ("Object dir: {0}" -f $objectDir)

if ($DryRun) {
    Write-Info 'DryRun = ON. Nothing was deployed.'
    Write-Info 'You can inspect generated files, then deploy manually:'
    Write-Info ("  sf project deploy start --source-dir {0} --target-org {1}" -f $objectDir, $TargetOrgAlias)
} else {
    Write-Info ''
    Write-Info 'To deploy run:'
    Write-Info ("  sf project deploy start --source-dir {0} --target-org {1}" -f $objectDir, $TargetOrgAlias)
    Write-Info ''
    Write-Info 'Script itself does NOT deploy automatically (to avoid extra surprises).'
}

Write-Info 'DONE'
# $global:LASTEXITCODE = 0
# return
exit 0