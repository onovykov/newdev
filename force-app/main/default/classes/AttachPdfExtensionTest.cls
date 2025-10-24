@isTest 
private class AttachPdfExtensionTest extends BaseTest{

	@isTest
	private static void testName() {
		Account testAcc = t.newAccounts('testacc')[0];
		testAcc.ID_ERP__c = '123789';
		insert testAcc;

		Opportunity testOpp = t.newOpportunities('testopp', testAcc.Id, 'New', Date.today())[0];
		insert testOpp;

		Quote testQuote = new Quote(Name='testQuote', OpportunityId = testOpp.Id);
		insert testQuote;

		t.start();
			ApexPages.StandardController standard = new ApexPages.StandardController(testQuote);
			AttachPdfExtension controll = new AttachPdfExtension(standard);
			PageReference verifyRef = controll.attachPDF();
		t.stop();

		List<QuoteDocument> verifyPDFs = [SELECT Id FROM QuoteDocument];

		//verify that documents are inserted
		System.assertEquals(1, verifyPDFs.size());
		//verify correct page reference
		PageReference expected = Page.QuotePDFPage;
		expected.getParameters().put('Id', testQuote.Id);
		System.assertEquals(expected.getUrl(), verifyRef.getUrl());
	}

	static { BaseTest.t = new AttachPdfExtensionTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}