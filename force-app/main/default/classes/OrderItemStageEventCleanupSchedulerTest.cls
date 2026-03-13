@IsTest
private class OrderItemStageEventCleanupSchedulerTest {
    @TestSetup
    static void setup() {

        // Processed → має бути видалений
        insert new OrderItemStageEvent__c(
            ERP_Key__c = '1-1',
            ERP_Opportunity_Id__c = '1',
            ERP_Item_Id__c = '1',
            Raw_Stage_Code__c = '_12',
            SF_Stage__c = 'Processing',
            Stage__c = 'Processed'
        );

        // Failed → має бути видалений
        insert new OrderItemStageEvent__c(
            ERP_Key__c = '2-2',
            ERP_Opportunity_Id__c = '2',
            ERP_Item_Id__c = '2',
            Raw_Stage_Code__c = '_12',
            SF_Stage__c = 'Processing',
            Stage__c = 'Failed'
        );

        // Pending → НЕ має бути видалений
        insert new OrderItemStageEvent__c(
            ERP_Key__c = '3-3',
            ERP_Opportunity_Id__c = '3',
            ERP_Item_Id__c = '3',
            Raw_Stage_Code__c = '_12',
            SF_Stage__c = 'Processing',
            Stage__c = 'Pending'
        );
    }

    @IsTest
    static void testSchedulerExecute() {

        Test.startTest();

        // Scheduler з тригером на виконання
        String cron = '0 0 1 * * ?';
        System.schedule('CleanupJobTest', cron, new OrderItemStageEventCleanupScheduler());

        Test.stopTest(); // <-- Тут Scheduler викликає Job

        // Pending залишився
        Integer pendingCount = [
            SELECT COUNT()
            FROM OrderItemStageEvent__c
            WHERE Stage__c = 'Pending'
        ];
        System.assertEquals(1, pendingCount, 'Pending must NOT be deleted');

        // Processed / Failed повинні бути видалені
        Integer removedCount = [
            SELECT COUNT()
            FROM OrderItemStageEvent__c
            WHERE Stage__c IN ('Processed', 'Failed')
        ];
        System.assertEquals(0, removedCount, 'Processed/Failed must be deleted');
        //System.assertEquals(1, removedCount, 'Processed/Failed must be deleted');
    }

    @IsTest
    static void testDirectJobExecution() {

        Test.startTest();
        // Правильний виклик static методу
        OrderItemStageEventCleanupJob.runCleanup();
        Test.stopTest();

        // Pending залишився
        Integer pendingCount = [
            SELECT COUNT()
            FROM OrderItemStageEvent__c
            WHERE Stage__c = 'Pending'
        ];
        System.assertEquals(1, pendingCount);

        // Processed / Failed видалені
        Integer removed = [
            SELECT COUNT()
            FROM OrderItemStageEvent__c
            WHERE Stage__c IN ('Processed', 'Failed')
        ];
        System.assertEquals(0, removed);
        //System.assertEquals(1, removed);
    }
}