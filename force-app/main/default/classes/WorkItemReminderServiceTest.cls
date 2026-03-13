@IsTest
private class WorkItemReminderServiceTest {

    @IsTest
    static void testProcessReminders_NoWorkItems() {
        // Немає Work Items для обробки
        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        System.assert(true, 'Should complete without errors when no work items');
    }

    @IsTest
    static void testProcessReminders_SendFirstReminder() {
        // Створити Work Item з Next_Reminder_At в минулому
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1); // Минуле
        workItem.Reminder_Count__c = 0;
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        // Перевірити що нагадування відправлено
        Notification_Work_Item__c updated = [
            SELECT Reminder_Count__c, Last_Reminder_At__c, Next_Reminder_At__c, Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(1, updated.Reminder_Count__c, 'Reminder count should be 1');
        System.assertNotEquals(null, updated.Last_Reminder_At__c, 'Last reminder should be set');
        System.assertNotEquals(null, updated.Next_Reminder_At__c, 'Next reminder should be scheduled');
        System.assertEquals('New', updated.Work_Status__c, 'Status should remain New');
    }

    @IsTest
    static void testProcessReminders_SendSecondReminder() {
        // Створити Work Item з 1 нагадуванням вже відправленим
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Reminder_Count__c = 1;
        workItem.Last_Reminder_At__c = DateTime.now().addHours(-8);
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1); // Час для 2-го нагадування
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        Notification_Work_Item__c updated = [
            SELECT Reminder_Count__c, Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(2, updated.Reminder_Count__c, 'Reminder count should be 2');
        System.assertEquals('New', updated.Work_Status__c, 'Status should remain New');
    }

    @IsTest
    static void testProcessReminders_SendThirdReminder() {
        // Створити Work Item з 2 нагадуваннями вже відправленими
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Reminder_Count__c = 2;
        workItem.Last_Reminder_At__c = DateTime.now().addHours(-12);
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1); // Час для 3-го нагадування
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        Notification_Work_Item__c updated = [
            SELECT Reminder_Count__c, Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(3, updated.Reminder_Count__c, 'Reminder count should be 3');
        System.assertEquals('New', updated.Work_Status__c, 'Status should remain New');
    }

    @IsTest
    static void testProcessReminders_AutoClose() {
        // Створити Work Item з 3 нагадуваннями і час авто-закриття настав
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Reminder_Count__c = 3;
        workItem.Last_Reminder_At__c = DateTime.now().addHours(-16);
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1); // Час авто-закриття
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        Notification_Work_Item__c updated = [
            SELECT Work_Status__c, Resolution_Comment__c, Next_Reminder_At__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals('Ignored', updated.Work_Status__c, 'Should be auto-closed as Ignored');
        System.assert(updated.Resolution_Comment__c.contains('Auto-closed'), 'Should have auto-close comment');
        System.assertEquals(null, updated.Next_Reminder_At__c, 'Next reminder should be null');
    }

