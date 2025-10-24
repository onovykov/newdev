@isTest
public class PARUpdateOpportunityBatchTest extends BaseTest {
	
     
    @IsTest
	static void testUpdateStagePAR() {
		PriceApprovalRequest__c par = [select Id, Name from PriceApprovalRequest__c].get(0);
        //par.Stage__c = 'Resolved';
        Opportunity opp = [SELECT Margin__c FROM Opportunity LIMIT 1];
        PriceApprovalRequestItem__c parItem = [SELECT Margin__c,Margin_t__c FROM PriceApprovalRequestItem__c order by OpportunityLineItemId__c  LIMIT 1];     
        //System.assertEquals(0, opp.Margin__c);
        
        OpportunityLineItem oppLineItem1 = [SELECT Margin__c,Quantity,Margin_t__c FROM OpportunityLineItem order by id LIMIT 1  ];
        //System.assertNotEquals(parItem.Margin_t__c, oppLineItem1.Margin_t__c);
        
        t.start();
		PARUpdateOpportunityBatch aru = new PARUpdateOpportunityBatch();
		Id aruId = Database.executeBatch(aru,1);
		t.stop();
        OpportunityLineItem oppLineItem = [SELECT Margin__c,Quantity,Margin_t__c FROM OpportunityLineItem order by id LIMIT 1];
        
        OpportunityLineItem oppLineItem2 = [SELECT Margin__c,Quantity,Margin_t__c FROM OpportunityLineItem order by id ][1];
        PriceApprovalRequestItem__c parItem2 = [SELECT Margin__c,Margin_t__c FROM PriceApprovalRequestItem__c order by OpportunityLineItemId__c ][1];
        
        system.debug(parItem.Margin_t__c);
        system.debug(oppLineItem.Margin_t__c);
        system.debug(parItem2.Margin_t__c);
        system.debug(oppLineItem2.Margin_t__c);
        
        //System.assertEquals(oppLineItem.Margin__c,oppLineItem.Quantity*oppLineItem.Margin_t__c);
        //System.assertEquals(parItem.Margin_t__c, oppLineItem.Margin_t__c);
        //System.assertEquals(parItem2.Margin_t__c, oppLineItem2.Margin_t__c);
	}
    
    
    @testSetup 
	static void testSetup() {
		
		Account testAccount = t.newAccounts('Test Account')[0];
		insert testAccount;

		
        
        Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
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
		insert testOppProd1;
        
        OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.TubeOD__c = od.Id;
		testOppProd2.TubeWT__c = wt.Id;
		testOppProd2.Weight_kpm__c = 5.41;
		testOppProd2.Weight_ppf__c = 3.63;
		testOppProd2.LengthSize__c = size.Id;
		testOppProd2.ID_ERP__c = '0003';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd2.InquiryUnitPrice__c = 5.41;
        testOppProd2.Margin_t__c = 0;
		insert testOppProd2;
        /*
		OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.Quantity = 100;
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.InquiryUnitPrice__c = 5.41;
		insert testOppProd2;*/
        
        PriceApprovalRequest__c par = new PriceApprovalRequest__c();
		par.Account__c = testAccount.Id;        
		par.Name = '2020/0001';
        par.Stage__c = 'Resolved';
        //par.ApprovalResolution__c = 'SalesRep:0';
		insert par;
        
        PriceApprovalRequestItem__c parItem1 = new PriceApprovalRequestItem__c();
        parItem1.PriceApprovalRequestId__c = par.id;
        parItem1.OpportunityLineItemId__c = testOppProd1.id;
        parItem1.OpportunityId__c = testOpp.id;
        parItem1.Margin__c = 1;
        parItem1.Margin_t__c = 2;
        insert parItem1;  
        
        PriceApprovalRequestItem__c parItem2 = new PriceApprovalRequestItem__c();
        parItem2.PriceApprovalRequestId__c = par.id;
        parItem2.OpportunityLineItemId__c = testOppProd2.id;
        parItem2.OpportunityId__c = testOpp.id;
        parItem2.Margin__c = 16;
        parItem2.Margin_t__c = 23;
        insert parItem2;
        
        OpportunityPARRelationship__c oppParRelation = new OpportunityPARRelationship__c();
        oppParRelation.Opportunity__c = testOpp.id;
        oppParRelation.PriceApprovalRequest__c = par.id;
        insert oppParRelation;
        
	}
    
    static { BaseTest.t = new PARUpdateOpportunityBatchTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}