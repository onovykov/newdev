@isTest
public class BalanceUpdaOppProdAndOrderProdBatchTest extends BaseTest {

    @isTest
    public static void updateBalanceField() {
        
        t.start();  
        BalanceUpdaOppProdAndOrderProdBatch aru = new BalanceUpdaOppProdAndOrderProdBatch();
		Id aruId = Database.executeBatch(aru);
        t.stop();
        OpportunityLineItem checkProduct = [SELECT Balance_t__c FROM OpportunityLineItem WHERE ITENumber__c='123' LIMIT 1];
        System.assertEquals(3,checkProduct.Balance_t__c);
        //
        
    }
    
    @testSetup
	static void testSetup() {
    Account testAccount = t.newAccounts('Test Account') [0];
		testAccount.ID_ERP__c = '1';
		testAccount.BillingCity = 'City';
		testAccount.BillingCountry = 'Ukraine';
		testAccount.BillingStreet = 'Street';
		testAccount.BillingPostalCode = '12345';
		testAccount.ShippingCity = 'ShipCity';
		testAccount.ShippingCountry = 'Ukraine';
		testAccount.ShippingStreet = 'ShipStreet';
		testAccount.ShippingPostalCode = '54321';
		testAccount.Description = 'Test';
        insert testAccount;
    
    Order testOrder = new Order();
        testOrder.AccountId = testAccount.id;
		testOrder.EffectiveDate = date.TODAY();
		testOrder.Status = 'Draft';        
    	testOrder.ID_ERP__c = '12312331';
        testOrder.ITENumber__c = '34324234';
   		insert testOrder;
        
   
        
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
        testOppProd1.ITENumber__c = '123';
        testOppProd1.Quantity = 5;
		insert testOppProd1;
                                             
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
                
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        // insert account
        Account acc = new Account(
            Name = 'SFDCPanther.com',
            Rating = 'Hot',
            Industry = 'Banking',
            Phone = '9087654321'
        );
        insert acc;
        
        Order order = new Order(
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        OrderItem lineItem = new OrderItem();
        lineItem.OrderId = order.id;
        lineItem.Quantity = 24;
        lineItem.UnitPrice = 240;
        lineItem.Product2id = p.id;
        lineItem.PricebookEntryId=standardPrice.id;
        lineItem.ITENumber__c = '123';
                
                lineItem.ProducedQuantity__c = 2;        
        insert lineItem;
        
        // Now update & Activate the Order
        order.Status = 'Activated';
        update order;
        
		  
    }
    
    
    static { BaseTest.t = new BalanceUpdaOppProdAndOrderProdBatchTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}