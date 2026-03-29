global with sharing class InboundBatchFinalizer
    implements Database.Batchable<Id>, Schedulable {

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
    // START: select LIVE batches only
    // =========================================================
    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id
            FROM ERP_InboundBatch__c
            WHERE Status__c IN :InboundBatchStatusProvider.liveStatusKeys()
            ORDER BY LastSeenAt__c ASC
        ]);
    }

    // =========================================================
    // EXECUTE
    // =========================================================
    global void execute(Database.BatchableContext bc, List<Id> scope) {

        if (scope.isEmpty()) return;

        AsyncConfig cfg = AsyncConfigProvider.get();
        Integer timeoutSeconds = cfg.timeout;

        // Lock headers to avoid double-processing
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
            WHERE Id IN :scope
            FOR UPDATE
        ];

        List<ERP_InboundBatch__c> toUpdate  = new List<ERP_InboundBatch__c>();
        List<ERP_InboundBatch__c> toProcess = new List<ERP_InboundBatch__c>();

        for (ERP_InboundBatch__c b : batches) {

            // -----------------------------------------------------
            // TERMINAL GUARD
            // -----------------------------------------------------
            if (InboundBatchStatusProvider.isTerminal(b.Status__c)) {
                continue;
            }

            Integer total =
                b.TotalParts__c == null ? 0 : Integer.valueOf(b.TotalParts__c);
            Integer recv =
                b.ReceivedParts__c == null ? 0 : Integer.valueOf(b.ReceivedParts__c);

            Boolean isComplete =
                (total > 0 && recv >= total);

            Boolean isTimeout =
                InboundBatchStatusProvider.canTimeout(b.Status__c)
                && b.FirstSeenAt__c != null
                && b.FirstSeenAt__c.addSeconds(timeoutSeconds) <= System.now();

            // -----------------------------------------------------
            // TIMEOUT
            // -----------------------------------------------------
            if (!isComplete && isTimeout) {
                b.Status__c = InboundBatchStatusProvider.timeout();
                b.ErrorMessage__c =
                    'Timeout: received=' + recv +
                    ', expected=' + total +
                    ', timeoutSec=' + timeoutSeconds;
                toUpdate.add(b);
                continue;
            }

            // -----------------------------------------------------
            // WAIT
            // -----------------------------------------------------
            if (!isComplete) {
                continue;
            }

            // -----------------------------------------------------
            // MOVE TO PROCESSING (LOCKED)
            // -----------------------------------------------------
            if (b.Status__c != InboundBatchStatusProvider.processing()) {
                b.Status__c = InboundBatchStatusProvider.processing();
                b.ProcessingStartedAt__c = System.now();
                toUpdate.add(b);
            }

            toProcess.add(b);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // ---------------------------------------------------------
        // PROCESS COMPLETE BATCHES
        // ---------------------------------------------------------
        for (ERP_InboundBatch__c b : toProcess) {
            processBatch(b);
        }
    }

    // =========================================================
    // PROCESS SINGLE BATCH
    // =========================================================
    private static void processBatch(ERP_InboundBatch__c batch) {

        // 1️⃣ Load parts
        List<ERP_InboundPart__c> parts = [
            SELECT PartNumber__c, Payload__c
            FROM ERP_InboundPart__c
            WHERE BatchKey__c = :batch.BatchKey__c
            ORDER BY PartNumber__c ASC
        ];

        // 2️⃣ Assemble JSON
        String fullJson = '';
        for (ERP_InboundPart__c p : parts) {
            if (p.Payload__c != null) {
                fullJson += p.Payload__c;
            }
        }

        // 3️⃣ Call Orchestrator
        IntegrationResponse r =
            IntegrationOrchestrator.process(
                fullJson,
                batch.Direction__c
            );

        // 4️⃣ Finalize under lock (idempotency)
        ERP_InboundBatch__c locked = [
            SELECT Id, Status__c, ErrorMessage__c
            FROM ERP_InboundBatch__c
            WHERE Id = :batch.Id
            FOR UPDATE
        ];

        // Double-processing guard
        if (InboundBatchStatusProvider.isTerminal(locked.Status__c)) {
            return;
        }

        if (r != null && r.success) {
            locked.Status__c      = InboundBatchStatusProvider.completed();
            locked.CompletedAt__c = System.now();
            locked.ErrorMessage__c = null;
        } else {
            locked.Status__c = InboundBatchStatusProvider.failed();
            locked.ErrorMessage__c =
                (r == null)
                    ? 'NULL_RESPONSE_FROM_ORCHESTRATOR'
                    : (r.code + ': ' + r.message);
        }

        update locked;
    }

    // =========================================================
    // FINISH (OPTIONAL METRICS / LOGGING)
    // =========================================================
    global void finish(Database.BatchableContext bc) {
        // place for metrics, logging, events
    }
}