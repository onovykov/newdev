# Корінь Salesforce-проєкту
$projectRoot = "C:\Users\aleksandr.novikov\InterpipeNewDev"

# Metadata paths
$classesPath  = Join-Path $projectRoot "force-app\main\default\classes"
$triggersPath = Join-Path $projectRoot "force-app\main\default\triggers"

# Apex Classes
$apexClasses = @(
    "CopyProductionAmountinQuotas",
    "CopyProductionAmountinQuotasTest",
    "ProductionQuoteAddOppItem",
    "ProductionQuoteAddOppItemTest",
    "ProductionQuoteAddRelativeItems",
    "ProductionQuoteAddShopQuota",
    "ProductionQuoteCreateBatch",
    "ProductionQuoteDeleteDuplicationTest",
    "ProductionQuoteDeleteOppItemsBatchTest",
    "ProductionQuoteFromSalBudgetBatch",
    "ProductionQuoteFromSalBudgetBatchTest",
    "ProductionQuoteGroupAllBatch",
    "ProductionQuoteGroupBatch",
    "ProductionQuoteOnUpdateBatch",
    "ProductionQuoteUpdateOppItem",
    "SalesBudgetRecordTriggerHandler",
    "ShopQuotaTriggerHelper",
    "DeleteExtraShopQuotaOpportunity",
    "DeleteExtraShopQuotaOpportunityTest"
)

# Apex Triggers
$apexTriggers = @(
    "ShopQuotaTrigger",
    "SalesBudgetRecordTrigger"
)

Write-Host "=== Removing Apex Classes ===" -ForegroundColor Cyan

foreach ($name in $apexClasses) {

    $clsFile      = "$classesPath\$name.cls"
    $clsMetaFile  = "$classesPath\$name.cls-meta.xml"

    foreach ($file in @($clsFile, $clsMetaFile)) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Host "Deleted: $file"
        } else {
            Write-Host "Not found: $file"
        }
    }
}

Write-Host "`n=== Removing Apex Triggers ===" -ForegroundColor Cyan

foreach ($name in $apexTriggers) {

    $trgFile     = "$triggersPath\$name.trigger"
    $trgMetaFile = "$triggersPath\$name.trigger-meta.xml"

    foreach ($file in @($trgFile, $trgMetaFile)) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Host "Deleted: $file"
        } else {
            Write-Host "Not found: $file"
        }
    }
}

Write-Host "`nCleanup completed." -ForegroundColor Green