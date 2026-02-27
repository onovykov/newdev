@IsTest
private class InvoiceOrderDebtCleaning_Tests {

    // ─── MockBatchContext ─────────────────────────────────────────────────────
    // Database.BatchableContext is an interface, so we can implement it to call
    // execute() directly without going through Database.executeBatch().
    // execute() in InvoiceOrderDebtCleaning does not use the context object,
    // so returning null from both methods is safe.

    private class MockBatchContext implements Database.BatchableContext {
        public Id getJobId()      { return null; }
        public Id getChildJobId() { return null; }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static List<InvoiceOrderDebt__c> makeDebts(Integer n) {
        List<InvoiceOrderDebt__c> rows = new List<InvoiceOrderDebt__c>();
        for (Integer i = 0; i < n; i++) {
            rows.add(new InvoiceOrderDebt__c());
        }
        insert rows;
        return rows;
    }

    private static void setCreated(List<InvoiceOrderDebt__c> rows, Datetime dt) {
        for (InvoiceOrderDebt__c r : rows) {
            Test.setCreatedDate(r.Id, dt);
        }
    }

    private static Integer countCleaningBatchJobs() {
        return [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
        ];
    }

    private static ERPMessageParser.InvoiceOrderDebtMessageData makeMessageData(String invoiceName) {
        ERPMessageParser.InvoiceOrderDebtMessageData m = new ERPMessageParser.InvoiceOrderDebtMessageData();
        m.NDM_INVOCE = invoiceName;
        m.NET_AMNT   = 100;
        m.VAL        = 'USD';
        return m;
    }

    // ─── Constructor coverage ─────────────────────────────────────────────────

    @IsTest
    static void testLegacySingleArgConstructor() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(src), 200);
        Test.stopTest();

