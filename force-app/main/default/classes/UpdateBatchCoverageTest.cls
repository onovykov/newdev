@IsTest
public class UpdateBatchCoverageTest {

    @IsTest
    static void coverBatchSingleExecute() {
        List<Account> accs = TestDataFactory.createAccounts(1);

        Test.startTest();
        Database.executeBatch(
            new UpdateBatch(accs),
            200   // batchSize > records.size()
        );
        Test.stopTest();
    }
}