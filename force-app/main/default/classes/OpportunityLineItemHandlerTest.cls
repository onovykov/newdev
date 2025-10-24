@isTest
public class OpportunityLineItemHandlerTest extends BaseTest {
	@isTest
	public static void test_updateOLIStageShippedAndAllOLIShipped() {
		List<Opportunity> testOppList = [Select Id, StageName FROM Opportunity];
		for (Opportunity opp : testOppList) {
			opp.MarketSegment__c = '00002';
		}

		List<OpportunityLineItem> testOppLIList = [SELECT Id, Stage__c FROM OpportunityLineItem];
		for (OpportunityLineItem oli : testOppLIList) {
			oli.Stage__c = 'Shipped';
		}

		t.start();
		update testOppList;
		update testOppLIList;
		t.stop();

		Opportunity opp = [SELECT Id, StageName FROM Opportunity];

		System.assertEquals('Closed Won', opp.StageName);
	}

	@isTest
	public static void test_updateOLIStageShippedAndNotAllOLIShipped() {
		OpportunityLineItem testOppLI = [SELECT Id, Stage__c FROM OpportunityLineItem LIMIT 1];
		testOppLI.Stage__c = 'Shipped';

		t.start();
		update testOppLI;
		t.stop();

		Opportunity opp = [SELECT Id, StageName FROM Opportunity];

		System.assertEquals('Qualification', opp.StageName);
	}

