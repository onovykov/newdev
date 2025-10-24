@isTest
public class ERPWebServiceHandlerTest extends BaseTest {

	private static String getJSONBody(String ID_ERP_Opportunity, String ID_ERP_Opportunity_Product, String CurrencyISOCode, String Quantity_Mt, String paymentTermsName) {

		String json_body = '{"MessageType": "ERP-SF_OpportunityData",' +
		'"MessageTimestamp": "' + Datetime.now().getTime() + '",' +
		'"ProductType": "Tubes",' +
		'"General_Data": ' +
		'{"ID_SF": "0060Y00000IcrXLQAZ",' +
		'"ID_ERP": "' + ID_ERP_Opportunity + '",' +
		'"AddNumber": "SI-13.03.01/2018",' + 
		'"CreatedDate": "1538006400",' +
		'"OrderDate": "1538006400",' +
		
		'"Account": {"ID": "22449","Name": "INDUSTRIAL MATERIAL SUPPLY FZCO"},"MarketSegment":"00002", "Region":"6", "Country":"45646", "PaymentTerms":{"ID": "T13","Name": "' + paymentTermsName + '"},"DeliveryTerms": {' +
		'"ID": "002","Name": "CIF - передача после погрузки на судно - оплачено до пункта доставки","Incoterms": "CIF"},' +
		'"OpportunityCurrency": "' + CurrencyISOCode + '",' +
		'"Owner": {"ID":"54124", "Name":""}, "BOSpecialist": {"ID":"54124", "Name":""},' +
		'"CrossMarketSegment": "",' +
		'"CrossMarketManager": "",' +
		'"CrossMarketManagerName": "",' +
		'"CrossMarketPercent": "0.00",' +
		'"Item_Data": [' +
		'{"ID_SF": "", "ID_ERP": "' + ID_ERP_Opportunity_Product + '",' +
		'"ITENumber": "18-002357-002","ProductGroup": {"ID": "34", "Name": "ТТ б/ш (слиток и НТК)"},' +
		'"QuotaType": {"ID": "10","Name": "ТПЦ2: Экспорт","Shop": "9"},' +
		'"Standard": {"ID": "1100","Name": "API 5L/ ASTM A106/ ASTM A53"},' +
		'"SpecLevel": {"ID": "1","Name": "PSL1"},' +
		'"SteelGrade": {"ID": "28","Name": "B"},' +
		'"OD": {"ID": "3E","Name": "219,10", "OD_mm":"219"},' +
		'"WT": {"ID": "3Z","Name": "8,18", "WT_mm":"8"},' +
		'"LengthSize": {"ID": "3U","Name": "5900-6100"},' +
		'"Weight_ppf": "","Weight_kpm": "",' +
		'"Ends": {"ID": "T","Name": "Фаска 30-35"},' +
		'"Coating": {"ID": "K","Name": "Покрытие лаком"},' +
		'"CoatingSpec": "","Shop": {"ID": "9","Name": "ТПЦ2"},' +
		'"WheelStandard": {"ID": "","Name": ""},' +
		'"WheelSteelGrade": {"ID": "","Name": ""},' +
		'"WheelDiameter": {"ID": "","Name": ""},' +
		'"WheelHub": {"ID": "","Name": ""},' +
		'"WheelDrawing": {"ID": "","Name": ""},' +
		'"InqQuantity": "8500.00000","InqUnit": "20","Quantity_Mt": "' + Quantity_Mt + '",' +
		'"Quantity_m": "8500.00000","Quantity_ft": "","Quantity_pcs": "","Price": "48.95000","Price_t": "1150.00000","Margin_t": "422.67007","TotalPrice": "",' +
		'"ShippingPoint": {"Type": "1","ID": "51025","Name": "ALEXANDRIA (EGYPT)"},' +
		'"TechExp": "2","CDD": "1540944000","FinStatus": "Согласование Коммерческим директором",' +
		'"FinApproval": "-1","Stage": "Confirmed",' +
		'"Produced": "152.552",' +
		'"Dispatched": "152.552",' +
		'"Shipped": "152.552",' +
		'"Lots": [' +
            '{' +
              '"Date": "1538006400",' +
              '"Produced": "118.517",' +
			  '"Dispatched": "118.517",' +
			  '"Shipped": "118.517"' +
            '},' +
            '{' +
              '"Date": "1538092800",' +
              '"Produced": "28.381",' +
			  '"Dispatched": "28.381",' +
			  '"Shipped": "28.381"' +
            '},' +
            '{' +
              '"Date": "1538179200",' +
              '"Produced": "5.654",' +
			  '"Dispatched": "5.654",' +
			  '"Shipped": "5.654"' +
            '}' +
        '],' +
		'"FinDataShipped": "0", "FinDataMargin": "0"}]}}';

		return json_body;
		
	}

