@IsTest
private class OrderItemHandlerTest {

    // Utility method to insert required mock records for testing
    @TestSetup
    static void setup() {
        User usr = TestDataFactory.createTestUser();
        Account acc = TestDataFactory.createTestAccount();
        Product2 prod2 = TestDataFactory.createTestProduct2('SampleProduct');
        insert prod2;
        Pricebook2 standardPriceBook = TestDataFactory.getStandardPricebook2();
        update standardPriceBook;
        ProductStandard__c prodStandard = TestDataFactory.createTestProductStandard();
        insert prodStandard;
        TubeWT__c tubeWT = TestDataFactory.createTestTubeWT(88.90, 23.25);
        insert tubeWT;
        TubeOD__c tubeOD = TestDataFactory.createTestTubeOD(12.14, 61.15);
        insert tubeOD;
        SteelGrade__c steelGrade = TestDataFactory.createTestSteelGrade();
        insert steelGrade;
        TubeLengthSize__c tubeLS = TestDataFactory.createTestTubeLengthSize('test', 14.22, 26.51);
        insert tubeLS;
        
    }
    
    @IsTest
    private static void testOCTG_Americas() {
        testFillName('OCTG', '00001', '840');
    }
    @IsTest
    private static void testOCTG_MENA() {
        testFillName('OCTG', '00002', '840');
    }
    @IsTest
    private static void testOCTG_Europe() {
        testFillName('OCTG', '00004', '840');
    }
    @IsTest
    private static void testOCTG_Else() {
        testFillName('OCTG', '00011', '840');
    }

    @IsTest
    private static void testLPGU_AmericasUSA() {
        testFillName('LP/GU', '00001', '840');
    }
    @IsTest
    private static void testLPGU_AmericasElse() {
        testFillName('LP/GU', '00001', '32');
    }
    @isTest
    private static void testLPGU_Else() {
        testFillName('LP/GU', '00001', '32');
    }

    @isTest
    private static void testElse() {
        testFillName('LP/GU', '00001', '32');
    }

    private static void testFillName(String product2FamilyName, String marketSegment, String countryNumCode) {
        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id, Profile.Name FROM User LIMIT 1];
        TubeWT__c tubeWT = [SELECT Id FROM TubeWT__c LIMIT 1];
        TubeOD__c tubeOD = [SELECT Id FROM TubeOD__c LIMIT 1];
        SteelGrade__c steelGrade = [SELECT Id FROM SteelGrade__c LIMIT 1];
        TubeLengthSize__c tubeLS = [SELECT Id FROM TubeLengthSize__c LIMIT 1];
        
        Country__c country = TestDataFactory.createTestCountry('Test', countryNumCode);
        insert country;
        Product2 prod2 = TestDataFactory.createTestProduct2(product2FamilyName);
        insert prod2;
        PricebookEntry priceBookEnt = TestDataFactory.createTestPricebookEntry(standardPriceBook.Id, prod2.Id);
        insert priceBookEnt;
        
        Order ord = TestDataFactory.createTestOrder(acc.Id, usr.Id, standardPriceBook.Id, country.Id, marketSegment);
        System.debug('%%%%' +ord );
        insert ord;
        OrderItem orderItem = TestDataFactory.createTestOrderItem(ord.id, prod2.id, tubeOD.id, tubeWT.id, steelGrade.id, tubeLS.id, priceBookEnt.id);
        insert orderItem;
        update orderItem;
    }

}