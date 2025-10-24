@isTest
public class ERPMessageHandlerOppDataTest extends BaseTest {

	private static String getJSONBody(String ID_ERP_Opportunity, String ID_ERP_Opportunity_Product, String CurrencyISOCode, String Quantity_Mt, String paymentTermsName) {

		String json_body =   
		'{' +
			'"Metadata": {' +
			  '"MsgType": "ERP-SF_OpportunityData",' +
			  '"MsgTypeVersion": 0.0,' +
			  '"MsgTimestamp": "2021-11-01T16:00:52.6592404+02:00",' +
			  '"PartNumber": 1,' +
			  '"TotalParts": 1' +
			'},' +
			'"Data": {' +
			  '"OrderType": "Tubes",' +
			  '"OrderCurrency": "'+CurrencyISOCode+'",' +
			  '"Header": {' +
				'"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				'"IteNumber": "21-000320",' +
				'"AltNumber": "COC21/0079",' +
				'"CreatedDate": "2021-01-18T19:17:18",' +
				'"OrderDate": "2021-01-18T00:00:00",' +
				'"Account": {' +
				  '"Name": "Tubos Oliveira Ltda",' +
				  '"Id": "62549"' +
				'},' +
				'"BusinessSegmentId": "00001",' +
				'"RegionId": 5,' +
				'"CountryId": 76,' +
				'"PaymentTerms": {' +
				  '"Name": "'+paymentTermsName+'",' +
				  '"Id": "K91"' +
				'},' +
				'"DeliveryTerms": {' +
				  '"Name": "CIF - передача после погрузки на судно - оплачено до пункта доставки",' +
				  '"Incoterms": "CIF",' +
				  '"Id": "002"' +
				'},' +
				'"SalesRep": {' +
				  '"Name": "Rodriguez Marcelo",' +
				  '"UserId": null,' +
				  '"Email": "marcelo.rodriguez@m.interpipe.biz",' +
				  '"Id": "54124"' +
				'},' +
				'"BoSpecialist": {' +
				  '"Name": "Недилько Анна Игоревна",' +
				  '"UserId": "AINEDILKO",' +
				  '"Email": "Anna.Nedilko@m.interpipe.biz",' +
				  '"Id": "  54809"' +
				'},' +
				'"CrossMarket_BusinessSegment": "",' +
				'"CrossMarket_SalesRep": {' +
				  '"Name": "",' +
				  '"UserId": "",' +
				 ' "Email": "",' +
				  '"Id": ""' +
				'},' +
				'"CrossMarket_Percent": 0.00' +
			  '},' +
			  '"Items": [' +
				'{' +
				  '"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				  '"Npp": '+Integer.valueOf(ID_ERP_Opportunity_Product)+',' +
				  '"IteNumber": "21-000320-001",' +
				  '"ProductGroup": {' +
					'"Name": "БОН",' +
					'"Id": "20"' +
				'},' +
				  '"QuotaType": {' +
					'"Shop": {' +
					  '"Name": "Tube-rolling shop 7",' +
					  '"Id": "7"' +
					'},' +
					'"Name": "Shop7: ф32-38",' +
					'"Id": "6"' +
				  '},' +
				  '"Shop": {' +
					'"Mill": {' +
					  '"Name": "Interpipe Nikotube, LLC",' +
					  '"Id": "2"' +
					'},' +
					'"Name": "Tube-rolling shop 7",' +
					'"Id": "7"' +
				  '},' +
				  '"InqQuantity": 5.00000,' +
				  '"InqUnit": 34,' +
				  '"Quantity_Mt": '+Decimal.valueOf(Quantity_Mt)+',' +
				  '"Quantity_m": 1998.12700,' +
				  '"Quantity_ft": 0.0,' +
				  '"Quantity_pcs": 0.0,' +
				  '"LinearWeight_ppf": 1.681,' +
				  '"LinearWeight_kpm": 1000.000,' +
				  '"Price": 880.00000,' +
				  '"Price_t": 880.00000,' +
				  '"Margin_t": 100.81133,' +
				  '"TotalPrice": 0.0,' +
				  '"ShippingPoint": {' +
					'"spType": 1,' +
					'"Id": "52048",' +
					'"Name": "SANTOS (BRAZIL)"' +
				  '},' +
				  '"IsTypical": 1,' +
				  '"TechExp": 2,' +
				  '"CriticalDispatchDate": "2021-04-30T00:00:00",' +
				  '"RecommendedCDD": "2021-04-30T00:00:00",' +
				  '"FinStatus": "Approved",' +
				 ' "FinApproval": 1,' +
				 ' "Stage": "_6",' +
				  '"Produced": 0.0,' +
				  '"Dispatched": 0.0,' +
				  '"Shipped": 0.0,' +
				  '"Lots": [],' +
				  '"Quotas": [' +
					'{' +
					  '"QuotaDate": "2021-04-01T00:00:00",' +
					  '"Quantity_Mt": 5.0000,' +
					  '"Quantity_pcs": 345.0000,' +
					  '"PriceExw_t": 764.60000,' +
					  '"Margin_t": 100.81133' +
					'}' +
				  '],' +
				  '"FinDataShipped": 0.0,' +
				  '"FinDataMargin": 0.0,' +
				  '"ProductCharacteristic": {' +
					'"Diameter": {' +
					  '"OD_mm": 33.400,' +
					  '"Name": "33,40",' +
					  '"FacetCode": "DIMP",' +
					  '"Id": "0H"' +
					'},' +
					'"Thickness": {' +
					  '"Wt_mm": 3.380,' +
					  '"Name": "3,38",' +
					  '"FacetCode": "WLMP",' +
					  '"Id": "2B"' +
					'},' +
					'"LengthSize": {' +
					  '"MinLength": 5500.000000,' +
					  '"MaxLength": 5800.000000,' +
					  '"Name": "5500-5800",' +
					  '"FacetCode": "LNMP",' +
					  '"Id": "VW"' +
					'},' +
					'"Ends": {' +
					  '"Name": "Обрезка под прямым углом",'+
					  '"FacetCode": "P1PG",' +
					  '"Id": "Г"' +
					'},' +
					'"Coating": {' +
					  '"Name": "Покрытие лаком",' +
					  '"FacetCode": "P2PG",' +
					  '"Id": "K"' +
					'},' +
					'"Standard": {' +
					  '"Name": "API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015",' +
					  '"Id": "2492"' +
					'},' +
					'"SteelGrade": {' +
					  '"Name": "B",' +
					  '"FacetCode": "SGMP",' +
					  '"Id": "28"' +
					'}'+ 
				 ' },' +
				  '"CoatingSpec": "Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.",' +
				  '"SpecLevel": {' +
					'"Name": "PSL1",' +
					'"Id": "1"' +
				  '},' +
				  '"WeightMainUnit_kg": 1000.000,' +
				  '"LengthMin_mm": 0.0,' +
				  '"LengthMax_mm": 0.0' +
				'}' +
			  ']' +
			'}' +
		 ' }';

		//json_body = '{"Metadata":{"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":0,"MsgTimestamp":"2021-11-01T16:00:52.6592404+02:00","PartNumber":1,"TotalParts":1},"Data":{"OrderType":"Tubes","OrderCurrency":"USD","Header":{"Undoc":22655316,"IteNumber":"21-000320","AltNumber":"COC21/0079","CreatedDate":"2021-01-18T19:17:18","OrderDate":"2021-01-18T00:00:00","Account":{"Name":"Tubos Oliveira Ltda","Id":"62549"},"BusinessSegmentId":"00001","RegionId":5,"CountryId":76,"PaymentTerms":{"Name":"50% Оплата в теч. 0 к.д. Специальная дата до Банковский перевод, 50% Оплата в теч. 30 к.д. Факт отгрузки с перевалки Банковский перевод,","Id":"K91"},"DeliveryTerms":{"Name":"CIF - передача после погрузки на судно - оплачено до пункта доставки","Incoterms":"CIF","Id":"002"},"SalesRep":{"Name":"Rodriguez Marcelo","UserId":null,"Email":"marcelo.rodriguez@m.interpipe.biz","Id":"ttt321123"},"BoSpecialist":{"Name":"Недилько Анна Игоревна","UserId":"AINEDILKO","Email":"Anna.Nedilko@m.interpipe.biz","Id":"  54809"},"CrossMarket_BusinessSegment":"","CrossMarket_SalesRep":{"Name":"","UserId":"","Email":"","Id":""},"CrossMarket_Percent":0},"Items":[{"Undoc":22655316,"Npp":1,"IteNumber":"21-000320-001","ProductGroup":{"Name":"БОН","Id":"20"},"QuotaType":{"Shop":{"Name":"Tube-rolling shop 7","Id":"7"},"Name":"Shop7: ф32-38","Id":"6"},"Shop":{"Mill":{"Name":"Interpipe Nikotube, LLC","Id":"2"},"Name":"Tube-rolling shop 7","Id":"7"},"InqQuantity":5,"InqUnit":34,"Quantity_Mt":5,"Quantity_m":1998.127,"Quantity_ft":0,"Quantity_pcs":0,"LinearWeight_ppf":1.681,"LinearWeight_kpm":1000,"Price":880,"Price_t":880,"Margin_t":100.81133,"TotalPrice":0,"ShippingPoint":{"spType":1,"Id":"52048","Name":"SANTOS (BRAZIL)"},"IsTypical":1,"TechExp":2,"CriticalDispatchDate":"2021-04-30T00:00:00","RecommendedCDD":"2021-04-30T00:00:00","FinStatus":"Approved","FinApproval":1,"Stage":"Processing","Produced":0,"Dispatched":0,"Shipped":0,"Lots":[],"Quotas":[{"QuotaDate":"2021-04-01T00:00:00","Quantity_Mt":5,"Quantity_pcs":345,"PriceExw_t":764.6,"Margin_t":100.81133}],"FinDataShipped":0,"FinDataMargin":0,"ProductCharacteristic":{"Diameter":{"OD_mm":33.4,"Name":"33,40","FacetCode":"DIMP","Id":"0H"},"Thickness":{"Wt_mm":3.38,"Name":"3,38","FacetCode":"WLMP","Id":"2B"},"LengthSize":{"MinLength":5500,"MaxLength":5800,"Name":"5500-5800","FacetCode":"LNMP","Id":"VW"},"Ends":{"Name":"Обрезка под прямым углом","FacetCode":"P1PG","Id":"Г"},"Coating":{"Name":"Покрытие лаком","FacetCode":"P2PG","Id":"K"},"Standard":{"Name":"API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015","Id":"2492"},"SteelGrade":{"Name":"B","FacetCode":"SGMP","Id":"28"}},"CoatingSpec":"Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.","SpecLevel":{"Name":"PSL1","Id":"1"},"WeightMainUnit_kg":1000,"LengthMin_mm":0,"LengthMax_mm":0}]}}';
		return json_body;
	}
    
