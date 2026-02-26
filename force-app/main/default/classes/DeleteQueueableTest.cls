@IsTest
public class DeleteQueueableTest {
    @IsTest
    static void coverQueueable() {
        List<Account> accs = TestDataFactory.createAccounts(1);
        Test.startTest();
        System.enqueueJob(new DeleteQueueable(accs));
        Test.stopTest();
    }
}