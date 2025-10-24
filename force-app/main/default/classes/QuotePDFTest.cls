@isTest
private class QuotePDFTest extends BaseTest{
    
    @isTest static void testGetDynamicFormatString() {
        // Implement test code
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        String testString = '123456789.789';
        t.start();
        String resultString = quoteController.getDynamicFormatString(testString);
        t.stop();

        System.assertEquals(' 123 456 789.789', resultString);

    }
    
    @isTest static void testFormatedDecimal() {
        // Implement test code
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        Decimal testDecimal = 123456789.789123456;
        t.start();
        String resultString = quoteController.formatedDecimalToOneSign(testDecimal);
        t.stop();

        System.assertEquals('123456789.8', resultString);
    }

    @isTest static void testGetAccountAddress() {
        // Implement test code
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        String resultString = quoteController.getAccountAddress();
        t.stop();

        String expectedAddress = 'Test Street, Test City, Test Code, Ukraine';
        System.assertEquals(expectedAddress, resultString);
    }

    @isTest static void testGetNumPdfs() {
        // Implement test code
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        Integer result = quoteController.getNumPdfs();
        t.stop();

        System.assertEquals(1, result);
    }

    @isTest static void testFormatAllNumberFields() {
        Map<String, Object> mapTest = new Map<String, Object>();
        mapTest.put('test', 111110.22);
        mapTest.put('InquiryUnitPrice__c', 11110.22);
        mapTest.put('InquiryQuantity__c', 1111110.22);

        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        Map<String, String> result = quoteController.formatAllNumberFields(mapTest);
        t.stop();

        Map<String, String> mapExpected = new Map<String, String>();
        mapExpected.put('test', ' 111 110.2');
        mapExpected.put('InquiryUnitPrice__c', '11 110.22');
        mapExpected.put('InquiryQuantity__c', '1 111 110.2');
        System.assertEquals(mapExpected, result);
    }
    
    @isTest static void testGetApinameToLabelMap() {

        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        Map<String, String> result = quoteController.getApinameToLabelMap();
        t.stop();

        System.assertEquals('t', result.get('34'));
    }
    
    @isTest static void testOLIMaps() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        quoteController.groupOLI();
        t.stop();