    private static String getJSONBodyInqUnit20(String ID_ERP_Opportunity, String ID_ERP_Opportunity_Product, String CurrencyISOCode, String Quantity_Mt, String paymentTermsName) {

		String json_body =   
		'{' +
			'"Metadata": {' +
			  '"MsgType": "ERP-SF_OpportunityData",' +
			  '"MsgTypeVersion": 0.0,' +
			  '"MsgTimestamp": "2021-11-01T16:00:52.6592404+02:00",' +
			  '"PartNumber": 1,' +
			  '"TotalParts": 1' +
			'},' +
			'"Data": {' +
			  '"OrderType": "Tubes",' +
			  '"OrderCurrency": "'+CurrencyISOCode+'",' +
			  '"Header": {' +
				'"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				'"IteNumber": "21-000320",' +
				'"AltNumber": "COC21/0079",' +
				'"CreatedDate": "2021-01-18T19:17:18",' +
				'"OrderDate": "2021-01-18T00:00:00",' +
				'"Account": {' +
				  '"Name": "Tubos Oliveira Ltda",' +
				  '"Id": "62549"' +
				'},' +
				'"BusinessSegmentId": "00001",' +
				'"RegionId": 5,' +
				'"CountryId": 76,' +
				'"PaymentTerms": {' +
				  '"Name": "'+paymentTermsName+'",' +
				  '"Id": "K91"' +
				'},' +
				'"DeliveryTerms": {' +
				  '"Name": "CIF - передача после погрузки на судно - оплачено до пункта доставки",' +
				  '"Incoterms": "CIF",' +
				  '"Id": "002"' +
				'},' +
				'"SalesRep": {' +
				  '"Name": "Rodriguez Marcelo",' +
				  '"UserId": null,' +
				  '"Email": "marcelo.rodriguez@m.interpipe.biz",' +
				  '"Id": "54124"' +
				'},' +
				'"BoSpecialist": {' +
				  '"Name": "Недилько Анна Игоревна",' +
				  '"UserId": "AINEDILKO",' +
				  '"Email": "Anna.Nedilko@m.interpipe.biz",' +
				  '"Id": "  54809"' +
				'},' +
				'"CrossMarket_BusinessSegment": "",' +
				'"CrossMarket_SalesRep": {' +
				  '"Name": "",' +
				  '"UserId": "",' +
				 ' "Email": "",' +
				  '"Id": ""' +
				'},' +
				'"CrossMarket_Percent": 0.00' +
			  '},' +
			  '"Items": [' +
				'{' +
				  '"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				  '"Npp": '+Integer.valueOf(ID_ERP_Opportunity_Product)+',' +
				  '"IteNumber": "21-000320-001",' +
				  '"ProductGroup": {' +
					'"Name": "БОН",' +
					'"Id": "20"' +
				'},' +
				  '"QuotaType": {' +
					'"Shop": {' +
					  '"Name": "Tube-rolling shop 7",' +
					  '"Id": "7"' +
					'},' +
					'"Name": "Shop7: ф32-38",' +
					'"Id": "6"' +
				  '},' +
				  '"Shop": {' +
					'"Mill": {' +
					  '"Name": "Interpipe Nikotube, LLC",' +
					  '"Id": "2"' +
					'},' +
					'"Name": "Tube-rolling shop 7",' +
					'"Id": "7"' +
				  '},' +
				  '"InqQuantity": 5.00000,' +
				  '"InqUnit": 20,' +
				  '"Quantity_Mt": '+Decimal.valueOf(Quantity_Mt)+',' +
				  '"Quantity_m": 1998.12700,' +
				  '"Quantity_ft": 0.0,' +
				  '"Quantity_pcs": 0.0,' +
				  '"LinearWeight_ppf": 1.681,' +
				  '"LinearWeight_kpm": 1000.000,' +
				  '"Price": 880.00000,' +
				  '"Price_t": 880.00000,' +
				  '"Margin_t": 100.81133,' +
				  '"TotalPrice": 0.0,' +
				  '"ShippingPoint": {' +
					'"spType": 1,' +
					'"Id": "52048",' +
					'"Name": "SANTOS (BRAZIL)"' +
				  '},' +
				  '"IsTypical": 1,' +
				  '"TechExp": 2,' +
				  '"CriticalDispatchDate": "2021-04-30T00:00:00",' +
				  '"RecommendedCDD": "2021-04-30T00:00:00",' +
				  '"FinStatus": "Approved",' +
				 ' "FinApproval": 1,' +
				 ' "Stage": "_6",' +
				  '"Produced": 0.0,' +
				  '"Dispatched": 0.0,' +
				  '"Shipped": 0.0,' +
				  '"Lots": [],' +
				  '"Quotas": [' +
					'{' +
					  '"QuotaDate": "2021-04-01T00:00:00",' +
					  '"Quantity_Mt": 5.0000,' +
					  '"Quantity_pcs": 345.0000,' +
					  '"PriceExw_t": 764.60000,' +
					  '"Margin_t": 100.81133' +
					'}' +
				  '],' +
				  '"FinDataShipped": 0.0,' +
				  '"FinDataMargin": 0.0,' +
				  '"ProductCharacteristic": {' +
					'"Diameter": {' +
					  '"OD_mm": 33.400,' +
					  '"Name": "33,40",' +
					  '"FacetCode": "DIMP",' +
					  '"Id": "0H"' +
					'},' +
					'"Thickness": {' +
					  '"Wt_mm": 3.380,' +
					  '"Name": "3,38",' +
					  '"FacetCode": "WLMP",' +
					  '"Id": "2B"' +
					'},' +
					'"LengthSize": {' +
					  '"MinLength": 5500.000000,' +
					  '"MaxLength": 5800.000000,' +
					  '"Name": "5500-5800",' +
					  '"FacetCode": "LNMP",' +
					  '"Id": "VW"' +
					'},' +
					'"Ends": {' +
					  '"Name": "Обрезка под прямым углом",'+
					  '"FacetCode": "P1PG",' +
					  '"Id": "Г"' +
					'},' +
					'"Coating": {' +
					  '"Name": "Покрытие лаком",' +
					  '"FacetCode": "P2PG",' +
					  '"Id": "K"' +
					'},' +
					'"Standard": {' +
					  '"Name": "API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015",' +
					  '"Id": "2492"' +
					'},' +
					'"SteelGrade": {' +
					  '"Name": "B",' +
					  '"FacetCode": "SGMP",' +
					  '"Id": "28"' +
					'}'+ 
				 ' },' +
				  '"CoatingSpec": "Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.",' +
				  '"SpecLevel": {' +
					'"Name": "PSL1",' +
					'"Id": "1"' +
				  '},' +
				  '"WeightMainUnit_kg": 1000.000,' +
				  '"LengthMin_mm": 0.0,' +
				  '"LengthMax_mm": 0.0' +
				'}' +
			  ']' +
			'}' +
		 ' }';

		//json_body = '{"Metadata":{"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":0,"MsgTimestamp":"2021-11-01T16:00:52.6592404+02:00","PartNumber":1,"TotalParts":1},"Data":{"OrderType":"Tubes","OrderCurrency":"USD","Header":{"Undoc":22655316,"IteNumber":"21-000320","AltNumber":"COC21/0079","CreatedDate":"2021-01-18T19:17:18","OrderDate":"2021-01-18T00:00:00","Account":{"Name":"Tubos Oliveira Ltda","Id":"62549"},"BusinessSegmentId":"00001","RegionId":5,"CountryId":76,"PaymentTerms":{"Name":"50% Оплата в теч. 0 к.д. Специальная дата до Банковский перевод, 50% Оплата в теч. 30 к.д. Факт отгрузки с перевалки Банковский перевод,","Id":"K91"},"DeliveryTerms":{"Name":"CIF - передача после погрузки на судно - оплачено до пункта доставки","Incoterms":"CIF","Id":"002"},"SalesRep":{"Name":"Rodriguez Marcelo","UserId":null,"Email":"marcelo.rodriguez@m.interpipe.biz","Id":"ttt321123"},"BoSpecialist":{"Name":"Недилько Анна Игоревна","UserId":"AINEDILKO","Email":"Anna.Nedilko@m.interpipe.biz","Id":"  54809"},"CrossMarket_BusinessSegment":"","CrossMarket_SalesRep":{"Name":"","UserId":"","Email":"","Id":""},"CrossMarket_Percent":0},"Items":[{"Undoc":22655316,"Npp":1,"IteNumber":"21-000320-001","ProductGroup":{"Name":"БОН","Id":"20"},"QuotaType":{"Shop":{"Name":"Tube-rolling shop 7","Id":"7"},"Name":"Shop7: ф32-38","Id":"6"},"Shop":{"Mill":{"Name":"Interpipe Nikotube, LLC","Id":"2"},"Name":"Tube-rolling shop 7","Id":"7"},"InqQuantity":5,"InqUnit":34,"Quantity_Mt":5,"Quantity_m":1998.127,"Quantity_ft":0,"Quantity_pcs":0,"LinearWeight_ppf":1.681,"LinearWeight_kpm":1000,"Price":880,"Price_t":880,"Margin_t":100.81133,"TotalPrice":0,"ShippingPoint":{"spType":1,"Id":"52048","Name":"SANTOS (BRAZIL)"},"IsTypical":1,"TechExp":2,"CriticalDispatchDate":"2021-04-30T00:00:00","RecommendedCDD":"2021-04-30T00:00:00","FinStatus":"Approved","FinApproval":1,"Stage":"Processing","Produced":0,"Dispatched":0,"Shipped":0,"Lots":[],"Quotas":[{"QuotaDate":"2021-04-01T00:00:00","Quantity_Mt":5,"Quantity_pcs":345,"PriceExw_t":764.6,"Margin_t":100.81133}],"FinDataShipped":0,"FinDataMargin":0,"ProductCharacteristic":{"Diameter":{"OD_mm":33.4,"Name":"33,40","FacetCode":"DIMP","Id":"0H"},"Thickness":{"Wt_mm":3.38,"Name":"3,38","FacetCode":"WLMP","Id":"2B"},"LengthSize":{"MinLength":5500,"MaxLength":5800,"Name":"5500-5800","FacetCode":"LNMP","Id":"VW"},"Ends":{"Name":"Обрезка под прямым углом","FacetCode":"P1PG","Id":"Г"},"Coating":{"Name":"Покрытие лаком","FacetCode":"P2PG","Id":"K"},"Standard":{"Name":"API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015","Id":"2492"},"SteelGrade":{"Name":"B","FacetCode":"SGMP","Id":"28"}},"CoatingSpec":"Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.","SpecLevel":{"Name":"PSL1","Id":"1"},"WeightMainUnit_kg":1000,"LengthMin_mm":0,"LengthMax_mm":0}]}}';
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



@IsTest static void testSyncedOpportunityRequest() {

	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];
	OpportunityLineItem changed_oppLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

	Datetime currentDateTime = Datetime.now();
	Long getEpochFromDate = currentDateTime.getTime();

	String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length() - 3);

