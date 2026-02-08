global class ClientLeadDataQualityBatch extends DataQualityBatchBase {

    global ClientLeadDataQualityBatch(Boolean dryRun) {
        super('ClientLead__c', dryRun);
    }
}