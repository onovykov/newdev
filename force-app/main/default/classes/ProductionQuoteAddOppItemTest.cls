@isTest 
public class ProductionQuoteAddOppItemTest {

     @IsTest
    static void ProductionQuoteAddOppItemtest() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;
                       
		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
        testOppProd2.Cdd__c = date.today();
        testOppProd2.Balance_t__c = 1;
        testOppProd2.Quantity = 3;
		insert testOppProd2;             
        
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
        
        String todaysMonth = String.valueof(Date.Today().Month());
        if(todaysMonth == '1' || todaysMonth == '2' || todaysMonth == '3' || todaysMonth == '4' || todaysMonth == '5' || todaysMonth == '6' || todaysMonth == '7' || todaysMonth == '8' || todaysMonth == '9'){
            todaysMonth = '0'+todaysMonth;
        }
        
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = todaysMonth;
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        sObject testObj = (sObject)testOppProd2;
        List<sObject> testListSobj = new List<sObject>{testObj};
        
        t.start();
		ProductionQuoteAddOppItem aru = new ProductionQuoteAddOppItem(testListSobj);
		Id aruId = Database.executeBatch(aru,30);
		t.stop();
        
    }
    
     @IsTest
    static void ProductionQuoteUpdateOppItemtest() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;                       

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
        testOppProd2.Cdd__c = date.today();
        testOppProd2.Balance_t__c = 1;
        testOppProd2.Quantity = 3;
		insert testOppProd2;              
        
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
        
        String todaysMonth = String.valueof(Date.Today().Month());
        if(todaysMonth == '1' || todaysMonth == '2' || todaysMonth == '3' || todaysMonth == '4' || todaysMonth == '5' || todaysMonth == '6' || todaysMonth == '7' || todaysMonth == '8' || todaysMonth == '9'){
            todaysMonth = '0'+todaysMonth;
        }
        
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = todaysMonth;
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        Production_Quota__c newProdQuota = new Production_Quota__c();
        newProdQuota.Quota_Type__c = testQt.id;
        insert newProdQuota;
        
        ProdQuoteToOppProduct__c oppProdOnProdQuote = new ProdQuoteToOppProduct__c();
        oppProdOnProdQuote.Production_Quota__c  = newProdQuota.id;
        oppProdOnProdQuote.Opportunity_Product__c = testOppProd2.id;
        insert oppProdOnProdQuote;
        sObject testObj = (sObject)testOppProd2;
        List<sObject> testListSobj = new List<sObject>{testObj};
        
        t.start();
		ProductionQuoteUpdateOppItem aru = new ProductionQuoteUpdateOppItem(testListSobj);
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        
    }
    
    @IsTest
    static void ProductionQuoteUpdateOppItemtest2() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;
        
        
        

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
        testOppProd2.Cdd__c = date.today();
        testOppProd2.Balance_t__c = 1;
        testOppProd2.Quantity = 3;
		insert testOppProd2;
        
        
        
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
        String todaysMonth = String.valueof(Date.Today().Month());
        if(todaysMonth == '1' || todaysMonth == '2' || todaysMonth == '3' || todaysMonth == '4' || todaysMonth == '5' || todaysMonth == '6' || todaysMonth == '7' || todaysMonth == '8' || todaysMonth == '9'){
            todaysMonth = '0'+todaysMonth;
        }
        
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = todaysMonth;
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        Production_Quota__c newProdQuota = new Production_Quota__c();
        newProdQuota.Quota_Type__c = testQt.id;
        insert newProdQuota;
        
        //ProdQuoteToOppProduct__c oppProdOnProdQuote = new ProdQuoteToOppProduct__c();
        //oppProdOnProdQuote.Production_Quota__c  = newProdQuota.id;
        //oppProdOnProdQuote.Opportunity_Product__c = testOppProd2.id;
        
        sObject testObj = (sObject)testOppProd2;
        List<sObject> testListSobj = new List<sObject>{testObj};
       
        t.start();
		ProductionQuoteUpdateOppItem aru = new ProductionQuoteUpdateOppItem(testListSobj);
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        
    }
    
    @IsTest
    static void ProductionQuoteUpdateOppItemtest3() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;
       
        
        

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
        testOppProd2.Cdd__c = date.today();
        testOppProd2.Balance_t__c = 1;
        testOppProd2.Quantity = 3;
		insert testOppProd2;
        
        
        
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
        
        String todaysMonth = String.valueof(Date.Today().Month());
        if(todaysMonth == '1' || todaysMonth == '2' || todaysMonth == '3' || todaysMonth == '4' || todaysMonth == '5' || todaysMonth == '6' || todaysMonth == '7' || todaysMonth == '8' || todaysMonth == '9'){
            todaysMonth = '0'+todaysMonth;
        }
        
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = todaysMonth;
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        Production_Quota__c newProdQuota = new Production_Quota__c();
        newProdQuota.Quota_Type__c = testQt.id;
        insert newProdQuota;
        
        ProdQuoteToOppProduct__c oppProdOnProdQuote = new ProdQuoteToOppProduct__c();
        oppProdOnProdQuote.Production_Quota__c  = newProdQuota.id;
        oppProdOnProdQuote.Opportunity_Product__c = testOppProd2.id;
        oppProdOnProdQuote.Shop__c = testOppProd2.Shop__c;
        oppProdOnProdQuote.Quota_Type__c = testOppProd2.QuotaType__c;
        insert oppProdOnProdQuote;
        sObject testObj = (sObject)testOppProd2;
        List<sObject> testListSobj = new List<sObject>{testObj};
        
        t.start();
		ProductionQuoteUpdateOppItem aru = new ProductionQuoteUpdateOppItem(testListSobj);
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        
    }
    
    @IsTest
    static void ProductionQuoteAddShopQuotatest() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;
                       
		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
		insert testOppProd2;
               
        
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = '05';
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        Production_Quota__c newProdQuota = new Production_Quota__c();
        newProdQuota.Quota_Type__c = testQt.id;
        insert newProdQuota;
        
        ProdQuoteToOppProduct__c oppProdOnProdQuote = new ProdQuoteToOppProduct__c();
        oppProdOnProdQuote.Production_Quota__c  = newProdQuota.id;
        oppProdOnProdQuote.Opportunity_Product__c = testOppProd2.id;
        
        list<Shop_Quota__c> shopQuotas = [SELECT id FROM Shop_Quota__c];
       // sObject testObj = (sObject)testOppProd2;
       // List<sObject> testListSobj = new List<sObject>{testObj};
       // system.debug(testListSobj);
        t.start();
		ProductionQuoteAddShopQuota aru = new ProductionQuoteAddShopQuota(shopQuotas);
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        
    }
    
    @IsTest
    static void ProductionQuoteGroupBatchtest() {
        
        
        Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
        testProd1.Family = 'LP/GU';
        
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
		testProd2.Type__c = 'Tube';
        testProd2.Family = 'OCTG';
		insert testProd2;
                       

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 1000.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
        testOppProd1.Margin_t__c = 0;
        testOppProd1.Quotatype__c = testQt.id;
        testOppProd1.Product2Id = testProd1.id;
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry2.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
        testOppProd2.Quotatype__c = testQt.id;
        testOppProd2.Product2Id = testProd2.id;
		insert testOppProd2;
                
        SalesBudget__c sb = new SalesBudget__c();
		Integer year = Date.today().year();
		sb.Type__c = 'Y';
		sb.Year__c = year;
		sb.Name = year + ' - Initial';
		sb.Approved__c = true;
		insert sb;

		ID rtPlanMonthId = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SalesBudgetRecord__c' And Name = 'Plan Month'].Id;
		SalesBudgetRecord__c sbr = new SalesBudgetRecord__c();
		sbr.RecordTypeId = rtPlanMonthId;
		sbr.SalesBudget__c = sb.Id;
		sbr.PeriodMonth__c = '05';
		sbr.PeriodYear__c = year;
		sbr.SalesManager__c = UserInfo.getUserId();
		sbr.ProductionAmount__c = 90;
		sbr.SalesAmount__c = 90;
		sbr.Revenue__c = 90000;
		sbr.Margin__c = 18000;
        sbr.MarketSegment__c = '00002';
        sbr.QuotaType__c = testQt.id;
        sbr.Product__c = testProd1.id;
		insert sbr;
        
        Production_Quota__c newProdQuota = new Production_Quota__c();
        newProdQuota.Quota_Type__c = testQt.id;
        insert newProdQuota;
        
        ProdQuoteToOppProduct__c oppProdOnProdQuote = new ProdQuoteToOppProduct__c();
        oppProdOnProdQuote.Production_Quota__c  = newProdQuota.id;
        oppProdOnProdQuote.Opportunity_Product__c = testOppProd2.id;
        
        list<Shop_Quota__c> shopQuotas = [SELECT id FROM Shop_Quota__c];
       // sObject testObj = (sObject)testOppProd2;
       // List<sObject> testListSobj = new List<sObject>{testObj};
       // system.debug(testListSobj);
        t.start();
		ProductionQuoteGroupBatch ProductionQuoteGroupBatchRun = new ProductionQuoteGroupBatch();
		Id ProductionQuoteGroupBatchRunId = Database.executeBatch(ProductionQuoteGroupBatchRun,1);
		t.stop();
        
    }
    
    
    @testSetup 
	static void testSetup() {
		
		
        
    } 
    static { BaseTest.t = new ProductionQuoteFromSalBudgetBatchTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}