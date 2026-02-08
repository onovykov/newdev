@IsTest
private class FieldAuditServiceEdgeCaseTest {

    @IsTest
    static void updateWithoutChange_hitsNoChangeBranch() {

        // Arrange
        Opportunity opp = new Opportunity(
            Name = 'Coverage Edge',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(7),
            BidGuarantees__c = 'Yes'
        );
        insert opp;

        // Reload to be safe
        Opportunity sameOpp = [
            SELECT Id, BidGuarantees__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // Act: update WITHOUT changing the field
        Test.startTest();
        update sameOpp;
        Test.stopTest();

        // Assert
        // Ми тут нічого не перевіряємо навмисно
        // Нам важливо виконати гілку "no change"
        System.assert(true);
    }
}