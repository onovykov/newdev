# Resolve-LwcBundle.ps1
# Usage:
#   .\Resolve-LwcBundle.ps1 -BundleId 0Rb1n000000bolECAQ
#   .\Resolve-LwcBundle.ps1 -BundleId 0Rb... -Root "force-app" -MaxResultsPerPattern 200

param(
  [Parameter(Mandatory=$true)]
  [string]$BundleId,                     # e.g. 0Rb1n000000bolECAQ
  [string]$Root = "force-app",           # metadata root in repo
  [int]$MaxResultsPerPattern = 200       # cap per-search output
)

function Get-SfJson([string]$cmd) {
  $raw = Invoke-Expression "$cmd --json"
  if (-not $raw) { return $null }
  try { return ($raw | ConvertFrom-Json) } catch { return $null }
}

function To-KebabCase([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $s }
  # ABCD -> abcd; ExcelImportBatch -> excel-import-batch
  $s = ($s -replace '([a-z0-9])([A-Z])','$1-$2') -replace '([A-Z])([A-Z][a-z])','$1-$2'
  return $s.ToLower()
}

# 1) Bundle info
$bundle = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, DeveloperName, NamespacePrefix, ApiVersion, Description FROM LightningComponentBundle WHERE Id='$BundleId'`""
if (-not $bundle -or -not $bundle.result.records) {
  Write-Error "LightningComponentBundle not found by Id: $BundleId"
  exit 1
}
$rec = $bundle.result.records[0]
$devName = $rec.DeveloperName
$ns = if ($rec.NamespacePrefix) { $rec.NamespacePrefix } else { 'c' }
$kebab = To-KebabCase $devName

Write-Host "== Bundle ==" -ForegroundColor Cyan
Write-Host ("Id:            {0}" -f $rec.Id)
Write-Host ("DeveloperName: {0}" -f $devName)
Write-Host ("Namespace:     {0}" -f $ns)
Write-Host ("ApiVersion:    {0}" -f $rec.ApiVersion)
Write-Host ("Description:   {0}" -f $rec.Description)

# 2) Bundle resources
$res = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, FilePath, Format, Source FROM LightningComponentResource WHERE LightningComponentBundleId='$BundleId' ORDER BY FilePath`""
Write-Host "`n== Resources ==" -ForegroundColor Cyan
if ($res -and $res.result.records) {
  $res.result.records | Select-Object FilePath,Format | Format-Table -AutoSize
} else {
  Write-Host "(none)"
}

# 3) Local folder hint
$localPath = Join-Path $Root ("main\default\lwc\" + $devName)
Write-Host ("`nLocal folder (expected): {0}" -f $localPath)

# 4) Find references in repo
$patterns = @()
$patterns += "$ns/$devName"                 # JS import
$patterns += "<$($ns.ToLower())-$kebab"     # markup tag prefix
$patterns = $patterns | Sort-Object -Unique

Write-Host "`n== References in repo ($Root) ==" -ForegroundColor Cyan
$rg = Get-Command rg -ErrorAction SilentlyContinue

if ($rg) {
  foreach ($p in $patterns) {
    Write-Host "`n--- Pattern: $p"
    rg -n --no-heading --line-number --fixed-strings "$p" "$Root" 2>$null | Select-Object -First $MaxResultsPerPattern
  }
} else {
  Write-Host "(ripgrep not found; using Select-String - slower)"
  # collect plain paths (strings) to avoid pipeline-binding issues
  $paths = Get-ChildItem -Recurse -File $Root | Select-Object -ExpandProperty FullName
  foreach ($p in $patterns) {
    Write-Host "`n--- Pattern: $p"
    if ($paths -and $paths.Count -gt 0) {
      $hits = Select-String -Path $paths -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue
      if ($hits) {
        $hits |
          Select-Object -First $MaxResultsPerPattern |
          ForEach-Object { "{0}:{1}: {2}" -f $_.Path, $_.LineNumber, ($_.Line.Trim()) }
      } else {
        Write-Host "(no matches)"
      }
    } else {
      Write-Host "(no files under $Root)"
    }
  }
}

Write-Host "`nTips:" -ForegroundColor DarkCyan
Write-Host ("- Retrieve bundle if missing:  sf project retrieve start -m `"LightningComponentBundle:{0}`"" -f $devName)
Write-Host ("- Likely markup tag:           <{0}-{1} ...></{0}-{1}>" -f $ns.ToLower(), $kebab)
Write-Host ("- Likely JS import:            import x from '{0}/{1}';" -f $ns, $devName)