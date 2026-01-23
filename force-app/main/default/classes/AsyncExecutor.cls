public with sharing class AsyncExecutor {
    // Дефолтний AsyncConfigProvider
    public static AsyncExecutorResult updateSmart(
        List<SObject> records
    ) {
        return updateSmart(
            records,
            AsyncConfigProvider.get()
        );
    }
    // AsyncConfigProvider вибирається параметром
    public static AsyncExecutorResult updateSmart(
        List<SObject> records,
        String configDeveloperName
    ) {
        AsyncConfig cfg =
            AsyncConfigProvider.getByDeveloperName(configDeveloperName);

        AsyncExecutorResult res =
            updateSmart(records, cfg);

        res.configName = configDeveloperName;
        return res;
    }

    // З параметром AsyncConfig
    public static AsyncExecutorResult updateSmart(
        List<SObject> records,
        AsyncConfig cfg
    ) {
        AsyncExecutorResult result = new AsyncExecutorResult();
        result.executedAt = DateTime.now();

        if (records == null || records.isEmpty()) {
            result.mode = AsyncExecutionMode.NOOP;
            result.recordCount = 0;
            result.message = 'No records to process';
            return result;
        }

        result.recordCount = records.size();

        // 🔒 Safety guard
        if (cfg.syncLimit >= cfg.queueLimit) {
            throw new AsyncConfigException('Invalid AsyncConfig limits');
        }

        if (result.recordCount <= cfg.syncLimit) {
            DmlService.updateRecords(records, false);

            result.mode = AsyncExecutionMode.SYNC;
            result.message = 'Updated synchronously';

        } else if (result.recordCount <= cfg.queueLimit) {
            Id jobId =
                System.enqueueJob(
                    new UpdateQueueable(records)
                );

            result.mode = AsyncExecutionMode.QUEUEABLE;
            result.asyncJobId = jobId;
            result.message = 'Enqueued Queueable job';

        } else {
            Id jobId =
                Database.executeBatch(
                    new UpdateBatch(records),
                    cfg.batchSize
                );

            result.mode = AsyncExecutionMode.BATCH;
            result.asyncJobId = jobId;
            result.message = 'Batch job started';
        }

        return result;
    }

    public static AsyncExecutorResult insertSmart(
        List<SObject> records,
        AsyncConfig cfg,
        Boolean dryRun
    ) {
        AsyncExecutorResult res = new AsyncExecutorResult();
        res.recordCount = records.size();
        res.executedAt = DateTime.now();

        if (records == null || records.isEmpty()) {
            res.mode = AsyncExecutionMode.NOOP;
            res.recordCount = 0;
            res.message = 'No records to process';
            return res;
        }

        if (dryRun == true) {
            res.mode = AsyncExecutionMode.DRY_RUN;
            res.message = 'Dry-run: insert skipped';
            return res;
        }

        if (records.size() <= cfg.syncLimit) {
            DmlService.insertRecords(records, false);
            res.mode = AsyncExecutionMode.SYNC;
            res.message = 'Inserted synchronously';

        } else if (records.size() <= cfg.queueLimit) {
            res.asyncJobId =
                System.enqueueJob(
                    new InsertQueueable(records)
                );
            res.mode = AsyncExecutionMode.QUEUEABLE;
            res.message = 'Insert queued';

        } else {
            res.asyncJobId =
                Database.executeBatch(
                    new InsertBatch(records),
                    cfg.batchSize
                );
            res.mode = AsyncExecutionMode.BATCH;
            res.message = 'Insert batch started';
        }

        return res;
    }

    public static AsyncExecutorResult deleteSmart(
        List<SObject> records,
        AsyncConfig cfg,
        Boolean dryRun
    ) {
        AsyncExecutorResult res = new AsyncExecutorResult();
        res.recordCount = records.size();
        res.executedAt = DateTime.now();

        if (records == null || records.isEmpty()) {
            res.mode = AsyncExecutionMode.NOOP;
            res.recordCount = 0;
            res.message = 'No records to process';
            return res;
        }

        if (dryRun == true) {
            res.mode = AsyncExecutionMode.DRY_RUN;
            res.message = 'Dry-run: delete skipped';
            return res;
        }

        if (records.size() <= cfg.syncLimit) {
            DmlService.deleteRecords(records, false);
            res.mode = AsyncExecutionMode.SYNC;
            res.message = 'Deleted synchronously';

        } else if (records.size() <= cfg.queueLimit) {
            res.asyncJobId =
                System.enqueueJob(
                    new DeleteQueueable(records)
                );
            res.mode = AsyncExecutionMode.QUEUEABLE;
            res.message = 'Delete queued';

        } else {
            res.asyncJobId =
                Database.executeBatch(
                    new DeleteBatch(records),
                    cfg.batchSize
                );
            res.mode = AsyncExecutionMode.BATCH;
            res.message = 'Delete batch started';
        }

        return res;
    }
    // Дефолтний виклик - завжди NO DRY-RUN
    public static AsyncExecutorResult deleteSmart(
        List<SObject> records,
        AsyncConfig cfg
    ) {
        return deleteSmart(records, cfg, false);
    }  
}