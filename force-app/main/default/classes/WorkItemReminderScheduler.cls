/**
 * Scheduler для WorkItemReminderService.
 * Запускається кожні 4 години для обробки нагадувань по Work Items.
 *
 * Для активації в org:
 * System.schedule('Work Item Reminder Job', '0 0 0/4 * * ?', new WorkItemReminderScheduler());
 */
public class WorkItemReminderScheduler implements Schedulable {

    /**
     * Execute method викликається Salesforce scheduler.
     */
    public void execute(SchedulableContext ctx) {
        System.debug('WorkItemReminderScheduler: Starting reminder processing');

        try {
            WorkItemReminderService.processReminders();
            System.debug('WorkItemReminderScheduler: Reminder processing completed successfully');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'WorkItemReminderScheduler: Error processing reminders: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Helper method для ручного запуску з Developer Console.
     * Usage: WorkItemReminderScheduler.scheduleJob();
     */
    public static String scheduleJob() {
        // Видалити існуючі job з такою назвою
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Work Item Reminder Job'
        ];

        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }

        // Запланувати новий job: кожні 4 години
        String cronExp = '0 0 0/4 * * ?';
        String jobId = System.schedule('Work Item Reminder Job', cronExp, new WorkItemReminderScheduler());

        System.debug('WorkItemReminderScheduler: Job scheduled with ID: ' + jobId);
        return jobId;
    }

    /**
     * Helper method для видалення job.
     * Usage: WorkItemReminderScheduler.unscheduleJob();
     */
    public static void unscheduleJob() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Work Item Reminder Job'
        ];

        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
            System.debug('WorkItemReminderScheduler: Aborted job with ID: ' + job.Id);
        }
    }
}