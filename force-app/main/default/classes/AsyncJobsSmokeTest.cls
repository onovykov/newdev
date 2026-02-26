@IsTest
public class AsyncJobsSmokeTest {

    private static List<SObject> toSObjects(List<Account> accs) {
        List<SObject> res = new List<SObject>();
        res.addAll(accs);
        return res;
    }

    private static AsyncConfig cfg() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 10;
        c.batchSize  = 200;
        return c;
    }

    @IsTest
    static void testUpdate_viaExecutor_smoke() {

        List<SObject> recs = toSObjects(TestDataFactory.createAccounts(2));

        Test.startTest();
        AsyncExecutorResult res =
            AsyncExecutor.updateSmart(
                recs,
                cfg()
            );
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(2, res.recordCount);
        System.assertEquals(
            AsyncExecutionMode.SYNC,
            res.mode,
            'In test context executor runs SYNC'
        );
    }

    @IsTest
    static void testInsertDryRun_smoke() {
        List<SObject> recs = toSObjects(TestDataFactory.createAccounts(1));

        AsyncExecutorResult res =
            AsyncExecutor.insertSmart(
                recs,
                cfg(),
                true
            );

        System.assertEquals(AsyncExecutionMode.DRY_RUN, res.mode);
        System.assertEquals(1, res.recordCount);
    }

    @IsTest
    static void testDeleteDryRun_smoke() {
        List<SObject> recs = toSObjects(TestDataFactory.createAccounts(1));

        AsyncExecutorResult res =
            AsyncExecutor.deleteSmart(
                recs,
                cfg(),
                true
            );

        System.assertEquals(AsyncExecutionMode.DRY_RUN, res.mode);
        System.assertEquals(1, res.recordCount);
    }
}