    @IsTest
    static void testProcessReminders_CompletedWorkItem_NotProcessed() {
        // Створити Work Item зі статусом Completed
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Work_Status__c = 'Completed';
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        Notification_Work_Item__c updated = [
            SELECT Reminder_Count__c, Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(0, updated.Reminder_Count__c, 'No reminder should be sent for completed item');
        System.assertEquals('Completed', updated.Work_Status__c, 'Status should remain Completed');
    }

    @IsTest
    static void testCalculateFirstReminderTime() {
        DateTime createdDate = DateTime.now();
        Decimal reactTimeHours = 4.0;

        DateTime result = WorkItemReminderService.calculateFirstReminderTime(createdDate, reactTimeHours);

        // Перевірити що результат = createdDate + 4 години
        Long expectedTime = createdDate.getTime() + (4 * 60 * 60 * 1000);
        System.assertEquals(expectedTime, result.getTime(), 'First reminder should be 4 hours after creation');
    }

    @IsTest
    static void testProcessReminders_ConstantIntervalTiming() {
        // Тест перевіряє що кожне нагадування йде через ОДНАКОВИЙ інтервал (ReactTime)
        Decimal reactTimeHours = 4.0;
        Notification_Work_Item__c workItem = createWorkItem(reactTimeHours);

        DateTime createdDate = workItem.CreatedDate;

        // Перевірити початковий стан: Next_Reminder_At = CreatedDate + ReactTime
        workItem = [
            SELECT Next_Reminder_At__c, CreatedDate
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        Long expectedFirstReminder = createdDate.getTime() + (4 * 60 * 60 * 1000);
        Long timeDiff1 = Math.abs(expectedFirstReminder - workItem.Next_Reminder_At__c.getTime());
        System.assert(timeDiff1 < 60000, 'First reminder should be CreatedDate + 4h');

        // ========== Перше нагадування ==========
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1); // Час настав
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        workItem = [
            SELECT Reminder_Count__c, Last_Reminder_At__c, Next_Reminder_At__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(1, workItem.Reminder_Count__c, 'Should have 1 reminder sent');
        System.assertNotEquals(null, workItem.Last_Reminder_At__c, 'Last_Reminder_At should be set');

        // Перевірити що Next_Reminder_At = Last_Reminder_At + 4h (CONSTANT interval)
        Long expectedSecondReminder = workItem.Last_Reminder_At__c.getTime() + (4 * 60 * 60 * 1000);
        Long timeDiff2 = Math.abs(expectedSecondReminder - workItem.Next_Reminder_At__c.getTime());
        System.assert(timeDiff2 < 60000, 'Second reminder should be Last_Reminder + 4h (constant interval)');

        // ========== Друге нагадування ==========
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        WorkItemReminderService.processReminders();

        workItem = [
            SELECT Reminder_Count__c, Last_Reminder_At__c, Next_Reminder_At__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(2, workItem.Reminder_Count__c, 'Should have 2 reminders sent');

        // Перевірити що Next_Reminder_At = Last_Reminder_At + 4h (SAME interval as before)
        Long expectedThirdReminder = workItem.Last_Reminder_At__c.getTime() + (4 * 60 * 60 * 1000);
        Long timeDiff3 = Math.abs(expectedThirdReminder - workItem.Next_Reminder_At__c.getTime());
        System.assert(timeDiff3 < 60000, 'Third reminder should be Last_Reminder + 4h (same constant interval)');

        // ========== Третє нагадування ==========
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        WorkItemReminderService.processReminders();

        workItem = [
            SELECT Reminder_Count__c, Last_Reminder_At__c, Next_Reminder_At__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals(3, workItem.Reminder_Count__c, 'Should have 3 reminders sent');

        // Перевірити що Next_Reminder_At знову = Last_Reminder_At + 4h
        Long expectedFourthReminder = workItem.Last_Reminder_At__c.getTime() + (4 * 60 * 60 * 1000);
        Long timeDiff4 = Math.abs(expectedFourthReminder - workItem.Next_Reminder_At__c.getTime());
        System.assert(timeDiff4 < 60000, 'Fourth reminder would be Last_Reminder + 4h (constant interval)');

        // ========== Авто-закриття після 3 нагадувань ==========
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        WorkItemReminderService.processReminders();

        workItem = [
            SELECT Work_Status__c, Next_Reminder_At__c, Reminder_Count__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals('Ignored', workItem.Work_Status__c, 'Should be auto-closed after 3 reminders');
        System.assertEquals(null, workItem.Next_Reminder_At__c, 'Next_Reminder_At should be null after auto-close');
        System.assertEquals(3, workItem.Reminder_Count__c, 'Reminder count should stay at 3');
    }

    @IsTest
    static void testProcessReminders_CustomMaxReminders() {
        // Тест перевіряє що Maximum_Reminders__c field використовується для авто-закриття
        Notification_Work_Item__c workItem = createWorkItem(4.0);
        workItem.Maximum_Reminders__c = 5; // Custom max (не default 3)
        workItem.Reminder_Count__c = 4;
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        Test.startTest();
        WorkItemReminderService.processReminders();
        Test.stopTest();

        workItem = [
            SELECT Reminder_Count__c, Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        // Після 4-го нагадування, не має закриватись (max = 5)
        System.assertEquals(5, workItem.Reminder_Count__c, 'Should have 5 reminders sent');
        System.assertEquals('New', workItem.Work_Status__c, 'Should NOT auto-close before max');

        // Тепер авто-закриємо після 5-го
        workItem.Next_Reminder_At__c = DateTime.now().addHours(-1);
        update workItem;

        WorkItemReminderService.processReminders();

        workItem = [
            SELECT Work_Status__c
            FROM Notification_Work_Item__c
            WHERE Id = :workItem.Id
        ];

        System.assertEquals('Ignored', workItem.Work_Status__c, 'Should auto-close after reaching max=5');
    }

    @IsTest
    static void testScheduler() {
        // Тест Scheduler
        Test.startTest();
        String cronExp = '0 0 0 * * ?'; // Опівночі щодня
        String jobId = System.schedule('Test Work Item Reminder', cronExp, new WorkItemReminderScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should be scheduled');

        // Очистити
        System.abortJob(jobId);
    }

    // Helper метод
    private static Notification_Work_Item__c createWorkItem(Decimal reactTimeHours) {
        Notification_Work_Item__c workItem = new Notification_Work_Item__c(
            Summary__c = 'Test Work Item',
            Details__c = 'Test details',
            Work_Status__c = 'New',
            Notification_Type__c = 'SYSTEM_CALLOUT',
            Reaction_Time_Hours__c = reactTimeHours,
            Reminder_Count__c = 0,
            Next_Reminder_At__c = DateTime.now().addHours(4)
        );
        insert workItem;
        return workItem;
    }
}