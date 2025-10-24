@isTest
private class QuoteLineItemTriggerHandlerTest extends BaseTest {
    
	@isTest static void testFillQLIasOLI() {
		OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
														ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
														ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
														FROM OpportunityLineItem LIMIT 1];
		Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
		insert testQuote;
		QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, InquiryUnit__c='34', Product2Id = oli.Product2Id);
		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
		t.start();
		insert qli;
		t.stop();

		QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
														ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, 
														ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
														FROM QuoteLineItem LIMIT 1];
		System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
		System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
		System.assertEquals(oli.InquiryUnit__c, insertedQLI.InquiryUnit__c);
		System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
		System.assertEquals(oli.Name__c, insertedQLI.Name__c);
		System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
		System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
		System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
		System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
		System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
		System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
		System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
		System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
		System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
    }
    


	@isTest static void testUpdateQLIFirstGroupTo34() {
		OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM OpportunityLineItem LIMIT 1];
		Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
		insert testQuote;
		QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
		insert qli;
		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
        
		t.start();
		qli.InquiryUnit__c = '34';
		update qli;
		t.stop();

		QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM QuoteLineItem LIMIT 1];
		System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
		System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
		System.assertEquals('34', insertedQLI.InquiryUnit__c);
		System.assertEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
		//System.assertNotEquals(oli.UnitPrice, insertedQLI.UnitPrice);
		System.assertNotEquals(oli.Quantity, insertedQLI.Quantity);
		System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
		System.assertEquals(oli.Name__c, insertedQLI.Name__c);
		System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
		System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
		System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
		System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
		System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
		System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
		System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
		System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
		System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
	}



	@isTest static void testUpdateQLIFirstGroupTo74() {
		OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM OpportunityLineItem LIMIT 1];
		Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
		insert testQuote;
		QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
		insert qli;
		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
        
		t.start();
		qli.InquiryUnit__c = '74';
		update qli;
		t.stop();

		QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM QuoteLineItem LIMIT 1];
		System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
		System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
		System.assertEquals('74', insertedQLI.InquiryUnit__c);
		System.assertEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
		System.assertNotEquals(oli.Quantity, insertedQLI.Quantity);
		//System.assertNotEquals(oli.UnitPrice, insertedQLI.UnitPrice);
		System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
		System.assertEquals(oli.Name__c, insertedQLI.Name__c);
		System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
		System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
		System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
		System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
		System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
		System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
		System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
		System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
		System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
	}



	@isTest static void testUpdateQLIFirstGroupTo43() {
		OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM OpportunityLineItem LIMIT 1];
		Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
		insert testQuote;
		QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
		insert qli;
		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
        
		t.start();
		qli.InquiryUnit__c = '43';
		update qli;
		t.stop();

		QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
								ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
								ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
								FROM QuoteLineItem LIMIT 1];
		System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
		System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
		System.assertEquals('43', insertedQLI.InquiryUnit__c);
		System.assertEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
		System.assertNotEquals(oli.Quantity, insertedQLI.Quantity);
		//System.assertNotEquals(oli.UnitPrice, insertedQLI.UnitPrice);
		System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
		System.assertEquals(oli.Name__c, insertedQLI.Name__c);
		System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
		System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
		System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
		System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
		System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
		System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
		System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
		System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
		System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
	}

  @isTest static void testUpdateQLIFirstGroupTo20() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
	oli.InquiryUnit__c = '34';
    update oli;	
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;	
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 

    t.start();
    qli.InquiryUnit__c = '20';
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals('20', insertedQLI.InquiryUnit__c);
	System.assertEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
	//Bahtiyar {
	//System.assertEquals(oli.Quantity, insertedQLI.Quantity);
	//System.assertEquals(oli.UnitPrice.setScale(2), insertedQLI.UnitPrice.setScale(2));
	//Bahtiyar }
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLIFirstGroupInqQuantity() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
      
    t.start();
    qli.InquiryQuantity__c = 656;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals(oli.InquiryUnit__c, insertedQLI.InquiryUnit__c);
	System.assertNotEquals(oli.Quantity, insertedQLI.Quantity);
	//System.assertEquals(oli.UnitPrice.setScale(2), insertedQLI.UnitPrice.setScale(2));
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(656, insertedQLI.InquiryQuantity__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLIFirstGroupInqUnitPrice() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
      
    t.start();
    qli.InquiryUnitPrice__c = 874;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, UnitPrice, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals(oli.InquiryUnit__c, insertedQLI.InquiryUnit__c);
	System.assertEquals(874, insertedQLI.InquiryUnitPrice__c);
	//System.assertEquals(oli.Quantity, insertedQLI.Quantity);
	//System.assertNotEquals(oli.UnitPrice, insertedQLI.UnitPrice);
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLISecondGroupWith20() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	QuoteLineItem insertedQLI1 = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, Quantity, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem WHERE Id=:qli.Id LIMIT 1];
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
      
    t.start();
    qli.UnitPrice = 60000;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, Quantity, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem WHERE Id=:qli.Id LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals(oli.InquiryUnit__c, insertedQLI.InquiryUnit__c);
	System.assertEquals(60000, insertedQLI.UnitPrice);
	System.assertEquals(insertedQLI1.Quantity, insertedQLI.Quantity);
	//Bahtiyar {
	//System.assertEquals(insertedQLI1.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
	//System.assertNotEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
	//Bahtiyar }
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLISecondGroupWith74() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];    
	oli.InquiryUnit__c = '74';
    update oli;
	Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 

    t.start();
    qli.UnitPrice = 60000;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem WHERE Id=:qli.Id LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals('74', insertedQLI.InquiryUnit__c);
	System.assertEquals(60000, insertedQLI.UnitPrice);
	//System.assertNotEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
	System.assertNotEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLISeconfGroupWith43() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
	oli.InquiryUnit__c = '43';
	update oli;
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
      
    t.start();
    qli.UnitPrice = 60000;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem WHERE Id=:qli.Id LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals('43', insertedQLI.InquiryUnit__c);
	System.assertEquals(60000, insertedQLI.UnitPrice);
	//System.assertNotEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
	System.assertNotEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLISeconfGroupWith34() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
    oli.InquiryUnit__c = '34';
    update oli;
	Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 

    t.start();
    qli.UnitPrice = 60000;
    update qli;
    t.stop();

    QuoteLineItem insertedQLI = [SELECT Id, TubeEnds__c, TubeLengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM QuoteLineItem WHERE Id=:qli.Id LIMIT 1];
    System.assertEquals(oli.TubeEnds__c, insertedQLI.TubeEnds__c);
    System.assertEquals(oli.LengthSize__c, insertedQLI.TubeLengthSize__c);
    System.assertEquals('34', insertedQLI.InquiryUnit__c);
	System.assertEquals(60000, insertedQLI.UnitPrice);
	//System.assertNotEquals(oli.InquiryQuantity__c, insertedQLI.InquiryQuantity__c);
	System.assertNotEquals(oli.InquiryUnitPrice__c, insertedQLI.InquiryUnitPrice__c);
    System.assertEquals(oli.TubeOD__c, insertedQLI.TubeOD__c);
    System.assertEquals(oli.Name__c, insertedQLI.Name__c);
    System.assertEquals(oli.ProductSpecLevel__c, insertedQLI.ProductSpecLevel__c);
    System.assertEquals(oli.ProductStandard__c, insertedQLI.ProductStandard__c);
    System.assertEquals(oli.ShippingPoint__c, insertedQLI.ShippingPoint__c);
    System.assertEquals(oli.Shop__c, insertedQLI.Shop__c);
    System.assertEquals(oli.SteelGrade__c, insertedQLI.SteelGrade__c);
    System.assertEquals(oli.Weight_kpm__c, insertedQLI.Weight_kpm__c);
    System.assertEquals(oli.Weight_ppf__c, insertedQLI.Weight_ppf__c);
    System.assertEquals(oli.TubeWT__c, insertedQLI.TubeWT__c);
  }

  @isTest static void testUpdateQLIBothGroupsError() {
    OpportunityLineItem oli = [SELECT Id, OpportunityId, PriceBookEntryId, Product2Id, TubeEnds__c, LengthSize__c, InquiryUnit__c, TubeOD__c, Name__c, 
                            ProductSpecLevel__c, ProductStandard__c, InquiryQuantity__c, InquiryUnitPrice__c, Quantity, UnitPrice, 
                            ShippingPoint__c, Shop__c, SteelGrade__c, Weight_kpm__c, Weight_ppf__c, TubeWT__c
                            FROM OpportunityLineItem LIMIT 1];
    Quote testQuote = new Quote(Name='Test',ExpirationDate = Date.Today(), OpportunityId = oli.OpportunityId, Pricebook2Id = Test.getStandardPricebookId());
    insert testQuote;
    QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = testQuote.Id, PriceBookEntryId = oli.PriceBookEntryId, Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
    insert qli;
	Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testQuote.Id, '123456', '22222')); 
      
    t.start();
    qli.UnitPrice = 60000;
	qli.InquiryUnit__c = '34';
    try {
		update qli;
	} catch (Exception e) {
		Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot change inquiry measurement unit values and metric tonn values at once. Please, cancel one of these changes.') ? true : false;
		System.AssertEquals(true, expectedExceptionThrown);
	}
    t.stop();    
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
    private class ERP_WebServiceMock implements WebServiceMock {

		String oppId;
		String ERP_ID;
		String SyncDateTime;
		String isError;

		public ERP_WebServiceMock(String oppId, String ERP_Id, String SyncDateTime, String isError) {
			//this(oppId, ERP_Id);
			this.oppId = oppId;
			this.ERP_ID = ERP_Id;
			this.isError = isError;
			this.SyncDateTime = SyncDateTime;
		}

		public ERP_WebServiceMock(String oppId, String ERP_Id, String SyncDateTime) {
			this.oppId = oppId;
			this.ERP_ID = ERP_Id;
			this.SyncDateTime = SyncDateTime;
			isError = '';
		}

		private final String LOGIN_RESPONCE = '{"Success":true,"UserName":"IT_SF","Ticket":"11917DDC-C039-4C59-B010-ED6335073AF7","FailReason":null,"NeedChangePassword":false,"TempPasswordRequired":false,"TempPasswordMessage":null}';
		private final String ACCEPTED_RESPONCE = '{"Success":true,"Comments":""}';
        private final String DENIED_RESPONCE = '{"Success":false,"Comments":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}';
        private final String WRONGJSON_RESPONCE = '"{"Success":false,"Comments":"* ERROR *nЗначение не может быть неопределенным.rnИмя параметра: valuen* INBOUND DATA *n"}"';
		//private final String OPPO_ACCEPTED_RESPONCE = '"{\"Opportunity_ID\":{\"ID_SF\":\"%oppID%\",\"ID_ERP\":\"%erpId%\"}}"';
		private final String ERROR_RESPONSE = '"{\"ErrorType\": \"JSON Data Error\",\"ErrorMessage\": \"Wrong Account_ID_ERP value, expected int.\"}"';

		public void doInvoke(
		                     Object stub,
		                     Object request,
		                     Map<String, Object> response,
		                     String endpoint,
		                     String soapAction,
		                     String requestName,
		                     String responseNS,
		                     String responseName,
		                     String responseType) {

			if (request instanceOf SFToERP.LoginEx_element) {
				SFToERP.LoginExResponse_element resp = new SFToERP.LoginExResponse_element();
				resp.LoginExResult = LOGIN_RESPONCE;
				response.put('response_x', resp);
			} else if (request instanceOf SFToERP.ExecuteEx_element) {
				if(isError.equals('falseSuccess')){
                    SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = DENIED_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
                }else if (isError.equals('exception')) {
					throw new CalloutException('Test');
				}else if (isError.equals('jsonError')) {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = WRONGJSON_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
				}else {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = ACCEPTED_RESPONCE;
					system.debug(request);
					response.put('response_x', resp);
				}
			}
		}
	}
    

	static { BaseTest.t = new QuoteLineItemTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
    
}