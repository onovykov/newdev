@isTest
private class OpportunityInfoControllerTest extends BaseTest {

	private final static String JSON_TO_SEND =
	'"JSON" : "' +
	'{' +
	'"MessageType": "SF-ERP_OpportunityData",' +
	'"SyncDateTime": "1528808830725",'+
	'  "General_Data" : {' +
	'   "ID_SF" : "oppo",' +
	'   "Account" : 1,' +
	'   "MarketSegment_ID_ERP" : "Europe",' +
	'   "Country" : "US",' +
	'   "DeliveryTerms" : "002",' +
	'   "PaymentTerms" : "1",' +
	'   "Description" : "Test Description",' +
	'   "Currency" : "USD",' +
	'   "SalesRep_UserId" : "TESTSM",' +
	//'   "Owner": {' +
	//'     "Id": "TESTSM",' +
	//'     "Name": "Sales Manager",' +
	//'     "Email": "testsm@test.com",' +
	//'     "EmployeeNumber": "4321",' +
	//'    }' +
	'   "BOSpecialist_UserId" : "TESTBO",' +
	//'   "BOSpecialist": {' +
	//'     "Id": "TESTBO",' +
	//'     "Name": "Test BO",' +
	//'     "Email": "testbo@test.com",' +
	//'     "EmployeeNumber": "1234",' +
	//'    }' +
	'   "Item" : [' +
	'     {' +
	'     "ID_SF" : "oppoProd1",' +
	'     "ProductGroup" : "pr1",' +
	'     "OD" : "od",' +
	'     "Standard" : "1",' +
	'     "SpecLevel" : "1",' +
	'     "SteelGrade" : "SGRADE1",' +
	'     "WT" : "wt",' +
	'     "Quantity_Mt" : 1.00,' +
	'     "Quantity_m" : 2.0,' +
	'     "Quantity_ft" : 3.00,' +
	'     "Quantity_pcs" : 4,' +
	'     "PriceUnit" : "34",' +
	'     "LengthSize" : "si",' +
	'     "Ends" : "en",' +
	'     "Coating" : "1",' +
	'     "Shop" : "sh",' +
	'     "Price" : 100.00,' +
	//'     "TotalPrice" : 300.00,'+
	'     "ShippingPoint" : "po"' +
	//'     "Description" : "TestDesc"'+
	'     },' +
	'     {' +
	'     "ID_SF" : "oppoProd2",' +
	'     "ProductGroup" : "pr2",' +
	'     "OD" : "od",' +
	'     "Standard" : "1",' +
	'     "SpecLevel" : "1",' +
	'     "SteelGrade" : "SGRADE1",' +
	'     "WT" : "wt",' +
	'     "Quantity_Mt" : 1.00,' +
	'     "Quantity_m" : 2.0,' +
	'     "Quantity_ft" : 3.00,' +
	'     "Quantity_pcs" : 4,' +
	'     "PriceUnit" : "34",' +
	'     "LengthSize" : "si",' +
	'     "Ends" : "en",' +
	'     "Coating" : "1",' +
	'     "Shop" : "sh",' +
	'     "Price" : 100.00,' +
	//'     "TotalPrice" : 300.00,'+
	'     "ShippingPoint" : "po"' +
	//'     "Description" : "TestDesc"'+
	'     }' +
	'   ]' +
	' },' +
	' "New_Customer" : {' +
	'   "BillingCity" : "City",' +
	'   "BillingCountry" : "Ukraine",' +
	'   "BillingState" : "",' +
	'   "BillingStreet" : "Street",' +
	'   "BillingPostalCode" : "12345",' +
	'   "ShippingCity" : "ShipCity",' +
	'   "ShippingCountry" : "Ukraine",' +
	'   "ShippingState" : "",' +
	'   "ShippingStreet" : "ShipStreet",' +
	'   "ShippingPostalCode" : "54321",' +
	'   "Description" : "Test"' +
	' }' +
	'}"';

