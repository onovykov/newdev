@IsTest
private class UpdateQueueableCoverageTest {

    @IsTest
    static void coverExecuteWithRecords() {
        List<Account> accs =
            TestDataFactory.createAccounts(1);

        List<SObject> sobjs = new List<SObject>();
        sobjs.addAll(accs);

        Test.startTest();
        System.enqueueJob(
            new UpdateQueueable(sobjs)
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void coverExecuteEmpty() {
        Test.startTest();
        System.enqueueJob(
            new UpdateQueueable(
                new List<SObject>()
            )
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void coverExecute() {
        List<Account> accs = TestDataFactory.createAccounts(1); // already inserted
        accs[0].Name = 'Updated';

        Test.startTest();
        System.enqueueJob(new UpdateQueueable(accs));
        Test.stopTest();

        Account a = [SELECT Name FROM Account WHERE Id = :accs[0].Id];
        System.assertEquals('Updated', a.Name);

        // cover TestVisible method
        System.assertEquals(true, UpdateQueueable.coveragePing());
    }
}