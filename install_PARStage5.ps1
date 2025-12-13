Write-Host "=== STEP 5: Extracting PARStage_cmdt_records.zip ===" -ForegroundColor Cyan

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

# ✨ Custom extractor with overwrite support for Windows PowerShell 5.1
$zipFile = [System.IO.Compression.ZipFile]::OpenRead($zip)

foreach ($entry in $zipFile.Entries) {
    $targetFile = Join-Path $dest $entry.FullName

    # Create directory if needed
    $targetDir = Split-Path $targetFile
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Overwrite existing files
    if (Test-Path $targetFile) {
        Remove-Item $targetFile -Force
    }

    # Extract file
    $entryStream = $entry.Open()
    $fileStream = [System.IO.File]::Open($targetFile, "Create")
    $entryStream.CopyTo($fileStream)

    $fileStream.Close()
    $entryStream.Close()
}

$zipFile.Dispose()

Write-Host "ZIP extracted with overwrite support.`n" -ForegroundColor Green
