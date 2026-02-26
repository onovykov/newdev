@IsTest
private class UpdateQueueableFinalCoverageTest {

    @IsTest
    static void coverWithData() {
        List<Account> accs = TestDataFactory.createAccounts(1);
        List<SObject> s = new List<SObject>();
        s.addAll(accs);

        Test.startTest();
        System.enqueueJob(new UpdateQueueable(s));
        Test.stopTest();
    }

    @IsTest
    static void coverEmpty() {
        Test.startTest();
        System.enqueueJob(
            new UpdateQueueable(new List<SObject>())
        );
        Test.stopTest();
    }
}