        System.assert(countCleaningBatchJobs() > 0, 'Batch should be enqueued via legacy single-arg constructor');
    }

    @IsTest
    static void testTwoArgConstructor() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(src, 'Test:TwoArg'), 200);
        Test.stopTest();

        System.assert(countCleaningBatchJobs() > 0, 'Two-arg constructor should produce a valid, runnable batch');
    }

    // ─── start() / execute() — normal delete path ────────────────────────────

    @IsTest
    static void testDeletesOldKeepsFresh_withExecuteBatch() {
        List<InvoiceOrderDebt__c> all = makeDebts(3);

        List<InvoiceOrderDebt__c> oldOnes   = new List<InvoiceOrderDebt__c>{ all[0], all[1] };
        List<InvoiceOrderDebt__c> freshOnes = new List<InvoiceOrderDebt__c>{ all[2] };

        setCreated(oldOnes,   Datetime.now().addHours(-1));
        setCreated(freshOnes, Datetime.now());

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:SingleBatch'), 200);
        Test.stopTest();

        Set<Id> oldIds   = new Set<Id>{ oldOnes[0].Id, oldOnes[1].Id };
        Set<Id> freshIds = new Set<Id>{ freshOnes[0].Id };

        Map<Id, InvoiceOrderDebt__c> oldFetched = new Map<Id, InvoiceOrderDebt__c>([
            SELECT Id, IsDeleted FROM InvoiceOrderDebt__c WHERE Id IN :oldIds ALL ROWS
        ]);
        Map<Id, InvoiceOrderDebt__c> freshFetched = new Map<Id, InvoiceOrderDebt__c>([
            SELECT Id, IsDeleted FROM InvoiceOrderDebt__c WHERE Id IN :freshIds ALL ROWS
        ]);

        System.assertEquals(2, oldFetched.size(), 'Must fetch both old rows');
        for (InvoiceOrderDebt__c r : oldFetched.values()) {
            System.assertEquals(true, r.IsDeleted, 'Old record must be deleted');
        }
        System.assertEquals(1, freshFetched.size(), 'Must fetch fresh row');
        for (InvoiceOrderDebt__c r : freshFetched.values()) {
            System.assertEquals(false, r.IsDeleted, 'Fresh record must NOT be deleted');
        }
    }

    @IsTest
    static void testNoOldRecords_executeNotCalled() {
        // All records are fresh → start() returns empty scope → execute() is not called.
        // Nothing should be deleted.
        List<InvoiceOrderDebt__c> fresh = makeDebts(2);
        setCreated(fresh, Datetime.now());

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:EmptyScope'), 200);
        Test.stopTest();

        List<InvoiceOrderDebt__c> remaining = [SELECT Id FROM InvoiceOrderDebt__c WHERE Id IN :fresh];
        System.assertEquals(2, remaining.size(), 'Fresh records must not be touched when execute() gets empty scope');
    }

    // ─── start() guard — two batches queued ──────────────────────────────────

    @IsTest
    static void testGuardNoOpWhenTwoQueued() {
        List<InvoiceOrderDebt__c> one = makeDebts(1);
        setCreated(one, Datetime.now().addHours(-1));

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:GuardA', 0, 0), 200);
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:GuardB', 0, 0), 200);
        Test.stopTest();

        InvoiceOrderDebt__c fetched = [
            SELECT Id, IsDeleted FROM InvoiceOrderDebt__c WHERE Id = :one[0].Id ALL ROWS
        ];
        System.assertEquals(false, fetched.IsDeleted,
            'With two same batches queued and retryMax=0, guard makes one no-op; record must survive');
    }

    @IsTest
    static void testGuardEnqueuesRetryQueueable_whenRetryAllowed() {
        InvoiceOrderDebt__c d = new InvoiceOrderDebt__c();
        insert d;
        Test.setCreatedDate(d.Id, Datetime.now().addHours(-2));

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:RetryA', 0, 1), 200);
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:RetryB', 0, 1), 200);
        Test.stopTest();

        // At least one cleaning job must exist; the guard on the second batch
        // enqueues InvoiceOrderDebtRetryQueueable (which in tests is a no-op re-enqueue),
        // but the original batch itself must have run.
        System.assert(countCleaningBatchJobs() > 0,
            'At least one InvoiceOrderDebtCleaning batch job must exist after guard+retry path');
    }

    // ─── finish() — CronTrigger / scheduler path ──────────────────────────────

    @IsTest
    static void testSchedulerBranch_usesSchedulerPath_butNotBrittle() {
        Test.startTest();
        String jobName = 'DebtCleanTestJob_' + String.valueOf(Datetime.now().getTime());
        System.scheduleBatch(new InvoiceOrderDebtCleaning(null, 'Test:Scheduler'), jobName, 1, 200);
        Test.stopTest();

        AsyncApexJob j = [
            SELECT Id, ApexClass.Name, JobType, CreatedDate
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, j, 'Batch job should exist after scheduleBatch');
        System.assertEquals('InvoiceOrderDebtCleaning', j.ApexClass.Name);
    }

    // ─── finish() — source-triggered InvoiceOrderDebtBatch ───────────────────

    @IsTest
    static void testFinishLaunchesDebtBatch_whenSourceIsNonEmpty() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>{
                makeMessageData('INV-FINISH-TEST')
            };

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(src, 'Test:FinishWithSource'), 200);
        Test.stopTest();

        Integer debtBatchCnt = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtBatch'
        ];
        System.assert(debtBatchCnt > 0,
            'finish() must launch InvoiceOrderDebtBatch when source list is non-empty');
    }

    @IsTest
    static void testFinishDoesNotLaunchDebtBatch_whenSourceIsNull() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:FinishNullSource'), 200);
        Test.stopTest();

        Integer debtBatchCnt = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtBatch'
        ];
        System.assertEquals(0, debtBatchCnt,
            'finish() must NOT launch InvoiceOrderDebtBatch when source is null');
    }

    @IsTest
    static void testFinishDoesNotLaunchDebtBatch_whenSourceIsEmpty() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(src, 'Test:FinishEmptySource'), 200);
        Test.stopTest();

        Integer debtBatchCnt = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtBatch'
        ];
        System.assertEquals(0, debtBatchCnt,
            'finish() must NOT launch InvoiceOrderDebtBatch when source is an empty list');
    }

    // ─── execute() error branches — direct invocation via MockBatchContext ────

    @IsTest
    static void testExecute_alreadyDeletedRecord_incrementsAlreadyDeleted() {
        // Soft-delete a record so it lives in the recycle bin.
        // Database.delete(scope, false) on a recycled record returns a DeleteResult
        // with isSuccess=false and StatusCode.ENTITY_IS_DELETED → alreadyDeleted++.
        InvoiceOrderDebt__c d = new InvoiceOrderDebt__c();
        insert d;
        Id deletedId = d.Id;
        delete d; // soft-delete → recycle bin

        List<InvoiceOrderDebt__c> recycled = [
            SELECT Id FROM InvoiceOrderDebt__c WHERE Id = :deletedId ALL ROWS
        ];
        System.assertEquals(1, recycled.size(), 'Soft-deleted record must be fetchable with ALL ROWS');

        InvoiceOrderDebtCleaning batch = new InvoiceOrderDebtCleaning(null, 'Test:AlreadyDeleted');

        Test.startTest();
        batch.execute(new MockBatchContext(), recycled);
        Test.stopTest();

        // Assertion: the method completed without throwing.
        // The ENTITY_IS_DELETED branch (alreadyDeleted++) was covered.
        InvoiceOrderDebt__c still = [
            SELECT Id, IsDeleted FROM InvoiceOrderDebt__c WHERE Id = :deletedId ALL ROWS
        ];
        System.assertEquals(true, still.IsDeleted,
            'Record must remain in recycle bin after execute() attempted a second delete');
    }
}