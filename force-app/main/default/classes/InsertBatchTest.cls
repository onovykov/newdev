@IsTest
public class InsertBatchTest {
    @IsTest
    static void coverBatch() {
        List<Account> accs = TestDataFactory.createAccounts(1);
        Test.startTest();
        Database.executeBatch(new InsertBatch(accs), 1);
        Test.stopTest();
    }
}