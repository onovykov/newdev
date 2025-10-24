@isTest 
private class AllocateOrdersToProductionTest {

	@isTest
	private static void allocateOrders() {
		Account acc = new Account();
		acc.Name = 'ACME';
		acc.ID_ERP__c = '123456';
		insert acc;

		Product2 prod2 = TestDataFactory.createTestProduct2('SampleProduct');
        insert prod2;
        Pricebook2 standardPriceBook = TestDataFactory.getStandardPricebook2();
        update standardPriceBook;

		PricebookEntry pricebookEntry = TestDataFactory.createTestPricebookEntry(standardPriceBook.Id, prod2.Id);
		insert pricebookEntry;

		Order ord = new Order();
		ord.AccountId = acc.Id;
		ord.Status = 'Draft';
		ord.MarketSegment__c = '00002';
		ord.EffectiveDate = Date.today() + 30;
		ord.Pricebook2Id = standardPriceBook.Id;
		insert ord;

		OrderItem oi = new OrderItem();
		oi.OrderId = ord.Id;
		oi.Quantity = 50;
		oi.Stage__c = 'Drafting';
		oi.ID_ERP__c = '123456';
		oi.Product2Id = prod2.Id;
		oi.PricebookEntryId = pricebookEntry.Id;
		oi.UnitPrice = 100.00;
		insert oi;

		SalesPlanFact__c spf = new SalesPlanFact__c();
		spf.Type__c = 'Order';
		spf.Period__c = Date.today();
		spf.MarketSegment__c = '00002';
		spf.ProductionAmount__c = 200.00;
		insert spf;

		ProductionJournalRecord__c pjr = new ProductionJournalRecord__c();
		pjr.Type__c = 'Fact';
		pjr.ApprovedFact__c = true;
		pjr.OrderItem__c = oi.Id;
		pjr.Period__c = Date.today() - 30;
		pjr.DispatchedQuantity__c = 2;
		PJR.Order__c = ord.Id;
		insert pjr;

		Test.startTest();
		Id batchProcessId = Database.executeBatch(new AllocateOrdersToProduction());
		Test.stopTest();
	}
}