        System.assertEquals(1, quoteController.mapOLI.get('Tubenullnullnull').size());
        System.assertEquals(2, quoteController.mapOLI.get('Wheelnullnullnull').size());
        System.assertEquals(2, quoteController.mapGroupsToMapAggregates.size());
        System.assertEquals('10.0', quoteController.mapGroupsToMapAggregates[1].get('q'));
        System.assertEquals('1 000.0', quoteController.mapGroupsToMapAggregates[1].get('totalPrice'));
        System.assertEquals(' 200.00', quoteController.mapGroupsToMapAggregates[1].get('unitPrice'));
        //System.assertEquals('0.000', quoteController.mapGroupsToMapAggregates[1].get('inqUnitPrice'));
       // System.assertEquals('0.000', quoteController.mapGroupsToMapAggregates[1].get('inqQ'));
    }

	@isTest static void testGetShowLB_FTForTables() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        List<Boolean> result = quoteController.getShowLB_FTForTables();
        t.stop();
		        
		System.assertEquals(2, result.size());
		System.assertEquals(true, result[0]);
        System.assertEquals(false, result[1]);        
    }

	@isTest static void testGetShowWTForTables() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);

        t.start();
        List<Boolean> result = quoteController.getShowWTForTables();
        t.stop();
		        
		System.assertEquals(2, result.size());
		System.assertEquals(false, result[0]);
        System.assertEquals(true, result[1]);        
    }

    @isTest static void testOLISums() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        
        t.start();
        QuotePDF quoteController = new QuotePDF(stdContr);
        t.stop();

       // System.assertEquals('0.000', quoteController.quantitySumAsString);
        //System.assertEquals('15.000', quoteController.quantityMTSumAsString);
        //System.assertEquals('1 500.000', quoteController.totalPriceSumAsString);
    }

    @isTest static void testGetManufacturerOriginString() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        
        t.start();
        QuotePDF quoteController = new QuotePDF(stdContr);
        t.stop();

        System.assertEquals(true, quoteController.manufacturerAndOrigin.contains('Test Name 1'));
		System.assertEquals(true, quoteController.manufacturerAndOrigin.contains('Test Name 2'));
    }

    @isTest static void testGetGroupKeys() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        List<String> result = quoteController.getGroupKeys();
        t.stop();

        List<String> expectedList = new List<String>();
        expectedList.add('Tubenullnullnull');
        expectedList.add('Wheelnullnullnull');
        System.assertEquals(expectedList, result);
    }

    @isTest static void testGetListOpps() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        List<List<QuoteLineItem>> result = quoteController.getListOpps();
        t.stop();

        System.assertEquals(2, result.size());
        System.assertEquals(1, result[0].size());
        System.assertEquals(2, result[1].size());
    }

    @isTest static void testGetBankDetails() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        Bank_Details__mdt bd = [SELECT Details__c FROM Bank_Details__mdt];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        String result = quoteController.getBankDetails();
        t.stop();

        System.assertEquals(bd.Details__c, result);
    }

    @isTest static void testGetMetadataRecordName() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];
        Bank_Details__mdt bd = [SELECT Label FROM Bank_Details__mdt];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        String result = quoteController.getMetadataRecordName();
        t.stop();

        System.assertEquals(bd.Label, result);
    }

    @isTest static void testGetOwnerName() {
        Quote testQuote = [SELECT Id, Opportunity.Owner.Name FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        String result = quoteController.getOwnerName();
        t.stop();

        System.assertEquals(testQuote.Opportunity.Owner.Name, result);
    }

    @isTest static void testGetOwnerPosition() {
        Quote testQuote = [SELECT Id, Opportunity.Owner.Title FROM Quote WHERE Name='testQuote'];
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        t.start();
        String result = quoteController.getOwnerPosition();
        t.stop();

        System.assertEquals(testQuote.Opportunity.Owner.Title, result);
    }
    
    @isTest static void testGetNamesOfMeasureUnits() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];

        Test.setCurrentPageReference(new PageReference('')); 
        ApexPages.currentPage().getParameters().put('MeasureUnits', 'unit1,unit2');
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        List<String> result = quoteController.getNamesOfMeasureUnits();
        System.assertNotEquals(null, result);
    }
    
    @isTest static void testGetNamesOfMeasureUnitsRus() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name='testQuote'];

        Test.setCurrentPageReference(new PageReference(''));
        ApexPages.currentPage().getParameters().put('MeasureUnits', 'unit1,unit2');
        
        ApexPages.StandardController stdContr = new ApexPages.StandardController(testQuote);
        QuotePDF quoteController = new QuotePDF(stdContr);
        
        List<String> result = quoteController.getNamesOfMeasureUnitsRus();
        System.assertNotEquals(null, result);
    }

    @testSetup static void testSetup() {
        Account testAccount = t.newAccounts('Test Account') [0];
        testAccount.BillingStreet = 'Test Street';
        testAccount.BillingCity = 'Test City';
        testAccount.BillingPostalCode = 'Test Code';
        testAccount.BillingCountry = 'Ukraine';
        testAccount.ID_ERP__c = '12345';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        insert testOpp;
        
        

        List<Product2> prList = new List<Product2>();
        for(Integer i=0; i<3; i++){
            Product2 pr = t.newProducts('test'+i, '000')[0];
            if(i==0){
                pr.Type__c = 'Tube';
				pr.Family='OCTG';
            }
            else{
                pr.Type__c = 'Wheel';
            }
            
            prList.add(pr);
        }
        insert prList;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry testPriceBookEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry1;
        PricebookEntry testPriceBookEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry2;
        PricebookEntry testPriceBookEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[2].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry3;
        Plant__c plant = new Plant__c(FullName__c = 'Test Name 1');
        Plant__c plant2 = new Plant__c(FullName__c = 'Test Name 2');
        List<Plant__c> plants = new List<Plant__c>();
        plants.add(plant);
        plants.add(plant2);
        insert plants;

        Shop__c shop = new Shop__c(Plant__c=plant.Id);
        Shop__c shop2 = new Shop__c(Plant__c=plant2.Id);
        List<Shop__c> shops = new List<Shop__c>();
        shops.add(shop);
        shops.add(shop2);
        insert shops;

        Quote testQuote = new Quote(Name='testQuote', OpportunityId = testOpp.Id, Pricebook2Id = pricebookId);
        insert testQuote;

        QuoteLineItem qli = new QuoteLineItem(InquiryUnit__c='43',InquiryQuantity__c=2,Shop__c = shop.Id, QuoteId = testQuote.Id, Product2Id = prList[0].Id, PricebookEntryId = testPriceBookEntry1.Id, Quantity=5, UnitPrice = 100.00,showInPDF__c=true);
        insert qli;
        
        QuoteLineItem qli2 = new QuoteLineItem(InquiryUnit__c='43',InquiryQuantity__c=2,QuoteId = testQuote.Id, Product2Id = prList[1].Id, PricebookEntryId = testPriceBookEntry1.Id, Quantity=5, UnitPrice = 100.00,showInPDF__c=true);
        insert qli2;

        QuoteLineItem qli3 = new QuoteLineItem(InquiryUnit__c='43',InquiryQuantity__c=2,Shop__c = shop2.Id, QuoteId = testQuote.Id, Product2Id = prList[1].Id, PricebookEntryId = testPriceBookEntry1.Id, Quantity=5, UnitPrice = 100.00,showInPDF__c=true);
        insert qli3;
    }
    
    static { BaseTest.t = new QuotePDFTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}