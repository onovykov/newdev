@IsTest
public class AdminFacadeCoverageTest {

    @IsTest
    static void coverSelectToJsonAndCsv() {
        TestDataFactory.createAccounts(2);

        String json = AdminFacade.selectToJson(
            'Account',
            new List<String>{ 'Id', 'Name' },
            'Name LIKE \'Test Account%\'',
            10
        );
        System.assertNotEquals(null, json);

        String csv = AdminFacade.selectToCsv(
            'Account',
            new List<String>{ 'Id', 'Name' },
            'Name LIKE \'Test Account%\'',
            10
        );
        System.assertNotEquals(null, csv);
    }

    @IsTest
    static void coverUpdateByQuery_dryRun_and_execute() {
        TestDataFactory.createAccounts(2);

        // dry-run
        AsyncExecutorResult dry =
            AdminFacade.updateByQuery(
                'Account',
                new List<String>{ 'Id', 'Name' },
                'Name LIKE \'Test Account%\'',
                null,
                true
            );
        System.assertEquals(AsyncExecutionMode.DRY_RUN, dry.mode);
        System.assertEquals(2, dry.recordCount);

        // execute (в тесті буде SYNC)
        AsyncExecutorResult exec =
            AdminFacade.updateByQuery(
                'Account',
                new List<String>{ 'Id', 'Name' },
                'Name LIKE \'Test Account%\'',
                null,
                false
            );
        System.assertEquals(AsyncExecutionMode.SYNC, exec.mode);
    }

    @IsTest
    static void coverDeleteByQuery_dryRun() {
        TestDataFactory.createAccounts(2);

        AsyncExecutorResult res =
            AdminFacade.deleteByQuery(
                'Account',
                'Name LIKE \'Test Account%\'',
                null,
                true
            );

        System.assertEquals(AsyncExecutionMode.DRY_RUN, res.mode);
        System.assertEquals(2, res.recordCount);
    }

    @IsTest
    static void coverSelectToCsvFile() {
        TestDataFactory.createAccounts(2);

        Id cvId =
            AdminFacade.selectToCsvFile(
                'Account',
                new List<String>{ 'Id', 'Name' },
                'Name LIKE \'Test Account%\'',
                10
            );

        System.assertNotEquals(null, cvId);
    }

    @IsTest
    static void coverValidationErrors() {
        try {
            AdminFacade.updateByQuery(
                null,
                new List<String>{ 'Id' },
                null,
                null,
                true
            );
            System.assert(false, 'AdminLimitException expected');
        } catch (AdminLimitException e) {
            System.assert(true);
        }

        try {
            AdminFacade.updateByQuery(
                'Account',
                null,
                null,
                null,
                true
            );
            System.assert(false, 'AdminLimitException expected');
        } catch (AdminLimitException e) {
            System.assert(true);
        }

        try {
            AdminFacade.deleteByQuery(
                null,
                null,
                null,
                true
            );
            System.assert(false, 'AdminLimitException expected');
        } catch (AdminLimitException e) {
            System.assert(true);
        }
    }
}