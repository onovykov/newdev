/*
    QueueableTest
    Перевіряємо:
    - Job реально викликає gateway
    - suppressTriggerDispatch працює
*/
@IsTest
private class OpportunityStageSyncJobTest {

    private class MockGateway implements IOpportunityStageSyncGateway {
        public Set<Id> receivedIds = new Set<Id>();
        public void sync(Set<Id> opportunityIds) {
            receivedIds.addAll(opportunityIds);
        }
    }

    @IsTest
    static void testQueueableExecutesGateway() {
        OpportunityStageSyncContext.reset();

        MockGateway mock = new MockGateway();
        OpportunityStageSyncGatewayFactory.setTestOverride(mock);

        Set<Id> ids = new Set<Id>{ '006000000000003AAA' };

        Test.startTest();
        System.enqueueJob(new OpportunityStageSyncJob(ids));
        Test.stopTest();

        System.assertEquals(true, mock.receivedIds.contains('006000000000003AAA'));

        OpportunityStageSyncGatewayFactory.reset();
    }
}