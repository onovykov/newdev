@IsTest
public class AsyncExecutorMoreCoverageTest {

    private static AsyncConfig cfg() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit = 1;
        c.queueLimit = 1;
        c.batchSize = 200;
        return c;
    }

    private static List<SObject> data(Integer n) {
        List<SObject> s = new List<SObject>();
        s.addAll(TestDataFactory.createAccounts(n));
        return s;
    }

    @IsTest
    static void coverMoreBranches() {

        // updateSmart with config name
        Test.startTest();
        AsyncExecutor.updateSmart(
            data(1),
            'Default_Setting'
        );
        Test.stopTest();

        // updateSmart DRY-RUN
        AsyncExecutor.insertSmart(
            data(1),
            cfg(),
            true
        );

        // delete SYNC (no dry-run overload)
        AsyncExecutor.deleteSmart(
            data(1),
            cfg()
        );
    }
}