	String receivedBody = getJSONBodyForSyncedResponce(epochFromDate, '1335452', changed_oppLI.Id, '1');

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

	Opportunity testOpp_verify = [SELECT Id, LastSyncERP__c FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];
	OpportunityLineItem changed_oppLI_verify = [SELECT Id, NPP_ERP__c FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

	System.debug('testOpp_verify.LastSyncERP__c ' + testOpp_verify.LastSyncERP__c);
	System.debug('currentDateTime ' + currentDateTime);
	System.assertEquals(testOpp_verify.LastSyncERP__c, currentDateTime);
	System.assertEquals(changed_oppLI_verify.NPP_ERP__c, '9011961777');
}

@IsTest static void testSyncedOpportunityRequestRejected() {

	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];
	OpportunityLineItem changed_oppLI = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id LIMIT 1];

	Datetime currentDateTime = Datetime.now();
	Long getEpochFromDate = currentDateTime.getTime();

	String epochFromDate = String.valueOf(getEpochFromDate).substring(0, String.valueOf(getEpochFromDate).length() - 3);

	String receivedBody = getJSONBodyForSyncedResponce(epochFromDate, '1335452', changed_oppLI.Id, '-1');

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

	Opportunity testOpp_verify = [SELECT Id, LastSyncERP__c FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];

	System.debug('testOpp_verify.LastSyncERP__c ' + testOpp_verify.LastSyncERP__c);
	System.debug('currentDateTime ' + currentDateTime);
	System.assertNOtEquals(testOpp_verify.LastSyncERP__c, currentDateTime);

}

