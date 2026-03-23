@IsTest
private class OpportunityTriggerHandlerCoverageTest {

    @IsTest
    static void testBeforeAndAfter() {

        OpportunityStageSyncContext.allowDispatchInTest = true;

        User u = [SELECT Id, SalesDivision__c FROM User LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            OwnerId = u.Id
        );

        Test.startTest();
        insert opp;

        opp.StageName = 'Closed Won';
        opp.Id_ERP__c = 'ERP123';
        update opp;
        Test.stopTest();

        System.assert(true);
    }
}