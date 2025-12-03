@IsTest
private class RenamePARNamesSchedulerTest {
    @IsTest
    static void test_scheduler_runs() {
        Test.startTest();
        String cron = '0 0 * * * ?';
        System.schedule('Test PAR Rename Job', cron, new RenamePARNamesScheduler());
        Test.stopTest();
    }
}