@IsTest
public class AdminFacadeTest {

    @IsTest
    static void testUpdateByQuery_dryRun() {
        // Arrange
        TestDataFactory.createAccounts(3);

        // Act
        AsyncExecutorResult res =
            AdminFacade.updateByQuery(
                'Account',
                new List<String>{ 'Type' }, // Id буде додано автоматично
                'Name LIKE \'Test Account%\'',
                null,
                true
            );

        // Assert
        System.assertEquals(
            AsyncExecutionMode.DRY_RUN,
            res.mode,
            'Expected DRY_RUN mode'
        );
        System.assertEquals(
            3,
            res.recordCount,
            'Dry-run must return selected record count'
        );
    }

    @IsTest
    static void testUpdateByQuery_execute() {
        // Arrange
        TestDataFactory.createAccounts(2);

        // Act
        AsyncExecutorResult res =
            AdminFacade.updateByQuery(
                'Account',
                new List<String>{ 'Type' },
                'Name LIKE \'Test Account%\'',
                null,
                false
            );

        // Assert
        System.assertEquals(
            2,
            res.recordCount,
            'Expected 2 records to be selected'
        );
        System.assertNotEquals(
            AsyncExecutionMode.DRY_RUN,
            res.mode,
            'Execution mode must not be DRY_RUN'
        );
    }

    @IsTest
    static void testDeleteByQuery_execute() {
        // Arrange
        TestDataFactory.createAccounts(2);

        // Act
        AsyncExecutorResult res =
            AdminFacade.deleteByQuery(
                'Account',
                'Name LIKE \'Test Account%\'',
                null,
                false
            );

        // Assert
        System.assertEquals(
            2,
            res.recordCount,
            'Expected 2 records to be deleted'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Account],
            'All test accounts must be deleted'
        );
    }
}