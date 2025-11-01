# Find-LwcUsages.ps1
# Usage:
#   .\Find-LwcUsages.ps1 -ComponentName excelImport
#   .\Find-LwcUsages.ps1 -BundleId 0Rb1n000000bolECAQ
# Optional: -Root "force-app" -MaxResults 200 -SkipRetrieve

param(
  [string]$ComponentName,               # LWC DeveloperName (e.g., excelImport)
  [string]$BundleId,                    # or bundle Id 0Rb...
  [string]$Root = "force-app",
  [int]$MaxResults = 200,
  [switch]$SkipRetrieve
)

function Get-SfJson([string]$cmd) {
  $raw = Invoke-Expression "$cmd --json"
  if (-not $raw) { return $null }
  try { return ($raw | ConvertFrom-Json) } catch { return $null }
}

function To-KebabCase([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $s }
  # camelCase/PascalCase -> kebab-case
  $s = ($s -replace '([a-z0-9])([A-Z])','$1-$2')
  return $s.ToLower()
}

# Resolve ComponentName from BundleId if needed
$ns = 'c'
if (-not $ComponentName) {
  if (-not $BundleId) { Write-Error "Provide -ComponentName or -BundleId."; exit 1 }
  $b = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, DeveloperName, NamespacePrefix FROM LightningComponentBundle WHERE Id='$BundleId'`""
  if (-not $b -or -not $b.result.records) { Write-Error "Bundle not found by Id: $BundleId"; exit 1 }
  $ComponentName = $b.result.records[0].DeveloperName
  if ($b.result.records[0].NamespacePrefix) { $ns = $b.result.records[0].NamespacePrefix }
} else {
  $b2 = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, NamespacePrefix FROM LightningComponentBundle WHERE DeveloperName='$ComponentName' LIMIT 1`""
  if ($b2 -and $b2.result.records -and $b2.result.records[0].NamespacePrefix) { $ns = $b2.result.records[0].NamespacePrefix }
}

$kebab = To-KebabCase $ComponentName
$nsLower = $ns.ToLower()

Write-Host ("Component: {0} (namespace: {1})" -f $ComponentName, $ns)

# Retrieve metadata (unless skipped)
if (-not $SkipRetrieve) {
  Write-Host "Retrieving metadata (FlexiPage, Flow, ExperienceBundle, Aura, QuickAction)..." -ForegroundColor Cyan
  sf project retrieve start -m "FlexiPage,Flow,ExperienceBundle,AuraDefinitionBundle,QuickAction" | Out-Null
}

# Patterns to search
$patterns = @(
  # App Builder (FlexiPage) internal name:
  "componentName=`"$($ns)__$($ComponentName)`"",
  # Flow screen use (internal name):
  "$($ns)__$($ComponentName)",
  # Markup tag (kebab):
  "<$nsLower-$kebab",
  # JS import form:
  "$ns/$ComponentName"
) | Sort-Object -Unique

Write-Host "`nSearching repo for patterns:"
$patterns | ForEach-Object { " - $_" }

# Helper: search with ripgrep if present, else Select-String (paths)
function Search-Paths($patterns, $root, $max) {
  $rg = Get-Command rg -ErrorAction SilentlyContinue
  $results = @()
  if ($rg) {
    foreach ($p in $patterns) {
      $hits = rg -n --no-heading --line-number --fixed-strings "$p" "$root" 2>$null | Select-Object -First $max
      if ($hits) {
        $hits | ForEach-Object {
          $m = $_ -split ":",3
          if ($m.Count -ge 3) {
            $results += [PSCustomObject]@{ Path=$m[0]; Line=$m[1]; Text=$m[2]; Pattern=$p }
          }
        }
      }
    }
  } else {
    # Collect plain path strings; do NOT pipe FileInfo into Select-String
    $paths = Get-ChildItem -Recurse -File $root | Select-Object -ExpandProperty FullName
    foreach ($p in $patterns) {
      if ($paths -and $paths.Count -gt 0) {
        $hits = Select-String -Path $paths -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue
        if ($hits) {
          $hits | Select-Object -First $max | ForEach-Object {
            $results += [PSCustomObject]@{ Path=$_.Path; Line=$_.LineNumber; Text=$_.Line.Trim(); Pattern=$p }
          }
        }
      }
    }
  }
  return $results
}

# Explicit folder list as strings (щоб не плутатись із Join-Path)
$folders = @(
  "$Root\main\default\flexipages",
  "$Root\main\default\flows",
  "$Root\main\default\experiences",
  "$Root\main\default\aura",
  "$Root\main\default\lwc",
  "$Root"
)

$allHits = @()
foreach ($f in $folders) {
  if (Test-Path $f) {
    $hits = Search-Paths $patterns $f $MaxResults
    if ($hits) { $allHits += $hits }
  }
}

# Tooling: QuickActionDefinition checks
$qaByName = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, DeveloperName, Label, Type, TargetObject, LightningWebComponentId FROM QuickActionDefinition WHERE Type='LightningWebComponent' AND DeveloperName LIKE '%$ComponentName%'`""
$qaById = $null
if ($BundleId) {
  $qaById = Get-SfJson "sf data query --use-tooling-api -q `"SELECT Id, DeveloperName, Label, Type, TargetObject, LightningWebComponentId FROM QuickActionDefinition WHERE Type='LightningWebComponent' AND LightningWebComponentId='$BundleId'`""
}

