@IsTest
public class AsyncExecutorTest {

    @IsTest
    static void testUpdateSmart_sync() {
        List<Account> accs = TestDataFactory.createAccounts(2);

        for (Account a : accs) {
            a.Type = 'Customer';
        }

        AsyncExecutorResult res =
            AsyncExecutor.updateSmart(
                accs,
                TestDataFactory.defaultAsyncConfig()
            );

        System.assertEquals(AsyncExecutionMode.SYNC, res.mode);
        System.assertEquals(2, res.recordCount);

        Account check =
            [SELECT Type FROM Account WHERE Id = :accs[0].Id];
        System.assertEquals('Customer', check.Type);
    }

    @IsTest
    static void testUpdateSmart_noop() {
        AsyncExecutorResult res =
            AsyncExecutor.updateSmart(
                new List<SObject>(),
                TestDataFactory.defaultAsyncConfig()
            );

        System.assertEquals(AsyncExecutionMode.NOOP, res.mode);
        System.assertEquals(0, res.recordCount);
    }

    @IsTest
    static void testDeleteSmart_dryRun() {
        List<Account> accs = TestDataFactory.createAccounts(2);

        AsyncExecutorResult res =
            AsyncExecutor.deleteSmart(
                accs,
                TestDataFactory.defaultAsyncConfig(),
                true
            );

        System.assertEquals(AsyncExecutionMode.DRY_RUN, res.mode);
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Account WHERE Id IN :accs]
        );
    }
}