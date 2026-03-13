@IsTest
public class DeleteOldERPInboundSchedulerTest {

    @IsTest
    static void testSchedulerExecution() {
        Test.startTest();

        // Schedule the job
        String cronExp = '0 0 0 * * ?'; // Run at midnight daily
        String jobId = System.schedule('DeleteOldERPInboundScheduler_Test',
                                       cronExp,
                                       new DeleteOldERPInboundScheduler());

        // Verify the job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE Id = :jobId];
        Assert.areEqual(cronExp, ct.CronExpression, 'Cron expression should match');
        Assert.areEqual(0, ct.TimesTriggered, 'Job should not have run yet');
        Assert.isNotNull(ct.NextFireTime, 'Next fire time should be set');

        Test.stopTest();

        // Verify the scheduler executed without errors
        Assert.isNotNull(jobId, 'Job should be scheduled successfully');
    }

    @IsTest
    static void testSchedulerDirectExecution() {
        Test.startTest();

        // Execute the scheduler directly
        DeleteOldERPInboundScheduler scheduler = new DeleteOldERPInboundScheduler();

        // This should execute without throwing exceptions
        try {
            scheduler.execute(null);
            Assert.isTrue(true, 'Scheduler executed successfully');
        } catch (Exception e) {
            Assert.fail('Scheduler should not throw exception: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testBatchJobCreation() {
        Test.startTest();

        // Execute the scheduler which should create a batch job
        DeleteOldERPInboundScheduler scheduler = new DeleteOldERPInboundScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Verify that the batch job was created and executed
        // Check AsyncApexJob for the batch execution
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType, ApexClass.Name
                                    FROM AsyncApexJob
                                    WHERE ApexClass.Name = 'DeleteRecordsBatch'
                                    AND JobType = 'BatchApex'
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];

        Assert.isFalse(jobs.isEmpty(), 'Batch job should be created');
        Assert.areEqual('DeleteRecordsBatch', jobs[0].ApexClass.Name, 'Should execute DeleteRecordsBatch');
    }
}