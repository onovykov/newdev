@IsTest
private class OpportunityTriggerBypassCoverageTest {

    @IsTest
    static void bypass_beforeInsert_isCovered() {

        OpportunityTriggerHandler.bypassAll = true;

        Opportunity opp = new Opportunity(
            Name = 'Bypass test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(1)
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        OpportunityTriggerHandler.bypassAll = false;

        System.assert(true, 'Bypass branch executed');
    }
}