public with sharing class AdminConsoleController {
    // Preview SOQL (тільки SELECT)
    // приймає SOQL (тільки SELECT, без DML)
    // повертає: columns, rows, recordCount

    public class PreviewResponse {
        @AuraEnabled public List<String> columns;
        @AuraEnabled public List<Map<String, Object>> rows;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public String message;
    }

    @AuraEnabled(cacheable=true)
    public static PreviewResponse previewSoql(String soql, Integer maxRows) {
        if (String.isBlank(soql)) {
            throw new AuraHandledException('SOQL is blank');
        }

        String s = soql.trim().toLowerCase();
        if (!s.startsWith('select ')) {
            throw new AuraHandledException('Only SELECT is allowed');
        }

        Integer lim = (maxRows == null || maxRows <= 0) ? 200 : Math.min(maxRows, 2000);

        // enforce LIMIT if missing
        String soqlFixed = soql;
        if (!s.contains(' limit ')) {
            soqlFixed += ' LIMIT ' + lim;
        }

        List<SObject> records = Database.query(soqlFixed);
        PreviewResponse res = new PreviewResponse();
        res.recordCount = records.size();
        res.columns = new List<String>();
        res.rows = new List<Map<String, Object>>();

        if (records.isEmpty()) {
            res.message = 'No rows';
            return res;
        }

        // columns from first record populated fields (best-effort)
        Map<String, Object> first = records[0].getPopulatedFieldsAsMap();
        res.columns.add('Id');
        for (String k : first.keySet()) {
            if (k != 'Id') res.columns.add(k);
        }

        for (SObject r : records) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', (Id) r.get('Id'));
            Map<String, Object> pm = r.getPopulatedFieldsAsMap();
            for (String k : res.columns) {
                if (k == 'Id') continue;
                row.put(k, pm.containsKey(k) ? pm.get(k) : null);
            }
            res.rows.add(row);
        }

        res.message = 'OK';
        return res;
    }

    // Execute UPDATE/DELETE “by query” + snapshot + dry-run
    public class ExecuteResponse {
        @AuraEnabled public AsyncExecutorResult result;
        @AuraEnabled public Id snapshotContentVersionId;
        @AuraEnabled public String message;
    }

    // payload: {"Type":"Customer","SomeField__c":123}
    @AuraEnabled
    public static ExecuteResponse executeUpdateByQuery(
        String sObjectApi,
        List<String> fieldsToSelect,    // must include Id + all fields you might rollback
        String whereClause,
        Map<String, Object> setValues,  // fields -> value
        String asyncConfigName,
        Boolean dryRun,
        Integer snapshotLimit
    ) {
        if (String.isBlank(sObjectApi)) throw new AuraHandledException('sObjectApi is required');
        if (fieldsToSelect == null || fieldsToSelect.isEmpty()) throw new AuraHandledException('fieldsToSelect is required');
        if (!fieldsToSelect.contains('Id')) fieldsToSelect.add('Id');
        if (setValues == null || setValues.isEmpty()) throw new AuraHandledException('setValues is required');

        // 1) Snapshot BEFORE update (even dry-run? I recommend yes for safety, but you can decide)
        Integer lim = (snapshotLimit == null || snapshotLimit <= 0) ? 5000 : snapshotLimit;

        Id snapshotId = AdminFacade.selectToCsvFile(
            sObjectApi,
            fieldsToSelect,
            whereClause,
            lim
        );

        // 2) Build records
        List<SObject> records = QueryService.selectRecords(
            sObjectApi,
            fieldsToSelect,
            whereClause,
            null
        );

        // 3) Apply changes in memory
        for (SObject r : records) {
            for (String f : setValues.keySet()) {
                r.put(f, setValues.get(f));
            }
        }

        // 4) Execute
        ExecuteResponse out = new ExecuteResponse();
        out.snapshotContentVersionId = snapshotId;

        if (dryRun == true) {
            AsyncExecutorResult res = new AsyncExecutorResult();
            res.mode = AsyncExecutionMode.DRY_RUN;
            res.recordCount = records.size();
            res.message = 'Dry-run: update skipped';
            out.result = res;
            out.message = 'Snapshot saved to Files (ContentVersionId=' + snapshotId + ')';
            return out;
        }

        out.result = AsyncExecutor.updateSmart(records, asyncConfigName);
        out.message = 'Executed. Snapshot ContentVersionId=' + snapshotId;
        return out;
    }

    @AuraEnabled
    public static ExecuteResponse executeDeleteByQuery(
        String sObjectApi,
        List<String> snapshotFields,
        String whereClause,
        String asyncConfigName,
        Boolean dryRun,
        Integer snapshotLimit
    ) {
        if (String.isBlank(sObjectApi)) throw new AuraHandledException('sObjectApi is required');
        if (snapshotFields == null || snapshotFields.isEmpty()) snapshotFields = new List<String>{'Id'};

        if (!snapshotFields.contains('Id')) snapshotFields.add('Id');

        Integer lim = (snapshotLimit == null || snapshotLimit <= 0) ? 5000 : snapshotLimit;

        Id snapshotId = AdminFacade.selectToCsvFile(
            sObjectApi,
            snapshotFields,
            whereClause,
            lim
        );

        ExecuteResponse out = new ExecuteResponse();
        out.snapshotContentVersionId = snapshotId;

        if (dryRun == true) {
            AsyncExecutorResult res = new AsyncExecutorResult();
            res.mode = AsyncExecutionMode.DRY_RUN;
            res.recordCount = QueryService.selectRecords(sObjectApi, new List<String>{'Id'}, whereClause, null).size();
            res.message = 'Dry-run: delete skipped';
            out.result = res;
            out.message = 'Snapshot saved to Files (ContentVersionId=' + snapshotId + ')';
            return out;
        }

        out.result = AdminFacade.deleteByQuery(sObjectApi, whereClause, asyncConfigName, false);
        out.message = 'Executed delete. Snapshot ContentVersionId=' + snapshotId;
        return out;
    }    
}