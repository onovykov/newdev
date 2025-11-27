Param(
  [string]$Target = "Production_Quota__c",
  [string]$SrcDir = "force-app\main\default",
  [string]$ApiVer = "61.0"
)

# Force UTF-8 output but keep all strings ASCII to avoid mojibake
try {
  chcp 65001 | Out-Null
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
  $Global:OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch {}

$depsCsv = "deps_$($Target).csv"
$occCsv  = "occurrences_$($Target).csv"

Write-Host "== 1) Tooling API dependencies -> $depsCsv =="

# Однорядковий SOQL (без here-string, щоб PowerShell нічого не зламав)
$q = "SELECT MetadataComponentType, MetadataComponentName, RefMetadataComponentType, RefMetadataComponentName " +
     "FROM MetadataComponentDependency " +
     "WHERE RefMetadataComponentName = '$Target' " +
     "ORDER BY MetadataComponentType, MetadataComponentName"

$records = @()
try {
  $json = sf data query -t -q $q --json
  $obj = $json | ConvertFrom-Json
  if ($obj -and $obj.result -and $obj.result.records) {
    $records = $obj.result.records
  }
} catch {
  Write-Host "Warning: Tooling API query failed: $($_.Exception.Message)"
}

if ($records.Count -gt 0) {
  $records |
    Select-Object MetadataComponentType, MetadataComponentName, RefMetadataComponentType, RefMetadataComponentName |
    Export-Csv -Path $depsCsv -Encoding utf8 -NoTypeInformation
} else {
  "MetadataComponentType,MetadataComponentName,RefMetadataComponentType,RefMetadataComponentName" |
    Out-File -FilePath $depsCsv -Encoding utf8
  Write-Host "Note: no metadata dependencies found (or query returned empty)."
}


Write-Host "== 2) Code/metadata occurrences -> $occCsv =="

# Collect files, exclude heavy dirs
$files = Get-ChildItem -Path $SrcDir -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.sfdx\\|\\\.sf\\' }

$results = New-Object System.Collections.Generic.List[Object]

# 2.1 Direct API name matches
$files |
  Select-String -Pattern $Target -SimpleMatch -Encoding UTF8 |
  ForEach-Object {
    $results.Add([pscustomobject]@{
      ArtifactType = 'GenericMatch'
      PathOrName   = $_.Path
      Location     = $_.LineNumber
      Snippet      = ($_.Line.Trim() -replace '\s+', ' ')
    })
  }

# 2.2 Heuristic: DML/SOQL with the object name
$regex = "FROM\s+$Target\b|INSERT\s+$Target\b|UPDATE\s+$Target\b|UPSERT\s+$Target\b|DELETE\s+$Target\b"
$files |
  Select-String -Pattern $regex -Encoding UTF8 |
  ForEach-Object {
    $results.Add([pscustomobject]@{
      ArtifactType = 'DML/SOQL'
      PathOrName   = $_.Path
      Location     = $_.LineNumber
      Snippet      = ($_.Line.Trim() -replace '\s+', ' ')
    })
  }

# 2.3 Flows/Process XML nodes
$flowRegex = "<object>$Target</object>|<table>$Target</table>|<sobject>$Target</sobject>"
Get-ChildItem -Path $SrcDir -Recurse -Include *.flow-meta.xml,*.process-* -ErrorAction SilentlyContinue |
  Select-String -Pattern $flowRegex -Encoding UTF8 |
  ForEach-Object {
    $results.Add([pscustomobject]@{
      ArtifactType = 'Flow/Process'
      PathOrName   = $_.Path
      Location     = $_.LineNumber
      Snippet      = ($_.Line.Trim() -replace '\s+', ' ')
    })
  }

# 2.4 Reports/Layouts/Validation Rules XML
Get-ChildItem -Path $SrcDir -Recurse -Include *.report-meta.xml,*.layout-meta.xml,*.validationRule-meta.xml -ErrorAction SilentlyContinue |
  Select-String -Pattern $Target -Encoding UTF8 |
  ForEach-Object {
    $results.Add([pscustomobject]@{
      ArtifactType = 'Report/Layout/Rule'
      PathOrName   = $_.Path
      Location     = $_.LineNumber
      Snippet      = ($_.Line.Trim() -replace '\s+', ' ')
    })
  }

# Write CSV
if ($results.Count -gt 0) {
  $results | Export-Csv -Path $occCsv -Encoding utf8 -NoTypeInformation
} else {
  "ArtifactType,PathOrName,Location,Snippet" | Out-File -FilePath $occCsv -Encoding utf8
}

Write-Host ""
Write-Host "Done."
Write-Host "Dependencies CSV: $depsCsv"
Write-Host "Occurrences CSV:  $occCsv"
Write-Host @'
Notes:
- Make sure all relevant metadata is retrieved locally, e.g.:
    sf project retrieve start -m ApexClass,ApexTrigger,Flow,Report,Layout,CustomObject,Profile,PermissionSet -o <alias> -w 10
- Dynamic access (Schema.describe, dynamic SOQL via String.format) may not be fully detectable; check GenericMatch hits.
'@