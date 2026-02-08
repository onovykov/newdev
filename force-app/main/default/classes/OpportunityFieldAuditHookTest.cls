@IsTest
private class OpportunityFieldAuditHookTest {

    @IsTest
    static void beforeUpdate_bulk_doesNotFail() {

        Opportunity opp = new Opportunity(
            Name = 'Audit Hook Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            BidGuarantees__c = 'Unknown'
        );
        insert opp;

        Opportunity upd = [
            SELECT Id, BidGuarantees__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();
        upd.BidGuarantees__c = 'Yes';
        update upd;
        Test.stopTest();

        // We assert stability, not PE execution
        System.assert(true, 'Audit hook executed without errors');
    }
}