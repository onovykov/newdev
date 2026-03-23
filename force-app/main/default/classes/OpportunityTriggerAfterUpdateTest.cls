/*
    Тест оновленого afterUpdate()
    Тут:
    - не робиvj callout
    - перевіриvj, що dispatch відбувся
    - підміняємо gateway mock-ом і дивимось, чи ID дійшов до gateway через Queueable
*/
@IsTest
private class OpportunityTriggerAfterUpdateTest {

    private class MockGateway implements IOpportunityStageSyncGateway {
        public Set<Id> receivedIds = new Set<Id>();
        public void sync(Set<Id> opportunityIds) {
            receivedIds.addAll(opportunityIds);
        }
    }

    @IsTest
    static void testAfterUpdateTriggersDispatch() {

        OpportunityStageSyncContext.reset();

        OpportunityStageSyncContext.allowDispatchInTest = true;

        MockGateway mock = new MockGateway();
        OpportunityStageSyncGatewayFactory.setTestOverride(mock);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today()
        );
        insert opp;

        opp.StageName = 'Closed Won';
        opp.Id_ERP__c = 'ERP123';

        Test.startTest();
        update opp;
        Test.stopTest();

        System.assertEquals(true, mock.receivedIds.contains(opp.Id));

        OpportunityStageSyncGatewayFactory.reset();
    }
}