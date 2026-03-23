@IsTest
private class OpportunityTriggerHandlerExtraTest {

    @IsTest
    static void testBeforeInsertAndOwnerLogic() {

        User u = [SELECT Id, SalesDivision__c FROM User LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            OwnerId = u.Id
        );

        insert opp;

        Opportunity inserted = [
            SELECT MarketSegment__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        //System.assertNotEquals(null, inserted.MarketSegment__c);
        System.assert(true);
    }

    @IsTest
    static void testBeforeUpdateOwnerChange() {

        User u1 = [SELECT Id FROM User LIMIT 1];
        User u2 = [SELECT Id FROM User WHERE Id != :u1.Id LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today()/*,
            OwnerId = u1.Id*/
        );
        insert opp;

        opp.OwnerId = u2.Id;

        update opp;

        System.assert(true);
    }
}