	private static String getJSONBodyForSyncedResponce(String epoch, String ID_ERP_Opportunity, String ID_Opportunity_Product, String SyncResult) {

		String json_body = '{"MessageType": "ERP-SF_Sync_Result",' +
		'"SyncDateTime": "' + epoch + '",' +
		'"SyncResult": "' + SyncResult + '",' +
		'"Opportunity":  {' +
		'"ID_SF": "0062500000BMPhGAAX",' +
		'"ID_ERP": "' + ID_ERP_Opportunity + '",' +
		'"Item": [{' +
		'"ID_SF": "' + ID_Opportunity_Product + '",' +
		'"ID_ERP": "9011961777"' +
		'}]}}';

		return json_body;
	}

	private static String getJSONBodyForItemStage() {

		String json_body = '{' +
		'"MessageType": "ERP-SF_ItemStage",' +
		'"Item_Stage":  {' +
		'"OpportunityID_ERP": "12341413",' +
		'"OpportunityItemID_ERP": "1234",' +
		'"TechExp_Comment": "Some text",' +
		'"SC_Comment": "Some text"' +
		'}}';
	
	return json_body;
}

@IsTest static void testItemStageRequest() {

	String receivedBody = getJSONBodyForItemStage();

	RestRequest req = new RestRequest();
	RestResponse res = new RestResponse();

	req.requestURI = '/ERPtoSF/v1/*';
	req.httpMethod = 'POST';
	req.requestBody = Blob.valueOf(receivedBody);
	RestContext.request = req;
	RestContext.response = res;

	Test.startTest();
		ERPtoSF.postCST();
	Test.stopTest();
}
    
// @IsTest static void testItemStageTechRequest() {
	
//     Opportunity testOpp = [SELECT Id,ID_ERP__c FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	OpportunityLineItem oppLI = [SELECT Id,NPP_ERP__c,ID_ERP__c FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];
    
// 	String receivedBody = '{' +
// 		'"MessageType": "ERP-SF_ItemStage",' +
// 		'"Item_Stage":  {' +
// 		'"OpportunityID_ERP": "'+testOpp.ID_ERP__c +'",' +
// 		'"OpportunityItemID_ERP": "'+oppLI.NPP_ERP__c +'",' +
//         '"Stage": "Drafting",'+
//         '"TechExp": "1",'+
// 		'"TechExp_Comment": "На доработку:  Прошу проверить корректность выбора требований",' +
// 		'"CDD": "",' +
//         '"CDD_Comment": ""'+
// 		'}}';

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 		ERPtoSF.postCST();
// 	Test.stopTest();
// }    

// @IsTest static void testSyncedOpportunityRequest() {

// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	OpportunityLineItem changed_oppLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

// 	Datetime currentDateTime = Datetime.now();
// 	Long getEpochFromDate = currentDateTime.getTime();

// 	String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length() - 3);

// 	String receivedBody = getJSONBodyForSyncedResponce(epochFromDate, 'opp01', changed_oppLI.Id, '1');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	Opportunity testOpp_verify = [SELECT Id, LastSyncERP__c FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	OpportunityLineItem changed_oppLI_verify = [SELECT Id, NPP_ERP__c FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

// 	System.debug('testOpp_verify.LastSyncERP__c ' + testOpp_verify.LastSyncERP__c);
// 	System.debug('currentDateTime ' + currentDateTime);
// 	System.assertEquals(testOpp_verify.LastSyncERP__c, currentDateTime);
// 	System.assertEquals(changed_oppLI_verify.NPP_ERP__c, '9011961777');
// }

// @IsTest static void testSyncedOpportunityRequestRejected() {

// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	OpportunityLineItem changed_oppLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

// 	Datetime currentDateTime = Datetime.now();
// 	Long getEpochFromDate = currentDateTime.getTime();

// 	String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length() - 3);

// 	String receivedBody = getJSONBodyForSyncedResponce(epochFromDate, 'opp01', changed_oppLI.Id, '-1');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	Opportunity testOpp_verify = [SELECT Id, LastSyncERP__c FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];

// 	System.debug('testOpp_verify.LastSyncERP__c ' + testOpp_verify.LastSyncERP__c);
// 	System.debug('currentDateTime ' + currentDateTime);
// 	System.assertNOtEquals(testOpp_verify.LastSyncERP__c, currentDateTime);

// }

// @IsTest static void CreateNewOpportunity() {

// 	String ID_ERP_of_new_opportunity = '14453663';
// 	String ID_ERP_of_new_Opp_Product = '2';

// 	String receivedBody = getJSONBody(ID_ERP_of_new_opportunity, ID_ERP_of_new_Opp_Product, 'USD', '3600','оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	List<Opportunity> opp = [SELECT Id
// 	                         FROM Opportunity WHERE
// 	                         ID_ERP__c = :ID_ERP_of_new_opportunity];

// 	//System.assertEquals(1, opp.size());
// }



// @IsTest static void checkOrderMapping() {

// 	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];

// 	String receivedBody = getJSONBody('opp01', '2', 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	testOpp.StageName = 'Closed Won';
// 	testOpp.MarketSegment__c = '00002';
// 	update testOpp;
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	Opportunity opp_to_verify = [SELECT Id, Country__c, SyncedOrder__c FROM Opportunity LIMIT 1];
// 	Order ord_to_verify = [SELECT Id, Country__c FROM Order LIMIT 1];
// 	System.debug('Country on opp - ' + opp_to_verify.Country__c);

// 	System.assertEquals(opp_to_verify.SyncedOrder__c, ord_to_verify.Id);
// 	//System.assertEquals(opp_to_verify.Country__c, ord_to_verify.Country__c);
// }

// @IsTest static void checkNullQuantity() {

// 	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];

// 	String receivedBody = getJSONBody('opp01', '2', 'USD', '', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	testOpp.StageName = 'Closed Won';
// 	testOpp.MarketSegment__c = '00002';
// 	update testOpp;
// 	ERPtoSF.postCST();
// 	Test.stopTest();


// 	OrderItem ordi_to_verify = [SELECT Id, Quantity FROM OrderItem LIMIT 1];
// 	System.debug('Quantity on order item - ' + ordi_to_verify.Quantity);

// 	System.assertNotEquals(null, ordi_to_verify.Quantity);

// }

// @IsTest static void checkPaymentTermsLongName() {

// 	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];

// 	String receivedBody = getJSONBody('opp01', '2', 'USD', '2300', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив.');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	testOpp.StageName = 'Closed Won';
// 	testOpp.MarketSegment__c = '00002';
// 	System.debug('This is before');
// 	update testOpp;
	
// 	ERPtoSF.postCST();
// 	System.debug('This is after');
// 	Test.stopTest();

// 	List<PaymentTerms__c> paymentTerms = [SELECT Name FROM PaymentTerms__c];
// 	//System.assertEquals('оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив,...', paymentTerms[0].Name);
// }


// @IsTest static void opportunityChangedCurrencyCode() {

// 	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
// 	Opportunity testOpp = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];

// 	String newCurrency = 'EUR';
// 	String receivedBody = getJSONBody('opp01', '2', newCurrency, '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	Opportunity opp_to_verify = [SELECT Id, CurrencyIsoCode FROM Opportunity LIMIT 1];


// 	//System.assertEquals(opp_to_verify.CurrencyIsoCode, newCurrency);

// }




@isTest static void test_generateResponseBody() {
	String error = 'There is no opportunity with such id';

	t.start();
	Blob response = ERPWebServiceHandler.generateResponseBody(500, error);
	t.stop();

	JSONGenerator gen = JSON.createGenerator(true);
	gen.writeStartObject();
	gen.writeNumberField('Status Code', 500);
	gen.writeStringField('Status', 'INTERNAL SERVER ERROR');
	gen.writeStringField('Error Message', error);
	gen.writeEndObject();
	String expectedJSON = gen.getAsString();

	System.assertEquals(Blob.valueOf(expectedJSON), response, 'Response is not right.');
}

// @isTest static void test_getOpportunitySF() {

// 	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = 'opp01'];
// 	String oppERPid = 'opp01';

// 	t.start();
// 	Opportunity opp = ERPWebServiceHandler.getOpportunitySFByERPID(oppERPid);
// 	t.stop();

// 	Opportunity expectedOpp = [SELECT Id FROM Opportunity LIMIT 1];
// 	System.assertEquals(expectedOpp.Id, opp.Id);
// }



private static List<ERPRequestParser.OpportunityProduct> createOppProductsList() {
	List<ERPRequestParser.OpportunityProduct> oppProductsList = new List<ERPRequestParser.OpportunityProduct> ();
	ERPRequestParser.OpportunityProduct oppProduct = new ERPRequestParser.OpportunityProduct();
	oppProduct.ID_ERP = '0002';
	oppProductsList.add(oppProduct);
	return oppProductsList;
}

@IsTest
static void test_getOpportunityLineItem() {
	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
	t.start();
	OpportunityLineItem[] oliNull = ERPWebServiceHandler.getOpportunityLineItem('0003', opp.id);
	OpportunityLineItem[] oliNotNull = ERPWebServiceHandler.getOpportunityLineItem('0001', opp.id);
	t.stop();
}

// @IsTest
// static void test_Opportunity_without_ID_ERP() {

// 	Opportunity testOpp = [SELECT Id, ID_ERP__c FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	List<OpportunityLineItem> oppLI = [SELECT Id, ID_ERP__c, NPP_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

// 	String receivedBody = getJSONBody('', oppLI[0].NPP_ERP__c, 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSFdev/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();

// 	try {
// 		ERPtoSF.postCST();
// 	} catch(Exception e) {
// 		System.assert(e.getMessage().contains('Your request does not contain ID_ERP field for Opportunity.'), e.getMessage());
// 	}

// 	Test.stopTest();
// }
    
//     @IsTest static void productGroupChangeOnOppProduct() {

// 	Opportunity testOpp = [SELECT Id, ID_ERP__c FROM Opportunity WHERE ID_ERP__c = 'opp01' LIMIT 1];
// 	List<OpportunityLineItem> oppLI = [SELECT Id, ID_ERP__c, NPP_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

// 	System.debug('ID_ERP of OppLI - ' + oppLI[0].ID_ERP__c);
// 	System.debug('OPpLine items - ' + oppLI);
// 	System.debug('Product2Id - ' + oppLI[0].Product2Id);

// 	String receivedBody = getJSONBody(testOpp.ID_ERP__c, oppLI[0].NPP_ERP__c, 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

// 	RestRequest req = new RestRequest();
// 	RestResponse res = new RestResponse();

// 	req.requestURI = '/ERPtoSF/v1/*';
// 	req.httpMethod = 'POST';
// 	req.requestBody = Blob.valueOf(receivedBody);
// 	RestContext.request = req;
// 	RestContext.response = res;

// 	Test.startTest();
// 	ERPtoSF.postCST();
// 	Test.stopTest();

// 	List<OpportunityLineItem> changed_oppLI = [SELECT Id, ID_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
// 	System.debug('Product2Id after logic done - ' + changed_oppLI[0].Product2Id);
// 	System.debug('oppLI[0] ' + oppLI[0]);
// 	System.debug('changed_oppLI[0] ' + changed_oppLI[0]);
// }



@testSetup static void testSetup() {

	Country__c country = new Country__c(Name = 'test', A2Code__c = '15', A3Code__c = '25', NumCode__c = '0');
	insert country;

	Shop__c shop_n_s = new Shop__c(Id_ERP__c = '0', Name = 'Not specified');
	insert shop_n_s;

	User newUser = t.newUser('john@acme.com');
	insert newUser;

	UserID_ERP__c user_id_in_erp = new UserID_ERP__c(Name = '54124', User__c = newUser.Id);
	insert user_id_in_erp;

	Account testAccount = t.newAccounts('Test Account') [0];
	testAccount.ID_ERP__c = '22449';
	insert testAccount;

	ProductStandard__c qStan = new ProductStandard__c();
	insert qStan;

	SteelGrade__c sGrade = new SteelGrade__c(ShortName__c = 'sg1');
	insert sGrade;

	TubeEnds__c tubeEnds = new TubeEnds__c(ShortName__c = 'EUE');
	insert tubeEnds;

	Plant__c plant = new Plant__c(FullName__c = 'Plant Full Name');
	insert plant;
	
	Shop__c shop = new Shop__c(Plant__c = plant.Id);
	insert shop;
	
	TubeOD__c tubeOD = new TubeOD__c();
	insert tubeOD;
	
	TubeWT__c tubeWT = new TubeWT__c();
	insert tubeWT;
	
	Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
	testOpp.ID_ERP__c = 'opp01';
    
	insert testOpp;

	Id pricebookId = Test.getStandardPricebookId();
	
	List<Product2> prodList = new List<Product2>();
	Product2 testProd1 = t.newProducts('Test product', '0000') [0];
	testProd1.ID_ERP__c = 'tt';
    //testProd1.Family = 'OCTG';
	prodList.add(testProd1);
	Product2 testProd2 = t.newProducts('Test product2', '0001') [0];
	testProd2.ID_ERP__c = 'tq';
    //testProd2.Family = 'OCTG';
	prodList.add(testProd2);
	insert prodList;

	List<PricebookEntry> pbeList = new List<PricebookEntry>();
	PricebookEntry testPriceBookEntry1 = new PricebookEntry(
	                                                        Pricebook2Id = pricebookId,
	                                                        Product2Id = testProd1.Id,
	                                                        UnitPrice = 100.00,
	                                                        IsActive = true
	);
	pbeList.add(testPriceBookEntry1);
	PricebookEntry testPriceBookEntry2 = new PricebookEntry(
	                                                        Pricebook2Id = pricebookId,
	                                                        Product2Id = testProd2.Id,
	                                                        UnitPrice = 200.00,
	                                                        IsActive = true
	);
	pbeList.add(testPriceBookEntry2);
	insert pbeList;

	List<OpportunityLineItem> oplineItems = new List<OpportunityLineItem>();

	OpportunityLineItem testOppProd1 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
	testOppProd1.Quantity = 3;
	testOppProd1.InquiryQuantity__c = 3;
	testOppProd1.InquiryUnit__c = '34';
	testOppProd1.ID_ERP__c = testOpp.Id + '-0001';
	testOppProd1.NPP_ERP__c = '0001';
	testOppProd1.ProductType__c = 'Tube';
	testOppProd1.TotalPrice = testPriceBookEntry1.UnitPrice;
	testOppProd1.SteelGrade__c = sGrade.Id;
	testOppProd1.TubeEnds__c = tubeEnds.Id;
	testOppProd1.Shop__c = shop.Id;
	testOppProd1.TubeOD__c = tubeOD.Id;
	oplineItems.add(testOppProd1);

	OpportunityLineItem testOppProd2 = t.newOpportunityProducts(testPriceBookEntry2.Id, testOpp.Id) [0];
	testOppProd2.Quantity = 2;
	testOppProd2.InquiryQuantity__c = 3;
	testOppProd2.InquiryUnit__c = '34';
	testOppProd2.ID_ERP__c = testOpp.Id + '-0002';
	testOppProd2.NPP_ERP__c = '0002';
	testOppProd2.ProductType__c = 'Tube';
	testOppProd2.TotalPrice = testPriceBookEntry2.UnitPrice;
	oplineItems.add(testOppProd2);

	OpportunityLineItem testOppProd3 = t.newOpportunityProducts(testPriceBookEntry1.Id, testOpp.Id) [0];
	testOppProd3.Quantity = 3;
	testOppProd3.InquiryQuantity__c = 3;
	testOppProd3.InquiryUnit__c = '34';
	testOppProd3.ID_ERP__c = testOpp.ID_ERP__c + '-3';
	testOppProd3.NPP_ERP__c = '3';
	testOppProd3.ProductType__c = 'Tube';
	testOppProd3.TotalPrice = testPriceBookEntry1.UnitPrice;
	testOppProd3.SteelGrade__c = sGrade.Id;
	testOppProd3.TubeEnds__c = tubeEnds.Id;
	testOppProd3.Shop__c = shop.Id;
	testOppProd3.TubeOD__c = tubeOD.Id;
	oplineItems.add(testOppProd3);

	insert oplineItems;

}
static { BaseTest.t = new ERPWebServiceHandlerTest(); }
static BaseTest t { get { return BaseTest.t; } }
}