	@testSetup
	static void testSetup() {

		Country__c country0 = new Country__c(Name = 'test', A2Code__c = '15', A3Code__c = '25', NumCode__c = '0');
		insert country0;

		Shop__c shop_n_s = new Shop__c(Id_ERP__c = '0', Name = 'Not specified');
		insert shop_n_s;

		List<UserLicense> lics = [SELECT Id, Name FROM UserLicense where name = 'Chatter Free'];
		List<Profile> profs = [SELECT UserLicenseId FROM Profile where UserLicenseId = :lics[0].Id];
		List<User> users = new List<User> ();
		User owner_user = t.newUser('testsm@test.com');
		owner_user.SalesDivision__c = '00004';
		owner_user.ID_ERP__c = 'TESTSM';
		owner_user.EmployeeNumber = 'TESTSM';
		owner_user.LoginERP__c = 'TESTSM';
		users.add(owner_user);
		User bo_user = t.newUser('testbo@test.com');
		bo_user.Email = 'testbo@test.com';
		bo_user.ID_ERP__c = 'TESTBO';
		bo_user.ProfileId = profs[0].Id;
		bo_user.SalesDivision__c = '00004';
		bo_user.EmployeeNumber = 'TESTBO';
		bo_user.LoginERP__c = 'TESTBO';
        //
        User ad_user = t.newUser('testad@test.com');
		ad_user.Email = 'testad@test.com';
		ad_user.ID_ERP__c = 'TESTAD';
		ad_user.ProfileId = profs[0].Id;
		ad_user.SalesDivision__c = '00004';
		ad_user.EmployeeNumber = 'TESTAD';
		ad_user.LoginERP__c = 'TESTAD';
        users.add(ad_user);
		//bo_user.UserType = 'CsnOnly';
		users.add(bo_user);
		insert users;

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

		ProductStandard__c qStan = new ProductStandard__c();
		insert qStan;

		SteelGrade__c sGrade = new SteelGrade__c(ShortName__c = 'sg1');
		sGrade.ID_ERP__c = 'SGRADE1';
		insert sGrade;

		Country__c country = new Country__c(NumCode__c = 'US', Name = 'test c');
		country.A2Code__c = 'a2';
		country.A3Code__c = 'a3';
		insert country;

		ShippingPoint__c point = new ShippingPoint__c(
		                                              ID_ERP__c = 'po',
		                                              Country__c = country.Id,
		                                              Type__c = '1'
		);
		insert point;

		PaymentTerms__c pay = new PaymentTerms__c();
		pay.ID_ERP__c = '1';
		insert pay;

		ProductStandard__c stand = new ProductStandard__c();
		stand.ID_ERP__c = '1';
		insert stand;

		ProductSpecLevel__c spec = new ProductSpecLevel__c();
		spec.ID_ERP__c = '1';
		insert spec;

		CoatingType__c coat = new CoatingType__c();
		coat.ID_ERP__c = '1';
		insert coat;

		TubeOD__c od = new TubeOD__c(ID_ERP__c = 'od', OD_mm__c = 48.30, OD_inch__c = 1.9);
		insert od;

		TubeWT__c wt = new TubeWT__c(ID_ERP__c = 'wt', Name = 'TestWT', WT_mm__c = 5.08, WT_inch__c = 0.2);
		insert wt;
		
		Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
		testOpp.Description = 'Test Description';
		testOpp.AssignedBOS__c = bo_user.Id;
        testOpp.AdditionalBOS__c = ad_user.Id;
		testOpp.OwnerId = owner_user.Id;
		testOpp.PaymentTerms__c = pay.Id;
		testOpp.Country__c = country.Id;
		insert testOpp;

		Id pricebookId = Test.getStandardPricebookId();
		Product2 testProd1 = t.newProducts('Test product', '0000') [0];
		testProd1.ID_ERP__c = 'pr1';
        testProd1.Family = 'OCTG';
		insert testProd1;
		Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
		testProd2.ID_ERP__c = 'pr2';
        testProd2.Family = 'OCTG';
		insert testProd2;

		PricebookEntry testPriceBookEntry1 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd1.Id,
		                                                        UnitPrice = 100.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry1;
		PricebookEntry testPriceBookEntry2 = new PricebookEntry(
		                                                        Pricebook2Id = pricebookId,
		                                                        Product2Id = testProd2.Id,
		                                                        UnitPrice = 100.00,
		                                                        IsActive = true
		);
		insert testPriceBookEntry2;

		OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
		testOppProd1.Quantity = 1;
		testOppProd1.InquiryUnit__c = '20';
		testOppProd1.InquiryQuantity__c = 1;
		testOppProd1.ID_ERP__c = '12345-1';
		testOppProd1.NPP_ERP__c = '1';
		testOppProd1.ProductType__c = 'Tube';
		testOppProd1.TotalPrice = testOppProd1.Quantity * testPriceBookEntry1.UnitPrice;
		testOppProd1.SteelGrade__c = sGrade.Id;
		testOppProd1.ProductStandard__c = stand.Id;
		testOppProd1.ProductSpecLevel__c = spec.Id;
		testOppProd1.Coating__c = coat.Id;
		testOppProd1.ShippingPoint__c = point.Id;
		testOppProd1.TubeOD__c = od.Id;
		testOppProd1.TubeWT__c = wt.Id;
		insert testOppProd1;
		OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, testOpp.Id) [0];
		testOppProd2.Quantity = 1;
		testOppProd2.InquiryUnit__c = '20';
		testOppProd2.InquiryQuantity__c = 1;
		testOppProd2.ID_ERP__c = '12345-2';
		testOppProd2.NPP_ERP__c = '2';
		//testOppProd2.ProductFamily__c = 'LP_GU';
		testOppProd2.ProductType__c = 'Tube';
		testOppProd2.TotalPrice = testOppProd2.Quantity * testPriceBookEntry2.UnitPrice;
		testOppProd2.SteelGrade__c = sGrade.Id;
		testOppProd2.ProductStandard__c = stand.Id;
		testOppProd2.ProductSpecLevel__c = spec.Id;
		testOppProd2.Coating__c = coat.Id;
		testOppProd2.ShippingPoint__c = point.Id;
		testOppProd2.TubeOD__c = od.Id;
		insert testOppProd2;

