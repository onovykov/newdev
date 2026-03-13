/**
 * Сервіс для відправки нагадувань по Notification_Work_Item__c.
 * Логіка:
 * - Кожне нагадування: через ReactTime годин від попереднього
 * - 1-е нагадування: CreatedDate + ReactTime
 * - 2-е нагадування: Last_Reminder + ReactTime
 * - 3-є нагадування: Last_Reminder + ReactTime
 * - Авто-закриття: після Maximum_Reminders__c нагадувань
 */
public with sharing class WorkItemReminderService {

    // Максимум нагадувань за замовчуванням
    private static final Integer DEFAULT_MAX_REMINDERS = 3;

    /**
     * Обробляє всі Work Items, яким потрібно відправити нагадування або авто-закрити.і
     * Викликається з Scheduler.
     */
    public static void processReminders() {
        DateTime now = DateTime.now();

        // Знайти всі Work Items, де Next_Reminder_At <= NOW і статус не закритий
        List<Notification_Work_Item__c> workItems = [
            SELECT Id, Name, Summary__c, Details__c, OwnerId, CreatedDate,
                   Work_Status__c, Reminder_Count__c, Last_Reminder_At__c,
                   Next_Reminder_At__c, Reaction_Time_Hours__c, Maximum_Reminders__c,
                   Notification_Type__c
            FROM Notification_Work_Item__c
            WHERE Next_Reminder_At__c <= :now
                AND Work_Status__c NOT IN ('Completed', 'Closed – Not Actionable', 'Ignored')
            ORDER BY Next_Reminder_At__c ASC
            LIMIT 200
        ];

        if (workItems.isEmpty()) {
            System.debug('WorkItemReminderService: No work items to process');
            return;
        }

        System.debug('WorkItemReminderService: Processing ' + workItems.size() + ' work items');

        List<Notification_Work_Item__c> toUpdate = new List<Notification_Work_Item__c>();

        for (Notification_Work_Item__c workItem : workItems) {
            Integer reminderCount = (workItem.Reminder_Count__c == null) ? 0 : workItem.Reminder_Count__c.intValue();
            Decimal reactTimeHours = (workItem.Reaction_Time_Hours__c == null) ? 4 : workItem.Reaction_Time_Hours__c;
            Integer maxReminders = (workItem.Maximum_Reminders__c == null) ? DEFAULT_MAX_REMINDERS : workItem.Maximum_Reminders__c.intValue();

            // Перевірити чи потрібно авто-закрити (якщо досягли maxReminders)
            if (reminderCount >= maxReminders) {
                // Авто-закрити
                autoCloseWorkItem(workItem, maxReminders, toUpdate);
                continue;
            }

            // Відправити нагадування
            sendReminder(workItem, reminderCount, reactTimeHours, maxReminders, toUpdate);
        }

        // Оновити Work Items
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('WorkItemReminderService: Updated ' + toUpdate.size() + ' work items');
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR,
                    'WorkItemReminderService: Failed to update work items: ' + e.getMessage());
            }
        }
    }

    /**
     * Відправляє нагадування для Work Item.
     */
    private static void sendReminder(
        Notification_Work_Item__c workItem,
        Integer currentReminderCount,
        Decimal reactTimeHours,
        Integer maxReminders,
        List<Notification_Work_Item__c> toUpdate
    ) {
        Integer newReminderCount = currentReminderCount + 1;

        System.debug('WorkItemReminderService: Sending reminder #' + newReminderCount +
            ' for Work Item ' + workItem.Id);

        // Підготувати vars для notification
        Map<String, Object> vars = new Map<String, Object>{
            'workItemId' => workItem.Id,
            'workItemName' => workItem.Name,
            'summary' => workItem.Summary__c,
            'details' => workItem.Details__c,
            'reminderNumber' => newReminderCount,
            'maxReminders' => maxReminders,
            'reactTimeHours' => reactTimeHours,
            'createdDate' => workItem.CreatedDate.format('yyyy-MM-dd HH:mm:ss'),
            'notificationType' => workItem.Notification_Type__c
        };

        // Відправити notification на HELPDESK_ADMIN Contacts з WhatId = workItemId
        try {
            // Створити mock SObject з OwnerId для контексту
            Notification_Work_Item__c contextItem = new Notification_Work_Item__c(
                Id = workItem.Id,
                OwnerId = workItem.OwnerId
            );

            NotificationService.notify('WORK_ITEM_REMINDER', contextItem, vars);
            System.debug('WorkItemReminderService: Reminder sent successfully to HELPDESK_ADMIN');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'WorkItemReminderService: Failed to send reminder: ' + e.getMessage());
        }

        // Оновити Work Item
        DateTime now = DateTime.now();
        workItem.Reminder_Count__c = newReminderCount;
        workItem.Last_Reminder_At__c = now;

        // Наступне нагадування: через ReactTime годин
        workItem.Next_Reminder_At__c = calculateNextReminderTime(now, reactTimeHours);

        toUpdate.add(workItem);
    }

    /**
     * Авто-закриває Work Item після досягнення ліміту нагадувань.
     */
    private static void autoCloseWorkItem(
        Notification_Work_Item__c workItem,
        Integer maxReminders,
        List<Notification_Work_Item__c> toUpdate
    ) {
        System.debug('WorkItemReminderService: Auto-closing Work Item ' + workItem.Id);

        workItem.Work_Status__c = 'Ignored';
        workItem.Resolution_Comment__c = 'Auto-closed after ' + maxReminders +
            ' reminders without response. CreatedDate: ' + workItem.CreatedDate.format('yyyy-MM-dd HH:mm:ss') +
            ', ReactTimeHours: ' + workItem.Reaction_Time_Hours__c;
        workItem.Next_Reminder_At__c = null; // Більше не потрібні нагадування

        toUpdate.add(workItem);
    }

    /**
     * Розраховує час наступного нагадування: базовий час + ReactTime.
     * Кожне нагадування через ОДНАКОВИЙ інтервал (ReactTime годин).
     */
    private static DateTime calculateNextReminderTime(DateTime baseTime, Decimal reactTimeHours) {
        Long millisToAdd = (reactTimeHours * 60 * 60 * 1000).longValue();
        return DateTime.newInstance(baseTime.getTime() + millisToAdd);
    }

    /**
     * Розраховує час першого нагадування: CreatedDate + ReactTime.
     * Використовується при створенні Work Item.
     */
    public static DateTime calculateFirstReminderTime(DateTime createdDate, Decimal reactTimeHours) {
        return calculateNextReminderTime(createdDate, reactTimeHours);
    }

    /**
     * TEMPORARY FOR TESTING: Відправляє email на конкретні адреси використовуючи Email Template.
     * TODO: Видалити цей метод після налаштування Recipient Groups.
     */
    private static void sendTestReminderEmail(
        Notification_Work_Item__c workItem,
        Integer reminderNumber,
        Integer maxReminders
    ) {
        try {
            // Знайти Email Template по DeveloperName
            List<EmailTemplate> templates = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = 'Work_Item_Reminder_Template'
                LIMIT 1
            ];

            if (templates.isEmpty()) {
                System.debug('WorkItemReminderService: Email Template "Work_Item_Reminder_Template" not found, skipping test email');
                return;
            }

            // Створити email з template
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            // Конкретні адреси для тестування
            email.setToAddresses(new List<String>{
                'a.tsyhanova@polytech.software',
                'a.d.tsyganova@gmail.com'
            });

            // Використати Email Template
            email.setTemplateId(templates[0].Id);

            // WhatId для merge fields (Notification_Work_Item__c)
            email.setWhatId(workItem.Id);

            // Не зберігати як Activity
            email.setSaveAsActivity(false);

            // Відправити
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            System.debug('WorkItemReminderService: Test reminder email sent using template to test addresses');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'WorkItemReminderService: Failed to send test email with template: ' + e.getMessage());
        }
    }
}