	@isTest
	public static void test_deleteOLI() {
		OpportunityLineItem testOppLI = [SELECT Id, Stage__c, OpportunityId FROM OpportunityLineItem LIMIT 1];

		t.start();
		delete testOppLI;
		t.stop();

		Integer oppLIQuantity = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :testOppLI.OpportunityId];
		System.assertEquals(1, oppLIQuantity);
	}

	@isTest
	public static void test_updateAllOLIStageShippedANDOpportunityStageIsClosedLost() {
		Opportunity opp = [SELECT Id, StageName FROM Opportunity];
		opp.StageName = 'Closed Lost';
		opp.LostReason__c = 'Size Range';
		update opp;
		List<OpportunityLineItem> testOppLIList = [SELECT Id, Stage__c FROM OpportunityLineItem];
		for (OpportunityLineItem oli : testOppLIList) {
			oli.Stage__c = 'Shipped';
		}

		t.start();
		update testOppLIList;
		t.stop();

		opp = [SELECT Id, StageName FROM Opportunity];

		System.assertEquals('Closed Lost', opp.StageName);
	}

	@isTest
	public static void test_namePopulationOnOLIODUpdate() {
		OpportunityLineItem testOppLI = [SELECT Id, Stage__c FROM OpportunityLineItem WHERE ID_ERP__c = '0001' LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		SteelGrade__c sg = new SteelGrade__c(Name = 'testSG', ShortName__c = 'test');
		insert sg;
		testOppLI.SteelGrade__c = sg.Id;

		t.start();
		update testOppLI;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, Name__c FROM OpportunityLineItem WHERE Id = :testOppLI.Id];
		String expextedName = sg.Name + ' ' + od.OD_mm__c + 'x' + wt.WT_mm__c + ' ' + ls.Name;
		System.assertEquals(expextedName, opp.Name__c);
	}

	@isTest
	public static void test_QuantityPopulationOnOLIWithMInsert() {
		PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		Opportunity testOpp = [SELECT ID FROM Opportunity LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.InquiryUnitPrice__c = 5.41;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
        testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = ls.Id;
		testOppProd1.ID_ERP__c = '0009';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = pricebookEntry.UnitPrice;


		t.start();
		insert testOppProd1;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, InquiryQuantity__c, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c FROM OpportunityLineItem WHERE ID_ERP__c = '0009'];
		System.assertEquals(18484.288, opp.InquiryQuantity__c);
		System.assertEquals(100, ((Decimal) opp.Quantity).setScale(2));
		System.assertEquals(18484.29, ((Decimal) opp.Quantity_m__c).setScale(2));
		System.assertEquals(60643.99, ((Decimal) opp.Quantity_ft__c).setScale(2));
		System.assertEquals(3187, ((Decimal) opp.Quantity_pcs__c));
	}


	@isTest
	public static void test_QuantityPopulationOnOLIWithTInsert() {
		PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		Opportunity testOpp = [SELECT ID FROM Opportunity LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '34';
		testOppProd1.InquiryQuantity__c = 100;
		testOppProd1.InquiryUnitPrice__c = 1000;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
        testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = ls.Id;
		testOppProd1.ID_ERP__c = '0009';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = pricebookEntry.UnitPrice;


		t.start();
		insert testOppProd1;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, InquiryQuantity__c, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c FROM OpportunityLineItem WHERE ID_ERP__c = '0009'];
		System.assertEquals(100, opp.InquiryQuantity__c);
		System.assertEquals(100, ((Decimal) opp.Quantity).setScale(2));
		System.assertEquals(18484.29, ((Decimal) opp.Quantity_m__c).setScale(2));
		System.assertEquals(60643.99, ((Decimal) opp.Quantity_ft__c).setScale(2));
		System.assertEquals(3187, ((Decimal) opp.Quantity_pcs__c));
	}

	@isTest
	public static void test_QuantityPopulationOnOLIWithFTInsert() {
		PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		Opportunity testOpp = [SELECT ID FROM Opportunity LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '74'; //lbs
		testOppProd1.InquiryQuantity__c = 60643.99;
		testOppProd1.InquiryUnitPrice__c = 1.65;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
        testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = ls.Id;
		testOppProd1.ID_ERP__c = '0009';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = pricebookEntry.UnitPrice;


		t.start();
		insert testOppProd1;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, InquiryQuantity__c, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c FROM OpportunityLineItem WHERE ID_ERP__c = '0009'];
		System.assertEquals(60643.99, opp.InquiryQuantity__c);
		System.assertEquals(100, ((Decimal) opp.Quantity).setScale(2));
		System.assertEquals(18484.29, ((Decimal) opp.Quantity_m__c).setScale(2));
		System.assertEquals(60643.99, ((Decimal) opp.Quantity_ft__c).setScale(2));
		System.assertEquals(3187, ((Decimal) opp.Quantity_pcs__c));
	}

	@isTest
	public static void test_QuantityPopulationOnOLIWithPCSInsert() {
		PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		Opportunity testOpp = [SELECT ID FROM Opportunity LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '43';
		testOppProd1.InquiryQuantity__c = 3187;
		testOppProd1.InquiryUnitPrice__c = 31.38;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
        testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = ls.Id;
		testOppProd1.ID_ERP__c = '0009';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = pricebookEntry.UnitPrice;


		t.start();
		insert testOppProd1;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, InquiryQuantity__c, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c FROM OpportunityLineItem WHERE ID_ERP__c = '0009'];
		System.assertEquals(3187, opp.InquiryQuantity__c);
		System.assertEquals(100, ((Decimal) opp.Quantity).setScale(2));
		System.assertEquals(18484.60, ((Decimal) opp.Quantity_m__c).setScale(2));
		System.assertEquals(60645.01, ((Decimal) opp.Quantity_ft__c).setScale(2));
		System.assertEquals(3187, ((Decimal) opp.Quantity_pcs__c));
	}


	@isTest
	public static void test_QuantityPopulationOnOLIUpdate() {
		OpportunityLineItem testOppLI = [SELECT Id, Stage__c FROM OpportunityLineItem WHERE ID_ERP__c = '0001' LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		testOppLI.InquiryUnit__c = '34';
		testOppLI.LengthSize__c = ls.Id;

		t.start();
		update testOppLI;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c FROM OpportunityLineItem WHERE Id = :testOppLI.Id];
		System.debug('---> Quantity: ' + opp.Quantity);
		System.debug('---> Quantity (m): ' + opp.Quantity_m__c);
		System.debug('---> Quantity (ft): ' + opp.Quantity_ft__c);
		System.debug('---> Quantity (pcs): ' + opp.Quantity_pcs__c);
		System.assertEquals(18484.29, ((Decimal) opp.Quantity).setScale(2));
		System.assertEquals(3416689.09, ((Decimal) opp.Quantity_m__c).setScale(2));
		System.assertEquals(11209609.89, ((Decimal) opp.Quantity_ft__c).setScale(2));
		System.assertEquals(589085, ((Decimal) opp.Quantity_pcs__c));
	}


	@isTest
	public static void test_namePopulationOnOLIODUpdateBulk() {
		List<OpportunityLineItem> listToInsert = new List<OpportunityLineItem> ();
		PricebookEntry pb = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		Opportunity testOpp = [SELECT Id, StageName FROM Opportunity];

		for (Integer i = 0; i< 10; i++) {
			OpportunityLineItem testOppLI = t.newOpportunityProducts(pb.Id, testOpp.Id) [0];
			testOppLI.Quantity = 1;
			testOppLI.InquiryUnitPrice__c = 1000;
			testOppLI.InquiryQuantity__c = 100;
			testOppLI.InquiryUnit__c = '34';
			testOppLI.ProductType__c = 'Tube';
			testOppLI.TubeOD__c = od.Id;
			testOppLI.TubeWT__c = wt.Id;
			testOppLI.Weight_kpm__c = 5.41;
			testOppLI.Weight_ppf__c = 3.63;
			testOppLI.LengthSize__c = ls.Id;
			listToInsert.add(testOppLI);
		}
		insert listToInsert;
		SteelGrade__c sg = new SteelGrade__c(Name = 'testSG', ShortName__c = 'test');
		insert sg;
		for (OpportunityLineItem oli : listToInsert) {
			oli.SteelGrade__c = sg.Id;
		}

		t.start();
		update listToInsert;
		t.stop();

		List<OpportunityLineItem> opp = [SELECT Id, Name__c FROM OpportunityLineItem WHERE ProductType__c = 'Tube'];
		String expextedName = sg.Name + ' ' + od.OD_mm__c + 'x' + wt.WT_mm__c + ' ' + ls.Name;
		for (OpportunityLineItem oli : opp) {
			//System.assertEquals(expextedName, oli.Name__c);
		}
	}

	@isTest
	public static void test_namePopulationOnOLIInsert() {
		PricebookEntry pb = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];

		Opportunity testOpp = [SELECT Id, StageName FROM Opportunity];
		OpportunityLineItem testOppLI = t.newOpportunityProducts(pb.Id, testOpp.Id) [0];
		testOppLI.Quantity = 1;
		testOppLI.InquiryUnitPrice__c = 1000;
		testOppLI.InquiryQuantity__c = 100;
		testOppLI.InquiryUnit__c = '34';
		testOppLI.ID_ERP__c = '0003';
		testOppLI.ProductType__c = 'Tube';
		testOppLI.TubeOD__c = od.Id;
		testOppLI.TubeWT__c = wt.Id;
		testOppLI.Weight_kpm__c = 5.41;
        testOppLI.Weight_ppf__c = 3.63;
		testOppLI.LengthSize__c = ls.Id;


		t.start();
		insert testOppLI;
		t.stop();

		OpportunityLineItem opp = [SELECT Id, Name__c FROM OpportunityLineItem WHERE Id = :testOppLI.Id];
		String expextedName = od.OD_mm__c + 'x' + wt.WT_mm__c + ' ' + ls.Name;
		System.assertEquals(expextedName, opp.Name__c);
	}

	@isTest
	public static void test_namePopulationOnOLIInsertBulk() {
		List<OpportunityLineItem> listToInsert = new List<OpportunityLineItem> ();
		PricebookEntry pb = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
		TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
		TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
		TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
		Opportunity testOpp = [SELECT Id, StageName FROM Opportunity];

		for (Integer i = 0; i< 10; i++) {
			OpportunityLineItem testOppLI = t.newOpportunityProducts(pb.Id, testOpp.Id) [0];
			testOppLI.Quantity = 1;
			testOppLI.InquiryUnitPrice__c = 1000;
			testOppLI.InquiryQuantity__c = 100;
			testOppLI.InquiryUnit__c = '34';
			testOppLI.ProductType__c = 'Axle';
			testOppLI.TubeOD__c = od.Id;
			testOppLI.TubeWT__c = wt.Id;
			testOppLI.Weight_kpm__c = 5.41;
			testOppLI.Weight_ppf__c = 3.63;
			testOppLI.LengthSize__c = ls.Id;
			listToInsert.add(testOppLI);
		}

		t.start();
		insert listToInsert;
		t.stop();

		List<OpportunityLineItem> opp = [SELECT Id, Name__c FROM OpportunityLineItem WHERE ProductType__c = 'Axle'];
		String expextedName = od.OD_mm__c + 'x' + wt.WT_mm__c + ' ' + ls.Name;
		for (OpportunityLineItem oli : opp) {
			System.assertEquals(expextedName, oli.Name__c);
		}
	}

	@isTest
	public static void test_QuoteProductionDeliveryChangeOnOLICDDUpdate() {
		OpportunityLineItem testOppLI = [SELECT OpportunityId, CDD__c FROM OpportunityLineItem WHERE ID_ERP__c = '0001' LIMIT 1];
		testOppLI.CDD__c = Date.today();

		t.start();
		update testOppLI;
		t.stop();

		List<Quote> quotes = [SELECT Production_Delivery__c FROM Quote WHERE OpportunityId = :testOppLI.OpportunityId];
		for (Quote qu : quotes) {
			System.assertEquals(Date.today().format(), qu.Production_Delivery__c);
		}
	}

	@isTest
	public static void test_QuoteInvoicingChangeOnOLIInquiryUnitUpdate() {
		OpportunityLineItem testOppLI = [SELECT OpportunityId, InquiryUnit__c FROM OpportunityLineItem WHERE ID_ERP__c = '0001' LIMIT 1];
		testOppLI.InquiryUnit__c = '34';

		t.start();
		update testOppLI;
		t.stop();

		List<Quote> quotes = [SELECT Invoicing__c FROM Quote WHERE OpportunityId = :testOppLI.OpportunityId];
		for (Quote qu : quotes) {
			System.assertEquals('USD, t', qu.Invoicing__c);
		}
	}
    
    @isTest
    public static void testSetFamilyField(){
        Opportunity opp = [SELECT Product_Family__c FROM Opportunity LIMIT 1];
        List<String> listOfValues = opp.Product_Family__c.split(';');
        System.assertEquals(2, listOfValues.size(),'not expected value');
    }
    
    @isTest
    public static void testChangeFamilyFieldOnDelete(){
        Opportunity opp = [SELECT Product_Family__c FROM Opportunity LIMIT 1];
        opportunitylineitem forDelete= [select id,product2id,product2.family from opportunitylineitem where opportunityId =:opp.id limit 1];
        system.debug('--------------------------------------------------------------------------------------------------------------------------------------------------------------------');
        system.debug(forDelete.Product2Id);
        system.debug(forDelete.product2.family);
        List<String> listOfValues = opp.Product_Family__c.split(';');
        System.assertEquals(2, listOfValues.size(),'not expected value');
        
        t.start();
        delete forDelete;
        t.stop();
        
        Opportunity oppAfterDeletedItem = [SELECT Product_Family__c FROM Opportunity where id=:opp.id LIMIT 1];
        List<String> listOfValues2 = oppAfterDeletedItem.Product_Family__c.split(';');
        System.assertEquals(1, listOfValues2.size(),'not expected value');
    }

   
	/*@isTest
	  public static void test_factCreationOnOLIInsert(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
	  Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
	  TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
	  TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
	  TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];   
	  Shop__c shop = new Shop__c();
	  insert shop;
	  OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id)[0];
	  testOppProd1.InquiryUnit__c = '34';
	  testOppProd1.InquiryQuantity__c = 1;
	  testOppProd1.InquiryUnitPrice__c = 1;
	  testOppProd1.TubeOD__c = od.Id;
	  testOppProd1.TubeWT__c = wt.Id;
	  testOppProd1.LengthSize__c = ls.Id;
	  testOppProd1.ID_ERP__c = '0009';
	  testOppProd1.ProductType__c = 'Tube';
	  testOppProd1.UnitPrice = pricebookEntry.UnitPrice;
	  testOppProd1.Shop__c = shop.Id;
	 
	  t.start();
	  insert testOppProd1;
	  t.stop();
	 
	  OpportunityLineItem oli = [SELECT Product2Id, Test_Field_For_Fact__c FROM OpportunityLineItem WHERE Id=:testOppProd1.Id];
	  List<SalesBudget__c> fact = [SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c=:shop.Id AND RecordTypeId=:factRT.Id];
	 
	  System.assertEquals(1, fact.size());
	  System.assertEquals(testOpp.OwnerId, fact[0].SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), fact[0].Period__c);
	  System.assertEquals(oli.Product2Id, fact[0].Product__c);
	  System.assertEquals(1, fact[0].ProductionAmount__c);
	  System.assertEquals(0, fact[0].SalesAmount__c);
	  System.assertEquals(fact[0].Id, oli.Test_Field_For_Fact__c);
	  }
	 
	  @isTest
	  public static void test_factCreationOnOLIWithNeededStageInsert(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
	  Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
	  TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
	  TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
	  TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];   
	  Shop__c shop = new Shop__c();
	  insert shop;
	  OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id)[0];
	  testOppProd1.InquiryUnit__c = '34';
	  testOppProd1.InquiryQuantity__c = 1;
	  testOppProd1.InquiryUnitPrice__c = 1;
	  testOppProd1.TubeOD__c = od.Id;
	  testOppProd1.TubeWT__c = wt.Id;
	  testOppProd1.LengthSize__c = ls.Id;
	  testOppProd1.ID_ERP__c = '0009';
	  testOppProd1.ProductType__c = 'Tube';
	  testOppProd1.UnitPrice = pricebookEntry.UnitPrice;
	  testOppProd1.Shop__c = shop.Id;
	  testOppProd1.Stage__c = 'Shipped';
	 
	  t.start();
	  insert testOppProd1;
	  t.stop();
	 
	  OpportunityLineItem oli = [SELECT Product2Id, Test_Field_For_Fact__c FROM OpportunityLineItem WHERE Id=:testOppProd1.Id];
	  List<SalesBudget__c> fact = [SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c=:shop.Id AND RecordTypeId=:factRT.Id];
	 
	  System.assertEquals(1, fact.size());
	  System.assertEquals(testOpp.OwnerId, fact[0].SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), fact[0].Period__c);
	  System.assertEquals(oli.Product2Id, fact[0].Product__c);
	  System.assertEquals(0, fact[0].ProductionAmount__c);
	  System.assertEquals(1, fact[0].SalesAmount__c);
	  System.assertEquals(fact[0].Id, oli.Test_Field_For_Fact__c);
	  }
	 
	  @isTest
	  public static void test_ManyFactCreationOnOLIInsertBulk(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
	  Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
	  TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
	  TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
	  TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];  
	  List<Shop__c> shops = new List<Shop__c>(); 
	  for(Integer i=0; i<10; i++) {
	  shops.add(new Shop__c());
	  }
	  insert shops;
	  List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
	  for(Integer i=0; i<10; i++) {
	  OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id)[0];
	  testOppProd1.InquiryUnit__c = '34';
	  testOppProd1.InquiryQuantity__c = 1;
	  testOppProd1.InquiryUnitPrice__c = 1;
	  testOppProd1.TubeOD__c = od.Id;
	  testOppProd1.TubeWT__c = wt.Id;
	  testOppProd1.UnitPrice = pricebookEntry.UnitPrice;
	  testOppProd1.Shop__c = shops[i].Id;
	  System.debug(shops[i].Id);
	  oliList.add(testOppProd1);
	  }
	 
	  t.start();
	  insert oliList;
	  t.stop();
	 
	  Map<Id, SalesBudget__c> factsMap = new Map<Id, SalesBudget__c>([SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c!=null AND RecordTypeId=:factRT.Id]);
	  List<OpportunityLineItem> insertedOLIList = [SELECT Product2Id, Test_Field_For_Fact__c FROM OpportunityLineItem WHERE Test_Field_For_Fact__c IN :factsMap.keySet()];
	 
	  System.assertEquals(10, factsMap.size());
	  for(SalesBudget__c fact : factsMap.values()) {
	  System.assertEquals(testOpp.OwnerId, fact.SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), fact.Period__c);
	  System.assertEquals(insertedOLIList[0].Product2Id, fact.Product__c);
	  System.assertEquals(1, fact.ProductionAmount__c);
	  System.assertEquals(0, fact.SalesAmount__c);
	  }
	  }
	 
	  @isTest
	  public static void test_OneFactCreationOnOLIInsertBulk(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
	  Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
	  TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
	  TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
	  TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];
	  Shop__c shop = new Shop__c();
	  insert shop;
	  List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
	  for(Integer i=0; i<10; i++) {
	  OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id)[0];
	  testOppProd1.InquiryUnit__c = '34';
	  testOppProd1.InquiryQuantity__c = 1;
	  testOppProd1.InquiryUnitPrice__c = 1;
	  testOppProd1.TubeOD__c = od.Id;
	  testOppProd1.TubeWT__c = wt.Id;
	  testOppProd1.UnitPrice = pricebookEntry.UnitPrice;
	  testOppProd1.Shop__c = shop.Id;
	  if(i==2 || i==3 || i==4) {
	  testOppProd1.Stage__c = 'Shipped';
	  }
	  oliList.add(testOppProd1);
	  }
	 
	  t.start();
	  insert oliList;
	  t.stop();
	 
	  List<SalesBudget__c> factsList = [SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c=:shop.Id AND RecordTypeId=:factRT.Id];
	  List<OpportunityLineItem> insertedOLIList = [SELECT Product2Id, Test_Field_For_Fact__c FROM OpportunityLineItem WHERE Test_Field_For_Fact__c = :factsList[0].Id];
	 
	  System.assertEquals(1, factsList.size());
	  System.assertEquals(10, insertedOLIList.size());
	  System.assertEquals(testOpp.OwnerId, factsList[0].SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), factsList[0].Period__c);
	  System.assertEquals(insertedOLIList[0].Product2Id, factsList[0].Product__c);
	  System.assertEquals(7, factsList[0].ProductionAmount__c);
	  System.assertEquals(3, factsList[0].SalesAmount__c);
	  }
	 
	  @isTest
	  public static void test_factCreationOnOLIWithDifferentStagesInsertBulk(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
	  Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
	  TubeOD__c od = [SELECT Id, OD_mm__c FROM TubeOD__c LIMIT 1];
	  TubeWT__c wt = [SELECT Id, WT_mm__c FROM TubeWT__c LIMIT 1];
	  TubeLengthSize__c ls = [SELECT Id, Name FROM TubeLengthSize__c LIMIT 1];  
	  List<Shop__c> shops = new List<Shop__c>(); 
	  for(Integer i=0; i<10; i++) {
	  shops.add(new Shop__c());
	  }
	  insert shops;
	  List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
	  for(Integer i=0; i<10; i++) {
	  OpportunityLineItem testOppProd1 = t.newOpportunityProducts(pricebookEntry.Id, testOpp.Id)[0];
	  testOppProd1.InquiryUnit__c = '34';
	  testOppProd1.InquiryQuantity__c = 1;
	  testOppProd1.InquiryUnitPrice__c = 1;
	  testOppProd1.TubeOD__c = od.Id;
	  testOppProd1.TubeWT__c = wt.Id;
	  testOppProd1.UnitPrice = pricebookEntry.UnitPrice;
	  testOppProd1.Shop__c = shops[i].Id;
	  System.debug(shops[i].Id);
	  if(i==2 || i==3 || i==4) {
	  testOppProd1.Stage__c = 'Shipped';
	  }
	  oliList.add(testOppProd1);			
	  }
	 
	  t.start();
	  insert oliList;
	  t.stop();
	 
	  Map<Id, SalesBudget__c> factsMap = new Map<Id, SalesBudget__c>([SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c!=null AND RecordTypeId=:factRT.Id]);
	  OpportunityLineItem insertedOLI = [SELECT Product2Id, Test_Field_For_Fact__c FROM OpportunityLineItem WHERE Test_Field_For_Fact__c IN :factsMap.keySet() LIMIT 1];
	 
	  System.assertEquals(10, factsMap.size());
	 
	  for(SalesBudget__c fact : factsMap.values()) {
	  if(fact.Shop__c == shops[2].Id || fact.Shop__c == shops[3].Id || fact.Shop__c == shops[4].Id) {
	  System.assertEquals(testOpp.OwnerId, fact.SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), fact.Period__c);
	  System.assertEquals(insertedOLI.Product2Id, fact.Product__c);
	  System.assertEquals(0, fact.ProductionAmount__c);
	  System.assertEquals(1, fact.SalesAmount__c);
	  } else {
	  System.assertEquals(testOpp.OwnerId, fact.SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), fact.Period__c);
	  System.assertEquals(insertedOLI.Product2Id, fact.Product__c);
	  System.assertEquals(1, fact.ProductionAmount__c);
	  System.assertEquals(0, fact.SalesAmount__c);
	  }
	  }
	  }
	 
	  @isTest
	  public static void test_newFactOnOLIUpdate(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  List<Shop__c> shops = new List<Shop__c>(); 
	  Shop__c shop = new Shop__c();
	  insert shop;
	  OpportunityLineItem oli = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  oli.Shop__c = shop.Id;
	 
	  t.start();
	  System.debug('start Update OLI');
	  update oli;
	  System.debug('stop Update OLI');
	  t.stop();
	 
	  OpportunityLineItem selectedOLI = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem WHERE Id=:oli.Id];
	  List<SalesBudget__c> newFact = [SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Shop__c=:shop.Id AND RecordTypeId=:factRT.Id];
	  SalesBudget__c previousFactAfter = [SELECT ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	 
	  System.assertEquals(1, newFact.size());
	  System.assertNotEquals(previousFactAfter.Id, newFact[0].Id);
	  System.assertEquals(selectedOLI.Opportunity.OwnerId, newFact[0].SalesManager__c);
	  System.assertEquals(Date.today().toStartOfMonth(), newFact[0].Period__c);
	  System.assertEquals(selectedOLI.Product2Id, newFact[0].Product__c);
	  System.assertEquals(selectedOLI.Quantity, newFact[0].ProductionAmount__c);
	  System.assertEquals(0, newFact[0].SalesAmount__c);
	  System.assertEquals(newFact[0].Id, selectedOLI.Test_Field_For_Fact__c);
	  System.assertEquals(previousFactBefore.ProductionAmount__c - oli.Quantity, previousFactAfter.ProductionAmount__c);
	  System.assertEquals(0, previousFactAfter.SalesAmount__c);
	  }
	 
	  @isTest
	  public static void test_updateFactOnOLIStageUpdate(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  List<Shop__c> shops = new List<Shop__c>(); 
	  Shop__c shop = new Shop__c();
	  insert shop;
	  OpportunityLineItem oli = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  oli.Stage__c = 'Shipped';
	 
	  t.start();
	  System.debug('start Update OLI');
	  update oli;
	  System.debug('stop Update OLI');
	  t.stop();
	 
	  OpportunityLineItem selectedOLI = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem WHERE Id=:oli.Id];
	  SalesBudget__c previousFactAfter = [SELECT ProductionAmount__c, SalesAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	 
	  System.assertEquals(oli.Test_Field_For_Fact__c, selectedOLI.Test_Field_For_Fact__c);
	  System.assertNotEquals(previousFactBefore.ProductionAmount__c, previousFactAfter.ProductionAmount__c);
	  System.assertEquals(0, previousFactAfter.ProductionAmount__c);
	  System.assertNotEquals(previousFactBefore.SalesAmount__c, previousFactAfter.SalesAmount__c);
	  System.assertEquals(selectedOLI.Quantity, previousFactAfter.SalesAmount__c);
	  }
	 
	  @isTest
	  public static void test_factUpdateOnOLIUpdate(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  OpportunityLineItem oli = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  oli.Quantity = oli.Quantity + 100;
	 
	  t.start();
	  update oli;
	  t.stop();
	 
	  SalesBudget__c previousFactAfter = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	 
	  System.assertEquals(previousFactBefore.ProductionAmount__c + 100, previousFactAfter.ProductionAmount__c);
	  }
	 
	  @isTest
	  public static void test_factUpdateOnOppCloseDateInTheSameMonthUpdate(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  OpportunityLineItem oli = [SELECT Opportunity.OwnerId, OpportunityId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  Opportunity opp = [SELECT CloseDate FROM Opportunity WHERE Id = :oli.OpportunityId];
	  opp.CloseDate = Date.today().toStartOfMonth();
	 
	  t.start();
	  update opp;
	  t.stop();
	 
	  OpportunityLineItem selectedOLI = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem WHERE Id=:oli.Id];
	 
	  System.assertEquals(previousFactBefore.Id, selectedOLI.Test_Field_For_Fact__c);
	  }
	 
	  @isTest
	  public static void test_factUpdateOnOppCloseDateInAnotherMonthUpdate(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  OpportunityLineItem oli = [SELECT Shop__c, Opportunity.OwnerId, OpportunityId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  Opportunity opp = [SELECT OwnerId, CloseDate FROM Opportunity WHERE Id = :oli.OpportunityId];
	  Date newDate = Date.today().addDays(33);
	  opp.CloseDate = newDate;
	 
	  t.start();
	  update opp;
	  t.stop();
	 
	  OpportunityLineItem selectedOLI = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem WHERE Id=:oli.Id];
	  SalesBudget__c previousFactAfter = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	  SalesBudget__c newFact = [SELECT Shop__c, SalesManager__c, Period__c, Product__c, ProductionAmount__c FROM SalesBudget__c WHERE Id=:selectedOLI.Test_Field_For_Fact__c];
	 
	  System.assertEquals(0, previousFactAfter.ProductionAmount__c);
	  System.assertNotEquals(previousFactAfter.Id, selectedOLI.Test_Field_For_Fact__c);
	  System.assertEquals(opp.OwnerId, newFact.SalesManager__c);
	  System.assertEquals(newDate.toStartOfMonth(), newFact.Period__c);
	  System.assertEquals(oli.Product2Id, newFact.Product__c);
	  System.assertEquals(oli.Quantity, newFact.ProductionAmount__c);
	  System.assertEquals(oli.Shop__c, newFact.Shop__c);
	  }
	 
	  @isTest
	  public static void test_factUpdateOnOLIDelete(){
	  RecordType factRT = [select id from RecordType where sObjecttype ='SalesBudget__c' and Name='Fact Month'];
	  OpportunityLineItem oli = [SELECT Opportunity.OwnerId, Product2Id, Test_Field_For_Fact__c, Quantity FROM OpportunityLineItem LIMIT 1];
	  SalesBudget__c previousFactBefore = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	 
	  t.start();
	  delete oli;
	  t.stop();
	 
	  SalesBudget__c previousFactAfter = [SELECT ProductionAmount__c FROM SalesBudget__c WHERE Id=:oli.Test_Field_For_Fact__c];
	 
	  System.assertEquals(previousFactBefore.ProductionAmount__c - oli.Quantity, previousFactAfter.ProductionAmount__c);
	  }*/

	@testSetup
	static void testSetup() {

		Account testAccount = t.newAccounts('Test Account') [0];
		testAccount.ID_ERP__c = '1';
		testAccount.MarketSegment__c = '00004';
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

		QuotaType__c qt = new QuotaType__c(ID_ERP__c = 'qt', Name = 'testQT');
		insert qt;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 18484.288;
		testOppProd1.Quantity = 100;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		testOppProd1.Weight_kpm__c = 5.41;
		testOppProd1.Weight_ppf__c = 3.63;
		testOppProd1.LengthSize__c = size.Id;
		testOppProd1.ID_ERP__c = '0001';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.UnitPrice = testPriceBookEntry1.UnitPrice;
		testOppProd1.InquiryUnitPrice__c = 5.41;
		testOppProd1.QuotaType__c = qt.Id;
		insert testOppProd1;
		OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, testOpp.Id) [0];
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.Quantity = 100;
		testOppProd2.InquiryQuantity__c = 18484.288;
		testOppProd2.ID_ERP__c = '0002';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.InquiryUnitPrice__c = 5.41;
		testOppProd2.QuotaType__c = qt.Id;
		insert testOppProd2;
		List<Quote> quotes = new List<Quote> ();
		for (Integer i = 0; i< 5; i++) {
			quotes.add(new Quote(Name = 'Test' + i, OpportunityId = testOpp.Id, Pricebook2Id = Test.getStandardPricebookId()));
		}
		insert quotes;
	}

	static { BaseTest.t = new OpportunityLineItemHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}