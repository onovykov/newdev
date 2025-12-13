public with sharing class SyncUsersScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        SyncUsersService.runSync();
    }

    // ---------------------------------------------------------
    // Запускаємо розклад із CMDT SyncUserSettings__mdt
    // ---------------------------------------------------------
    public static void applyScheduleFromSettings() {

        SyncUserSettings__mdt st = loadSettings();
        if (st == null) {
            System.debug('SyncUsersScheduler: No CMDT SyncUserSettings__mdt found');
            return;
        }

        if (!st.IsEnabled__c) {
            clearExistingJob('SyncUsersSchedulerJob');
            System.debug('SyncUsersScheduler: Scheduler disabled via CMDT');
            return;
        }

        String cron = st.ScheduleCron__c;
        if (String.isBlank(cron)) {
            clearExistingJob('SyncUsersSchedulerJob');
            System.debug('SyncUsersScheduler: Empty CRON — job removed');
            return;
        }

        // 🚫 БІЛЬШЕ НЕ ВАЛІДУЄМО САМІ — хай це робить Salesforce
        try {
            clearExistingJob('SyncUsersSchedulerJob');
            System.schedule('SyncUsersSchedulerJob', cron, new SyncUsersScheduler());
            System.debug('SyncUsersScheduler: Job scheduled → ' + cron);
        } catch (Exception e) {
            System.debug('SyncUsersScheduler: Schedule error → ' + e.getMessage());
        }
    }

    // ---------------------------------------------------------
    // Завантаження CMDT
    // ---------------------------------------------------------
    private static SyncUserSettings__mdt loadSettings() {
        List<SyncUserSettings__mdt> listSt = [
            SELECT DeveloperName, IsEnabled__c, AllowNotifications__c, ScheduleCron__c
            FROM SyncUserSettings__mdt
            WHERE DeveloperName = 'OrgDefaults'
            LIMIT 1
        ];
        return listSt.isEmpty() ? null : listSt[0];
    }

    // ---------------------------------------------------------
    // Видаляємо існуючий job, щоб не плодити дублі
    // ---------------------------------------------------------
    private static void clearExistingJob(String jobName) {
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
              AND State != 'Deleted'
        ];
        if (!jobs.isEmpty()) {
            System.abortJob(jobs[0].Id);
        }
    }

    // ---------------------------------------------------------
    // Невеличкий debug-хелпер
    // ---------------------------------------------------------
    public static void debugMe() {
        System.debug('SyncUsersScheduler.debugMe: started');
        SyncUserSettings__mdt st = loadSettings();
        if (st == null) {
            System.debug('SyncUsersScheduler.debugMe: no CMDT record');
        } else {
            System.debug('SyncUsersScheduler.debugMe: CMDT cron = ' + st.ScheduleCron__c);
        }
    }
}