@IsTest
public class UpdateBatchCoverageTest {

    @IsTest
    static void coverBatchSingleExecute() {

        // ❗ createAccounts вже робить insert
        List<Account> accs = TestDataFactory.createAccounts(1);

        accs[0].Name = 'Updated';

        Test.startTest();
        Database.executeBatch(
            new UpdateBatch(accs),
            200
        );
        Test.stopTest();

        Account a = [SELECT Name FROM Account WHERE Id = :accs[0].Id];
        System.assertEquals('Updated', a.Name);
    }
}