Write-Host "`n==== RESULTS ====" -ForegroundColor Green

# 1) Repo hits (grouped)
if ($allHits.Count -gt 0) {
  $byFile = $allHits | Group-Object Path | Sort-Object Name
  foreach ($g in $byFile) {
    Write-Host ("`nFile: {0}" -f $g.Name) -ForegroundColor Cyan
    $g.Group | Sort-Object {[int]$_.Line} | Select-Object -First $MaxResults | ForEach-Object {
      "[{0}] {1}  ({2})" -f $_.Line, $_.Text.Trim(), $_.Pattern
    }
  }
} else {
  Write-Host "No file references found in repo search."
}

# 2) QuickActions
Write-Host "`nQuickActionDefinition (by name):" -ForegroundColor Cyan
if ($qaByName -and $qaByName.result.records) {
  $qaByName.result.records | Select-Object DeveloperName,Label,Type,TargetObject,LightningWebComponentId | Format-Table -AutoSize
} else {
  Write-Host "(none)"
}
if ($BundleId) {
  Write-Host "QuickActionDefinition (by bundle Id):" -ForegroundColor Cyan
  if ($qaById -and $qaById.result.records) {
    $qaById.result.records | Select-Object DeveloperName,Label,Type,TargetObject,LightningWebComponentId | Format-Table -AutoSize
  } else {
    Write-Host "(none)"
  }
}

# 3) Summary
Write-Host "`n==== SUMMARY ====" -ForegroundColor Green
$summary = @()
foreach ($g in ($allHits | Group-Object {
    if ($_.Path -match '\\flexipages\\') { 'FlexiPage' }
    elseif ($_.Path -match '\\flows\\') { 'Flow' }
    elseif ($_.Path -match '\\experiences\\') { 'ExperienceBundle' }
    elseif ($_.Path -match '\\aura\\') { 'Aura' }
    elseif ($_.Path -match '\\lwc\\') { 'LWC (local refs)' }
    else { 'Other' }
  })) {
  $summary += [PSCustomObject]@{ Location=$g.Name; Count=$g.Count }
}
if ($qaByName -and $qaByName.result.records) {
  $summary += [PSCustomObject]@{ Location='QuickActionDefinition(by name)'; Count=$qaByName.result.records.Count }
}
if ($qaById -and $qaById.result.records) {
  $summary += [PSCustomObject]@{ Location='QuickActionDefinition(by Id)'; Count=$qaById.result.records.Count }
}
if ($summary.Count -gt 0) {
  $summary | Sort-Object Location | Format-Table -AutoSize
} else {
  Write-Host "No usages detected in searched surfaces."
}