@isTest
public class PreviewPdfControllerTest extends BaseTest {
    @isTest
    static void testValidateQuoteTermsTrue () {
        Boolean result = false;
        PaymentTerms__c pt = PreviewPdfControllerTestFactory.createPaymentTerms();
        DeliveryTerms__c dt = PreviewPdfControllerTestFactory.createDeliveryTerms();
        Opportunity opp = PreviewPdfControllerTestFactory.createOpportunity();
        
        insert pt;
        insert dt;
        insert opp;
        
        Quote qt = PreviewPdfControllerTestFactory.createQuote(opp.id, pt.Id, dt.Id);
        insert qt;
        
        Test.startTest();
		result = PreviewPdfController.validateQuoteTerms(qt.Id);
		Test.stopTest();
        
        System.assertEquals(true, result, 'Method result is False');
    }
    
    @isTest
    static void testValidateQuoteTermsFalse () {
        Boolean result = false;
        Opportunity opp = PreviewPdfControllerTestFactory.createOpportunity();
        
        insert opp;
        
        Quote qt = PreviewPdfControllerTestFactory.createQuote(opp.id, null, null);
        insert qt;
        
        Test.startTest();
		result = PreviewPdfController.validateQuoteTerms(qt.Id);
		Test.stopTest();
        
        System.assertEquals(false, result, 'Method result is True');
    }
    
    @isTest
    static void testFetchQuoteLineItems () {
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());       
        insert testQuote;
        List<QuoteLineItem> qliForInsert = PreviewPdfControllerTestFactory.creqteQuoteLineItems(oli,testQuote.id,5);
        insert qliForInsert;
        List<QuoteLineItem> qliFetched = PreviewPdfController.fetchQuoteLineItems(testQuote.id);
        System.assertEquals(5, qliFetched.size(), 'Quantity of items doesnt correct');
        
    }
    
    @isTest
    static void testchangeShowInPdfToTrue () {
        List<Id> idsOfQuoteItemsForUpdate = new List<Id>();
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());       
        insert testQuote;
        List<QuoteLineItem> qliForInsert = PreviewPdfControllerTestFactory.creqteQuoteLineItems(oli,testQuote.id,5);
        insert qliForInsert;
        for(QuoteLineItem q :[SELECT Id FROM QuoteLineItem WHERE QuoteId=:testQuote.id LIMIT 2]){
            idsOfQuoteItemsForUpdate.add(q.id);
        }
        PreviewPdfController.changeShowInPdfToTrue(idsOfQuoteItemsForUpdate);
        List<QuoteLineItem> updatedQuoteLineItem = [SELECT Id FROM QuoteLineItem WHERE QuoteId=:testQuote.id AND showInPDF__c=TRUE];
        System.assertEquals(2, updatedQuoteLineItem.size(), 'Expected quantity of updated items doesnt correct');
        
    }
    
    @isTest
    static void testChangeShowInPdfToFalse () {
        
        OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,ID_ERP__c,ITENumber__c
                            FROM OpportunityLineItem LIMIT 1];
        Quote testQuote = new Quote(Name='Test', OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());       
        insert testQuote;
        List<QuoteLineItem> qliForInsert = PreviewPdfControllerTestFactory.creqteQuoteLineItemsWithTrueShowInPDF(oli,testQuote.id,5);
        insert qliForInsert;
                      
        PreviewPdfController.changeShowInPdfToFalse(testQuote.id);
        List<QuoteLineItem> updatedQuoteLineItemWithFalseField = [SELECT Id FROM QuoteLineItem WHERE QuoteId=:testQuote.id AND showInPDF__c=FALSE];
        System.assertEquals(5, updatedQuoteLineItemWithFalseField.size(), 'Expected quantity of updated items doesnt correct');
        
    }
    
    @testSetup 
	static void testSetup() {

		Account testAccount = t.newAccounts('Test Account')[0];
        testAccount.ID_ERP__c = '123456';
		insert testAccount;

		Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today())[0];
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000')[0];
		testProd1.ID_ERP__c = 'pr1';
		insert testProd1;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = testProd1.Id,
			UnitPrice = 1000.00,
			IsActive = true
		);
		insert testPriceBookEntry1;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;
		
		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		size.Type__c = 'R1';
		insert size;
    
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id)[0];
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
		insert testOppProd1;
	}
    
    static { BaseTest.t = new QuoteJSONGeneratorTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}