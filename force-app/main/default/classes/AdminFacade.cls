public with sharing class AdminFacade {

    public static String selectToJson(
        String obj,
        List<String> fields,
        String whereClause,
        Integer limitSize
    ) {
        List<SObject> data =
            QueryService.selectRecords(obj, fields, whereClause, limitSize);

        return ExportService.toJson(data);
    }

    public static String selectToCsv(
        String obj,
        List<String> fields,
        String whereClause,
        Integer limitSize
    ) {
        List<SObject> data =
            QueryService.selectRecords(obj, fields, whereClause, limitSize);

        return ExportService.toCsv(data, fields);
    }

    public static AsyncExecutorResult updateByQuery(
        String sObjectApi,
        List<String> fields,
        String whereClause,
        String asyncConfigName,
        Boolean dryRun
    ) {
        if (String.isBlank(sObjectApi)) {
            throw new AdminLimitException('sObjectApi is required');
        }
        if (fields == null || fields.isEmpty()) {
            throw new AdminLimitException('fields are required');
        }
        if (!fields.contains('Id')) {
            fields.add('Id');
        }

        // 1) SELECT
        List<SObject> records =
            QueryService.selectRecords(
                sObjectApi,
                fields,
                whereClause,
                null
            );

        // 2) Guard
        guard(records.size());

        // 3) DRY-RUN — РАННІЙ ВИХІД
        if (dryRun == true) {
            AsyncExecutorResult res = new AsyncExecutorResult();
            res.mode = AsyncExecutionMode.DRY_RUN;
            res.recordCount = records.size();
            res.message = 'Dry-run: update skipped';
            return res;
        }

        // 4) Реальне виконання
        if (String.isBlank(asyncConfigName)) {
            return AsyncExecutor.updateSmart(records);
        } else {
            return AsyncExecutor.updateSmart(records, asyncConfigName);
        }
    }

    // Legacy / simple usage
    public static void updateByQuery(
        String obj,
        List<String> fields,
        String whereClause
    ) {
        updateByQuery(
            obj,
            fields,
            whereClause,
            null,   // default config
            false   // no dry-run
        );
    }

    public static Id selectToCsvFile(
        String obj,
        List<String> fields,
        String whereClause,
        Integer limitSize
    ) {
        List<SObject> data =
            QueryService.selectRecords(obj, fields, whereClause, limitSize);

        guard(data.size());

        String csv = ExportService.toCsv(data, fields);

        ContentVersion cv =
            ExportService.exportCsvToFile(
                obj + '_export_' + DateTime.now().format('yyyyMMdd_HHmm'),
                csv
            );

        return cv.Id;
    }

    public static AsyncExecutorResult deleteByQuery(
        String sObjectApi,
        String whereClause,
        String asyncConfigName,
        Boolean dryRun
    ) {
        if (String.isBlank(sObjectApi)) {
            throw new AdminLimitException('sObjectApi is required');
        }

        // 1) SELECT Id
        List<SObject> records =
            QueryService.selectRecords(
                sObjectApi,
                new List<String>{ 'Id' },
                whereClause,
                null
            );

        // 2) Guard
        guard(records.size());

        // 3) Resolve AsyncConfig
        AsyncConfig cfg = String.isBlank(asyncConfigName)
            ? AsyncConfigProvider.get()
            : AsyncConfigProvider.getByDeveloperName(asyncConfigName);

        // 4) Execute
        return AsyncExecutor.deleteSmart(records, cfg, dryRun);
    }

    private static void guard(Integer size) {
        if (size > AdminLimits.MAX_ALLOWED) {
            throw new AdminLimitException(
                'Too many rows selected: ' + size +
                ' (max allowed: ' + AdminLimits.MAX_ALLOWED + ')'
            );
        }
    }

}