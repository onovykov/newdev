@IsTest
public class DeleteBatchTest {
    @IsTest
    static void coverBatch() {
        List<Account> accs = TestDataFactory.createAccounts(1);
        Test.startTest();
        Database.executeBatch(new DeleteBatch(accs), 1);
        Test.stopTest();
    }
}