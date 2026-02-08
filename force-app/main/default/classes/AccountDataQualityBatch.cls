global class AccountDataQualityBatch extends DataQualityBatchBase {

    global AccountDataQualityBatch(Boolean dryRun) {
        super('Account', dryRun);
    }
}