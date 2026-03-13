@IsTest
private class WorkItemServiceTest {

    @IsTest
    static void testCreateWorkItem_Success() {
        // Створити тестові дані
        String errorKey = 'SYSTEM_CALLOUT';
        Id pharosLogId = createPharosLog().Id;
        Id assigneeId = UserInfo.getUserId();
        Decimal reactTimeHours = 4.0;

        Map<String, Object> errorDetails = new Map<String, Object>{
            'occurrenceCount' => 5,
            'frequencyPerWeek' => 7.5,
            'exceptionMessage' => 'Test exception',
            'exceptionType' => 'CalloutException'
        };

        DateTime beforeCreate = DateTime.now();

        Test.startTest();
        Id workItemId = WorkItemService.createWorkItem(
            errorKey,
            pharosLogId,
            assigneeId,
            reactTimeHours,
            errorDetails
        );
        Test.stopTest();

        DateTime afterCreate = DateTime.now();

        // Перевірити що Work Item створений
        System.assertNotEquals(null, workItemId, 'Work Item should be created');

        Notification_Work_Item__c workItem = [
            SELECT Id, Summary__c, Details__c, Work_Status__c, Notification_Type__c,
                   Reaction_Time_Hours__c, Correlation_Key__c, OwnerId,
                   Reminder_Count__c, Next_Reminder_At__c, CreatedDate
            FROM Notification_Work_Item__c
            WHERE Id = :workItemId
        ];

        System.assertEquals('New', workItem.Work_Status__c, 'Status should be New');
        System.assertEquals(errorKey, workItem.Notification_Type__c, 'Notification Type should match');
        System.assertEquals(reactTimeHours, workItem.Reaction_Time_Hours__c, 'React time should match');
        System.assertEquals(assigneeId, workItem.OwnerId, 'Owner should match');
        System.assert(workItem.Summary__c.contains(errorKey), 'Summary should contain errorKey');
        System.assert(workItem.Details__c.contains('5'), 'Details should contain occurrence count');

        // Перевірити Reminder fields
        System.assertEquals(0, workItem.Reminder_Count__c, 'Reminder count should be 0');
        System.assertNotEquals(null, workItem.Next_Reminder_At__c, 'Next reminder should be set');

        // Перевірити що Next_Reminder_At приблизно = CreatedDate + 4 години
        Long expectedTime = workItem.CreatedDate.getTime() + (4 * 60 * 60 * 1000);
        Long actualTime = workItem.Next_Reminder_At__c.getTime();
        Long timeDiff = Math.abs(expectedTime - actualTime);
        System.assert(timeDiff < 60000, 'Next reminder should be ~4 hours after creation (within 1 minute)');
    }

    @IsTest
    static void testCreateWorkItem_WithoutErrorDetails() {
        String errorKey = 'TEST_ERROR';
        Id pharosLogId = createPharosLog().Id;
        Id assigneeId = UserInfo.getUserId();

        Test.startTest();
        Id workItemId = WorkItemService.createWorkItem(
            errorKey,
            pharosLogId,
            assigneeId,
            2.0,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, workItemId, 'Work Item should be created without errorDetails');

        Notification_Work_Item__c workItem = [
            SELECT Id, Summary__c, Details__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItemId
        ];

        System.assert(workItem.Summary__c.contains(errorKey), 'Summary should contain errorKey');
        System.assert(workItem.Details__c.contains(errorKey), 'Details should contain errorKey');
    }

    @IsTest
    static void testCreateWorkItem_BlankErrorKey() {
        Id pharosLogId = createPharosLog().Id;
        Id assigneeId = UserInfo.getUserId();

        Test.startTest();
        try {
            WorkItemService.createWorkItem('', pharosLogId, assigneeId, 4.0, null);
            System.assert(false, 'Should throw exception for blank errorKey');
        } catch (WorkItemService.WorkItemException e) {
            System.assert(e.getMessage().contains('errorKey'), 'Exception should mention errorKey');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateWorkItem_CorrelationKey() {
        String errorKey = 'TEST_ERROR';
        Id pharosLogId = createPharosLog().Id;

        Test.startTest();
        Id workItemId = WorkItemService.createWorkItem(
            errorKey,
            pharosLogId,
            UserInfo.getUserId(),
            4.0,
            null
        );
        Test.stopTest();

        Notification_Work_Item__c workItem = [
            SELECT Correlation_Key__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItemId
        ];

        String expectedKey = errorKey + '_' + pharosLogId;
        System.assertEquals(expectedKey, workItem.Correlation_Key__c, 'Correlation key should match pattern');
    }

    // Helper метод
    private static pharos__Log__c createPharosLog() {
        pharos__Log__c log = new pharos__Log__c(
            pharos__Summary__c = 'Test error',
            pharos__Category__c = 'Apex',
            pharos__Type__c = 'Exception',
            pharos__Area__c = 'OpportunityData'
        );
        insert log;
        return log;
    }
}