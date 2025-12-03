@IsTest
private class CronJobUtilsTest {

    private class DummyScheduler implements Schedulable {
        public void execute(SchedulableContext sc) {}
    }

    @IsTest
    static void test_cron_job_utils() {

        Test.startTest();

        String cron = '0 0 0 1 1 ? 2099';

        System.schedule('UTIL_TestJob_One', cron, new DummyScheduler());
        System.schedule('UTIL_TestJob_Two', cron, new DummyScheduler());
        System.schedule('OTHER_TestJob',    cron, new DummyScheduler());

        Test.stopTest();

        // 1) listAllJobs()
        List<CronJobUtils.JobInfo> all = CronJobUtils.listAllJobs();
        System.assert(all.size() >= 3);

        // 2) listByNameLike()
        List<CronJobUtils.JobInfo> util = CronJobUtils.listByNameLike('UTIL_TestJob%');
        System.assertEquals(2, util.size());

        // 3) abortByExactName()
        Integer killedExact = CronJobUtils.abortByExactName('UTIL_TestJob_One');
        System.assertEquals(1, killedExact);

        // 4) abortByNameLike()
        Integer killedLike = CronJobUtils.abortByNameLike('UTIL_TestJob%');
        System.assertEquals(1, killedLike);

        // 5) abortByClassName() - повертає 0 (бо не підтримується в org)
        Integer killedClass = CronJobUtils.abortByClassName('CronJobUtilsTest.DummyScheduler');
        System.assertEquals(0, killedClass);
    }
}