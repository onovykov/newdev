@IsTest
public class OrderItemStageEventScheduler_Tests {

    @IsTest
    static void testSchedulerSystemSchedule() {

        Test.startTest();
            String jobId = System.schedule(
                'Test_OrderItemStageEventScheduler',
                '0 0 0 1 1 ? 2099',
                new OrderItemStageEventScheduler()
            );
        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'System.schedule should return a non-null job ID'
        );
    }
}