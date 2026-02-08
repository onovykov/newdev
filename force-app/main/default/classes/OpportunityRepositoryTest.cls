@IsTest
private class OpportunityRepositoryTest {

    private static Opportunity createOpp() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),

            RecordTypeId = getTenderRecordTypeId(),

            ID_ERP__c = 'ERP-12345',
            ITENumber__c = '25-000123',
            BidGuarantees__c = 'Yes'
        );
        insert opp;
        return opp;
    }

    private static Id getTenderRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND DeveloperName IN ('Tubes_Tender','Wheels_Tender')
            LIMIT 1
        ].Id;
    }

    @IsTest
    static void testFindByErpId() {

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // встановлюємо ERP-поля НА UPDATE
        opp.ID_ERP__c   = 'ERP-12345';
        opp.ITENumber__c = '25-000123';
        update opp;

        Test.startTest();
        Opportunity found =
            OpportunityRepository.findByErpId('ERP-12345');
        Test.stopTest();

        System.assertNotEquals(
            null,
            found,
            'Opportunity must be found by ERP ID after update'
        );
    }

    @IsTest
    static void testFindByIteNumber() {

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // ITE number ставиться ПІСЛЯ insert
        opp.ITENumber__c = '25-000123';
        update opp;

        Test.startTest();
        Opportunity found =
            OpportunityRepository.findByIteNumber('25-000123');
        Test.stopTest();

        System.assertNotEquals(
            null,
            found,
            'Opportunity must be found by ITE number after update'
        );
        System.assertEquals(
            opp.Id,
            found.Id,
            'Found opportunity must match inserted one'
        );
    }

    @IsTest
    static void testFindReturnsNullForUnknownKey() {
        Test.startTest();
        Opportunity found =
            OpportunityRepository.findByErpId('UNKNOWN_ERP_ID');
        Test.stopTest();

        System.assertEquals(
            null,
            found,
            'Repository must return null when record is not found'
        );
    }
}