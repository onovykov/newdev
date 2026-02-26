@IsTest
public class InsertQueueableTest {
    @IsTest
    static void coverQueueable() {
        List<Account> accs = TestDataFactory.createAccounts(1);
        Test.startTest();
        System.enqueueJob(new InsertQueueable(accs));
        Test.stopTest();
    }
}