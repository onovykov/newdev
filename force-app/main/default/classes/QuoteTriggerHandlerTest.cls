@isTest
private class QuoteTriggerHandlerTest extends BaseTest {

	@isTest
	private static void testHeaderOnUpdate() {
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Quote testQuote = new Quote(Name='Test', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
		insert testQuote;

		t.start();
		testQuote.HeaderText__c = 'Test Header';
		update testQuote;
		t.stop();

		Quote updatedQuote = [SELECT HeaderText__c FROM Quote WHERE Id = :testQuote.Id];
		System.assertEquals('Test Header', updatedQuote.HeaderText__c);
	}

	@isTest
	private static void testHeaderOnInsert() {
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Quote testQuote = new Quote(Name='Test', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
		List<Bank_Details__mdt> banks = [SELECT Id, HeaderText__c FROM Bank_Details__mdt];		

		t.start();
		insert testQuote;
		t.stop();

		Quote updatedQuote = [SELECT HeaderText__c FROM Quote WHERE Id = :testQuote.Id];
		System.assertEquals(banks[0].HeaderText__c.replaceAll('<[/a-zAZ0-9]*>',''), updatedQuote.HeaderText__c.replaceAll('<[/a-zAZ0-9]*>',''));
	}

	@testSetup 
    static void testSetup() {

      Account testAccount = t.newAccounts('Test Account')[0];
      testAccount.ID_ERP__c = 'acc1';
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
          UnitPrice = 100.00,
          IsActive = true
      );
      insert testPriceBookEntry1;

      TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 1.4);
      insert wt;

      TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
      size.MaxLength__c = 10;
      size.MinLength__c = 2;
	  size.Type__c = 'R1';
      insert size;

      TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 5.3);
      insert od;
    
      OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id)[0];
        testOppProd1.Quantity_m__c = 14854.0295;
        testOppProd1.InquiryUnit__c = '20';
        testOppProd1.InquiryQuantity__c = 1;
        testOppProd1.Quantity = 1;
        testOppProd1.TubeOD__c = od.Id;
        testOppProd1.TubeWT__c = wt.Id;
        testOppProd1.LengthSize__c = size.Id;
        testOppProd1.ID_ERP__c = '0001';
        testOppProd1.ProductType__c = 'Tube';
        testOppProd1.Weight_kpm__c = 10245.12;
        testOppProd1.Weight_ppf__c = 1234.56;
        testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 2;
      insert testOppProd1;
    }
    static { BaseTest.t = new QuoteTriggerHandlerTest(); }
    static BaseTest t { get { return BaseTest.t; } }
}