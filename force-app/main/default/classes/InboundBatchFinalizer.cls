global with sharing class InboundBatchFinalizer
    implements Database.Batchable<SObject>, Schedulable {

    // =========================================================
    // SCHEDULER ENTRY POINT
    // =========================================================
    global void execute(SchedulableContext sc) {

        AsyncConfig cfg = AsyncConfigProvider.get();

        Database.executeBatch(
            new InboundBatchFinalizer(),
            cfg.batchSize
        );
    }

    // =========================================================
    // START
    // =========================================================
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // FIX: жорстко матеріалізуємо Set → щоб SOQL не зламав IN
        Set<String> liveStatuses = new Set<String>();
        liveStatuses.addAll(InboundBatchStatusProvider.liveStatusKeys());

        System.debug('LIVE STATUSES (FINALIZER) = ' + liveStatuses);

        return Database.getQueryLocator([
            SELECT Id
            FROM ERP_InboundBatch__c
            WHERE Status__c IN :liveStatuses
            ORDER BY LastSeenAt__c ASC
        ]);
    }

    // =========================================================
    // EXECUTE
    // =========================================================
    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        if (scope == null || scope.isEmpty()) {
            return;
        }

        // Config
        AsyncConfig cfg = AsyncConfigProvider.get();
        Integer timeoutSeconds = cfg.timeout;

        // Collect IDs
        Set<Id> ids = new Set<Id>();
        for (SObject s : scope) {
            ids.add((Id)s.get('Id'));
        }

        // Lock batches
        List<ERP_InboundBatch__c> batches = [
            SELECT Id,
                BatchKey__c,
                Status__c,
                Direction__c,
                TotalParts__c,
                ReceivedParts__c,
                FirstSeenAt__c,
                LastSeenAt__c,
                ProcessingStartedAt__c,
                CompletedAt__c,
                ErrorMessage__c
            FROM ERP_InboundBatch__c
            WHERE Id IN :ids
            FOR UPDATE
        ];

        List<ERP_InboundBatch__c> toUpdate = new List<ERP_InboundBatch__c>();
        List<ERP_InboundBatch__c> toProcess = new List<ERP_InboundBatch__c>();

        for (ERP_InboundBatch__c b : batches) {

            // skip terminal
            if (InboundBatchStatusProvider.isTerminal(b.Status__c)) {
                continue;
            }

            //Integer total = b.TotalParts__c;
            //Integer recv  = b.ReceivedParts__c;
            Integer total = b.TotalParts__c != null
                ? Integer.valueOf(b.TotalParts__c)
                : null;

            Integer recv = b.ReceivedParts__c != null
                ? Integer.valueOf(b.ReceivedParts__c)
                : null;

            Boolean isComplete =
                (total != null && recv != null && recv >= total);

            Boolean isTimeout = false;

            if (!isComplete && b.LastSeenAt__c != null) {
                Long ageMs = System.now().getTime() - b.LastSeenAt__c.getTime();
                isTimeout =
                    (ageMs > (timeoutSeconds * 1000)) &&
                    InboundBatchStatusProvider.canTimeout(b.Status__c);
            }

            // 1. COMPLETE → COMPLETED
            if (isComplete) {

                b.Status__c = InboundBatchStatusProvider.completed();
                b.CompletedAt__c = System.now();

                toUpdate.add(b);
                toProcess.add(b);

                continue;
            }

            // 2. TIMEOUT → TIMEOUT
            if (isTimeout) {

                b.Status__c = InboundBatchStatusProvider.timeout();
                b.CompletedAt__c = System.now();
                b.ErrorMessage__c = 'Batch timeout';

                toUpdate.add(b);

                continue;
            }

            // 3. STILL PROCESSING → mark PROCESSING (once)
            if (b.ProcessingStartedAt__c == null) {

                b.Status__c = InboundBatchStatusProvider.processing();
                b.ProcessingStartedAt__c = System.now();

                toUpdate.add(b);
            }
        }

        // Update statuses first
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // Process completed batches
        for (ERP_InboundBatch__c b : toProcess) {

            try {
                processBatch(b);

            } catch (Exception ex) {

                b.Status__c = InboundBatchStatusProvider.failed();
                b.ErrorMessage__c = ex.getMessage();
                b.CompletedAt__c = System.now();

                update b;
            }
        }
    }

    // =========================================================
    // PROCESS SINGLE BATCH
    // =========================================================
    private static void processBatch(ERP_InboundBatch__c batch) {

        try {

            // -------------------------------------
            // 1. Load parts
            // -------------------------------------
            List<ERP_InboundPart__c> parts = [
                SELECT PartNumber__c, Payload__c
                FROM ERP_InboundPart__c
                WHERE BatchKey__c = :batch.BatchKey__c
                ORDER BY PartNumber__c ASC
            ];

            // -------------------------------------
            // 2. Assemble JSON
            // -------------------------------------
            String fullJson = '';

            for (ERP_InboundPart__c p : parts) {
                if (p.Payload__c != null) {
                    fullJson += p.Payload__c;
                }
            }

            // -------------------------------------
            // 3. Assemble + normalize JSON
            // -------------------------------------
            Map<String, Object> meta;
            Map<String, Object> combinedData = new Map<String, Object>();

            for (ERP_InboundPart__c p : parts) {

                if (p.Payload__c == null) continue;

                Map<String, Object> part =
                    (Map<String, Object>) JSON.deserializeUntyped(p.Payload__c);

                // Metadata беремо тільки один раз
                if (meta == null && part.containsKey('Metadata')) {
                    meta = (Map<String, Object>) part.get('Metadata');
                }

                // Data об'єднуємо
                if (part.containsKey('Data')) {
                    Map<String, Object> dataPart =
                        (Map<String, Object>) part.get('Data');

                    combinedData.putAll(dataPart);
                }
            }

            // -------------------------------------
            // FINAL NORMALIZED JSON
            // -------------------------------------
            Map<String, Object> normalized = new Map<String, Object>{
                'Metadata' => meta,
                'Payload'  => combinedData
            };

            String normalizedJson = JSON.serialize(normalized);

            // -------------------------------------
            // 4. Call Orchestrator
            // -------------------------------------
            IntegrationResponse r =
                IntegrationOrchestrator.process(
                    normalizedJson,
                    null
                );

            // -------------------------------------
            // 5. Finalize under lock
            // -------------------------------------
            ERP_InboundBatch__c locked = [
                SELECT Id, Status__c, ErrorMessage__c, CompletedAt__c
                FROM ERP_InboundBatch__c
                WHERE Id = :batch.Id
                FOR UPDATE
            ];

            if (InboundBatchStatusProvider.isTerminal(locked.Status__c)) {
                return;
            }

            if (isSuccess(r)) {

                locked.Status__c = InboundBatchStatusProvider.completed();
                locked.CompletedAt__c = System.now();
                locked.ErrorMessage__c = null;

            } else {

                locked.Status__c = InboundBatchStatusProvider.failed();

                locked.ErrorMessage__c =
                    (r == null)
                        ? 'NULL_RESPONSE_FROM_ORCHESTRATOR'
                        : ((r.code != null ? r.code : 'NO_CODE') +
                           ': ' +
                           r.message);
            }

            update locked;

        } catch (Exception ex) {

            ERP_InboundBatch__c locked = [
                SELECT Id, Status__c, ErrorMessage__c
                FROM ERP_InboundBatch__c
                WHERE Id = :batch.Id
                FOR UPDATE
            ];

            locked.Status__c = InboundBatchStatusProvider.failed();
            locked.ErrorMessage__c = 'EXCEPTION: ' + ex.getMessage();

            update locked;
        }
    }

    // =========================================================
    // SUCCESS CHECK
    // =========================================================
    private static Boolean isSuccess(IntegrationResponse r) {

        if (r == null) return false;

        if (r.status == 'FULL_SUCCESS' || r.status == 'PARTIAL_SUCCESS') {
            return true;
        }

        if (r.success == true) {
            return true;
        }

        return false;
    }

    // =========================================================
    // FINISH
    // =========================================================
    global void finish(Database.BatchableContext bc) {
        // metrics / logging hook
    }
}