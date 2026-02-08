global class ContactDataQualityBatch extends DataQualityBatchBase {

    global ContactDataQualityBatch(Boolean dryRun) {
        super('Contact', dryRun);
    }
}