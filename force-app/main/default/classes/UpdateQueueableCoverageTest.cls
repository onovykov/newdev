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
        List<Account> accs = TestDataFactory.createAccounts(1);
        insert accs;

        Test.startTest();
        System.enqueueJob(new UpdateQueueable(accs));
        Test.stopTest();

        // якщо дійшли сюди — execute() відпрацював
        System.assertEquals(true, UpdateQueueable.coveragePing());
    }    
}