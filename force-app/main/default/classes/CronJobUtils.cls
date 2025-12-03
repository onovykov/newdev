public with sharing class CronJobUtils {

    public class JobInfo {
        public Id id {get;set;}
        public String name {get;set;}
        public String state {get;set;}
        public Datetime nextFireTime {get;set;}
        public String cronExpression {get;set;}
    }

    public static List<JobInfo> listAllJobs() {
        List<CronTrigger> rows = [
            SELECT Id,
                   State,
                   NextFireTime,
                   CronExpression,
                   CronJobDetailId,
                   CronJobDetail.Name
            FROM CronTrigger
            ORDER BY CronJobDetail.Name
        ];
        return toJobInfo(rows);
    }

    public static List<JobInfo> listByNameLike(String nameLike) {
        if (String.isBlank(nameLike)) return listAllJobs();

        List<CronTrigger> rows = [
            SELECT Id,
                   State,
                   NextFireTime,
                   CronExpression,
                   CronJobDetailId,
                   CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :nameLike
            ORDER BY CronJobDetail.Name
        ];
        return toJobInfo(rows);
    }

    public static Integer abortByExactName(String jobName) {
        if (String.isBlank(jobName)) return 0;

        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        for (CronTrigger ct : jobs) System.abortJob(ct.Id);
        return jobs.size();
    }

    public static Integer abortByNameLike(String nameLike) {
        if (String.isBlank(nameLike)) return 0;

        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :nameLike
        ];
        for (CronTrigger ct : jobs) System.abortJob(ct.Id);
        return jobs.size();
    }

    // Немає SObject reference на ApexClass → функція недоступна
    public static Integer abortByClassName(String schedulableClassName) {
        // У нашій org немає можливості отримати className для Cron
        // Тому повертаємо 0
        return 0;
    }

    private static List<JobInfo> toJobInfo(List<CronTrigger> rows) {
        List<JobInfo> out = new List<JobInfo>();
        for (CronTrigger ct : rows) {
            JobInfo ji = new JobInfo();
            ji.id = ct.Id;
            ji.name = ct.CronJobDetail.Name;
            ji.state = ct.State;
            ji.nextFireTime = ct.NextFireTime;
            ji.cronExpression = ct.CronExpression;
            out.add(ji);
        }
        return out;
    }
}