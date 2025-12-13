public with sharing class SyncUsersSettingsTriggerHandler {

    private static Boolean isRunning = false;

    public static void afterSave() {
        // Захист від рекурсії
        if (isRunning) return;
        isRunning = true;

        SyncUsersSettings__c st = SyncUsersSettings__c.getOrgDefaults();
        if (st == null) return;

        // Якщо CRON порожній — Scheduler буде видалено applyScheduleFromSettings()
        SyncUsersScheduler.applyScheduleFromSettings();

        isRunning = false;
    }
}