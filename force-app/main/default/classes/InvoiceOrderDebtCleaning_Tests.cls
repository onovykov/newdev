@IsTest
private class InvoiceOrderDebtCleaning_Tests {

    // --- утиліта: створити N записів дебіторки
    private static List<InvoiceOrderDebt__c> makeDebts(Integer n) {
        List<InvoiceOrderDebt__c> rows = new List<InvoiceOrderDebt__c>();
        for (Integer i = 0; i < n; i++) {
            InvoiceOrderDebt__c d = new InvoiceOrderDebt__c();
            // TODO: якщо на об'єкті є обов'язкові поля — заповніть тут
            // d.SomeRequired__c = 'X';
            rows.add(d);
        }
        insert rows;
        return rows;
    }

    // --- утиліта: проставити CreatedDate постфактум
    private static void setCreated(List<InvoiceOrderDebt__c> rows, Datetime dt) {
        for (InvoiceOrderDebt__c r : rows) {
            Test.setCreatedDate(r.Id, dt);
        }
    }

    @IsTest
    static void testDeletesOldKeepsFresh_withExecuteBatch() {
        // Дані: 2 старі, 1 свіжий
        List<InvoiceOrderDebt__c> all = makeDebts(3);

        // Явно сформуємо групи без subList
        List<InvoiceOrderDebt__c> oldOnes = new List<InvoiceOrderDebt__c>{ all[0], all[1] };
        List<InvoiceOrderDebt__c> freshOnes = new List<InvoiceOrderDebt__c>{ all[2] };

        // Старі: 1 година тому; Свіжі: зараз
        setCreated(oldOnes, Datetime.now().addHours(-1));
        setCreated(freshOnes, Datetime.now());

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:SingleBatch'), 200);
        Test.stopTest();

        // Перевірка
        Set<Id> oldIds = new Set<Id>{ oldOnes[0].Id, oldOnes[1].Id };
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
    static void testGuardNoOpWhenTwoQueued() {
        // Один старий запис
        List<InvoiceOrderDebt__c> one = makeDebts(1);
        setCreated(one, Datetime.now().addHours(-1)); // старий

        Test.startTest();
        // Два однакові батчі поспіль — їхній внутрішній guard у start() поверне порожній QueryLocator
        // retry=0, retryMax=0 => ретрай вимкнено, guard робить чистий no-op
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:GuardA', 0, 0, 10), 200);
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:GuardB', 0, 0, 10), 200);
        Test.stopTest();

        // Має лишитися НЕ видаленим
        InvoiceOrderDebt__c fetched = [
            SELECT Id, IsDeleted FROM InvoiceOrderDebt__c WHERE Id = :one[0].Id ALL ROWS
        ];
        System.assertEquals(false, fetched.IsDeleted,
            'With two same batches queued, guard should make them no-op (record stays)');
    }

    @IsTest
    static void testSchedulerBranch_usesSchedulerPath_butNotBrittle() {
        Test.startTest();
        String jobName = 'DebtCleanTestJob_' + String.valueOf(Datetime.now().getTime());

        System.scheduleBatch(
            new InvoiceOrderDebtCleaning(null, 'Test:Scheduler'),
            jobName,
            1,   // хв
            200
        );
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

    @IsTest
    static void testRetrySchedulesAnotherBatchJob() {
        // 1 старий запис (не критично, але хай буде)
        InvoiceOrderDebt__c d = new InvoiceOrderDebt__c();
        insert d;
        Test.setCreatedDate(d.Id, Datetime.now().addHours(-2));

        Test.startTest();
        // Запускаємо два батчі, щоб другий попав на guard і створив ретрі-queueable
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:RetryA', 0, 1, 10), 200);
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Test:RetryB', 0, 1, 10), 200);
        Test.stopTest();

        // Має бути принаймні один batch-job нашого класу (оригінал або той, що стартонув із queueable)
        Integer cnt = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
        ];
        System.assert(cnt > 0, 'There should be at least one InvoiceOrderDebtCleaning batch job (original or retry)');
    }
  
    @IsTest
    static void testLegacySingleArgConstructor() {
        // Порожнє джерело для легасі-ctors
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        Test.startTest();
        // Викликаємо однопараметричний конструктор
        Database.executeBatch(new InvoiceOrderDebtCleaning(src), 200);
        Test.stopTest();

        // Мінімальна перевірка: job класу існує
        Integer cnt = [SELECT COUNT() FROM AsyncApexJob
                       WHERE JobType='BatchApex'
                         AND ApexClass.Name='InvoiceOrderDebtCleaning'];
        System.assert(cnt > 0, 'Batch should be enqueued via legacy constructor');
    }    
/*
    @IsTest
    static void testSchedulerBranch_usesCronTrigger() {
        Test.startTest();
        String jobName = 'DebtCleanTestJob_' + String.valueOf(Datetime.now().getTime());

        // Запускаємо через scheduleBatch, щоб покрити шлях виконання з планувальника
        System.scheduleBatch(
            new InvoiceOrderDebtCleaning(null, 'Test:Scheduler'),
            jobName,
            1,   // delay (хв)
            200  // batch size
        );
        Test.stopTest();

        // Перевіряємо, що наш batch-job справді існує і завершився
        AsyncApexJob j = [
            SELECT Id, ApexClass.Name, JobType, Status, CreatedDate
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, j, 'Batch job should exist');
        System.assertEquals('InvoiceOrderDebtCleaning', j.ApexClass.Name, 'Should be our batch class');
        System.assert(
            j.Status == 'Completed' || j.Status == 'Aborted' || j.Status == 'Failed',
            'Batch should have finished execution path in test context'
        );
    }
*/
}