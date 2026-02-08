@IsTest
private class OpportunityTriggerAuditTest {

    @IsTest
    static void bulkUpdate_doesNotFail() {

        // Arrange
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                BidGuarantees__c = 'Unknown'
            ));
        }
        insert opps;

        // Act
        for (Opportunity o : opps) {
            o.BidGuarantees__c = 'Yes';
        }

        Test.startTest();
        update opps;
        Test.stopTest();

        // Assert
        // Ми не перевіряємо PE / audit тут
        // Ціль — trigger + bulk-hook працюють без exception
        System.assert(true, 'Bulk update passed');
    }
}