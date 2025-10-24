@isTest
public class UpdateInquiryOnQuoteItemsBatchTest extends BaseTest {
	
    
    @isTest static void testFillQLIasOLI() {
		OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
														ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
														ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c,Quantity_ft__c
														FROM OpportunityLineItem LIMIT 1];
		Quote testQuote = new Quote(Name='Test', OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
        system.debug(oli.Quantity_ft__c);
		insert testQuote;
		QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, InquiryUnit__c='34', Product2Id = oli.Product2Id);
		insert qli;
		t.start();		
        		UpdateInquiryOnQuoteItemsBatch aru = new UpdateInquiryOnQuoteItemsBatch();
                Id aruId = Database.executeBatch(aru);    
        t.stop();
        
        QuoteLineItem insertedQLI = [SELECT Id, Quantity_m__c,Sales_Price_m__c,InquiryQuantity__c,InquiryUnitPrice__c,Quantity_ft__c,Sales_Price_ft__c FROM QuoteLineItem LIMIT 1];
    	System.assertEquals(insertedQLI.InquiryQuantity__c, insertedQLI.Quantity_m__c);
        System.assertEquals(insertedQLI.InquiryUnitPrice__c, insertedQLI.Sales_Price_m__c);
        system.debug(insertedQLI.Sales_Price_ft__c);
        system.debug(insertedQLI.Quantity_ft__c);
    	system.debug(insertedQLI.InquiryQuantity__c);
        system.debug(insertedQLI.Quantity_m__c);
    }
    
    
    
    @testSetup 
	static void testSetup() {

		Account testAccount = t.newAccounts('Test Account')[0];
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
		testOppProd1.InquiryQuantity__c = 33;
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
    
    
    static { BaseTest.t = new UpdateInquiryOnQuoteItemsBatchTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}