@IsTest static void CreateNewOpportunity() {

	String ID_ERP_of_new_opportunity = '14453663';
	String ID_ERP_of_new_Opp_Product = '2';

	String receivedBody = getJSONBodyInqUnit74(ID_ERP_of_new_opportunity, ID_ERP_of_new_Opp_Product, 'USD', '3600','оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

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

	List<Opportunity> opp = [SELECT Id
	                         FROM Opportunity WHERE
	                         ID_ERP__c = :ID_ERP_of_new_opportunity];

	//System.assertEquals(1, opp.size());
}



@IsTest static void checkOrderMapping() {

	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];

	String receivedBody = getJSONBody('1335452', '2', 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

	RestRequest req = new RestRequest();
	RestResponse res = new RestResponse();

	req.requestURI = '/ERPtoSF/v1/*';
	req.httpMethod = 'POST';
	req.requestBody = Blob.valueOf(receivedBody);
	RestContext.request = req;
	RestContext.response = res;

	Test.startTest();
	testOpp.StageName = 'Closed Won';
	testOpp.MarketSegment__c = '00002';
	update testOpp;
	ERPtoSF.postCST();
	Test.stopTest();

	// Opportunity opp_to_verify = [SELECT Id, Country__c, SyncedOrder__c FROM Opportunity LIMIT 1];
	// Order ord_to_verify = [SELECT Id, Country__c FROM Order LIMIT 1];
	//System.debug('Country on opp - ' + opp_to_verify.Country__c);

	//System.assertEquals(opp_to_verify.SyncedOrder__c, ord_to_verify.Id);
	//System.assertEquals(opp_to_verify.Country__c, ord_to_verify.Country__c);
}

@IsTest static void checkNullQuantity() {

	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];

	String receivedBody = getJSONBody('1335452', '2', 'USD', '0', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

	RestRequest req = new RestRequest();
	RestResponse res = new RestResponse();

	req.requestURI = '/ERPtoSF/v1/*';
	req.httpMethod = 'POST';
	req.requestBody = Blob.valueOf(receivedBody);
	RestContext.request = req;
	RestContext.response = res;

	Test.startTest();
	testOpp.StageName = 'Closed Won';
	testOpp.MarketSegment__c = '00002';
	update testOpp;
	ERPtoSF.postCST();
	Test.stopTest();


	// OrderItem ordi_to_verify = [SELECT Id, Quantity FROM OrderItem LIMIT 1];
	// System.debug('Quantity on order item - ' + ordi_to_verify.Quantity);

	// System.assertNotEquals(null, ordi_to_verify.Quantity);

}

@IsTest static void checkPaymentTermsLongName() {

	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];

	String receivedBody = getJSONBody('1335452', '2', 'USD', '2300', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив, оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив.');

	RestRequest req = new RestRequest();
	RestResponse res = new RestResponse();

	req.requestURI = '/ERPtoSF/v1/*';
	req.httpMethod = 'POST';
	req.requestBody = Blob.valueOf(receivedBody);
	RestContext.request = req;
	RestContext.response = res;

	Test.startTest();
	testOpp.StageName = 'Closed Won';
	testOpp.MarketSegment__c = '00002';
	System.debug('This is before');
	update testOpp;
	
	ERPtoSF.postCST();
	System.debug('This is after');
	Test.stopTest();

	List<PaymentTerms__c> paymentTerms = [SELECT Name FROM PaymentTerms__c];
	//System.assertEquals('оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив,...', paymentTerms[0].Name);
}


@IsTest static void opportunityChangedCurrencyCode() {

	Country__c country = [SELECT Id FROM Country__c WHERE NumCode__c = '0'];
	Opportunity testOpp = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];

	String newCurrency = 'EUR';
	String receivedBody = getJSONBodyInqUnit43('1335452', '2', newCurrency, '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

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

	Opportunity opp_to_verify = [SELECT Id, CurrencyIsoCode FROM Opportunity LIMIT 1];


	//System.assertEquals(opp_to_verify.CurrencyIsoCode, newCurrency);

}




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

@isTest static void test_getOpportunitySF() {

	Opportunity testOpp = [SELECT Id FROM Opportunity WHERE ID_ERP__c = '1335452'];
	String oppERPid = '1335452';

	t.start();
	Opportunity opp = ERPWebServiceHandler.getOpportunitySFByERPID(oppERPid);
	t.stop();

	Opportunity expectedOpp = [SELECT Id FROM Opportunity LIMIT 1];
	System.assertEquals(expectedOpp.Id, opp.Id);
}



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

@IsTest
static void test_Opportunity_without_ID_ERP() {

	// Opportunity testOpp = [SELECT Id, ID_ERP__c FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];
	// List<OpportunityLineItem> oppLI = [SELECT Id, ID_ERP__c, NPP_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

	// String receivedBody = getJSONBody(null, oppLI[0].NPP_ERP__c, 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

	// RestRequest req = new RestRequest();
	// RestResponse res = new RestResponse();

	// req.requestURI = '/ERPtoSFdev/v1/*';
	// req.httpMethod = 'POST';
	// req.requestBody = Blob.valueOf(receivedBody);
	// RestContext.request = req;
	// RestContext.response = res;

	// Test.startTest();

	// try {
	// 	ERPtoSF.postCST();
	// } catch(Exception e) {
	// 	System.assert(e.getMessage().contains('Your request does not contain ID_ERP field for Opportunity.'), e.getMessage());
	// }

	// Test.stopTest();
}
    
    @IsTest static void productGroupChangeOnOppProduct() {

	Opportunity testOpp = [SELECT Id, ID_ERP__c FROM Opportunity WHERE ID_ERP__c = '1335452' LIMIT 1];
	List<OpportunityLineItem> oppLI = [SELECT Id, ID_ERP__c, NPP_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

	System.debug('ID_ERP of OppLI - ' + oppLI[0].ID_ERP__c);
	System.debug('OPpLine items - ' + oppLI);
	System.debug('Product2Id - ' + oppLI[0].Product2Id);

	String receivedBody = getJSONBodyInqUnit20(testOpp.ID_ERP__c, oppLI[0].NPP_ERP__c, 'USD', '3600', 'оплата 100% в течение 60 календарных дней Дата ГТД Документарный аккредитив');

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

	List<OpportunityLineItem> changed_oppLI = [SELECT Id, ID_ERP__c, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
	System.debug('Product2Id after logic done - ' + changed_oppLI[0].Product2Id);
	System.debug('oppLI[0] ' + oppLI[0]);
	System.debug('changed_oppLI[0] ' + changed_oppLI[0]);
}
    
    private static String getJSONBodyInqUnit74(String ID_ERP_Opportunity, String ID_ERP_Opportunity_Product, String CurrencyISOCode, String Quantity_Mt, String paymentTermsName) {

		String json_body =   
		'{' +
			'"Metadata": {' +
			  '"MsgType": "ERP-SF_OpportunityData",' +
			  '"MsgTypeVersion": 0.0,' +
			  '"MsgTimestamp": "2021-11-01T16:00:52.6592404+02:00",' +
			  '"PartNumber": 1,' +
			  '"TotalParts": 1' +
			'},' +
			'"Data": {' +
			  '"OrderType": "Tubes",' +
			  '"OrderCurrency": "'+CurrencyISOCode+'",' +
			  '"Header": {' +
				'"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				'"IteNumber": "21-000320",' +
				'"AltNumber": "COC21/0079",' +
				'"CreatedDate": "2021-01-18T19:17:18",' +
				'"OrderDate": "2021-01-18T00:00:00",' +
				'"Account": {' +
				  '"Name": "Tubos Oliveira Ltda",' +
				  '"Id": "62549"' +
				'},' +
				'"BusinessSegmentId": "00001",' +
				'"RegionId": 5,' +
				'"CountryId": 76,' +
				'"PaymentTerms": {' +
				  '"Name": "'+paymentTermsName+'",' +
				  '"Id": "K91"' +
				'},' +
				'"DeliveryTerms": {' +
				  '"Name": "CIF - передача после погрузки на судно - оплачено до пункта доставки",' +
				  '"Incoterms": "CIF",' +
				  '"Id": "002"' +
				'},' +
				'"SalesRep": {' +
				  '"Name": "Rodriguez Marcelo",' +
				  '"UserId": null,' +
				  '"Email": "marcelo.rodriguez@m.interpipe.biz",' +
				  '"Id": "54124"' +
				'},' +
				'"BoSpecialist": {' +
				  '"Name": "Недилько Анна Игоревна",' +
				  '"UserId": "AINEDILKO",' +
				  '"Email": "Anna.Nedilko@m.interpipe.biz",' +
				  '"Id": "  54809"' +
				'},' +
				'"CrossMarket_BusinessSegment": "",' +
				'"CrossMarket_SalesRep": {' +
				  '"Name": "",' +
				  '"UserId": "",' +
				 ' "Email": "",' +
				  '"Id": ""' +
				'},' +
				'"CrossMarket_Percent": 0.00' +
			  '},' +
			  '"Items": [' +
				'{' +
				  '"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				  '"Npp": '+Integer.valueOf(ID_ERP_Opportunity_Product)+',' +
				  '"IteNumber": "21-000320-001",' +
				  '"ProductGroup": {' +
					'"Name": "БОН",' +
					'"Id": "20"' +
				'},' +
				  '"QuotaType": {' +
					'"Shop": {' +
					  '"Name": "Tube-rolling shop 7",' +
					  '"Id": "7"' +
					'},' +
					'"Name": "Shop7: ф32-38",' +
					'"Id": "6"' +
				  '},' +
				  '"Shop": {' +
					'"Mill": {' +
					  '"Name": "Interpipe Nikotube, LLC",' +
					  '"Id": "2"' +
					'},' +
					'"Name": "Tube-rolling shop 7",' +
					'"Id": "7"' +
				  '},' +
				  '"InqQuantity": 5.00000,' +
				  '"InqUnit": 74,' +
				  '"Quantity_Mt": '+Decimal.valueOf(Quantity_Mt)+',' +
				  '"Quantity_m": 1998.12700,' +
				  '"Quantity_ft": 0.0,' +
				  '"Quantity_pcs": 0.0,' +
				  '"LinearWeight_ppf": 1.681,' +
				  '"LinearWeight_kpm": 1000.000,' +
				  '"Price": 880.00000,' +
				  '"Price_t": 880.00000,' +
				  '"Margin_t": 100.81133,' +
				  '"TotalPrice": 0.0,' +
				  '"ShippingPoint": {' +
					'"spType": 1,' +
					'"Id": "52048",' +
					'"Name": "SANTOS (BRAZIL)"' +
				  '},' +
				  '"IsTypical": 1,' +
				  '"TechExp": 2,' +
				  '"CriticalDispatchDate": "2021-04-30T00:00:00",' +
				  '"RecommendedCDD": "2021-04-30T00:00:00",' +
				  '"FinStatus": "Approved",' +
				 ' "FinApproval": 1,' +
				 ' "Stage": "_6",' +
				  '"Produced": 0.0,' +
				  '"Dispatched": 0.0,' +
				  '"Shipped": 0.0,' +
				  '"Lots": [],' +
				  '"Quotas": [' +
					'{' +
					  '"QuotaDate": "2021-04-01T00:00:00",' +
					  '"Quantity_Mt": 5.0000,' +
					  '"Quantity_pcs": 345.0000,' +
					  '"PriceExw_t": 764.60000,' +
					  '"Margin_t": 100.81133' +
					'}' +
				  '],' +
				  '"FinDataShipped": 0.0,' +
				  '"FinDataMargin": 0.0,' +
				  '"ProductCharacteristic": {' +
					'"Diameter": {' +
					  '"OD_mm": 33.400,' +
					  '"Name": "33,40",' +
					  '"FacetCode": "DIMP",' +
					  '"Id": "0H"' +
					'},' +
					'"Thickness": {' +
					  '"Wt_mm": 3.380,' +
					  '"Name": "3,38",' +
					  '"FacetCode": "WLMP",' +
					  '"Id": "2B"' +
					'},' +
					'"LengthSize": {' +
					  '"MinLength": 5500.000000,' +
					  '"MaxLength": 5800.000000,' +
					  '"Name": "5500-5800",' +
					  '"FacetCode": "LNMP",' +
					  '"Id": "VW"' +
					'},' +
					'"Ends": {' +
					  '"Name": "Обрезка под прямым углом",'+
					  '"FacetCode": "P1PG",' +
					  '"Id": "Г"' +
					'},' +
					'"Coating": {' +
					  '"Name": "Покрытие лаком",' +
					  '"FacetCode": "P2PG",' +
					  '"Id": "K"' +
					'},' +
					'"Standard": {' +
					  '"Name": "API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015",' +
					  '"Id": "2492"' +
					'},' +
					'"SteelGrade": {' +
					  '"Name": "B",' +
					  '"FacetCode": "SGMP",' +
					  '"Id": "28"' +
					'}'+ 
				 ' },' +
				  '"CoatingSpec": "Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.",' +
				  '"SpecLevel": {' +
					'"Name": "PSL1",' +
					'"Id": "1"' +
				  '},' +
				  '"WeightMainUnit_kg": 1000.000,' +
				  '"LengthMin_mm": 0.0,' +
				  '"LengthMax_mm": 0.0' +
				'}' +
			  ']' +
			'}' +
		 ' }';

		//json_body = '{"Metadata":{"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":0,"MsgTimestamp":"2021-11-01T16:00:52.6592404+02:00","PartNumber":1,"TotalParts":1},"Data":{"OrderType":"Tubes","OrderCurrency":"USD","Header":{"Undoc":22655316,"IteNumber":"21-000320","AltNumber":"COC21/0079","CreatedDate":"2021-01-18T19:17:18","OrderDate":"2021-01-18T00:00:00","Account":{"Name":"Tubos Oliveira Ltda","Id":"62549"},"BusinessSegmentId":"00001","RegionId":5,"CountryId":76,"PaymentTerms":{"Name":"50% Оплата в теч. 0 к.д. Специальная дата до Банковский перевод, 50% Оплата в теч. 30 к.д. Факт отгрузки с перевалки Банковский перевод,","Id":"K91"},"DeliveryTerms":{"Name":"CIF - передача после погрузки на судно - оплачено до пункта доставки","Incoterms":"CIF","Id":"002"},"SalesRep":{"Name":"Rodriguez Marcelo","UserId":null,"Email":"marcelo.rodriguez@m.interpipe.biz","Id":"ttt321123"},"BoSpecialist":{"Name":"Недилько Анна Игоревна","UserId":"AINEDILKO","Email":"Anna.Nedilko@m.interpipe.biz","Id":"  54809"},"CrossMarket_BusinessSegment":"","CrossMarket_SalesRep":{"Name":"","UserId":"","Email":"","Id":""},"CrossMarket_Percent":0},"Items":[{"Undoc":22655316,"Npp":1,"IteNumber":"21-000320-001","ProductGroup":{"Name":"БОН","Id":"20"},"QuotaType":{"Shop":{"Name":"Tube-rolling shop 7","Id":"7"},"Name":"Shop7: ф32-38","Id":"6"},"Shop":{"Mill":{"Name":"Interpipe Nikotube, LLC","Id":"2"},"Name":"Tube-rolling shop 7","Id":"7"},"InqQuantity":5,"InqUnit":34,"Quantity_Mt":5,"Quantity_m":1998.127,"Quantity_ft":0,"Quantity_pcs":0,"LinearWeight_ppf":1.681,"LinearWeight_kpm":1000,"Price":880,"Price_t":880,"Margin_t":100.81133,"TotalPrice":0,"ShippingPoint":{"spType":1,"Id":"52048","Name":"SANTOS (BRAZIL)"},"IsTypical":1,"TechExp":2,"CriticalDispatchDate":"2021-04-30T00:00:00","RecommendedCDD":"2021-04-30T00:00:00","FinStatus":"Approved","FinApproval":1,"Stage":"Processing","Produced":0,"Dispatched":0,"Shipped":0,"Lots":[],"Quotas":[{"QuotaDate":"2021-04-01T00:00:00","Quantity_Mt":5,"Quantity_pcs":345,"PriceExw_t":764.6,"Margin_t":100.81133}],"FinDataShipped":0,"FinDataMargin":0,"ProductCharacteristic":{"Diameter":{"OD_mm":33.4,"Name":"33,40","FacetCode":"DIMP","Id":"0H"},"Thickness":{"Wt_mm":3.38,"Name":"3,38","FacetCode":"WLMP","Id":"2B"},"LengthSize":{"MinLength":5500,"MaxLength":5800,"Name":"5500-5800","FacetCode":"LNMP","Id":"VW"},"Ends":{"Name":"Обрезка под прямым углом","FacetCode":"P1PG","Id":"Г"},"Coating":{"Name":"Покрытие лаком","FacetCode":"P2PG","Id":"K"},"Standard":{"Name":"API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015","Id":"2492"},"SteelGrade":{"Name":"B","FacetCode":"SGMP","Id":"28"}},"CoatingSpec":"Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.","SpecLevel":{"Name":"PSL1","Id":"1"},"WeightMainUnit_kg":1000,"LengthMin_mm":0,"LengthMax_mm":0}]}}';
		return json_body;
	}
    
    private static String getJSONBodyInqUnit43(String ID_ERP_Opportunity, String ID_ERP_Opportunity_Product, String CurrencyISOCode, String Quantity_Mt, String paymentTermsName) {

		String json_body =   
		'{' +
			'"Metadata": {' +
			  '"MsgType": "ERP-SF_OpportunityData",' +
			  '"MsgTypeVersion": 0.0,' +
			  '"MsgTimestamp": "2021-11-01T16:00:52.6592404+02:00",' +
			  '"PartNumber": 1,' +
			  '"TotalParts": 1' +
			'},' +
			'"Data": {' +
			  '"OrderType": "Tubes",' +
			  '"OrderCurrency": "'+CurrencyISOCode+'",' +
			  '"Header": {' +
				'"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				'"IteNumber": "21-000320",' +
				'"AltNumber": "COC21/0079",' +
				'"CreatedDate": "2021-01-18T19:17:18",' +
				'"OrderDate": "2021-01-18T00:00:00",' +
				'"Account": {' +
				  '"Name": "Tubos Oliveira Ltda",' +
				  '"Id": "62549"' +
				'},' +
				'"BusinessSegmentId": "00001",' +
				'"RegionId": 5,' +
				'"CountryId": 76,' +
				'"PaymentTerms": {' +
				  '"Name": "'+paymentTermsName+'",' +
				  '"Id": "K91"' +
				'},' +
				'"DeliveryTerms": {' +
				  '"Name": "CIF - передача после погрузки на судно - оплачено до пункта доставки",' +
				  '"Incoterms": "CIF",' +
				  '"Id": "002"' +
				'},' +
				'"SalesRep": {' +
				  '"Name": "Rodriguez Marcelo",' +
				  '"UserId": null,' +
				  '"Email": "marcelo.rodriguez@m.interpipe.biz",' +
				  '"Id": "54124"' +
				'},' +
				'"BoSpecialist": {' +
				  '"Name": "Недилько Анна Игоревна",' +
				  '"UserId": "AINEDILKO",' +
				  '"Email": "Anna.Nedilko@m.interpipe.biz",' +
				  '"Id": "  54809"' +
				'},' +
				'"CrossMarket_BusinessSegment": "",' +
				'"CrossMarket_SalesRep": {' +
				  '"Name": "",' +
				  '"UserId": "",' +
				 ' "Email": "",' +
				  '"Id": ""' +
				'},' +
				'"CrossMarket_Percent": 0.00' +
			  '},' +
			  '"Items": [' +
				'{' +
				  '"Undoc": '+Integer.valueOf(ID_ERP_Opportunity)+',' +
				  '"Npp": '+Integer.valueOf(ID_ERP_Opportunity_Product)+',' +
				  '"IteNumber": "21-000320-001",' +
				  '"ProductGroup": {' +
					'"Name": "БОН",' +
					'"Id": "20"' +
				'},' +
				  '"QuotaType": {' +
					'"Shop": {' +
					  '"Name": "Tube-rolling shop 7",' +
					  '"Id": "7"' +
					'},' +
					'"Name": "Shop7: ф32-38",' +
					'"Id": "6"' +
				  '},' +
				  '"Shop": {' +
					'"Mill": {' +
					  '"Name": "Interpipe Nikotube, LLC",' +
					  '"Id": "2"' +
					'},' +
					'"Name": "Tube-rolling shop 7",' +
					'"Id": "7"' +
				  '},' +
				  '"InqQuantity": 5.00000,' +
				  '"InqUnit": 43,' +
				  '"Quantity_Mt": '+Decimal.valueOf(Quantity_Mt)+',' +
				  '"Quantity_m": 1998.12700,' +
				  '"Quantity_ft": 0.0,' +
				  '"Quantity_pcs": 0.0,' +
				  '"LinearWeight_ppf": 1.681,' +
				  '"LinearWeight_kpm": 1000.000,' +
				  '"Price": 880.00000,' +
				  '"Price_t": 880.00000,' +
				  '"Margin_t": 100.81133,' +
				  '"TotalPrice": 0.0,' +
				  '"ShippingPoint": {' +
					'"spType": 1,' +
					'"Id": "52048",' +
					'"Name": "SANTOS (BRAZIL)"' +
				  '},' +
				  '"IsTypical": 1,' +
				  '"TechExp": 2,' +
				  '"CriticalDispatchDate": "2021-04-30T00:00:00",' +
				  '"RecommendedCDD": "2021-04-30T00:00:00",' +
				  '"FinStatus": "Approved",' +
				 ' "FinApproval": 1,' +
				 ' "Stage": "_6",' +
				  '"Produced": 0.0,' +
				  '"Dispatched": 0.0,' +
				  '"Shipped": 0.0,' +
				  '"Lots": [],' +
				  '"Quotas": [' +
					'{' +
					  '"QuotaDate": "2021-04-01T00:00:00",' +
					  '"Quantity_Mt": 5.0000,' +
					  '"Quantity_pcs": 345.0000,' +
					  '"PriceExw_t": 764.60000,' +
					  '"Margin_t": 100.81133' +
					'}' +
				  '],' +
				  '"FinDataShipped": 0.0,' +
				  '"FinDataMargin": 0.0,' +
				  '"ProductCharacteristic": {' +
					'"Diameter": {' +
					  '"OD_mm": 33.400,' +
					  '"Name": "33,40",' +
					  '"FacetCode": "DIMP",' +
					  '"Id": "0H"' +
					'},' +
					'"Thickness": {' +
					  '"Wt_mm": 3.380,' +
					  '"Name": "3,38",' +
					  '"FacetCode": "WLMP",' +
					  '"Id": "2B"' +
					'},' +
					'"LengthSize": {' +
					  '"MinLength": 5500.000000,' +
					  '"MaxLength": 5800.000000,' +
					  '"Name": "5500-5800",' +
					  '"FacetCode": "LNMP",' +
					  '"Id": "VW"' +
					'},' +
					'"Ends": {' +
					  '"Name": "Обрезка под прямым углом",'+
					  '"FacetCode": "P1PG",' +
					  '"Id": "Г"' +
					'},' +
					'"Coating": {' +
					  '"Name": "Покрытие лаком",' +
					  '"FacetCode": "P2PG",' +
					  '"Id": "K"' +
					'},' +
					'"Standard": {' +
					  '"Name": "API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015",' +
					  '"Id": "2492"' +
					'},' +
					'"SteelGrade": {' +
					  '"Name": "B",' +
					  '"FacetCode": "SGMP",' +
					  '"Id": "28"' +
					'}'+ 
				 ' },' +
				  '"CoatingSpec": "Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.",' +
				  '"SpecLevel": {' +
					'"Name": "PSL1",' +
					'"Id": "1"' +
				  '},' +
				  '"WeightMainUnit_kg": 1000.000,' +
				  '"LengthMin_mm": 0.0,' +
				  '"LengthMax_mm": 0.0' +
				'}' +
			  ']' +
			'}' +
		 ' }';

		//json_body = '{"Metadata":{"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":0,"MsgTimestamp":"2021-11-01T16:00:52.6592404+02:00","PartNumber":1,"TotalParts":1},"Data":{"OrderType":"Tubes","OrderCurrency":"USD","Header":{"Undoc":22655316,"IteNumber":"21-000320","AltNumber":"COC21/0079","CreatedDate":"2021-01-18T19:17:18","OrderDate":"2021-01-18T00:00:00","Account":{"Name":"Tubos Oliveira Ltda","Id":"62549"},"BusinessSegmentId":"00001","RegionId":5,"CountryId":76,"PaymentTerms":{"Name":"50% Оплата в теч. 0 к.д. Специальная дата до Банковский перевод, 50% Оплата в теч. 30 к.д. Факт отгрузки с перевалки Банковский перевод,","Id":"K91"},"DeliveryTerms":{"Name":"CIF - передача после погрузки на судно - оплачено до пункта доставки","Incoterms":"CIF","Id":"002"},"SalesRep":{"Name":"Rodriguez Marcelo","UserId":null,"Email":"marcelo.rodriguez@m.interpipe.biz","Id":"ttt321123"},"BoSpecialist":{"Name":"Недилько Анна Игоревна","UserId":"AINEDILKO","Email":"Anna.Nedilko@m.interpipe.biz","Id":"  54809"},"CrossMarket_BusinessSegment":"","CrossMarket_SalesRep":{"Name":"","UserId":"","Email":"","Id":""},"CrossMarket_Percent":0},"Items":[{"Undoc":22655316,"Npp":1,"IteNumber":"21-000320-001","ProductGroup":{"Name":"БОН","Id":"20"},"QuotaType":{"Shop":{"Name":"Tube-rolling shop 7","Id":"7"},"Name":"Shop7: ф32-38","Id":"6"},"Shop":{"Mill":{"Name":"Interpipe Nikotube, LLC","Id":"2"},"Name":"Tube-rolling shop 7","Id":"7"},"InqQuantity":5,"InqUnit":34,"Quantity_Mt":5,"Quantity_m":1998.127,"Quantity_ft":0,"Quantity_pcs":0,"LinearWeight_ppf":1.681,"LinearWeight_kpm":1000,"Price":880,"Price_t":880,"Margin_t":100.81133,"TotalPrice":0,"ShippingPoint":{"spType":1,"Id":"52048","Name":"SANTOS (BRAZIL)"},"IsTypical":1,"TechExp":2,"CriticalDispatchDate":"2021-04-30T00:00:00","RecommendedCDD":"2021-04-30T00:00:00","FinStatus":"Approved","FinApproval":1,"Stage":"Processing","Produced":0,"Dispatched":0,"Shipped":0,"Lots":[],"Quotas":[{"QuotaDate":"2021-04-01T00:00:00","Quantity_Mt":5,"Quantity_pcs":345,"PriceExw_t":764.6,"Margin_t":100.81133}],"FinDataShipped":0,"FinDataMargin":0,"ProductCharacteristic":{"Diameter":{"OD_mm":33.4,"Name":"33,40","FacetCode":"DIMP","Id":"0H"},"Thickness":{"Wt_mm":3.38,"Name":"3,38","FacetCode":"WLMP","Id":"2B"},"LengthSize":{"MinLength":5500,"MaxLength":5800,"Name":"5500-5800","FacetCode":"LNMP","Id":"VW"},"Ends":{"Name":"Обрезка под прямым углом","FacetCode":"P1PG","Id":"Г"},"Coating":{"Name":"Покрытие лаком","FacetCode":"P2PG","Id":"K"},"Standard":{"Name":"API Spec 5L - 2018/ ASTM A106/A106M-2019/ ASME SA106/SA106M-2019/ NACE MR0175/ ISO 15156-2:2015/ NACE MR0103/ISO 17945:2015","Id":"2492"},"SteelGrade":{"Name":"B","FacetCode":"SGMP","Id":"28"}},"CoatingSpec":"Лак УФО (прозрачный либо smoked) или водорастворимый лак черного цвета. Выбор материала покрытия на усмотрение производителя.","SpecLevel":{"Name":"PSL1","Id":"1"},"WeightMainUnit_kg":1000,"LengthMin_mm":0,"LengthMax_mm":0}]}}';
		return json_body;
	}



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

	TubeEnds__c tubeEnds = new TubeEnds__c(ShortName__c = 'EUE',Id_ERP__C='Г');
	insert tubeEnds;

	Plant__c plant = new Plant__c(FullName__c = 'Plant Full Name');
	insert plant;
	
	Shop__c shop = new Shop__c(Plant__c = plant.Id);
	insert shop;
	
	TubeOD__c tubeOD = new TubeOD__c(ID_ERP__c = '0H');
	insert tubeOD;
	
	TubeWT__c tubeWT = new TubeWT__c(ID_ERP__c = '2B');
	insert tubeWT;
	
	Opportunity testOpp = t.newOpportunities('Test', testAccount.Id, 'Qualification', Date.today()) [0];
	testOpp.ID_ERP__c = '1335452';
    
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