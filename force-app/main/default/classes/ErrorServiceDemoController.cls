/**
 * Signal-in -> fixed scenario -> ErrorService.handle(key, context, exception)
 *
 * No UI selections. Caller passes ONLY errorKey from the approved list.
 */
public with sharing class ErrorServiceDemoController {

    // Only supported classification keys (your CMDT list)
    private static final Set<String> ALLOWED_KEYS = new Set<String>{
            'AR_OVERDUE_7D_USERS',
            'ERR_INT_OPPDATA_ERPMSGHANDLER',
            'ERR_INT_PRICE_APPROVAL',
            'OPP_CLOSED_WON_USERS',
            'OPP_CROSS_CREATE_USERS',
            'OPP_CROSS_WON_USERS',
            'SYSTEM_CALLOUT'
    };

    /**
     * Public entry point for "simulate signal".
     * This method does not take any other params besides the key.
     */
    @AuraEnabled
    public static String simulate(String errorKey) {
        if (String.isBlank(errorKey) || !ALLOWED_KEYS.contains(errorKey)) {
            throw new IllegalArgumentException('Unsupported errorKey: ' + errorKey);
        }

        Scenario sc = getScenario(errorKey);

        // Build context (SObject or null)
        SObject ctx = buildContext(sc);

        // Build exception (fixed per scenario)
        Exception ex = buildException(sc);

        // Single call (exactly your desired pattern)
        ErrorService.handle(errorKey, ctx, ex);

        return errorKey + ' error simulated successfully';
    }

    /**
     * Видаляє всі pharos__Log__c записи для SYSTEM_CALLOUT.
     * Використовується для очищення перед тестуванням escalation.
     */
    @AuraEnabled
    public static String deleteAllSystemCalloutLogs() {
        List<pharos__Log__c> logs = [
            SELECT Id
            FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
        ];

        if (logs.isEmpty()) {
            return 'No SYSTEM_CALLOUT logs found';
        }

        Integer count = logs.size();
        delete logs;

        return 'Deleted ' + count + ' SYSTEM_CALLOUT pharos__Log__c records';
    }

    /**
     * Видаляє всі Notification_Work_Item__c записи (escalation Work Items).
     * Використовується для очищення перед тестуванням.
     */
    @AuraEnabled
    public static String deleteAllWorkItems() {
        List<Notification_Work_Item__c> workItems = [
            SELECT Id
            FROM Notification_Work_Item__c
            WHERE Notification_Type__c = 'SYSTEM_CALLOUT'
        ];

        if (workItems.isEmpty()) {
            return 'No Work Items found';
        }

        Integer count = workItems.size();
        delete workItems;

        return 'Deleted ' + count + ' Notification_Work_Item__c records';
    }

    /**
     * Видаляє всі Notification_Log__c записи для SYSTEM_CALLOUT та SYSTEM_CALLOUT_ESCALATION.
     * Використовується для повного очищення.
     */
    @AuraEnabled
    public static String deleteAllNotificationLogs() {
        List<Notification_Log__c> logs = [
            SELECT Id
            FROM Notification_Log__c
            WHERE EventKey__c IN ('SYSTEM_CALLOUT', 'SYSTEM_CALLOUT_ESCALATION', 'WORK_ITEM_REMINDER')
        ];

        if (logs.isEmpty()) {
            return 'No Notification Logs found';
        }

        Integer count = logs.size();
        delete logs;

        return 'Deleted ' + count + ' Notification_Log__c records';
    }

    /**
     * Очищує ВСЕ: pharos__Log__c, Work Items, Notification Logs.
     * Використовується для повного reset перед тестуванням.
     */
    @AuraEnabled
    public static String cleanupAll() {
        Integer totalDeleted = 0;
        List<String> results = new List<String>();

        // 1. Видалити Work Items (спочатку, бо можуть бути lookup з pharos logs)
        List<Notification_Work_Item__c> workItems = [
            SELECT Id FROM Notification_Work_Item__c
            WHERE Notification_Type__c = 'SYSTEM_CALLOUT'
        ];
        if (!workItems.isEmpty()) {
            delete workItems;
            totalDeleted += workItems.size();
            results.add(workItems.size() + ' Work Items');
        }

        // 2. Видалити pharos__Log__c
        List<pharos__Log__c> pharosLogs = [
            SELECT Id FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
        ];
        if (!pharosLogs.isEmpty()) {
            delete pharosLogs;
            totalDeleted += pharosLogs.size();
            results.add(pharosLogs.size() + ' Pharos Logs');
        }

        // 3. Видалити Notification_Log__c
        List<Notification_Log__c> notifLogs = [
            SELECT Id FROM Notification_Log__c
            WHERE EventKey__c IN ('SYSTEM_CALLOUT', 'SYSTEM_CALLOUT_ESCALATION', 'WORK_ITEM_REMINDER')
        ];
        if (!notifLogs.isEmpty()) {
            delete notifLogs;
            totalDeleted += notifLogs.size();
            results.add(notifLogs.size() + ' Notification Logs');
        }

        if (totalDeleted == 0) {
            return 'Nothing to delete - all clean';
        }

        return 'CLEANUP COMPLETE: Deleted ' + String.join(results, ', ');
    }

    /**
     * Повертає статистику для SYSTEM_CALLOUT.
     */
    @AuraEnabled
    public static Map<String, Object> getStatistics() {
        Map<String, Object> stats = new Map<String, Object>();

        // Pharos Logs
        Integer pharosCount = [
            SELECT COUNT() FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
        ];
        stats.put('pharosLogCount', pharosCount);

        // Work Items
        Integer workItemCount = [
            SELECT COUNT() FROM Notification_Work_Item__c
            WHERE Notification_Type__c = 'SYSTEM_CALLOUT'
        ];
        stats.put('workItemCount', workItemCount);

        // Notification Logs - SYSTEM_CALLOUT
        Integer notifCalloutCount = [
            SELECT COUNT() FROM Notification_Log__c
            WHERE EventKey__c = 'SYSTEM_CALLOUT'
        ];
        stats.put('notificationCalloutCount', notifCalloutCount);

        // Notification Logs - ESCALATION
        Integer notifEscalationCount = [
            SELECT COUNT() FROM Notification_Log__c
            WHERE EventKey__c = 'SYSTEM_CALLOUT_ESCALATION'
        ];
        stats.put('notificationEscalationCount', notifEscalationCount);

        // Notification Logs - REMINDER
        Integer notifReminderCount = [
            SELECT COUNT() FROM Notification_Log__c
            WHERE EventKey__c = 'WORK_ITEM_REMINDER'
        ];
        stats.put('notificationReminderCount', notifReminderCount);

        // Перевірити чи є recurring (>= 3 за 7 днів)
        DateTime lookbackStart = DateTime.now().addDays(-7);
        Integer recentCount = [
            SELECT COUNT() FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
                AND CreatedDate >= :lookbackStart
        ];
        stats.put('recentCount', recentCount);
        stats.put('isRecurring', recentCount >= 3);

        return stats;
    }

    /**
     * Симулює звичайний SYSTEM_CALLOUT (БЕЗ ескалації).
     * Автоматично видаляє ВСІ старі pharos__Log__c перед запуском.
     * Результат: відправляється тільки звичайне повідомлення (Integration Primary Admin)
     */
    @AuraEnabled
    public static String simulateCalloutOnly() {
        // 1. Завжди видаляти всі pharos__Log__c (щоб не було ескалації)
        List<pharos__Log__c> oldLogs = [
            SELECT Id FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
        ];
        Integer deletedCount = 0;
        if (!oldLogs.isEmpty()) {
            delete oldLogs;
            deletedCount = oldLogs.size();
        }

        // 2. Створити 1 новий SYSTEM_CALLOUT
        simulate('SYSTEM_CALLOUT');

        return 'CALLOUT ONLY: Deleted ' + deletedCount + ' old pharos logs, created 1 new';
    }

    /**
     * Симулює SYSTEM_CALLOUT з ескалацією.
     * Автоматично видаляє Notification_Log__c з ESCALATION (щоб уникнути throttling 48h).
     * Приводить до стану: рівно 2 pharos__Log__c, потім створює 3-й → спрацює ОДНА ескалація.
     * Результат: відправляється звичайне повідомлення + ескалація (Helpdesk Admin + Work Item)
     */
    @AuraEnabled
    public static String simulateEscalation() {
        // 1. Видалити Notification_Log__c з ESCALATION (щоб уникнути throttling)
        List<Notification_Log__c> escalationLogs = [
            SELECT Id FROM Notification_Log__c
            WHERE EventKey__c = 'SYSTEM_CALLOUT_ESCALATION'
        ];
        Integer deletedEscalationLogs = 0;
        if (!escalationLogs.isEmpty()) {
            delete escalationLogs;
            deletedEscalationLogs = escalationLogs.size();
        }

        // 2. Отримати всі pharos__Log__c (сортувати за CreatedDate DESC - найновіші спочатку)
        List<pharos__Log__c> allLogs = [
            SELECT Id, CreatedDate
            FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
            ORDER BY CreatedDate DESC
        ];

        Integer currentCount = allLogs.size();
        String action = '';

        // 3. Привести до стану: рівно 2 pharos__Log__c (бо 3-й тригерить ескалацію)
        if (currentCount > 2) {
            // Видалити зайві (залишити тільки 2 найновіших)
            List<pharos__Log__c> toDelete = new List<pharos__Log__c>();
            for (Integer i = 2; i < allLogs.size(); i++) {
                toDelete.add(allLogs[i]);
            }
            delete toDelete;
            action = 'Deleted ' + toDelete.size() + ' old pharos logs (kept 2 newest)';
        } else if (currentCount < 2) {
            // Створити недостатню кількість до 2
            Integer toCreate = 2 - currentCount;
            for (Integer i = 0; i < toCreate; i++) {
                simulate('SYSTEM_CALLOUT');
            }
            action = 'Created ' + toCreate + ' pharos logs (to reach 2)';
        } else {
            action = 'Already have 2 pharos logs';
        }

        // 4. Тепер у нас рівно 2 pharos__Log__c. Створити 3-й → спрацює ОДНА ескалація (>= 3)
        simulate('SYSTEM_CALLOUT');

        return 'ESCALATION: Deleted ' + deletedEscalationLogs + ' escalation logs (throttling). ' + action + '. Created 3rd pharos log → escalation triggered (>= 3)';
    }

    /**
     * Викликає наступне нагадування для Work Item.
     * Логіка:
     * - Знаходить перший Work Item зі статусом 'New'
     * - Встановлює Next_Reminder_At__c в минуле
     * - Викликає WorkItemReminderService.processReminders()
     * Результат: відправляється нагадування на Helpdesk Admin
     */
    @AuraEnabled
    public static String triggerNextReminder() {
        // Знайти перший Work Item зі статусом 'New'
        List<Notification_Work_Item__c> workItems = [
            SELECT Id, Name, Work_Status__c, Reminder_Count__c
            FROM Notification_Work_Item__c
            WHERE Notification_Type__c = 'SYSTEM_CALLOUT'
                AND Work_Status__c = 'New'
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        if (workItems.isEmpty()) {
            return 'No Work Items with status "New" found';
        }

        Notification_Work_Item__c wi = workItems[0];
        Integer currentReminders = (wi.Reminder_Count__c == null) ? 0 : wi.Reminder_Count__c.intValue();

        // Встановити час нагадування в минуле
        wi.Next_Reminder_At__c = DateTime.now().addMinutes(-1);
        update wi;

        // Викликати обробку нагадувань
        try {
            WorkItemReminderService.processReminders();
            return 'REMINDER: Triggered reminder #' + (currentReminders + 1) + ' for Work Item ' + wi.Name;
        } catch (Exception e) {
            return 'REMINDER FAILED: ' + e.getMessage();
        }
    }

    /**
     * Повертає список Notification_Log__c для відображення в LWC.
     * Включає Id для можливості переходу на рекорд.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getNotificationLogs() {
        List<Notification_Log__c> logs = [
            SELECT Id, Name, EventKey__c, Status__c, Channel__c, CreatedDate
            FROM Notification_Log__c
            WHERE EventKey__c IN ('SYSTEM_CALLOUT', 'SYSTEM_CALLOUT_ESCALATION', 'WORK_ITEM_REMINDER')
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Notification_Log__c log : logs) {
            Map<String, Object> item = new Map<String, Object>();
            item.put('Id', log.Id);
            item.put('Name', log.Name);
            item.put('EventKey', log.EventKey__c);
            item.put('Status', log.Status__c);
            item.put('Channel', log.Channel__c);
            item.put('CreatedDate', log.CreatedDate);
            result.add(item);
        }
        return result;
    }

    /**
     * Повертає список pharos__Log__c для відображення в LWC.
     * Включає Id для можливості переходу на рекорд.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getPharosLogs() {
        List<pharos__Log__c> logs = [
            SELECT Id, Name, Error_Classification_ErrorKey__c, CreatedDate
            FROM pharos__Log__c
            WHERE Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT'
                AND Log_Source__c = 'ErrorService'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (pharos__Log__c log : logs) {
            Map<String, Object> item = new Map<String, Object>();
            item.put('Id', log.Id);
            item.put('Name', log.Name);
            item.put('ErrorKey', log.Error_Classification_ErrorKey__c);
            item.put('CreatedDate', log.CreatedDate);
            result.add(item);
        }
        return result;
    }

    /**
     * Повертає список Notification_Work_Item__c для відображення в LWC.
     * Включає Id для можливості переходу на рекорд.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getWorkItems() {
        List<Notification_Work_Item__c> items = [
            SELECT Id, Name, Summary__c, Work_Status__c, Reminder_Count__c, CreatedDate
            FROM Notification_Work_Item__c
            WHERE Notification_Type__c = 'SYSTEM_CALLOUT'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Notification_Work_Item__c item : items) {
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('Id', item.Id);
            obj.put('Name', item.Name);
            obj.put('Summary', item.Summary__c);
            obj.put('Status', item.Work_Status__c);
            obj.put('ReminderCount', item.Reminder_Count__c);
            obj.put('CreatedDate', item.CreatedDate);
            result.add(obj);
        }
        return result;
    }

    // ---------------- Internals ----------------

    private class Scenario {
        String key;
        String contextType;   // 'Opportunity' | 'Account' | 'PAR' | 'None'
        String exceptionType; // 'CalloutException' | 'DmlException' | 'QueryException' | 'Generic'
        String message;
        Scenario(String k, String ctx, String ex, String msg) {
            key = k; contextType = ctx; exceptionType = ex; message = msg;
        }
    }

    /**
     * Map: key -> fixed behavior (exception + context).
     * Keep everything deterministic here.
     */
    private static Scenario getScenario(String errorKey) {
        switch on errorKey {
            when 'SYSTEM_CALLOUT' {
                return new Scenario(
                        errorKey,
                        'Opportunity',
                        'CalloutException',
                        'Test CRITICAL error - ERP sync failed'
                );
            }
            when 'ERR_INT_OPPDATA_ERPMSGHANDLER' {
                return new Scenario(
                        errorKey,
                        'Opportunity',
                        'DmlException',
                        'Test HIGH error - ERP Opportunity upsert failed'
                );
            }
            when 'ERR_INT_PRICE_APPROVAL' {
                return new Scenario(
                        errorKey,
                        'PAR',
                        'QueryException',
                        'Test HIGH error - Price approval data invalid'
                );
            }
            when 'OPP_CLOSED_WON_USERS' {
                return new Scenario(
                        errorKey,
                        'Opportunity',
                        'Generic',
                        'Test CRITICAL - Closed Won workflow/job failure'
                );
            }
            when 'OPP_CROSS_CREATE_USERS' {
                return new Scenario(
                        errorKey,
                        'Opportunity',
                        'Generic',
                        'Test LOW - Cross create workflow/job issue'
                );
            }
            when 'OPP_CROSS_WON_USERS' {
                return new Scenario(
                        errorKey,
                        'Opportunity',
                        'Generic',
                        'Test LOW - Cross won workflow/job issue'
                );
            }
            when 'AR_OVERDUE_7D_USERS' {
                return new Scenario(
                        errorKey,
                        'Account',
                        'Generic',
                        'Test MEDIUM - AR overdue 7D users data mismatch'
                );
            }
            when else {
                // unreachable due to ALLOWED_KEYS check
                return new Scenario(errorKey, 'None', 'Generic', 'Test error');
            }
        }
    }

    /**
     * Context builder. Uses "latest record" approach so it works in any org without hardcoded IDs.
     * If you prefer using a specific ID, you can replace queries with a direct SELECT by Id.
     */
    private static SObject buildContext(Scenario sc) {
        if (sc == null || String.isBlank(sc.contextType) || sc.contextType == 'None') {
            return null;
        }

        if (sc.contextType == 'Opportunity') {
            List<Opportunity> opps = [
                    SELECT Id, OwnerId, AccountId, StageName
                    FROM Opportunity
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
            ];
            return opps.isEmpty() ? null : opps[0];
        }

        if (sc.contextType == 'Account') {
            List<Account> accs = [
                    SELECT Id, OwnerId, Name
                    FROM Account
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
            ];
            return accs.isEmpty() ? null : accs[0];
        }

        if (sc.contextType == 'PAR') {
            /**
             * Replace with your real "Price Approval Request" object if it exists.
             * Example:
             * List<Price_Approval_Request__c> pars = [
             *   SELECT Id, OwnerId, Name
             *   FROM Price_Approval_Request__c
             *   ORDER BY LastModifiedDate DESC
             *   LIMIT 1
             * ];
             * return pars.isEmpty() ? null : pars[0];
             */
            return null;
        }

        return null;
    }

    /**
     * Exception builder. The goal is to create a specific exception class instance.
     */
    private static Exception buildException(Scenario sc) {
        String msg = (sc != null && !String.isBlank(sc.message)) ? sc.message : 'Simulated error';

        switch on sc.exceptionType {
            when 'DmlException'     { return new DmlException(msg); }
            when 'QueryException'   { return new QueryException(msg); }
            when 'CalloutException' { return new CalloutException(msg); }
            when else               { return new SimulatedException(msg); }
        }
    }

    public class SimulatedException extends Exception {}
}