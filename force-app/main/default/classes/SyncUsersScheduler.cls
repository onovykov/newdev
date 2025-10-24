public class SyncUsersScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        SyncUsers.syncUsersToERP();
    }
    
    public static void scheduleJob() {
        // Schedule the job to run every day at 6:00 PM GMT+2
        String cron = '0 0 17 * * ?'; // 7:00 PM GMT+2 = 5:00 PM GMT
        SyncUsersScheduler job = new SyncUsersScheduler();
        System.schedule('Sync Users to ERP Job', cron, job);
    }
}