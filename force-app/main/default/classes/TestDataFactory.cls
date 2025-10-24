public class TestDataFactory {

    public static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'tstDFU', Email='testDataFactoryUser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, BusinesDivision__c = 'Pipes',
            TimeZoneSidKey='America/Los_Angeles', UserName='testDataFactoryUser@testorg.com',SalesDivision__c='00004',EmployeeNumber = '0000000', ID_ERP__c = '0000000');
        insert testUser;
        return testUser;
    }
    public static Account createTestAccount() {
        Account testAccount = new Account(
            Name = 'Test Account',
            MarketSegment__c = '00002'
        );
        insert testAccount;
        return testAccount;
    }

    public static Contact createTestContact(Id userId) {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testDataFactoryUser@example.com',
            OwnerId = userId
        );
        insert testContact;
        return testContact;
    }

    

    public static InvoiceOrderDebt__c createTestInvoice(Id accountId) {
        InvoiceOrderDebt__c testInvoice = new InvoiceOrderDebt__c(
            Account__c = accountId,
            Name = 'Test Invoice'
        );
        insert testInvoice;
        return testInvoice;
    }


    public static Product2 createTestProduct2(String familyName) {
        Product2 prod2 = new Product2(Name = 'Test Product', Family = familyName);
        // insert prod2;
        return prod2;
    }

    // Method to create related custom object records like ProductStandard__c, SteelGrade__c, etc.
    public static ProductStandard__c createTestProductStandard() {
        ProductStandard__c testStandard = new ProductStandard__c(Name = 'Test Standard', IsSecondChoice__c = false);
        // insert testStandard;
        return testStandard;
    }

    public static Pricebook2 getStandardPricebook2() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        // update standardPricebook;
        return standardPricebook;
    }
    
    public static PricebookEntry createTestPricebookEntry(id standardPricebookId, id product2Id) {
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product2Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        // insert pricebookEntry;
        return pricebookEntry;
    }
    public static Country__c createTestCountry(String name, String numCode){
        Country__c country = new Country__c(
            Name = name,
            NumCode__c = numCode,
            A2Code__c = '12',
            A3Code__c = '12'
        );
        // insert country;
        return country;
    }
    public static Order createTestOrder(Id accountId, Id ownerId, id standardPricebookId, id countryId, String marketSegment) {
        Order testOrder = new Order(
            AccountId = accountId,
            Status = 'Draft',
            OwnerId = ownerId,
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebookId,
            Country__c = countryId,
            MarketSegment__c = marketSegment
        );
        // insert testOrder;
        return testOrder;
    }

    public static SteelGrade__c createTestSteelGrade() {
        SteelGrade__c testGrade = new SteelGrade__c(Name = 'Test Grade');
        // insert testGrade;
        return testGrade;
    }

    public static TubeOD__c createTestTubeOD(Decimal odInch, Decimal odMm) {
        TubeOD__c testOD = new TubeOD__c(OD_inch__c = odInch, OD_mm__c = odMm);
        // insert testOD;
        return testOD;
    }

    public static TubeWT__c createTestTubeWT(Decimal wtInch, Decimal wtMm) {
        TubeWT__c testWT = new TubeWT__c(WT_inch__c = wtInch, WT_mm__c = wtMm);
        // insert testWT;
        return testWT;
    }

    public static TubeLengthSize__c createTestTubeLengthSize(String name, Decimal maxLength, Decimal minLength) {
        TubeLengthSize__c testLengthSize = new TubeLengthSize__c(
            Name = name,
            MaxLength__c = maxLength,
            MinLength__c = minLength
        );
        // insert testLengthSize;
        return testLengthSize;
    }

    public static OrderItem createTestOrderItem(Id orderId, Id product2Id, id tubeODId, id TubeWTid, id SteelGradeId, id tubeLsId, id pricebookEntryId) {
        OrderItem testOrderItem = new OrderItem(
            OrderId = orderId,
            Product2Id = product2Id,
            Quantity = 1,
            UnitPrice = 100.00,
            TubeWT__c = TubeWTid,
            TubeOD__c = tubeODId,
            SteelGrade__c = SteelGradeId,
            TubeLengthSize__c = tubeLsId,
            Mark_1__c = '12.51',
            Weight_ppf__c = 12.34,
            Weight_kpm__c = 56.78,
            NPS__c = '1',
            SCH__c = '2',
            PricebookEntryId = pricebookEntryId
        );
                    // Apex code to create a new ProductionJournalRecord__c with all fields


        // insert testOrderItem;
        return testOrderItem;
    }
    // public static ProductionJournalRecord__c createTestPJR(Id orderItemId) {
    //     ProductionJournalRecord__c testProductionJournalRecord = new ProductionJournalRecord__c(
    //         OrderItem__c = orderItemId,
    //         ApprovedFact__c = true,
    //         WholeMonthFact__c = false,
    //         CurrencyIsoCode = 'USD',
    //         Type__c = 'SampleType',
    //         DispatchedQuantity__c = 150.00,
    //         DispatchedQuantityNetto__c = 145.50,
    //         Margin__c = 2000.00,
    //         Period__c = Date.today(),
    //         ProducedQuantity__c = 1000.000,
    //         ProducedForecast__c = 1200.0000,
    //         Revenue__c = 50000.00,
    //         ShippedQuantity__c = 800.00,
    //         ShippedQuantityNetto__c = 790.00
    //     );
    //     insert testProductionJournalRecord;
    //     return testProductionJournalRecord;
    // }

}