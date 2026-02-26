@IsTest
public class AsyncExecutorCoverageTest {

    private static AsyncConfig cfg() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;
        c.batchSize  = 200;
        return c;
    }

    private static List<SObject> sobjs(Integer n) {
        List<SObject> s = new List<SObject>();
        s.addAll(TestDataFactory.createAccounts(n));
        return s;
    }

    @IsTest
    static void coverNoopAndSync() {
        AsyncExecutorResult r1 =
            AsyncExecutor.updateSmart(new List<SObject>(), cfg());
        System.assertEquals(AsyncExecutionMode.NOOP, r1.mode);

        AsyncExecutorResult r2 =
            AsyncExecutor.updateSmart(sobjs(1), cfg());
        System.assertEquals(AsyncExecutionMode.SYNC, r2.mode);
    }

    @IsTest
    static void coverInsertDeleteDryRun() {
        AsyncExecutorResult i =
            AsyncExecutor.insertSmart(sobjs(1), cfg(), true);
        System.assertEquals(AsyncExecutionMode.DRY_RUN, i.mode);

        AsyncExecutorResult d =
            AsyncExecutor.deleteSmart(sobjs(1), cfg(), true);
        System.assertEquals(AsyncExecutionMode.DRY_RUN, d.mode);
    }

    @IsTest
    static void coverInvalidConfig() {
        AsyncConfig bad = new AsyncConfig();
        bad.syncLimit = 5;
        bad.queueLimit = 1;

        try {
            AsyncExecutor.updateSmart(sobjs(1), bad);
            System.assert(false);
        } catch (AsyncConfigException e) {
            System.assert(true);
        }
    }
}