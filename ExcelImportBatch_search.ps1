# ExcelImportBatch_search.ps1  (версія без переносів у SOQL)

param(
  [string]$ClassName = 'ExcelImportBatch'
)

function Get-SfJson($cmd) {
  $raw = Invoke-Expression "$cmd --json"
  if (-not $raw) { return $null }
  try { return ($raw | ConvertFrom-Json) } catch { return $null }
}

# 1) Class Id
$cls = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, Name FROM ApexClass WHERE Name='$ClassName'`""
if (-not $cls -or -not $cls.result.records) { Write-Error "Class not found: $ClassName"; exit 1 }
$clsId = $cls.result.records[0].Id
Write-Host "Class $ClassName Id: $clsId"

# 2) Inbound / Outbound (ОДНОРЯДКОВО!)
$inbCmd  = "sf data query --use-tooling-api -q `"SELECT MetadataComponentId, MetadataComponentType, RefMetadataComponentId, RefMetadataComponentType FROM MetadataComponentDependency WHERE RefMetadataComponentType='ApexClass' AND RefMetadataComponentId='$clsId'`""
$outbCmd = "sf data query --use-tooling-api -q `"SELECT MetadataComponentId, MetadataComponentType, RefMetadataComponentId, RefMetadataComponentType FROM MetadataComponentDependency WHERE MetadataComponentType='ApexClass' AND MetadataComponentId='$clsId'`""

$inb  = Get-SfJson $inbCmd
$outb = Get-SfJson $outbCmd

$rows = @()
if ($inb -and $inb.result.records) {
  $rows += ($inb.result.records | ForEach-Object {
    [PSCustomObject]@{ Direction='Inbound'; Type=$_.MetadataComponentType; Id=$_.MetadataComponentId }
  })
}
if ($outb -and $outb.result.records) {
  $rows += ($outb.result.records | ForEach-Object {
    [PSCustomObject]@{ Direction='Outbound'; Type=$_.RefMetadataComponentType; Id=$_.RefMetadataComponentId }
  })
}

if (-not $rows) { Write-Host "No dependencies found."; return }

# 3) Resolve names per type (по Id → Name/DeveloperName)
function Resolve-Map($type, $ids) {
  $ids = $ids | Sort-Object -Unique
  if (-not $ids) { return @{} }
  $in = ($ids | ForEach-Object { "'$_'" }) -join ','
  $q = switch ($type) {
    'ApexClass'               { "SELECT Id, Name FROM ApexClass WHERE Id IN ($in)" }
    'ApexTrigger'             { "SELECT Id, Name FROM ApexTrigger WHERE Id IN ($in)" }
    'ApexPage'                { "SELECT Id, Name FROM ApexPage WHERE Id IN ($in)" }
    'LightningComponentBundle'{ "SELECT Id, DeveloperName Name FROM LightningComponentBundle WHERE Id IN ($in)" }
    'AuraDefinitionBundle'    { "SELECT Id, DeveloperName Name FROM AuraDefinitionBundle WHERE Id IN ($in)" }
    default                   { $null }
  }
  $map = @{}
  if ($q) {
    $res = Get-SfJson "sf data query --use-tooling-api -q `"$q`""
    if ($res -and $res.result.records) {
      foreach ($r in $res.result.records) { $map[$r.Id] = $r.Name }
    }
  }
  # Для невідомих типів просто залишимо Id як Name
  foreach ($i in $ids) { if (-not $map.ContainsKey($i)) { $map[$i] = '(unknown)' } }
  return $map
}

$resolved = @{}
$rows | Group-Object Type | ForEach-Object {
  $t = $_.Name
  $ids = $_.Group.Id
  $m = Resolve-Map $t $ids
  foreach ($k in $m.Keys) { $resolved[$k] = @{ Type=$t; Name=$m[$k] } }
}

$rows | ForEach-Object {
  $nm = if ($resolved.ContainsKey($_.Id)) { $resolved[$_.Id].Name } else { '(unknown)' }
  [PSCustomObject]@{
    Direction = $_.Direction
    Type      = $_.Type
    Id        = $_.Id
    Name      = $nm
  }
} | Sort-Object Direction, Type, Name | Format-Table -AutoSize