		List<Attachment> attachs = t.newAttachments(testOpp.Id);
		List<Attachment> attachToInsert = new List<Attachment> ();
		attachToInsert.add(attachs[0]);
		attachToInsert.add(attachs[1]);
		insert attachToInsert;
	}

	private static String getTestJSON() {
		Opportunity opp = [SELECT Id, ID_ERP__c, Owner.ID_ERP__c, Owner.Name, Owner.Email, Owner.EmployeeNumber, AssignedBOS__r.ID_ERP__c, AssignedBOS__r.Name, AssignedBOS__r.Email, AssignedBOS__r.EmployeeNumber, Description FROM Opportunity];
		Account acc = [SELECT Id FROM Account];
		List<OpportunityLineItem> opportunityProducts = [SELECT Id, Quantity, Quantity_m__c, Quantity_ft__c, Quantity_pcs__c,
		                                                 ID_ERP__c, ProductStandard__c, ProductSpecLevel__c, InquiryUnit__c, Coating__c, UnitPrice, Description
		                                                 FROM OpportunityLineItem];

		Datetime currentDateTime = Datetime.now();
		Long getEpochFromDate = currentDateTime.getTime();

		JSONGenerator jsonToSend = JSON.createGenerator(true);
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('MessageType', 'SF-ERP_OpportunityData');
		jsonToSend.writeObjectField('SyncDateTime', String.valueOf(getEpochFromDate));
		jsonToSend.writeFieldName('General_Data');
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('ID_SF', opp.Id);
		jsonToSend.writeStringField('Account_ID_ERP', opp.Account.ID_ERP__c);
		jsonToSend.writeObjectField('MarketSegment_ID_ERP', opp.MarketSegment__c);
		jsonToSend.writeObjectField('CountryCode', opp.Country__r.NumCode__c);
		jsonToSend.writeObjectField('DeliveryTerms', opp.DeliveryTerms__r.ID_ERP__c);
		jsonToSend.writeObjectField('Description', opp.Description);
		jsonToSend.writeObjectField('Currency_ID', opp.CurrencyIsoCode);
		jsonToSend.writeFieldName('Owner');
		jsonToSend.writeObjectField('Id', opp.Owner.ID_ERP__c);
		jsonToSend.writeObjectField('Name', opp.Owner.Name);
		jsonToSend.writeObjectField('Email', opp.Owner.Email);
		jsonToSend.writeObjectField('EmployeeNumber', opp.Owner.EmployeeNumber);
		jsonToSend.writeEndObject();
		jsonToSend.writeFieldName('BOSpecialist');
		jsonToSend.writeObjectField('Id', opp.AssignedBOS__r.ID_ERP__c);
		jsonToSend.writeObjectField('Name', opp.AssignedBOS__r.Name);
		jsonToSend.writeObjectField('Email', opp.AssignedBOS__r.Email);
		jsonToSend.writeObjectField('EmployeeNumber', opp.AssignedBOS__r.EmployeeNumber);
		jsonToSend.writeEndObject();
		jsonToSend.writeFieldName('Item_Data');
		jsonToSend.writeStartArray();
		for (OpportunityLineItem oppProduct : opportunityProducts) {
			jsonToSend.writeStartObject();
			jsonToSend.writeObjectField('ProductGroup_ID_ERP', oppProduct.Product2.ID_ERP__c);
			jsonToSend.writeObjectField('OD_ID_ERP', oppProduct.TubeOD__r.ID_ERP__c);
			jsonToSend.writeObjectField('SteelGrade_ID_ERP', oppProduct.SteelGrade__r.ID_ERP__c);
			jsonToSend.writeObjectField('Standard_ID_ERP', oppProduct.ProductStandard__c);
			jsonToSend.writeObjectField('ReqLevel_ID_ERP', oppProduct.ProductSpecLevel__c);
			jsonToSend.writeObjectField('WT_ID_ERP', oppProduct.TubeWT__r.ID_ERP__c);
			jsonToSend.writeObjectField('Quantity_Mt', oppProduct.Quantity);
			jsonToSend.writeObjectField('Quantity_m', oppProduct.Quantity_m__c);
			jsonToSend.writeObjectField('Quantity_ft', oppProduct.Quantity_ft__c);
			jsonToSend.writeObjectField('Quantity_Pieces', oppProduct.Quantity_pcs__c);
			jsonToSend.writeObjectField('PriceUnit_ID_SF', oppProduct.InquiryUnit__c);
			jsonToSend.writeObjectField('LengthSize_ID_ERP', oppProduct.LengthSize__r.ID_ERP__c);
			jsonToSend.writeObjectField('Ends_ID_ERP', oppProduct.TubeEnds__r.ID_ERP__c);
			//jsonToSend.writeObjectField('Coating_ID_SF', oppProduct.Coating__c);
			jsonToSend.writeObjectField('Shop_ID_ERP', oppProduct.Shop__r.ID_ERP__c);
			jsonToSend.writeObjectField('Price', oppProduct.UnitPrice);
			jsonToSend.writeObjectField('ShippingPoint_ID_ERP', oppProduct.ShippingPoint__r.ID_ERP__c);
			jsonToSend.writeObjectField('Description', oppProduct.Description);
			jsonToSend.writeEndObject();
		}
		jsonToSend.writeEndArray();
		jsonToSend.writeEndObject();

		jsonToSend.writeEndObject();

		System.debug(jsonToSend.getAsString());

		JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();

		System.debug(jsonWrapper.getAsString());
		return jsonWrapper.getAsString();
	}

	//@isTest
	//public static void test_getOpportunity_NoBO() {
		//Opportunity testOpp = [SELECT Id, Description FROM Opportunity];

		//testOpp.AssignedBOS__c = null;
		//update testOpp;

		//t.start();
		//OpportunityInfoController wrapper =
		//OpportunityInfoController.getOpportunity(testOpp.Id);
		//t.stop();

		//Account verifyAcc = [SELECT Name, ID_ERP__c FROM Account];

		////verify oppo
		//System.assertEquals(testOpp.Description, wrapper.oppo.Description);

		////verify acc
		//System.assertEquals(verifyAcc.ID_ERP__c, wrapper.acc.ID_ERP__c);
		//System.assertEquals(verifyAcc.Name, wrapper.acc.Name);

		////verify attaches
		//System.assertEquals(2, wrapper.attachements.size());
	//}

	@isTest
	public static void test_sendJsonData_sendEmail() {
		List<Opportunity> opps = [SELECT Id FROM Opportunity];

		Datetime currentDateTime = Datetime.now();
		Long getEpochFromDate = currentDateTime.getTime();

		String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length()-3);

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(opps[0].Id);
		//choose attachement
		wrapper.attachements.get(0).checkbox = true;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) opps[0].Id, '123456', epochFromDate));

		t.start();
		OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		System.assertEquals(2, Limits.getEmailInvocations());
		t.stop();

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c FROM Opportunity];

		System.assertEquals('123456', verifyOpp.ID_ERP__c);
	}

	@isTest
	public static void test_sendJsonData_DontSendEmail() {
		List<Opportunity> testOpp = [SELECT Id FROM Opportunity];

		Datetime currentDateTime = Datetime.now();
		Long getEpochFromDate = currentDateTime.getTime();

		String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length()-3);

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(testOpp[0].Id);
		//no chosen attachments
		wrapper.attachements.get(0).checkbox = false;
		wrapper.attachements.get(1).checkbox = false;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testOpp[0].Id, '123456', epochFromDate));

		t.start();
		OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		t.stop();

		System.assertEquals(0, Limits.getEmailInvocations());

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c, LastSyncERP__c FROM Opportunity];
		System.assertEquals('123456', verifyOpp.ID_ERP__c);
		System.assertEquals(currentDateTime, verifyOpp.LastSyncERP__c);
	}

	@isTest
	public static void test_sendJsonData_VerifyChangingAssignedBOS() {
		List<Opportunity> testOpp = [SELECT Id FROM Opportunity];

		Datetime currentDateTime = Datetime.now();
		Long getEpochFromDate = currentDateTime.getTime();

		String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length()-3);

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(testOpp[0].Id);

		User testUser = [SELECT Id, Name FROM User WHERE ID_ERP__c = 'TESTBO'];
		//wrapper.bo_user.Id = testUser.Id;
		wrapper.bo_user = testUser;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock((String) testOpp[0].Id, '123456', epochFromDate));

		t.start();
		OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		t.stop();

		System.assertEquals(0, Limits.getEmailInvocations());

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c, AssignedBOS__c FROM Opportunity];
		System.assertEquals(testUser.Id, verifyOpp.AssignedBOS__c);
		System.assertEquals('123456', verifyOpp.ID_ERP__c);
	}

	@IsTest
	public static void test_Error_ERPValidationError() {
		List<Opportunity> testOpp = [SELECT Id FROM Opportunity];


		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(testOpp[0].Id);
		//no chosen attachments
		wrapper.attachements.get(0).checkbox = false;
		wrapper.attachements.get(1).checkbox = false;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock(
		(String) testOpp[0].Id, '123456', '1528794966', 'validation'));

		String errorMsg;
		t.start();
		try {
			OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		} catch(AuraHandledException ahe) {
			errorMsg = ahe.getMessage();
		}
		t.stop();

		System.assertEquals(0, Limits.getEmailInvocations());

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c FROM Opportunity];
		System.assertEquals(null, verifyOpp.ID_ERP__c);

		System.assertEquals(errorMsg, 'Script-thrown exception');
	}

	@IsTest
	public static void test_Error_ERPCalloutException() {
		List<Opportunity> opps = [SELECT Id FROM Opportunity];

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(opps[0].Id);
		//no chosen attachments
		wrapper.attachements.get(0).checkbox = false;
		wrapper.attachements.get(1).checkbox = false;

		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock(
		(String) opps[0].Id, '123456', '1528794966','exception'));

		String errorMsg;
		t.start();
		try {
			OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		} catch(AuraHandledException ahe) {
			errorMsg = ahe.getMessage();
		}
		t.stop();

		System.assertEquals(0, Limits.getEmailInvocations());

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c FROM Opportunity];
		System.assertEquals(null, verifyOpp.ID_ERP__c);

		System.assertEquals(errorMsg, 'Script-thrown exception');
	}


	@IsTest
	public static void test_Error_ERPJSONSerializationException() {
		List<Opportunity> opps = [SELECT Id FROM Opportunity];

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(opps[0].Id);
		//no chosen attachments
		wrapper.attachements.get(0).checkbox = false;
		wrapper.attachements.get(1).checkbox = false;

		//inject "" to brake json string
		Test.setMock(WebServiceMock.class, new ERP_WebServiceMock(
		(String) opps[0].Id, '""', '1528794966','serialization'));

		String errorMsg;
		t.start();
		try {
			OpportunityInfoController.sendJSONData(JSON.serialize(wrapper));
		} catch(AuraHandledException ahe) {
			errorMsg = ahe.getMessage();
		}
		t.stop();

		System.assertEquals(0, Limits.getEmailInvocations());

		Opportunity verifyOpp = [SELECT Id, ID_ERP__c FROM Opportunity];
		System.assertEquals(null, verifyOpp.ID_ERP__c);

		System.assertEquals(errorMsg, 'Script-thrown exception');
	}


	@isTest
	public static void test_getJsonData_VerifyMapping() {
		Opportunity testOpp = [SELECT Id, AccountId, OwnerId FROM Opportunity];

		//testOpp.DeliveryTerms__c = '002';
		testOpp.CurrencyIsoCode = 'USD';
		update testOpp;

		TubeWT__c wt = new TubeWT__c(
		                             ID_ERP__c = 'wt1',
		                             Name = 'TestWT1',
		                             WT_mm__c = 5.08
		);
		insert wt;

		TubeOD__c od = new TubeOD__c(
		                             ID_ERP__c = 'ododod',
		                             Name = 'TestOD',
		                             OD_mm__c = 48.30
		);
		insert od;

		TubeLengthSize__c size = new TubeLengthSize__c(ID_ERP__c = 'si', Type__c = 'R1');
		size.MaxLength__c = 5800;
		size.MinLength__c = 5600;
		insert size;

		TubeEnds__c theend = new TubeEnds__c(ID_ERP__c = 'en', ShortName__c = 'EUE');
		insert theend;

		//{Edited: Bahtiyar 08.02.2018 22:12
		//Shop__c shop = new Shop__c(ID_ERP__c = 'sh');
		//shop.Plant__c = 'Steel';
		//Plant__c plant = new Plant__c(FullName__c = 'Full Name');
		//insert plant;
		//Shop__c shop = new Shop__c(Plant__c = plant.Id, ID_ERP__c = 'sh');
		Shop__c shop = new Shop__c(ID_ERP__c = 'sh');
		//}Edited: Bahtiyar 08.02.2018 22:12
		insert shop;

		Map<String, String> priceUnitValues = ApexUtil.getPicklistFieldMap('OpportunityLineItem', 'InquiryUnit__c');

		List<OpportunityLineItem> testProducts = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
		for (OpportunityLineItem prod : testProducts) {
			//prod.ReqLevel__c = 'General';
			prod.TubeWT__c = wt.Id;
			prod.TubeOD__c = od.Id;
			prod.Weight_kpm__c = 5.31;
			prod.Weight_ppf__c = 3.63;
			//prod.InquiryQuantity__c = 5;
			prod.Quantity = 100;
			prod.Quantity_m__c = 18484.29;
			prod.Quantity_ft__c = 60643.99;
			prod.Quantity_pcs__c = 3187;
			//prod.InquiryUnit__c = (priceUnitValues.values() [0]);
			prod.LengthSize__c = size.Id;
			prod.TubeEnds__c = theend.Id;
			//prod.Coating__c = 'None';
			prod.Shop__c = shop.Id;
			prod.Description = 'TestDesc';
		}
		update testProducts;

		OpportunityInfoController wrapper =
		OpportunityInfoController.getOpportunity(testOpp.Id);

		//User salesRep = [SELECT ID, ID_ERP__c, LoginERP__c, FirstName, Name, Email, EmployeeNumber FROM User WHERE Id = :wrapper.oppo.OwnerId];

		t.start();
		String testJSON = OpportunityInfoController.getJSONData(wrapper.oppo, wrapper.acc, wrapper.products);
		String processed = testJSON.remove('\\n').remove('\\');
		processed = processed.substring(1, processed.length() - 1);
		t.stop();

		String json_to_verify = JSON_TO_SEND
		.replace('   "ID_SF" : "oppo",', '   "ID_SF" : "' + testOpp.Id + '",')
		.replace('     "ID_SF" : "oppoProd1",', '     "ID_SF" : "' + testProducts[0].Id + '",')
		.replace('     "ID_SF" : "oppoProd2",', '     "ID_SF" : "' + testProducts[1].Id + '",');
		//System.debug(json_to_verify.trim().remove(' '));
		System.assertEquals(processed.trim().remove(' '), processed.trim().remove(' '));
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
		private final String OPPO_ACCEPTED_RESPONCE = '"{\"SyncResult\": \"1\",\"SyncDateTime\": \"%SyncDateTime%\",\"Opportunity\":{\"ID_SF\":\"%oppID%\",\"ID_ERP\":\"%erpId%\"}}"';
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
				if (isError.equals('validation')) {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = ERROR_RESPONSE;
					response.put('response_x', resp);
				} else if (isError.equals('exception')) {
					throw new CalloutException('Test');
				} else {
					SFToERP.ExecuteExResponse_element resp = new SFToERP.ExecuteExResponse_element();
					resp.ExecuteExResult = OPPO_ACCEPTED_RESPONCE
					.replace('%oppId%', oppId).replace('%erpId%', ERP_Id).replace('%SyncDateTime%', SyncDateTime);
					response.put('response_x', resp);
				}
			}
		}
	}

	static { BaseTest.t = new OpportunityInfoControllerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}