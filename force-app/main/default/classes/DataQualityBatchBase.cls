public abstract class DataQualityBatchBase
    implements Database.Batchable<SObject>, Database.Stateful {

    protected final String objectApi;
    protected final Boolean dryRun;

    // dry-run accumulator
    public List<DataQualityFinding> findings = new List<DataQualityFinding>();

    protected List<InvalidPhoneEmail__mdt> mappings;

    protected DataQualityBatchBase(String objectApi, Boolean dryRun) {
        this.objectApi = objectApi;
        this.dryRun = dryRun;
        this.mappings = loadMappings(objectApi);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Set<String> fields = new Set<String>{ 'Id', 'OwnerId' };
        List<String> conditions = new List<String>();

        for (InvalidPhoneEmail__mdt m : mappings) {
            fields.add(m.FieldAPI__c);
            fields.add(getInvalidFlagField(m));
            fields.add(getSuspiciousFlagField(m));
            conditions.add(m.FieldAPI__c + ' != null');
        }

        String soql =
            'SELECT ' + String.join(new List<String>(fields), ', ') +
            ' FROM ' + objectApi;

        if (!conditions.isEmpty()) {
            soql += ' WHERE (' + String.join(conditions, ' OR ') + ')';
        }

        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<SObject> toUpdate = new List<SObject>();

        for (SObject s : scope) {
            Boolean changed = false;

            for (InvalidPhoneEmail__mdt m : mappings) {

                String fieldApi = m.FieldAPI__c;
                Object raw = s.get(fieldApi);
                if (raw == null) continue;

                String val = String.valueOf(raw);

                Boolean invalid = DataQualityService.isInvalid(
                    m.ObjectNameParam__c,
                    m.FieldNameParam__c,
                    s
                );

                Boolean suspicious =
                    !invalid && isSuspiciousByType(m, val);

                // collect (dry-run / notifications)
                if (invalid || suspicious) {
                    DataQualityFinding f = new DataQualityFinding();
                    f.ownerId  = (Id)s.get('OwnerId');
                    f.objectApi = objectApi;
                    f.recordId = (Id)s.get('Id');
                    f.fieldApi = fieldApi;
                    f.level    = invalid ? 'Invalid' : 'Suspicious';
                    f.value    = val;
                    findings.add(f);
                }

                if (!dryRun) {
                    if (invalid &&
                        (Boolean)s.get(getInvalidFlagField(m)) != true) {

                        s.put(getInvalidFlagField(m), true);
                        changed = true;

                    } else if (suspicious &&
                        (Boolean)s.get(getSuspiciousFlagField(m)) != true) {

                        s.put(getSuspiciousFlagField(m), true);
                        changed = true;
                    }
                }
            }

            if (!dryRun && changed) {
                toUpdate.add(s);
            }
        }

        if (!dryRun && !toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {

        if (!dryRun) return;
        if (findings.isEmpty()) {
            System.debug('DATA QUALITY: no issues found');
            return;
        }

        Map<Id, DataQualityOwnerReport> byOwner =
            DataQualityAggregator.aggregate(findings);

        String json = System.JSON.serializePretty(byOwner);

        System.debug('===== DATA QUALITY DRY RUN RESULT =====');
        System.debug(json);
    }

    // ------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------

    private static List<InvalidPhoneEmail__mdt> loadMappings(String obj) {
        List<InvalidPhoneEmail__mdt> res = new List<InvalidPhoneEmail__mdt>();
        for (InvalidPhoneEmail__mdt m : InvalidPhoneEmail__mdt.getAll().values()) {
            if (m.ObjectAPI__c == obj) {
                res.add(m);
            }
        }
        return res;
    }

    private static String getInvalidFlagField(InvalidPhoneEmail__mdt m) {
        return m.FieldAPI__c.replace('__c', '') + '_Is_Invalid__c';
    }

    private static String getSuspiciousFlagField(InvalidPhoneEmail__mdt m) {
        return m.FieldAPI__c.replace('__c', '') + '_Is_Suspicious__c';
    }

    private static Boolean isSuspiciousByType(
        InvalidPhoneEmail__mdt m,
        String val
    ) {
        String f = m.FieldNameParam__c;
        if (f == 'Email') {
            return DataQualityService.isSuspiciousEmail(val);
        }
        if (f == 'Phone' || f == 'Mobile') {
            return DataQualityService.isSuspiciousPhone(val);
        }
        return false;
    }
}