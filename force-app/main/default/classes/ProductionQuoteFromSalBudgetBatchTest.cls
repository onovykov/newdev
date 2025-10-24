@isTest 
public class ProductionQuoteFromSalBudgetBatchTest extends BaseTest {
	
     @IsTest
    static void ProductionQuoteFromSalBudgetBatchTest() {
        system.debug('testtt');
        
        t.start();
		ProductionQuoteFromSalBudgetBatch aru = new ProductionQuoteFromSalBudgetBatch();
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        list<Production_Quota__c> test2 = [select id from Production_Quota__c];
        system.debug(test2);
        //System.assertEquals(1,test2.size());
    }
    
    // @IsTest
    // static void ProductionQuoteOnUpdateBatchTest() {
    //     system.debug('test2');
    //     Shop_Quota__c shopQuotaForUpdate = [SELECT Required_Quota_Date__c FROM Shop_Quota__c LIMIT 1];
    //     shopQuotaForUpdate.Required_Quota_Date__c = date.Today();
    //     update shopQuotaForUpdate;
    //     list<Production_Quota__c> test1 = [select id from Production_Quota__c];
    //     system.debug('check quote');
    //     system.debug(test1);
    //     t.start();
	// 	ProductionQuoteOnUpdateBatch aru = new ProductionQuoteOnUpdateBatch();
	// 	Id aruId = Database.executeBatch(aru,1);
	// 	t.stop();
    //     list<ProdQuoteToOppProduct__c> test2 = [select id from ProdQuoteToOppProduct__c];
    //     system.debug(test2);
    //     System.assertEquals(2,test2.size());
    // }
    
    @IsTest
    static void ProductionQuoteOnSalesBudget() {
       SalesBudget__c getSalesBudgetRecord = [SELECT id FROM SalesBudget__c LIMIT 1];
       Set<Id> sbrIdsSet = new Set<Id>(); 
       sbrIdsSet.add(getSalesBudgetRecord.id);
        
       t.start();
            
            ProductionQuoteDeleteBatch aru = new ProductionQuoteDeleteBatch(sbrIdsSet);
            Id aruId = Database.executeBatch(aru,1);       
        	
	   t.stop();
        
    }
    
    @IsTest
    static void deleteSalesPlanFactTest() {
       SalesBudget__c getSalesBudgetRecord = [SELECT id FROM SalesBudget__c LIMIT 1];
               
       t.start();
            
            SalesPlanFactDeleteBatch aru = new SalesPlanFactDeleteBatch(getSalesBudgetRecord.id);
            Id aruId = Database.executeBatch(aru,1);       
        	
	   t.stop();
        
    }
    
    @IsTest
    static void deleteDuplicates() {
                    
       t.start();           
            ProductionQuoteDeleteDuplicationBatch aru = new ProductionQuoteDeleteDuplicationBatch();
            Id aruId = Database.executeBatch(aru,1);              	
	   t.stop();
        
    }
    
    @IsTest
    static void OpportunitiesWithoutOrderBatchTest() {
       Order orderForDelete = [SELECT id FROM Order limit 1];
       delete orderForDelete; 
               
       t.start();
            
            OpportunitiesWithoutOrderBatch aru = new OpportunitiesWithoutOrderBatch();
            Id aruId = Database.executeBatch(aru,1);       
        	
	   t.stop();
        
    }
    
    @testSetup 
	static void testSetup() {
		
		Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

        testAccount.ID_ERP__c = '123123';
        update testAccount;

		QuotaType__c testQt = new QuotaType__c();
        testQt.Name = 'Test';
        insert testQt;
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Closed Won', Date.today()) [0];
        testOpp.MarketSegment__c = '00002';
		insert testOpp;

        testOpp.StageName = 'Closed Won';
        update testOpp;

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
        system.debug(testProd1);
        system.debug(testProd2);
        
        

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
        testOppProd1.Cdd__c = date.today();
        testOppProd1.Balance_t__c = 1;
        testOppProd1.Quantity = 3;
        testOppProd1.Stage__c = 'Drafting';
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
        testOppProd2.Stage__c = 'Drafting';
		insert testOppProd2;
        
        system.debug(testProd1.id);
        system.debug(testProd2.id);
        system.debug(testOppProd1.Id);
        system.debug(testOppProd2.Id);
        system.debug(testOppProd1.Product2Id);
        system.debug(testOppProd2.Product2Id);
        
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
        
        Order testOrder = new Order();
        testOrder.OpportunityId = testOpp.Id;
        testOrder.AccountId = testAccount.id;
		testOrder.EffectiveDate = date.TODAY();
		testOrder.Status = 'Draft';        
    	testOrder.ID_ERP__c = '12312331';
        testOrder.ITENumber__c = '34324234';
   		insert testOrder;
        
        String sbrQuotaType = sbr.QuotaType__c;
        String sbrMarketSegment = sbr.MarketSegment__c;
        Date sbrPeriod = sbr.Period__c;
        Decimal sbrProductionAmount = sbr.Production_Amount__c;
        String sbrSaleManager = sbr.SalesManager__c;
        String sbrProduct = sbr.Product__c;
        //Set<Id> opportunityIds = new Set<Id>();
        
       
            Production_Quota__c pq = new Production_Quota__c();
            pq.Quota_Type__c = sbrQuotaType;
            pq.Market_Segment__c = sbrMarketSegment;
            pq.Period__c = date.today();
            pq.Production_Amount_t__c = sbrProductionAmount;
            pq.Sales_Manager__c = sbrSaleManager;
            pq.Product__c = sbrProduct;
        	pq.Shop__c = sbr.Shop__c;
        insert pq;
        
        Product2 guProduct = new Product2(Name='GU');
        Product2 lpProduct = new Product2(Name='LP');
        
        insert guProduct;
        insert lpProduct;
        
        QuotaType__c quotaExport = new QuotaType__c(Name='Shop 5 (export)');
        insert quotaExport;
        
        QuotaType__c quotaTypeOut = new QuotaType__c(Name='Out of budget');
        insert quotaTypeOut;
        
        
    }
    
    public static void createProductionQuote(){
        
    }
    
    static { BaseTest.t = new ProductionQuoteFromSalBudgetBatchTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}