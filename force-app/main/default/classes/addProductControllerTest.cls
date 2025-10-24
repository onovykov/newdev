@isTest
private class addProductControllerTest extends BaseTest{
    
    @isTest static void test_getProductNames() {
        Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
        insert testOpp;
        Product2 testProd1 = t.newProducts('Test product', '0000')[0];
        insert testProd1;
        Id pricebookId = Test.getStandardPricebookId();
        List<Product2> prList = new List<Product2>();
        for(Integer i=0; i<3; i++){
            prList.add(t.newProducts('test'+i, '000')[0]);
        }
        insert prList;

        PricebookEntry testPriceBookEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry2;
        PricebookEntry testPriceBookEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry3;
        PricebookEntry testPriceBookEntry4 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prList[2].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry4;

        t.start();
        Map<String,String> productNames = addProductController.getProductNames(testOpp.Id);
        t.stop();

        Map<String,String> expextedNames = new Map<String, String>();
        for(Product2 pr2 : prList){
            expextedNames.put(pr2.Id, pr2.Name);
        }
        System.assertEquals(expextedNames, productNames);
    }
    
    @isTest static void test_getCurrencyIsoCode() {     
        Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
        testOpp.CurrencyIsoCode = 'USD';
        insert testOpp;

        t.start();
        String isoCode = addProductController.getCurrencyIsoCode(testOpp.Id);
        t.stop();

        System.assertEquals('USD', isoCode);
    }

    @isTest static void test_getFieldPicklistValues() {
        t.start();
        Map<String,String> mapPickList = addProductController.getFieldPicklistValues('InquiryUnit__c');
        t.stop();

        List<String> expextedValues = new List<String> { '34' , '20' , '74', '43'};
        System.assertEquals(expextedValues, mapPickList.values());
    }

    @isTest static void test_getNames() {

        List<SteelGrade__c> sgList = new List<SteelGrade__c>();
        for(Integer i=0; i<3; i++){
            SteelGrade__c sg = new SteelGrade__c();
            sg.Name = 'Test'+i;
            sg.ShortName__c='test';
            sgList.add(sg);
        }
        insert sgList;

        t.start();
        Map<String, String> namesToIds = addProductController.getNames('SteelGrade__c');
        t.stop();

        Map<String, String> sgMap = new Map<String, String>();
        List<SteelGrade__c> sgSelected = [SELECT Id, Name FROM SteelGrade__c];
        for (SteelGrade__c sg : sgSelected){
                sgMap.put(sg.Id, sg.Name);
        }
        System.assertEquals(sgMap, namesToIds);
    }

    @isTest static void test_isMobile() {
        addProductController.isInSalesforce1 = true;

        t.start();
        Boolean isMobile = addProductController.isMobile();
        t.stop();
        
        System.assertEquals(true, isMobile);
    }

    @isTest static void test_getNewOppProduct() {
        OpportunityLineItem newOppProduct = new OpportunityLineItem();

        t.start();
            OpportunityLineItem oppProduct = addProductController.getNewOppProduct();
        t.stop();
        
        System.assertEquals(newOppProduct, oppProduct);
    }
    
    @isTest static void test_getShippingPointForCountry() {
        Country__c testCountry1 = new Country__c(Name='Test Country1', A2Code__c = '1', A3Code__c = '1', NumCode__c = '1');
        insert testCountry1;
        Country__c testCountry2 = new Country__c(Name='Test Country2', A2Code__c = '2', A3Code__c = '2', NumCode__c = '2');
        insert testCountry2;
        Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
        testOpp.Country__c = testCountry1.Id;
        insert testOpp;
        List<ShippingPoint__c> spList = new List<ShippingPoint__c>();
        for(Integer i=0; i<3; i++){
            spList.add(new ShippingPoint__c(Country__c = testCountry1.Id, Name = 'testForCountry1'+i, Type__c='1'));
            spList.add(new ShippingPoint__c(Country__c = testCountry2.Id, Name = 'testForCountry2'+i, Type__c='1'));
        }
        insert spList;

        t.start();
        Map<String, String> spNamesToids = addProductController.getShippingPointForCountry(testOpp.Id);
        t.stop();

        Map<String, String> spMap = new Map<String, String>();
        List<ShippingPoint__c> spSelected = [SELECT Id, Name FROM ShippingPoint__c WHERE Country__c=:testCountry1.Id];
        for (ShippingPoint__c sp : spSelected){
            spMap.put(sp.Id, sp.Name);
        }
        System.assertEquals(spMap, spNamesToids);
    }

    @isTest static void test_addOppProductQ() {
        Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
        insert testOpp;
        Id pricebookId = Test.getStandardPricebookId();
        Product2 testProd1 = t.newProducts('Test product', '0000')[0];
        insert testProd1;
        TubeOD__c od = new TubeOD__c(OD_mm__c=5);
        insert od;
        TubeWT__c wt = new TubeWT__c(WT_mm__c=10);
        insert wt;

        PricebookEntry testPriceBookEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProd1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPriceBookEntry1;

        OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id)[0];
        testOppProd1.Quantity = 8;
        testOppProd1.TubeOD__c = od.Id;
        testOppProd1.TubeWT__c = wt.Id;
        testOppProd1.TotalPrice = 100;

        t.start();
        addProductController.addOppProductQ(testOppProd1, testOpp.Id);
        t.stop();

        /*OpportunityLineItem oppProduct = [SELECT Quantity, OpportunityId FROM OpportunityLineItem];
        System.assertEquals(8, oppProduct.Quantity);
        System.assertEquals(testOpp.Id, oppProduct.OpportunityId);*/
    }

    @isTest static void test_innerClass() {
        
        t.start();
            addProductController.ResponseData inerObj = new addProductController.ResponseData();
            inerObj.addError('TestError');
            String jsonStringObj = inerObj.getJsonString();
        t.stop();

        System.assertEquals('TestError', inerObj.errMsg);
        System.assertEquals(false, inerObj.isSuccess);
    }

    @isTest static void test_getIsAllowedToAddProducts() {
        Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
        insert testAccount;
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
        insert testOpp;

        t.start();
            Boolean result = addProductController.getIsAllowedToAddProducts(testOpp.Id);
        t.stop();

        System.assertEquals(true, result);
    }

    static { BaseTest.t = new addProductControllerTest(); }
    static BaseTest t { get { return BaseTest.t; } }
    
}