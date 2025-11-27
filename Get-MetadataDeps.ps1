Param(
  [string]$Target = "Production_Quota__c",
  [ValidateSet("table","csv","json")]
  [string]$Format = "table",
  [string]$OutFile = ""
)

# Optional: force UTF-8 output; keep strings ASCII
try {
  chcp 65001 | Out-Null
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
  $Global:OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch {}

# Single-line SOQL via Tooling API: "what references Target?"
$q = "SELECT MetadataComponentType, MetadataComponentName, RefMetadataComponentType, RefMetadataComponentName " +
     "FROM MetadataComponentDependency " +
     "WHERE RefMetadataComponentName = '$Target' " +
     "ORDER BY MetadataComponentType, MetadataComponentName"

$json = sf data query -t -q $q --json
$obj = $json | ConvertFrom-Json

$recs = @()
if ($obj -and $obj.result -and $obj.result.records) { $recs = $obj.result.records }

if ($Format -eq "json") {
  $out = $recs | ConvertTo-Json -Depth 5
  if ($OutFile) { $out | Out-File -FilePath $OutFile -Encoding utf8 } else { $out | Write-Output }
  exit 0
}

if ($Format -eq "csv") {
  if (-not $OutFile) { $OutFile = "deps_$($Target).csv" }
  if ($recs.Count -gt 0) {
    $recs | Select-Object MetadataComponentType, MetadataComponentName, RefMetadataComponentType, RefMetadataComponentName |
      Export-Csv -Path $OutFile -Encoding utf8 -NoTypeInformation
  } else {
    "MetadataComponentType,MetadataComponentName,RefMetadataComponentType,RefMetadataComponentName" |
      Out-File -FilePath $OutFile -Encoding utf8
  }
  Write-Host "CSV written: $OutFile"
  exit 0
}

# table (default)
if ($recs.Count -eq 0) { Write-Host "No dependencies found for: $Target"; exit 0 }
$recs | Select-Object MetadataComponentType, MetadataComponentName, RefMetadataComponentType, RefMetadataComponentName |
  Format-Table -AutoSize
