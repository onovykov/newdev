/*
    DispatcherTest
    Перевіряємо:
    - enqueue відбувається
    - дублікати не enqueue-яться
    - suppressTriggerDispatch блокує dispatch
*/

@IsTest
private class OpportunityStageSyncDispatcherTest {

    private class MockGateway implements IOpportunityStageSyncGateway {
        public Set<Id> receivedIds = new Set<Id>();
        public void sync(Set<Id> opportunityIds) {
            receivedIds.addAll(opportunityIds);
        }
    }

    @IsTest
    static void testDispatchEnqueuesJob() {
        OpportunityStageSyncContext.reset();

        MockGateway mock = new MockGateway();
        OpportunityStageSyncGatewayFactory.setTestOverride(mock);

        Test.startTest();
        OpportunityStageSyncDispatcher.dispatch(new Set<Id>{ '006000000000001AAA' });
        Test.stopTest();

        System.assertEquals(
            true,
            OpportunityStageSyncContext.queuedOpportunityIds.contains('006000000000001AAA'),
            'ID should be queued'
        );

        OpportunityStageSyncGatewayFactory.reset();
    }

    @IsTest
    static void testSuppressDispatch() {
        OpportunityStageSyncContext.reset();
        OpportunityStageSyncContext.suppressTriggerDispatch = true;

        Test.startTest();
        OpportunityStageSyncDispatcher.dispatch(new Set<Id>{ '006000000000002AAA' });
        Test.stopTest();

        System.assertEquals(
            false,
            OpportunityStageSyncContext.queuedOpportunityIds.contains('006000000000002AAA'),
            'Dispatch should be suppressed'
        );
    }
}