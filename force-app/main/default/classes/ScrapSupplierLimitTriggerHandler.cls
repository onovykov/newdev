public class ScrapSupplierLimitTriggerHandler extends TriggerHandler implements ITrigger {
    public ScrapSupplierLimitTriggerHandler(
            Map<Id, SObject> oldMap,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            List<SObject> newList
    ) {
        super(oldMap, newMap, oldList, newList);
    }

    // ==== ITrigger stubs (інтерфейсні методи) ====
    public void bulkBefore() { /* no-op */ }
    public void bulkAfter()  { /* no-op */ }

    public void beforeInsert(SObject so)                { /* no-op */ }
    public void beforeUpdate(SObject oldSo, SObject so) { /* no-op */ }
    public void beforeDelete(SObject so)                { /* no-op */ }  // <— ВАЖЛИВО: потрібний сигнатурою метод

    public void afterInsert(SObject so)                 { /* no-op */ }
    public void afterUpdate(SObject oldSo, SObject so)  { /* no-op */ }
    public void afterDelete(SObject so)                 { /* no-op */ }

    public override void beforePostProcessing()         { /* no-op */ }
    public void postProcessing()                        { /* no-op */ }

    // ========= ЛОГІКА BEFORE INSERT =========
    public void beforeInsert(List<ScrapSupplierLimit__c> newRecords) {
        if (newRecords.isEmpty()) return;

        Map<String, String> monthLabels = SysUtils.getPicklistFieldMap('Decade__c', 'Month__c', true);

        // Постачальники за Id
        Set<Id> supplierIds = new Set<Id>();
        for (ScrapSupplierLimit__c r : newRecords) if (r.Supplier__c != null) supplierIds.add(r.Supplier__c);

        Map<Id, Account> accById = new Map<Id, Account>();
        if (!supplierIds.isEmpty()) {
            for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :supplierIds]) accById.put(a.Id, a);
        }

        Set<String> keys = new Set<String>();
        Map<String, Integer> inBatchCounts = new Map<String, Integer>();

        for (ScrapSupplierLimit__c r : newRecords) {
            Integer nYear  = (r.YearPick__c != null) ? Integer.valueOf(r.YearPick__c) : Date.today().year();
            Integer nMonth = (r.Month__c    != null) ? Integer.valueOf(r.Month__c)    : Date.today().month();
            if (r.YearPick__c == null) r.YearPick__c = String.valueOf(nYear);
            if (r.Month__c    == null) r.Month__c    = String.valueOf(nMonth);

            r.MonthLookup__c = ScrapUtils.getMonthId(nYear, nMonth);
            r.Key__c = ScrapUtils.buildLimitKey(r);

            String monthName = monthLabels.get(r.Month__c);
            Account acc = accById.get(r.Supplier__c);
            String baseName = (acc != null)
                    ? StringUtilsEx.getFirstWord(ScrapUtils.getClearName(acc.Name))
                    : 'Постачальник';
            r.Name = baseName + ' ' + monthName + ' ' + r.YearPick__c + ' (' + r.Stage__c + ')';

            keys.add(r.Key__c);
            inBatchCounts.put(r.Key__c, (inBatchCounts.containsKey(r.Key__c) ? inBatchCounts.get(r.Key__c) + 1 : 1));
        }

        Map<String, Id> existingByKey = new Map<String, Id>();
        if (!keys.isEmpty()) {
            for (ScrapSupplierLimit__c ex : [
                    SELECT Id, Key__c
                    FROM ScrapSupplierLimit__c
                    WHERE Key__c IN :keys
            ]) existingByKey.put(ex.Key__c, ex.Id);
        }

        for (ScrapSupplierLimit__c r : newRecords) {
            Boolean dupInBatch = inBatchCounts.get(r.Key__c) > 1;
            Boolean dupInDb    = existingByKey.containsKey(r.Key__c);
            if (dupInBatch || dupInDb) {
                r.addError('❌ПОМИЛКА! Для цього постачальника на зазначений період уже існує ліміт в стадії «' + r.Stage__c + '»');
            }
        }
    }

    // ========= ЛОГІКА BEFORE UPDATE =========
    public void beforeUpdate(List<ScrapSupplierLimit__c> oldRecords, List<ScrapSupplierLimit__c> newRecords) {
        if (newRecords.isEmpty()) return;

        Map<String, String> monthLabels = SysUtils.getPicklistFieldMap('Decade__c', 'Month__c', true);

        Set<Id> supplierIds = new Set<Id>();
        for (ScrapSupplierLimit__c r : newRecords) if (r.Supplier__c != null) supplierIds.add(r.Supplier__c);

        Map<Id, Account> accById = new Map<Id, Account>();
        if (!supplierIds.isEmpty()) {
            for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :supplierIds]) accById.put(a.Id, a);
        }

        Set<String> keys = new Set<String>();
        Map<String, Integer> inBatchCounts = new Map<String, Integer>();

        for (Integer i = 0; i < newRecords.size(); i++) {
            ScrapSupplierLimit__c oldRec = oldRecords[i];
            ScrapSupplierLimit__c r      = newRecords[i];

            Boolean yearChanged  = oldRec.YearPick__c != r.YearPick__c;
            Boolean monthChanged = oldRec.Month__c    != r.Month__c;

            Integer nYear  = (r.YearPick__c != null) ? Integer.valueOf(r.YearPick__c)
                    : (oldRec.YearPick__c != null) ? Integer.valueOf(oldRec.YearPick__c)
                            : Date.today().year();
            Integer nMonth = (r.Month__c != null) ? Integer.valueOf(r.Month__c)
                    : (oldRec.Month__c != null) ? Integer.valueOf(oldRec.Month__c)
                            : Date.today().month();

            if (r.YearPick__c == null) r.YearPick__c = String.valueOf(nYear);
            if (r.Month__c    == null) r.Month__c    = String.valueOf(nMonth);

            if (yearChanged || monthChanged || r.MonthLookup__c == null) {
                r.MonthLookup__c = ScrapUtils.getMonthId(nYear, nMonth);
            }

            r.Key__c = ScrapUtils.buildLimitKey(r);

            String monthName = monthLabels.get(r.Month__c);
            Account acc = accById.get(r.Supplier__c);
            String baseName = (acc != null)
                    ? StringUtilsEx.getFirstWord(ScrapUtils.getClearName(acc.Name))
                    : 'Постачальник';
            r.Name = baseName + ' ' + monthName + ' ' + r.YearPick__c + ' (' + r.Stage__c + ')';

            keys.add(r.Key__c);
            inBatchCounts.put(r.Key__c, (inBatchCounts.containsKey(r.Key__c) ? inBatchCounts.get(r.Key__c) + 1 : 1));
        }

        Map<String, Id> existingIdByKey = new Map<String, Id>();
        if (!keys.isEmpty()) {
            for (ScrapSupplierLimit__c ex : [
                    SELECT Id, Key__c
                    FROM ScrapSupplierLimit__c
                    WHERE Key__c IN :keys
            ]) existingIdByKey.put(ex.Key__c, ex.Id);
        }

        for (ScrapSupplierLimit__c r : newRecords) {
            Boolean dupInBatch = inBatchCounts.get(r.Key__c) > 1;
            Id existId         = existingIdByKey.get(r.Key__c);
            Boolean dupInDb    = (existId != null && existId != r.Id);
            if (dupInBatch || dupInDb) {
                r.addError('❌ПОМИЛКА! Для цього постачальника на зазначений період уже існує ліміт в стадії «' + r.Stage__c + '»');
            }
        }
    }

    // Пакетні after — навмисно порожні, щоб не дублювати перевірки
    public void afterInsert(List<ScrapSupplierLimit__c> newRecords) { /* no-op */ }
    public void afterUpdate(List<ScrapSupplierLimit__c> newList, Map<Id, ScrapSupplierLimit__c> oldMap) { /* no-op */ }
}