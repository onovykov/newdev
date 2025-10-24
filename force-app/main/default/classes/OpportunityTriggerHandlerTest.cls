@isTest
private class OpportunityTriggerHandlerTest extends BaseTest {

	private final static String VALID_STAGE = 'Confirmed';
	
	@TestSetup
	private static void testSetup() {
		Map<String, String> priceUnitValues = ApexUtil.getPicklistFieldMap('User', 'SalesDivision__c');

		User u = t.newUser('test@test.com');
		//u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
		u.SalesDivision__c = priceUnitValues.values().get(0);
		insert u;

		Account accs = t.newAccounts('test') [0];
		accs.ID_ERP__c = '123789';
		insert accs;
	}

	@isTest
	private static void testInsert() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		User u = [SELECT Id FROM User WHERE UserType = 'Standard' LIMIT 1];

		List<Opportunity> opps = t.newOpportunities('test', acc.Id, 'New', Date.today());
		for (Opportunity opp : opps) {
			opp.OwnerId = u.Id;
		}

		t.start();
		insert opps;
		t.stop();

		List<Opportunity> verifyOpps = [SELECT id, MarketSegment__c, Owner.SalesDivision__c FROM Opportunity];

		for (Opportunity opp : verifyOpps) {
			System.assertEquals(opp.MarketSegment__c, opp.Owner.SalesDivision__c);
		}
	}

	@IsTest
	private static void testUpdate() {
		Map<String, String> priceUnitValues = ApexUtil.getPicklistFieldMap('User', 'SalesDivision__c');

		User u = [SELECT Id FROM User WHERE UserType = 'Standard' LIMIT 1];
		Account acc = [SELECT Id FROM Account LIMIT 1];

		List<Opportunity> opps = t.newOpportunities('test', acc.Id, 'New', Date.today());
		for (Opportunity opp : opps) {
			opp.OwnerId = u.Id;
		}
		insert opps;

		User newU = t.newUser('testn@testn.com');
		newU.SalesDivision__c = priceUnitValues.values().get(1);
		newU.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        newU.ID_ERP__c = 'TESTBO';		
		newU.SalesDivision__c = '00004';
		newU.EmployeeNumber = 'TESTBO';
		newU.LoginERP__c = 'TESTBO';
		insert newU;

		List<Opportunity> oppsToUpdate = [SELECT Id, OwnerId FROM Opportunity];
		for (Opportunity opp : oppsToUpdate) {
			opp.OwnerId = newU.Id;
		}

		t.start();
		update oppsToUpdate;
		t.stop();

		List<Opportunity> verifyOpps = [SELECT Id, MarketSegment__c FROM Opportunity];
		for (Opportunity opp : verifyOpps) {
			
			//System.assertEquals(opp.MarketSegment__c, newU.SalesDivision__c);
		}
	}

	@IsTest
	private static void testUpdateDeviveryTermsChanged() {
		createOppWithOLI();

		DeliveryTerms__c dt = new DeliveryTerms__c(Incoterms__c = 'CIF');
		insert dt;

		Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
		testOpp.DeliveryTerms__c = dt.Id;

		t.start();
		update testOpp;
		t.stop();

		Opportunity verifyOpp = [SELECT DeliveryTerms__c FROM Opportunity WHERE Id = :testOpp.Id];
		for (Quote qu : verifyOpp.Quotes) {
			System.assertEquals(dt.Id, qu.DeliveryTerms__c);
		}
	}

	@IsTest
	private static void testUpdatePaymentTermsChanged() {
		createOppWithOLI();

		PaymentTerms__c dt = new PaymentTerms__c();
		insert dt;

		Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
		testOpp.PaymentTerms__c = dt.Id;

		t.start();
		update testOpp;
		t.stop();

		Opportunity verifyOpp = [SELECT PaymentTerms__c FROM Opportunity WHERE Id = :testOpp.Id];
		for (Quote qu : verifyOpp.Quotes) {
			System.assertEquals(dt.Id, qu.PaymentTerms__c);
		}
	}

	/* 18.10.2020: закомментировал тесты по созданию ордеров, т.к. отключили функцию создания ордеров при перемещении оппы на стадию выигранной (ордер создается при обработке сообщения из ИТ-Предприятия)
	@IsTest
	private static void testUpdateStageToClosedWon() {
		createOppWithOLI();

		Opportunity testOpp = [SELECT Id, SyncedOrder__c, AccountId, Pricebook2Id, AdditionalNumber__c, AssignedBOS__c,
		                       ContractId, Country__c, DeliveryTerms__c, Description, ID_ERP__c,
		                       CurrencyIsoCode, Name, OwnerId, Type, PaymentTerms__c,
		(SELECT Id, Quantity, UnitPrice, PricebookEntryId, OpportunityId, ID_ERP__c, CDD__c,
		 Coating__c, TubeEnds__c, ITENumber__c, Description, Margin__c,
		 Margin_t__c, Name__c, Shop__c, NPP_ERP__c, Product2Id, ProductSpecLevel__c,
		 ProductStandard__c, QuotaType__c, ServiceDate, SteelGrade__c,
		 LengthSize__c, TubeOD__c, TubeWT__c, Weight_kpm__c, Weight_ppf__c FROM OpportunityLineItems) FROM Opportunity LIMIT 1];
		testOpp.StageName = 'Closed Won';
		testOpp.MarketSegment__c = '00002';

		t.start();
		update testOpp;
		t.stop();

		
		Opportunity opportunity_after_update = [SELECT Id, SyncedOrder__c FROM Opportunity WHERE Id = :testOpp.Id];

		Order verifyOrder = [SELECT Id, OpportunityId, AccountId, Pricebook2Id, AdditionalNumber__c,
		                     AssignedBOS__c, ContractId, Country__c, DeliveryTerms__c,
		                     Description, ID_ERP__c, CurrencyIsoCode, Name, OwnerId, Type, PaymentTerms__c,
		                     OrderReferenceNumber, Status, EffectiveDate,
		(SELECT Id, OrderId, Shop__c, Quantity, UnitPrice, PricebookEntryId, ID_ERP__c, CDD__c, Coating__c,
		 TubeEnds__c, ITENumber__c, Description, Margin__c, Margin_t__c, Name__c,
		 NPP_ERP__c, Product2Id, ProductSpecLevel__c, ProductStandard__c, QuotaType__c,
		 ServiceDate, SteelGrade__c, TubeLengthSize__c, TubeOD__c, TubeWT__c,
		 Weight_kpm__c, Weight_ppf__c, Stage__c FROM OrderItems) FROM Order LIMIT 1];

		System.assertEquals(opportunity_after_update.SyncedOrder__c, verifyOrder.Id);

		System.assertEquals(verifyOrder.Status, 'Activated');
		System.assertEquals(verifyOrder.OpportunityId, testOpp.Id);
		System.assertEquals(verifyOrder.AccountId, testOpp.AccountId);
		System.assertEquals(verifyOrder.Pricebook2Id, testOpp.Pricebook2Id);
		System.assertEquals(verifyOrder.AdditionalNumber__c, testOpp.AdditionalNumber__c);
		System.assertEquals(verifyOrder.AssignedBOS__c, testOpp.AssignedBOS__c);
		System.assertEquals(verifyOrder.ContractId, testOpp.ContractId);
		System.assertEquals(verifyOrder.Country__c, testOpp.Country__c);
		System.assertEquals(verifyOrder.DeliveryTerms__c, testOpp.DeliveryTerms__c);
		System.assertEquals(verifyOrder.Description, testOpp.Description);
		System.assertEquals(verifyOrder.ID_ERP__c, testOpp.ID_ERP__c);
		System.assertEquals(verifyOrder.CurrencyIsoCode, testOpp.CurrencyIsoCode);
		System.assertEquals(verifyOrder.Name, testOpp.Name);
		System.assertEquals(verifyOrder.OwnerId, testOpp.OwnerId);
		System.assertEquals(verifyOrder.type, testOpp.Type);
		System.assertEquals(verifyOrder.PaymentTerms__c, testOpp.PaymentTerms__c);
		System.assertEquals(verifyOrder.OrderReferenceNumber, testOpp.AdditionalNumber__c);
		System.assertEquals(Date.today(), verifyOrder.EffectiveDate);

		for (OrderItem ordItem : verifyOrder.OrderItems) {
			System.assertEquals(ordItem.OrderId, verifyOrder.Id);
			System.assertEquals(ordItem.Quantity, testOpp.OpportunityLineItems[0].Quantity);
			System.assertEquals(ordItem.UnitPrice, testOpp.OpportunityLineItems[0].UnitPrice);
			System.assertEquals(ordItem.PricebookEntryId, testOpp.OpportunityLineItems[0].PricebookEntryId);
			System.assertEquals(ordItem.ID_ERP__c, testOpp.OpportunityLineItems[0].ID_ERP__c);
			System.assertEquals(ordItem.CDD__c, testOpp.OpportunityLineItems[0].CDD__c);
			System.assertEquals(ordItem.Coating__c, testOpp.OpportunityLineItems[0].Coating__c);
			System.assertEquals(ordItem.TubeEnds__c, testOpp.OpportunityLineItems[0].TubeEnds__c);
			System.assertEquals(ordItem.ITENumber__c, testOpp.OpportunityLineItems[0].ITENumber__c);
			System.assertEquals(ordItem.Description, testOpp.OpportunityLineItems[0].Description);
			//System.assertEquals(ordItem.Name__c, testOpp.OpportunityLineItems[0].Name__c);
			System.assertEquals(ordItem.NPP_ERP__c, testOpp.OpportunityLineItems[0].NPP_ERP__c);
			System.assertEquals(ordItem.Product2Id, testOpp.OpportunityLineItems[0].Product2Id);
			System.assertEquals(ordItem.ProductSpecLevel__c, testOpp.OpportunityLineItems[0].ProductSpecLevel__c);
			System.assertEquals(ordItem.ProductSpecLevel__c, testOpp.OpportunityLineItems[0].ProductSpecLevel__c);
			System.assertEquals(ordItem.QuotaType__c, testOpp.OpportunityLineItems[0].QuotaType__c);
			System.assertEquals(ordItem.ServiceDate, testOpp.OpportunityLineItems[0].ServiceDate);
			System.assertEquals(ordItem.SteelGrade__c, testOpp.OpportunityLineItems[0].SteelGrade__c);
			System.assertEquals(ordItem.TubeLengthSize__c, testOpp.OpportunityLineItems[0].LengthSize__c);
			System.assertEquals(ordItem.TubeOD__c, testOpp.OpportunityLineItems[0].TubeOD__c);
			System.assertEquals(ordItem.TubeWT__c, testOpp.OpportunityLineItems[0].TubeWT__c);
			System.assertEquals(ordItem.Weight_kpm__c, testOpp.OpportunityLineItems[0].Weight_kpm__c);
			System.assertEquals(ordItem.Weight_ppf__c, testOpp.OpportunityLineItems[0].Weight_ppf__c);
			System.assertEquals(ordItem.Shop__c, testOpp.OpportunityLineItems[0].Shop__c);
			System.assertEquals(OpportunityTriggerHandlerTest.VALID_STAGE, ordItem.Stage__c);
		}
	}

	@IsTest
	private static void testUpdateStageToClosedWonBulk() {
		createOppListWithOLI();

		List<Opportunity> testOpps = [SELECT Id FROM Opportunity LIMIT 10];
		for (Opportunity opp : testOpps) {
			opp.StageName = 'Closed Won';
			opp.MarketSegment__c = '00002';
		}

		t.start();
		update testOpps;
		t.stop();

		List<Order> verifyOrder = [SELECT Id, OpportunityId, Status, (SELECT Id, OrderId FROM OrderItems) FROM Order];
		System.assertEquals(verifyOrder.size(), 10);
		for (Order ord : verifyOrder) {
			System.assertEquals(1, ord.OrderItems.size());
			System.assertEquals(ord.Status, 'Activated');
		}
	}

	@IsTest
	private static void testUpdateStageFromClosedWon() {
		createOppWithOLI();

		Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
		testOpp.StageName = 'Closed Won';
		testOpp.MarketSegment__c = '00002';
		update testOpp;

		List<Order> createdOrder = [SELECT Id, OpportunityId, (SELECT Id, OrderId FROM OrderItems) FROM Order];
		System.assertEquals(1, createdOrder.size());
		for (Order ord : createdOrder) {
			for (OrderItem ordItem : ord.OrderItems) {
				System.assertEquals(ordItem.OrderId, createdOrder[0].Id);
			}
		}

		t.start();
		testOpp.StageName = 'Proposal';
		update testOpp;
		t.stop();

		List<Order> verifyOrder = [SELECT Id FROM Order];
		System.assertEquals(0, verifyOrder.size());
	}

	@IsTest
	private static void testUpdateStageFromClosedWonBulk() {
		createOppListWithOLI();

		List<Opportunity> testOpps = [SELECT Id FROM Opportunity LIMIT 10];
		for (Opportunity opp : testOpps) {
			opp.StageName = 'Closed Won';
			opp.MarketSegment__c = '00002';
		}
		update testOpps;

		List<Order> createdOrders = [SELECT Id, OpportunityId, (SELECT Id, OrderId FROM OrderItems) FROM Order];
		System.assertEquals(10, createdOrders.size());
		for (Order ord : createdOrders) {
			System.assertEquals(1, ord.OrderItems.size());
		}

		t.start();
		for (Opportunity opp : testOpps) {
			opp.StageName = 'Proposal';
		}
		update testOpps;
		t.stop();

		List<Order> verifyOrders = [SELECT Id FROM Order];
		System.assertEquals(0, verifyOrders.size());
	}
	*/

	private static TubeWT__c createTubeWT() {
		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 1.4);
		return wt;
	}

	private static TubeOD__c createTubeOD() {
		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 5.3);
		return od;
	}

	private static DeliveryTerms__c createDeliveryTerms() {
		DeliveryTerms__c dt = new DeliveryTerms__c(Incoterms__c = 'CIF');
		return dt;
	}

	private static SteelGrade__c createSteelGrade() {
		SteelGrade__c sg = new SteelGrade__c(Name = 'testSG', ShortName__c = 'test');
		return sg;
	}

	private static CoatingType__c createCoatingType() {
		CoatingType__c ct = new CoatingType__c(Name = 'testCT');
		return ct;
	}

	private static Contract createContract(Account acc) {
		Contract con = new Contract(AccountId = acc.Id, Status = 'Draft', CurrencyIsoCode = 'USD', StartDate = Date.today(), ContractTerm = 1);
		return con;
	}

	private static Country__c createCountry() {
		Country__c con = new Country__c(Name = 'TestCountry', A2Code__c = '21', A3Code__c = '123', NumCode__c = '123');
		return con;
	}

	private static ProductStandard__c createProductStandart() {
		ProductStandard__c prod_s = new ProductStandard__c(Name = 'Test Product Standart');
		return prod_s;
	}

	private static TubeEnds__c createTubeEnds() {
		TubeEnds__c te = new TubeEnds__c(Name = 'New Tube Ends');
		return te;
	}

	private static ProductSpecLevel__c createProductSpecLevel() {
		ProductSpecLevel__c psl = new ProductSpecLevel__c(Name = 'Test Prod Spec Level');
		return psl;
	}

	private static QuotaType__c createQuotaType() {
		QuotaType__c qt = new QuotaType__c(Name = 'Test Qute Type');
		return qt;
	}

	private static TubeLengthSize__c createTubeLenghtSize() {
		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Name = 'testLS');
		size.MaxLength__c = 10;
		size.MinLength__c = 2;
		size.Type__c = 'R1';
		return size;
	}


	private static void createOppWithOLI() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		User u = [SELECT Id FROM User WHERE UserType = 'Standard' LIMIT 1];
		TubeLengthSize__c size = createTubeLenghtSize();
		insert size;
		TubeWT__c wt = createTubeWT();
		insert wt;
		TubeOD__c od = createTubeOD();
		insert od;
		DeliveryTerms__c dt = createDeliveryTerms();
		insert dt;
		PaymentTerms__c pt = new PaymentTerms__c();
		insert pt;
		SteelGrade__c sg = createSteelGrade();
		insert sg;
		CoatingType__c ct = createCoatingType();
		insert ct;
		Contract con = createContract(acc);
		insert con;
		con.Status = 'Activated';
		update con;
		Country__c country = createCountry();
		insert country;
		ProductStandard__c prod_s = createProductStandart();
		insert prod_s;
		TubeEnds__c te = createTubeEnds();
		insert te;
		ProductSpecLevel__c psl = createProductSpecLevel();
		insert psl;

		QuotaType__c qt = createQuotaType();
		insert qt;


		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
		insert testProd1;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 100.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;

		Opportunity opp = t.newOpportunities('test', acc.Id, 'New', Date.today()) [0];
		opp.OwnerId = u.Id;
		opp.AdditionalNumber__c = '1234';
		opp.AssignedBOS__c = u.Id;
		opp.ContractId = con.Id;
		opp.Country__c = country.Id;
		opp.DeliveryTerms__c = dt.Id;
		opp.Description = 'test description';
		opp.CurrencyIsoCode = 'USD';
		opp.OwnerId = u.Id;
		opp.Type = 'Project';
		opp.PaymentTerms__c = pt.Id;
		opp.Pricebook2Id = pricebookId;
		opp.AdditionalNumber__c = '1234';

		insert opp;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, opp.Id) [0];
		testOppProd1.Quantity_m__c = 14854.0295;
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 1;
		testOppProd1.Quantity = 1;
		testOppProd1.InquiryQuantity__c = 1;
		testOppProd1.InquiryUnit__c = '34';
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = testPriceBookEntry1.UnitPrice;
		testOppProd1.CDD__c = Date.today();
		testOppProd1.Coating__c = ct.Id;
		testOppProd1.TubeEnds__c = te.Id;
		testOppProd1.ITENumber__c = '1234';
		testOppProd1.Description = 'Test Description';
		testOppProd1.Margin__c = 1234;
		testOppProd1.Margin_t__c = 1234;
		testOppProd1.Name__c = 'test name';
		testOppProd1.NPP_ERP__c = '1234';
		testOppProd1.Product2Id = testProd1.Id;
		testOppProd1.ProductSpecLevel__c = psl.Id;
		testOppProd1.ProductStandard__c = prod_s.Id;
		testOppProd1.QuotaType__c = qt.Id;
		testOppProd1.ServiceDate = Date.today();
		testOppProd1.SteelGrade__c = sg.Id;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 1234;
		testOppProd1.Weight_ppf__c = 1234;
		insert testOppProd1;

		List<Quote> quotes = new List<Quote> ();
		for (Integer i = 0; i< 5; i++) {
			quotes.add(new Quote(Name = 'Test' + i, OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId()));
		}
		insert quotes;
	}


	private static void createOppListWithOLI() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		User u = [SELECT Id FROM User LIMIT 1];
		List<Opportunity> oppList = new List<Opportunity> ();
		Opportunity opp;
		for (Integer i = 0; i< 10; i++) {
			opp = t.newOpportunities('test' + i, acc.Id, 'New', Date.today()) [0];
			opp.OwnerId = u.Id;
			oppList.add(opp);
		}
		insert oppList;


		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
		testProd1.Type__c = 'Tube';
		insert testProd1;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 100.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;

		List<OpportunityLineItem> testOppProducts = new List<OpportunityLineItem> ();
		OpportunityLineItem testOppProd1;
		Integer i = 1;
		for (Opportunity opprt : oppList) {
			testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, opprt.Id) [0];
			testOppProd1.Quantity_m__c = 14854.0295;
			testOppProd1.InquiryUnit__c = '20';
			testOppProd1.InquiryQuantity__c = 1;
			testOppProd1.Quantity = 1;
			testOppProd1.InquiryQuantity__c = 1;
			testOppProd1.InquiryUnit__c = '34';
			testOppProd1.ID_ERP__c = '000' + i;
			testOppProd1.ProductType__c = 'Tube';
			testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
			testOppProd1.InquiryUnitPrice__c = testPriceBookEntry1.UnitPrice;
			testOppProducts.add(testOppProd1);
			i++;
		}
		insert testOppProducts;
	}

	static { BaseTest.t = new OpportunityTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}