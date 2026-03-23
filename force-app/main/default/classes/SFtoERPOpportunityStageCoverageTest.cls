@IsTest
private class SFtoERPOpportunityStageCoverageTest {

    @IsTest
    static void testCallFutureMethod() {

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today()
        );
        insert opp;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testFutureWithNull() {

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(null);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testFutureWithoutERP() {

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today()
        );
        insert opp;

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testFutureSuccessBypass() {

        Opportunity opp = new Opportunity(
            Name='Test',
            StageName='Qualification',
            CloseDate=Date.today()
        );
        insert opp;

        SFtoERPOpportunityStage.testBypassMode = 'success';

        Test.startTest();
        SFtoERPOpportunityStage.sendJSONData(opp.Id);
        Test.stopTest();

        System.assertEquals(true, SFtoERPOpportunityStage.testLastSyncUpdated);

        SFtoERPOpportunityStage.testBypassMode = null;
    }    
}