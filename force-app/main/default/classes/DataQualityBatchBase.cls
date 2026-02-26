global abstract class DataQualityBatchBase
    implements Database.Batchable<SObject>, Database.Stateful {

    protected final String objectApi;
    protected final Boolean dryRun;

    // Результати для агрегації / JSON / нотифікацій
    public List<DataQualityFinding> findings = new List<DataQualityFinding>();

    protected DataQualityBatchBase(String objectApi, Boolean dryRun) {
        this.objectApi = objectApi;
        this.dryRun = dryRun;
    }

    /* =======================
       START
       ======================= */
    global Database.QueryLocator start(Database.BatchableContext bc) {

        List<InvalidPhoneEmail__mdt> mappings =
            DataQualityService.getMappingsForObject(objectApi);

        if (mappings.isEmpty()) {
            return Database.getQueryLocator(
                'SELECT Id FROM ' + objectApi + ' WHERE Id = null'
            );
        }

        Set<String> fieldApis = new Set<String>();
        for (InvalidPhoneEmail__mdt m : mappings) {
            fieldApis.add(m.FieldAPI__c);
        }
        
        String accId = '';
        if(objectApi == 'Contact') accId = 'AccountId,';
        
        String soql =
            'SELECT Id, OwnerId, ' + accId +
            String.join(new List<String>(fieldApis), ',') +
            ' FROM ' + objectApi;

        return Database.getQueryLocator(soql);
    }

    /* =======================
       EXECUTE (DO NOT OVERRIDE)
       ======================= */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        // стандартні перевірки (email / phone / website)
        processStandardChecks(scope);

        // hook для спеціалізованих batch
        afterStandardChecks(scope);
    }

    /* =======================
       STANDARD CHECKS
       ======================= */
    protected void processStandardChecks(List<SObject> scope) {

        List<InvalidPhoneEmail__mdt> mappings =
            DataQualityService.getMappingsForObject(objectApi);

        if (mappings.isEmpty()) return;

        //List<SObject> toUpdate = new List<SObject>();
        Map<Id, SObject> toUpdate = new Map<Id, SObject>();

        for (SObject record : scope) {

            Id ownerId = (Id) record.get('OwnerId');

            for (InvalidPhoneEmail__mdt m : mappings) {

                String fieldApi = m.FieldAPI__c;
                String logicalField = m.FieldNameParam__c;

                Object raw = record.get(fieldApi);
                if (raw == null) continue;

                String value = String.valueOf(raw).trim();
                if (value == '') continue;

                Boolean isInvalid = false;
                Boolean isSuspicious = false;

                if (logicalField == 'Email') {
                    isInvalid = DataQualityService.isInvalidEmail(value);
                    if (!isInvalid) {
                        isSuspicious =
                            DataQualityService.isSuspiciousEmail(value);
                    }
                } else if (logicalField == 'Phone' || logicalField == 'Mobile') {
                    isInvalid = DataQualityService.isInvalidPhone(value);
                    if (!isInvalid) {
                        isSuspicious =
                            DataQualityService.isSuspiciousPhone(value);
                    }
                } else if (logicalField == 'Website') {
                    isInvalid = DataQualityService.isInvalidWebsite(value);
                }

                if (!isInvalid && !isSuspicious) continue;

                // === finding ===
                DataQualityFinding f = new DataQualityFinding();
                f.objectApi = objectApi;
                f.recordId  = record.Id;
                f.fieldApi  = fieldApi;
                f.value     = value;
                f.level     = isInvalid ? 'Invalid' : 'Suspicious';
                f.ownerId  = ownerId;

                findings.add(f);

                if (!dryRun) {
                    if (isInvalid) {
                        record.put(
                            logicalField + '_Is_Invalid__c',
                            true
                        );
                    }
                    if (isSuspicious) {
                        record.put(
                            logicalField + '_Is_Suspicious__c',
                            true
                        );
                    }
                    //toUpdate.add(record);
                    toUpdate.put(record.Id, record);
                }
            }
        }

        if (!dryRun && !toUpdate.isEmpty()) {
            //update toUpdate;
            update toUpdate.values();
        }
    }

    /* =======================
       EXTENSION HOOK
       ======================= */
    public virtual void afterStandardChecks(List<SObject> scope) {
        // default: nothing
        // ContactDataQualityBatch override here
    }

    /* =======================
       FINISH
       ======================= */
    global void finish(Database.BatchableContext bc) {
        // aggregation / notification / logging буде тут
    }
}