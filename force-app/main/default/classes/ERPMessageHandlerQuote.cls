public class ERPMessageHandlerQuote  {

	//public final static Map<String, String> labelsToSfAPINames = new Map<String, String> {
		//'Manager'		=> 'UserId_ERP__c',
		//'BOSpecialist'	=> 'UserId_ERP__c',
		//'PRMDirector'	=> 'UserId_ERP__c',
		//'Customer'		=> 'Account',
		//'Payment Terms' => 'PaymentTerms__c',
		//'Delivery Terms' => 'DeliveryTerms__c'
	//};

	//public final static Map<String, String> erp_to_sf_api_names = new Map<String, String> {
		//'ProductGroup'	=> 'Product2',
		//'Shop'			=> 'Shop__c',
		//'SpecLevel'		=> 'ProductSpecLevel__c',
		//'SteelGrade'	=> 'SteelGrade__c',
		//'Standard'		=> 'ProductStandard__c',
		//'OD'			=> 'TubeOD__c',
		//'WT'			=> 'TubeWT__c',
		//'LengthSize'	=> 'TubeLengthSize__c',
		//'Coating'		=> 'CoatingType__c',
		//'Ends'			=> 'TubeEnds__c',
		//'ShippingPoint'	=> 'ShippingPoint__c',
		//'DeliveryTerms' => 'DeliveryTerms__c'
	//};

	//public final static Country__c country_not_spec = [SELECT Id FROM Country__c WHERE NumCode__c = '0' LIMIT 1];
	////public final static List<Shop__c> shop_not_cpec = [SELECT Id, Id_ERP__C, Name FROM Shop__c WHERE Id_ERP__C = '0' LIMIT 1];
	
	//public static ProcessInstanceWorkitem[] workItems = new List<ProcessInstanceWorkitem>();

	//public static Map<Id, SteelGrade__c> sgMap = new Map<Id, SteelGrade__c> ();
	//public static Map<Id, TubeOD__c> odMap = new Map<Id, TubeOD__c> ();
	//public static Map<Id, TubeWT__c> wtMap = new Map<Id, TubeWT__c> ();
	//public static Map<Id, TubeLengthSize__c> lsMap = new Map<Id, TubeLengthSize__c> ();
	//public static Set<String> sgIds = new Set<String> ();
	//public static Set<String> odIds = new Set<String> ();
	//public static Set<String> wtIds = new Set<String> ();
	//public static Set<String> lsIds = new Set<String> ();
	
	//public static Set<String> oliITENumberSet  = new Set<String>();

	
	//public static MessageProcessingResult ProcessMessage(ERPRequestParser.QuoteMessage parsedMessage, String requestBody) {
		//MessageProcessingResult res = new MessageProcessingResult();
		//res.MessageType = parsedMessage.MessageType;

		//Decimal messageTimestamp = Decimal.valueOf(parsedMessage.MessageTimestamp);

		//List<QuoteLineItem> qliToUpsert = new List<QuoteLineItem> ();
		//List<QuoteLineItem> qliToDelete = new List<QuoteLineItem> ();
		//Map<String, PricebookEntry> pbeIdByProduct2erpId = selectPBEbyProduct2ERPId(parsedMessage.Items);

		//// Сохраним мапу с айдишниками юзеров в шапке сообщения:
		//List<String> usrIdErpList = new List<String>();
		//usrIdErpList.add(parsedMessage.Manager.Id.deleteWhitespace());
		//usrIdErpList.add(parsedMessage.BOSpecialist.Id.deleteWhitespace());
		//usrIdErpList.add(parsedMessage.PRMDirector.Id.deleteWhitespace());
		//List<UserID_ERP__c> usrList = [SELECT Id, Name, User__c FROM UserID_ERP__c WHERE Name in :usrIdErpList];
		//Map<String, Id> usrIdMap = new Map<String, Id>();
		//For(UserID_ERP__c usrIdErp : usrList) {
			//usrIdMap.put(usrIdErp.Name, usrIdErp.User__c);
		//}
		////------------------------------------------------------

		////Найдем существующую или создадим новую запись PriceApprovalRequest__c:
		//PriceApprovalRequest__c par = getPriceApprovalRequest(parsedMessage, usrIdMap, res);
		
		////Создадим мапу, в которой хранится имя объекта и мапа соответствия ID_ERP и ID. Объекты, которые добавляются в эту мапу, перечислены в erp_to_sf_api_names.
		////Например: <'Shop__c' --> <ID_ERP --> Id>>
		//Map<String, Map<String, Id>> objToIdMap = getObjectToIdMap(parsedMessage.Items);

		////Сформируем мапу: <Код OpportunityId_ERP --> объект Quote>
		//Map<String, Quote> qMap = getQuotesMap(parsedMessage, par, objToIdMap, res);

		////Сформируем мапу: <Код OpportunityLineItemITENumber --> OpportunityLineItem>
		//Map<String, OpportunityLineItem> oliITENumberToObjMap = getOliITENumberToObjMap();

		//sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name FROM SteelGrade__c WHERE ID_ERP__c = :sgIds]);
		//odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_mm__c, OD_inch__c FROM TubeOD__c WHERE ID_ERP__c = :odIds]);
		//wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_mm__c, WT_inch__c FROM TubeWT__c WHERE ID_ERP__c = :wtIds]);
		//lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c FROM TubeLengthSize__c WHERE ID_ERP__c = :lsIds]);

		////Сформируем мапу: <код ID_ERP --> объект Qli>
		//Map<String, QuoteLineItem> qliByIdERPMap = getQliSFMap(String.valueOf(par.Id));

		//for (ERPRequestParser.QuoteItem qliERP : parsedMessage.Items) {
			////Пропустим строку, если не заполнены продукт или количество:
			//if (String.isBlank(qliERP.ProductGroup.Id) || String.isBlank(qliERP.InqQuantity) || Decimal.valueOf(qliERP.InqQuantity) == 0) {
				//continue;
			//}
			//if (String.isBlank(qliERP.ProductGroup.Id) || !pbeIdByProduct2erpId.containsKey(qliERP.ProductGroup.Id)) {
				//if (String.isBlank(qliERP.ProductGroup.Id)) {
					//String errorMessage = String.isBlank(qliERP.ProductGroup.Id) ? ('ProductGroup field for Line Item #' + qliERP.GUID + ' is empty.') : ('There is no such Product Group (' + qliERP.ProductGroup + ') for item #' + qliERP.GUID);
					//throw new erpException(errorMessage);
				//}
			//}

			//String fullIdERP = qliERP.GUID;
			//QuoteLineItem qli;
			//Quote q = qMap.get(qliERP.OpportunityID_ERP);

			//if (res.newQuotesList.contains(qliERP.OpportunityID_ERP) || !qliByIdERPMap.containsKey(fullIdERP) || res.changedCurrencyQuotes.contains(qliERP.OpportunityID_ERP)) {
				//// Значит для данной оппы была создана новая квота по этой служебке,
				//// или строки с таким кодом не существует и нужно создать новую,
				//// или была изменена валюта
				//qli = new QuoteLineItem ();
				//qli.QuoteId = q.Id;
				//qli.ID_ERP__c = fullIdERP;
				//qli.PriceApprovalRequest__c = par.Id;
				//qli.PricebookEntryId = pbeIdByProduct2erpId.get(qliERP.ProductGroup.Id).Id;
			//} else {
				//qli = qliByIdERPMap.get(fullIdERP);
			//}
			
			//qli.ExchangeTimestamp__c = messageTimestamp;
			//qli.PriceApprovalRequest__c = par.Id;
			//mapRelatedERPId(qli, q, objToIdMap, qliERP);
			//qli.OpportunityLineItemITENumber__c = qliERP.OpportunityLineItemITENumber;
			//qli.NPP__c = qliERP.NPP;
			//fillName(qli);
			//qli.OpportunityLineItemId = oliITENumberToObjMap.get(qliERP.OpportunityLineItemITENumber).Id;
			//qli.InquiryQuantity__c = Decimal.valueOf(qliERP.InqQuantity);
			//qli.InquiryUnit__c = qliERP.InqUnit;
			//qli.Quantity = Decimal.valueOf(qliERP.Quantity_Mt);
			////qli.Quantity_m__c = Decimal.valueOf(qliERP.Quantity_m);
			////qli.Quantity_ft__c = Decimal.valueOf(qliERP.Quantity_ft);
			////qli.Quantity_pcs__c = Decimal.valueOf(qliERP.Quantity_pcs);
			//qli.InquiryUnitPrice__c = Decimal.valueOf(qliERP.Price);
			//qli.UnitPrice = Decimal.valueOf(qliERP.Price_t);
			//qli.UnitPriceEXW__c = Decimal.valueOf(qliERP.PriceEXW_t);
			//qli.Margin__c = Decimal.valueOf(qliERP.Margin);
			//qli.Margin_t__c = Decimal.valueOf(qliERP.Margin_t);
			//qli.Liabilities_t__c = Decimal.valueOf(qliERP.Liabilities_t);
			//qli.TransportationCost_t__c = Decimal.valueOf(qliERP.TransportationCosts_t);
			//qli.ROI__c = Decimal.valueOf(qliERP.ROI);
			//qli.BilletCost_t__c = Decimal.valueOf(qliERP.BilletCost_t);
			//qli.MetalPriceForProduction__c = Decimal.valueOf(qliERP.MetalPriceForProduction);
			//qli.CostsTKB__c = Decimal.valueOf(qliERP.CostsTKB);
			//qli.MarginTKB_t__c = Decimal.valueOf(qliERP.MarginTKB_t);
			//qli.MarginBillet_t__c = Decimal.valueOf(qliERP.MarginBillet_t);
			//qli.CustomDuty__c = Decimal.valueOf(qliERP.CustomDuty);
			//qli.CoatingCost__c = Decimal.valueOf(qliERP.CoatingCost);
			//qli.ExtraCosts__c = Decimal.valueOf(qliERP.ExtraCosts);


			//qliToUpsert.add(qli);
		//}

		//upsert qliToUpsert;

		//qliToDelete = [SELECT Id FROM QuoteLineItem WHERE Quote.PriceApprovalRequest__c = :par.Id AND ExchangeTimestamp__c < :messageTimestamp];
		//delete qliToDelete;

		//checkApprovalStatus(par, parsedMessage);

		//return res;
	//}



	//private static PriceApprovalRequest__c getPriceApprovalRequest(ERPRequestParser.QuoteMessage parsedMessage, Map<String, Id> usrIdMap, MessageProcessingResult res) {
		
		//PriceApprovalRequest__c par;
		//List<PriceApprovalRequest__c> parList = [
													//SELECT Id, ID_ERP__c, Stage__c, OwnerId, DocNumber__c, DocDate__c, IsPriceModel__c, MarketSegment__c,
														//Account__c, SalesRep__c, BOSpecialist__c, BOSpecialist__r.Name, PRMDirector__c, CurrencyIsoCode, PaymentTerms__c
													//FROM PriceApprovalRequest__c
													//WHERE Id_ERP__c = :parsedMessage.ID_ERP LIMIT 1
												//];

		//if (parList.size() == 0) {
			//par = new PriceApprovalRequest__c();
			//Id smSfId = usrIdMap.get(parsedMessage.Manager.Id.deleteWhitespace());
			//if (smSfId == null) {
				//throw new erpException('There is no any user (Sales Manager) with ID = ' + parsedMessage.Manager.Id.deleteWhitespace());
			//}
			//par.OwnerId = smSFId;
			//par.Id_ERP__c = parsedMessage.ID_ERP;
			//res.isNewPriceApprovalRequestCreated = true;
		//} else {
			//par = parList[0];
		//}

		//Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();

		//par.Name = parsedMessage.DocNumber;
		//par.DocNumber__c = parsedMessage.DocNumber;
		//par.DocDate__c = DateTime.newInstance(Long.valueOf(parsedMessage.DocDate + '000')).date();
		//par.CurrencyIsoCode = parsedMessage.Items[0].CurrencyCode;
		//par.IsPriceModel__c = parsedMessage.PriceModel == '1' ? true : false;
		//par.MarketSegment__c = parsedMessage.Segment;
		//// Аккаунт:
		//List<Account> accList = [SELECT Id FROM Account WHERE ID_ERP__c = :parsedMessage.Customer.Id];
		//checkListSize(accList, 'Customer', parsedMessage.Customer, null);
		//par.Account__c = accList[0].Id;
		////---------
		//par.SalesRep__c = usrIdMap.get(parsedMessage.Manager.Id.deleteWhitespace());
		//par.BOSpecialist__c = usrIdMap.get(parsedMessage.BOSpecialist.Id.deleteWhitespace());
		//par.PRMDirector__c = usrIdMap.get(parsedMessage.PRMDirector.Id.deleteWhitespace());
		//// Условия оплаты:
		//List<PaymentTerms__c> ptList = [SELECT Id FROM PaymentTerms__c WHERE ID_ERP__c = :parsedMessage.PaymentTerms.Id];
		//checkListSize(ptList, 'Payment Terms', parsedMessage.PaymentTerms, sObjects_to_insert);
		//par.PaymentTerms__c = ptList.isEmpty() ? sObjects_to_insert.get('Payment Terms').Id : ptList[0].Id;
		//// Условия поставки:
		//List<DeliveryTerms__c> dtList = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :parsedMessage.Items[0].DeliveryTerms.Id];
		//checkListSize(dtList, 'Delivery Terms', parsedMessage.Items[0].DeliveryTerms, sObjects_to_insert);
		//par.DeliveryTerms__c = dtList.isEmpty() ? sObjects_to_insert.get('Delivery Terms').Id : dtList[0].Id;
		////----------------
		//switch on parsedMessage.Stage {
			//when 'BO' {
				//par.Stage__c = 'Draft';
			//}
			//when 'SalesRep' {
				//par.Stage__c = 'Needs Confirmation';
			//}
			//when 'Costing' {
				//par.Stage__c = 'Costing';
			//}
			//when 'PRM' {
				//par.Stage__c = 'PRM';
			//}
			//when 'ExtraCosts' {
				//par.Stage__c = 'In Review';
			//}
			//when 'Decision' {
				//par.Stage__c = 'In Review';
			//}
			//when 'Finish' {
				//par.Stage__c = 'Resolved';
			//}
		//}
		//par.FED__c = parsedMessage.FED == '1' ? true : false;
		//par.Transportation__c = parsedMessage.Transportation == '1' ? true : false;
		//par.Turnover__c = parsedMessage.Turnover == '1' ? true : false;
		//par.Status__c = parsedMessage.Status;

		//upsert par;

		//return par;

	//}


	
	//public static void checkListSize(List<SObject> listToCheck, String sfObjectLabel, ERPRequestParser.ERPObject erpObject, Map<String, sObject> sObjects_to_insert) {
		//if (listToCheck.size() == 0) {
			//if (sfObjectLabel == 'Account' || sfObjectLabel == 'Customer') {
				//String errorMessage = 'There is no any ' + sfObjectLabel + ' with such ID ERP (' + erpObject.Id + ')';
				//throw new erpException(errorMessage);
			//} else {
				//if (sfObjectLabel == 'Country') {
					//sObjects_to_insert.put(sfObjectLabel, country_not_spec);
				//} else {
					//System.debug('There is no any ' + sfObjectLabel + ' with such ID ERP (' + erpObject.Id + ') - Creating a new one.');
					//sObject sObj_to_insert = Schema.getGlobalDescribe().get(labelsToSfAPINames.get(sfObjectLabel)).newSObject();
					//String erpObjName;
					//if (sfObjectLabel == 'Payment Terms') {
						//erpObjName = checkNameFieldSize(erpObjName, 255);
						//sObj_to_insert.put('NameFull__c', erpObjName);
						//sObj_to_insert.put('NameFullRus__c', erpObjName);

						//erpObjName = checkNameFieldSize(erpObjName, 80);
						//sObj_to_insert.put('NameRus__c', erpObjName);
					//}
					//erpObjName = checkNameFieldSize(erpObjName, 80);

					//sObj_to_insert.put('Name', erpObjName);
					//sObj_to_insert.put('Id_ERP__c', erpObject.Id);
					//insert sObj_to_insert;
					//System.debug('Created new object - ' + sObj_to_insert);
					//sObjects_to_insert.put(sfObjectLabel, sObj_to_insert);
				//}
			//}
		//} else if (listToCheck.size() > 1) {
			//String errorMessage = 'There are several ' + sfObjectLabel + ' with such ID ERP(' + erpObject.Id + ').';
			//System.debug(errorMessage.removeEnd('.') + ': ');
			//Integer i = 1;
			//for (SObject sobj : listToCheck) {
				//System.debug(i + '--' + sobj);
				//i++;
			//}
			//throw new erpException(errorMessage);
		//}
	//}



	//public static String checkNameFieldSize(String nameOfObject, Integer fieldSize) {
		//if (nameOfObject.length() > fieldSize) {
			//nameOfObject = nameOfObject.substring(0, fieldSize - 4) + '...';
		//}
		//return nameOfObject;
	//}



	//@testVisible
	//private static Map<String, QuoteLineItem> getQliSFMap(String parId) {
		
		//List<QuoteLineItem> qliList = [
												//SELECT Id, ID_ERP__c, OpportunityLineItemITENumber__c, NPP__c, Name__c, Shop__c, Shop__r.Id_ERP__c, Product2Id, Product2.Id_ERP__c,
													//TubeOD__c, TubeOD__r.Id_ERP__c, TubeWT__c, TubeWT__r.Id_ERP__c, Coating__c, Coating__r.ID_ERP__c, SteelGrade__c, SteelGrade__r.Id_ERP__c, TubeEnds__c, TubeEnds__r.ID_ERP__c, TubeLengthSize__c
												//FROM QuoteLineItem
												//WHERE Quote.PriceApprovalRequest__c = :parId
											//];

		//Map<String, QuoteLineItem> qliMap = new Map<String, QuoteLineItem> ();
		//for (QuoteLineItem qli : qliList) {
			//qliMap.put(qli.ID_ERP__c, qli);
		//}

		//System.debug('==============>>>>> qliSfMap: ' + qliMap);
		//return qliMap;
	//}



	//private static Map<String, Quote> getQuotesMap(ERPRequestParser.QuoteMessage parsedMessage, PriceApprovalRequest__c par, Map<String, Map<String, Id>> objToIdMap, MessageProcessingResult res) {
		//List<ERPRequestParser.QuoteItem> qItems = parsedMessage.Items;

		////Сначала соберем все айдишники опп из сообщения, а также воспользуемся моментом и выполним вспомогательные операции:
		//Set<String> oppIdERPSet = new Set<String>();
		//Set<String> currSet = new Set<String>(); // В этот сет соберем коды валют из всех строк, и если есть разные коды, то выбросим ошибку.
		//for (ERPRequestParser.QuoteItem qItem : qItems) {
			//oppIdERPSet.add(qItem.OpportunityID_ERP);
			//oliITENumberSet.add(qItem.OpportunityLineItemITENumber);
			
			////Заполним сеты с ID_ERP записей, которые понадобятся при формировании наименования строки квоты.
			//sgIds.add(qItem.SteelGrade.Id.deleteWhitespace());
			//odIds.add(qItem.OD.Id.deleteWhitespace());
			//wtIds.add(qItem.WT.Id.deleteWhitespace());
			//lsIds.add(qItem.LengthSize.Id.deleteWhitespace());

			//currSet.add(qItem.CurrencyCode.deleteWhitespace());
		//}
		//if (currSet.size() > 1) {
			//throw new erpException('All items of the Price Approval Request must have the same currency!');
		//}
		
		//// Сформируем Мапу <Id_Erp --> Opportunity>:
		//List<Opportunity> oppList = [SELECT Id, Name, ID_ERP__c, OwnerId, Pricebook2Id FROM Opportunity WHERE ID_ERP__c in :oppIdERPSet];
		//Map<String, Opportunity> oppIdErpMap = new Map<String, Opportunity>();
		//for (Opportunity opp : oppList){
			//oppIdErpMap.put(opp.ID_ERP__c, opp);
		//}

		//// Сформируем мапу <Id_Erp --> Quote>:
		//Map<String, Quote> qMap = new Map<String, Quote>();
		//List<Quote> qList = [Select Id, Opportunity.Id_ERP__c, Status, Pricebook2Id, CurrencyIsoCode FROM Quote Where Opportunity.ID_ERP__c in :OppIdErpSet AND PriceApprovalRequest__c = :par.Id];
		//for (Quote q : qList) {
			//qMap.put(q.Opportunity.ID_ERP__c, q);
		//}
		
		//// Пройдемся по всем айдишникам опп из сообщения и проверим, есть ли квота (и оппа).
		//for(String oppIdERP : oppIdERPSet) {
			//// Первым делом проверим, есть ли вообще оппа с таким Id_ERP:
			//Opportunity opp = oppIdErpMap.get(oppIdERP);
			//if (opp == null) {
				//throw new erpException('There is no any Opportunity with ID_ERP = ' + oppIdERP);
			//}
			
			//Quote q = qMap.get(oppIdERP);
			//if (q == null) {
				//// Такой квоты нет, нужно ее создать:
				//q = new Quote();
				//q.Name = opp.Name + ': Quote #' + parsedMessage.DocNumber;
				//q.OwnerId = opp.OwnerId;
				//q.OpportunityId = opp.Id;
				//q.PriceApprovalRequest__c = par.Id;
				//q.CurrencyIsoCode = parsedMessage.Items[0].CurrencyCode;
			//}
			//// Проапдейтим/заполним поля квоты
			//if (q.Pricebook2Id != opp.Pricebook2Id){
				//q.Pricebook2Id = opp.Pricebook2Id;
			//}
			//if (q.CurrencyIsoCode != parsedMessage.Items[0].CurrencyCode) {
				//// Сюда попадаем только если это уже существующая квота и ее валюта отличается от валюты в строке служебки.
				//res.changedCurrencyQuotes.add(oppIdERP);
				//List<QuoteLineItem> qliToDelete = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :q.Id];
				//delete qliToDelete;
			//}
			
			//q.DeliveryTerms__c = par.DeliveryTerms__c;
			//q.PaymentTerms__c = par.PaymentTerms__c;
			//switch on par.Stage__c {
				//when 'Draft', 'Needs Confirmation', 'Costing', 'PRM', 'In Review' {
					//q.Status = par.Stage__c;
				//}
				//when 'Resolved' {
					//if (q.Status == null || q.Status == 'Draft' || q.Status == 'Needs Confirmation' || q.Status == 'Costing' || q.Status == 'PRM' || q.Status == 'In Review' || q.Status == 'Approved' || q.Status == 'Rejected' ){
						//q.Status = par.Status__c == '1' ? 'Approved' : 'Rejected';
					//}
				//}
			//}

			//upsert q;
			//if (qMap.get(oppIdERP) == null) {
				//qMap.put(oppIdERP, q);
				
			//}
		//}

		//return qMap;
	//}



	//private static Map<String, OpportunityLineItem> getOliITENumberToObjMap() {
		
		//List<OpportunityLineItem> oliList = [SELECT Id, Name, ID_ERP__c, ITENumber__c FROM OpportunityLineItem WHERE ITENumber__c in :oliITENumberSet];

		//Map<String, OpportunityLineItem> oliITENumberToObjMap = new Map<String, OpportunityLineItem>();
		//for (OpportunityLineItem oli : oliList){
			//oliITENumberToObjMap.put(oli.ITENumber__c, oli);
		//}

		//return oliITENumberToObjMap;
	//}



	//private static Map<String, Map<String, Id>> getObjectToIdMap(List<ERPRequestParser.QuoteItem> qliERP) {
		//Map<String, Map<String, Id>> objectToIdMap = new Map<String, Map<String, Id>> ();
		//Map<String, Set<String>> erpValuesForObject = new Map<String, Set<String>> ();
		//System.debug(qliERP);
		//String serializedString = JSON.serialize(qliERP);
		//System.debug(serializedString);
		//List<Object> qliFieldsList = (List<Object>) JSON.deserializeUntyped(serializedString);
		//System.debug('-- List: ' + qliFieldsList);
		//for (String key : erp_to_sf_api_names.keyset()) {
			//Set<String> valuesSet = new Set<String> ();
			//for (Integer i = 0; i < qliFieldsList.size(); i++) {
				//Map<String, Object> qliField = (Map<String, Object>) qliFieldsList.get(i);

				//Map<String, Object> ERPObject = (Map<String, Object>) qliField.get(key);
				//if ((String) ERPObject.get('Id') != null) {
					//System.debug('--- ' + (String) ERPObject.get('Id'));
					//if (key == 'ShippingPoint') {
						//valuesSet.add((String) ERPObject.get('OptionalValue1') + '-' + ((String) ERPObject.get('Id')).deleteWhitespace());
					//}
					//else {
						//valuesSet.add(((String) ERPObject.get('Id')).deleteWhitespace());
					//}
				//}
			//}
			//erpValuesForObject.put(key, valuesSet);
		//}
		//System.debug(erpValuesForObject);

		//for (String key : erpValuesForObject.keySet()) {
			//Set<String> setERPIds = erpValuesForObject.get(key);
			//List<sObject> objectList;
			//Map<String, Id> erpIdToIdMap = new Map<String, Id> ();
			//switch on key {
				//when 'Manager', 'BOSpecialist', 'PRMDirector' {
					////Запрос выполняется не по справочнику User и полю Id, а по справочнику UserId_ERP__c и полю Name
					//objectList = Database.query('SELECT Name, User__c FROM UserId_ERP__c WHERE Name IN :setERPIds');
					//for (sObject ob : objectList) {
						//erpIdToIdMap.put((String) ob.get('Name'), (Id) ob.get('User__c'));
					//}
					//objectToIdMap.put(key, erpIdToIdMap);
				//}
				//when else {
					//objectList = Database.query('SELECT Id, ID_ERP__c FROM ' + erp_to_sf_api_names.get(key) + ' WHERE ID_ERP__c IN :setERPIds');
					//for (sObject ob : objectList) {
						//erpIdToIdMap.put((String) ob.get('ID_ERP__c'), ob.Id);
					//}
				//}
			//}
			//objectToIdMap.put(key, erpIdToIdMap);
			//System.debug('Object to ID Map: ' + objectToIdMap);
		//}
		//return objectToIdMap;
	//}



	//private static void mapRelatedERPId(QuoteLineItem qli, Quote q, Map<String, Map<String, Id>> objToIdMap, ERPRequestParser.QuoteItem qliERP) {
		//List<String> fields = new List<String> { 'ProductGroup', 'Shop', 'SpecLevel', 'SteelGrade', 'Standard', 'OD', 'WT', 'LengthSize', 'Ends', 'Coating', 'ShippingPoint', 'DeliveryTerms' };
		//Map<String, Object> productAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(qliERP));

		//List<String> errList = new List<String> ();
		//String allErrors = '';

		//String qliFullId = qliERP.GUID;

		//Map<String, SObject> sObjects_to_insert = new Map<String, SObject> ();

		//for (String fieldName : fields) {
			//System.debug('--- Product As Map: ' + productAsMap);

			//String ERPObjectID;
			//Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get(fieldName);
			//if (fieldName == 'ShippingPoint') {
				//ERPObjectID = ((String) ERPObject.get('OptionalValue1')) + '-' + ((String) ERPObject.get('Id')).deleteWhitespace();
			//} else {
				//ERPObjectID = ((String) ERPObject.get('Id')).deleteWhitespace();
			//}
			//String ERPObjectName = (String) ERPObject.get('Name');
			//if (String.isBlank(ERPObjectName)) {
				//ERPObjectName = 'Object with ERP Id = ' + ERPObjectID;
			//}

			//System.debug('--- Object: ' + objToIdMap.get(fieldName).get(ERPObjectID));

			//if (String.isNotBlank(ERPObjectID) && objToIdMap.get(fieldName).get(ERPObjectID) == null) {

				//System.debug('There is no any ' + fieldName + ' with ERP-ID ' + ERPObjectID + ' (Quote line item #' + qliFullId + ') - Creating new one.');

				//String objName = erp_to_sf_api_names.get(fieldName);
				//sObject sObj_to_insert = Schema.getGlobalDescribe().get(objName).newSObject();
				//sObj_to_insert.put('Id_ERP__c', ERPObjectID);
				//sObj_to_insert.put('Name', checkFieldValueSize(ERPObjectName, 80));
				//if (objHasField(objName, 'NameRus__c')){
					//sObj_to_insert.put('NameRus__c', checkFieldValueSize(ERPObjectName, 255));
				//}
				//if (fieldName == 'QuotaType'){
					//sObj_to_insert.put('Shop__c', objToIdMap.get(fieldName).get((String) ERPObject.get('OptionalValue1')));
				//} else if (fieldName == 'ShippingPoint') {
					//sObj_to_insert.put('Type__c', objToIdMap.get(fieldName).get((String) ERPObject.get('OptionalValue1')));
				//} else if (fieldName == 'DeliveryTerms') {
					//sObj_to_insert.put('Incoterms__c', objToIdMap.get(fieldName).get((String) ERPObject.get('OptionalValue1')));
				//}
				//System.debug('Created new object - ' + sObj_to_insert);

				//sObjects_to_insert.put(fieldName, sObj_to_insert);
			//}
		//}

		//if (sObjects_to_insert.values().size() > 0) {
			//insert sObjects_to_insert.values();
			//for (String fieldName : sObjects_to_insert.keySet()) {
				//String ERPObjectID;
				//Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get(fieldName);
				//if (fieldName == 'ShippingPoint') {
					//ERPObjectID = ((String) ERPObject.get('OptionalValue1')) + '-' + ((String) ERPObject.get('Id')).deleteWhitespace();
				//} else {
					//ERPObjectID = ((String) ERPObject.get('Id')).deleteWhitespace();
				//}
				//objToIdMap.get(fieldName).put(ERPObjectID, sObjects_to_insert.get(fieldName).Id);
			//}
		//}

		//if (errList.size() > 0) {
			//for (String errorMessage : errList) {
				//System.debug(errorMessage);
			//}
			//throw new erpException(allErrors);
		//}

		
		////if (qli.Id == null) {
			////// Product2Id можно установить только для новой записи.
			////Id productSfId = objToIdMap.get('ProductGroup').get(qliERP.ProductGroup.Id.deleteWhitespace());
			////if (productSfId == null) {
				////throw new erpException('There is no any product with ID = ' + qliERP.ProductGroup.Id.deleteWhitespace());
			////}
			////qli.Product2Id = productSfId;
		////}
		//qli.Shop__c = objToIdMap.get('Shop').get(qliERP.Shop.Id.deleteWhitespace());
		//qli.SteelGrade__c = objToIdMap.get('SteelGrade').get(qliERP.SteelGrade.Id.deleteWhitespace());
		//qli.ProductStandard__c = objToIdMap.get('Standard').get(qliERP.Standard.ID.deleteWhitespace());
		//qli.ProductSpecLevel__c = objToIdMap.get('SpecLevel').get(qliERP.SpecLevel.Id.deleteWhitespace());
		//qli.TubeOD__c = objToIdMap.get('OD').get(qliERP.OD.Id.deleteWhitespace());
		//qli.TubeWT__c = objToIdMap.get('WT').get(qliERP.WT.Id.deleteWhitespace());
		//qli.TubeLengthSize__c = objToIdMap.get('LengthSize').get(qliERP.LengthSize.Id.deleteWhitespace());
		//qli.TubeEnds__c = objToIdMap.get('Ends').get(qliERP.Ends.Id.deleteWhitespace());
		//qli.Coating__c = objToIdMap.get('Coating').get(qliERP.Coating.Id.deleteWhitespace());
		////qli.QuotaType__c = objToIdMap.get('QuotaType').get(qliERP.QuotaType.Id.deleteWhitespace());
		//qli.ShippingPoint__c = objToIdMap.get('ShippingPoint').get(qliERP.ShippingPoint.OptionalValue1 + '-' + qliERP.ShippingPoint.Id.deleteWhitespace());

	//}



	//private static Boolean objHasField(String objName, String fieldName) {

		//Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		//Schema.DescribeSObjectResult objDescription = gd.get(objName).getDescribe();
		//Map<String, Schema.SObjectField> fieldsMap = objDescription.fields.getMap();
		//if (fieldsMap.containsKey(fieldName)) {
			//return true;
		//} else {
			//return false;
		//}

	//}
	

	
	//public static String checkFieldValueSize(String fieldValue, Integer maxValueSize) {

		//if (fieldValue.length() > maxValueSize) {
			//fieldValue = fieldValue.substring(0, maxValueSize - 4) + '...';
		//}
		//return fieldValue;
	//}



	//private static Map<String, PricebookEntry> selectPBEbyProduct2ERPId(List<ERPRequestParser.QuoteItem> items) {

		//Map<String, PricebookEntry> result = new Map<String, PricebookEntry> ();

		//Map<String, ERPRequestParser.QuoteItem> product2erpIdMap = new Map<String, ERPRequestParser.QuoteItem> ();
		//for (ERPRequestParser.QuoteItem qliERP : items) {
			//product2erpIdMap.put(qliERP.ProductGroup.Id, qliERP);
		//}

		//System.debug('Products ID_ERP from json items - ' + product2erpIdMap.keySet());

		//Map<Id, String> prods = new Map<Id, String> ();
		//for (Product2 prod2_item :[
		     //SELECT Id, ID_ERP__c
		     //FROM Product2
		     //WHERE ID_ERP__c IN :product2erpIdMap.keySet()]) {
			//prods.put(prod2_item.Id, prod2_item.ID_ERP__c);
		//}

		//List<Product2> products_to_insert = new List<Product2> ();

		//for (String product2erpId : product2erpIdMap.keySet()) {
			//if (!prods.values().contains(product2erpId)) {
				//Product2 newProduct = new Product2();
				//product2erpIdMap.get(product2erpId).ProductGroup.Name = checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 255);
				//newProduct.Name = product2erpIdMap.get(product2erpId).ProductGroup.Name;
				//product2erpIdMap.get(product2erpId).ProductGroup.Name = checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 80);
				//newProduct.NameRus__c = product2erpIdMap.get(product2erpId).ProductGroup.Name;
				//newProduct.ID_ERP__c = product2erpIdMap.get(product2erpId).ProductGroup.Id;
				//products_to_insert.add(newProduct);
			//}
		//}

		//if (!products_to_insert.isEmpty()) {
			//insert products_to_insert;
			//System.debug('Inserted new Products - ' + products_to_insert);

			//for (Product2 prod2_item : products_to_insert) {
				//prods.put(prod2_item.ID, prod2_item.ID_ERP__c);
			//}
		//}


		//List<PriceBookEntry> pb2;
		//Pricebook2 pb1;
		//Id pricebookId;

		//if (Test.isRunningTest()) {
			//pricebookId = Test.getStandardPricebookId();
			//pb2 = [SELECT Id, UnitPrice, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id in :prods.keySet()];
		//} else {
			//pb1 = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard = True LIMIT 1];
			//pb2 = [SELECT Id, UnitPrice, CurrencyIsoCode, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :pb1.Id AND CurrencyISOcode = :items[0].CurrencyCode AND Product2Id in :prods.keySet()];
		//}

		//Map<Id, PricebookEntry> pbeIdByProduct2erpId = new Map<Id, PricebookEntry> ();
		//for (PricebookEntry pbe : pb2) {
			//pbeIdByProduct2erpId.put(pbe.Product2Id, pbe);
		//}

		//System.debug('Product2 ID from SOQL - ' + pbeIdByProduct2erpId.keySet());
		//System.debug('Product2 ID from prods map - ' + prods.keySet());
		//List<PricebookEntry> pbe_to_insert = new List<PricebookEntry> ();

		//for (String Product2Id : prods.keySet()) {
			//if (!pbeIdByProduct2erpId.keySet().contains(Product2Id)) {
				//PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode = items[0].CurrencyCode,
					                                    //Pricebook2Id = Test.isRunningTest() ? pricebookId : pb1.Id,
					                                    //IsActive = true,
					                                    //Product2Id = Product2Id,
					                                    //UnitPrice = Decimal.valueOf(product2erpIdMap.get(prods.get(Product2Id)).Price_t)
				//);
				//pbe_to_insert.add(pbe);
			//}
		//}

		//if (!pbe_to_insert.isEmpty()) {
			//insert pbe_to_insert;
			//System.debug('Inserted new PBE - ' + pbe_to_insert);

			//for (PricebookEntry pbe_item : pbe_to_insert) {
				//pb2.add(pbe_item);
			//}
		//}

		//for (PricebookEntry pbe : pb2) {
			//result.put(prods.get(pbe.Product2Id), pbe);
			//System.debug('Result map key - ' + prods.get(pbe.Product2Id) + ' value - ' + pbe);
		//}

		//System.debug('Result  - ' + result);
		//return result;
	//}



	//public static void fillName(QuoteLineItem qli) {
		//String sg = (sgMap.get(qli.SteelGrade__c) != null ? sgMap.get(qli.SteelGrade__c).Name + ' ' : '');
		//String od = (odMap.get(qli.TubeOD__c) != null ? String.valueOf(odMap.get(qli.TubeOD__c).OD_mm__c) + 'x' : '');
		//String wt = (wtMap.get(qli.TubeWT__c) != null ? String.valueOf(wtMap.get(qli.TubeWT__c).WT_mm__c) + ' ' : '');
		//String ls = (lsMap.get(qli.TubeLengthSize__c) != null ? lsMap.get(qli.TubeLengthSize__c).Name : '');
		//qli.Name__c = sg + od + wt + ls;
	//}


	
	//private static void checkApprovalStatus(PriceApprovalRequest__c par, ERPRequestParser.QuoteMessage parsedMessage) {
		//Id workItemId;
		//String currentApprovalStatus = getCurrentApprovalStatus(par);
		//if (currentApprovalStatus.contains('Pending')) {
			//List<ProcessInstanceWorkitem> workItems =	[
															//SELECT Id
															//FROM ProcessInstanceWorkitem
															//WHERE ProcessInstance.TargetObjectId = :par.Id //WHERE ProcessInstanceId = :pi.Id 
														//];
			//workItemId = workItems.get(0).Id;
		//}
		//Boolean isSynced = false;
		
		//while (!isSynced) {
			//switch on currentApprovalStatus {
				//when 'Not Started', 'Removed' {
					////Значит нет активного либо завершенного Approval Process.
					//if (parsedMessage.Stage == 'BO') {
						////Ничего делать не нужно
						//isSynced = true;
					//} else {
						////Сформируем запрос на подтверждение служебки продавцом:
						//Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
						//psr.setObjectId(par.Id);
						//psr.setProcessDefinitionNameOrId('Price_Approval_Request');
						//psr.setComments('Submitted in IT-Enterprise by ' + par.BOSpecialist__r.Name);
						////psr.setSubmitterId(par.BOSpecialist__c);
						////psr.setSkipEntryCriteria(true);
						//Approval.ProcessResult apprResult = Approval.process(psr);
							
						//System.assert(apprResult.isSuccess());
						//System.assertEquals('Pending', apprResult.getInstanceStatus());
							
						//workItemId = apprResult.getNewWorkItemIds().get(0);
						//currentApprovalStatus = 'Pending: SalesRep';
					//}
				//}
				
				//when 'Pending: SalesRep' {
					////Значит есть активный Approval Process на шаге подтверждения служебки продавцом.
					//if (parsedMessage.Stage == 'SalesRep') {
						//// Ничего не нужно делать, запрос и так уже на этом шаге процесса утверждения.
						//isSynced = true;
					//} else {
						//Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
						//pwr.setWorkItemId(workItemId);
						//if (parsedMessage.Stage == 'BO') {
							//// Отзовем запрос (Recall)
							//pwr.setAction('Removed');
							//pwr.setComments('The request was recalled in the ERP system');
							//currentApprovalStatus = 'Removed';
							//isSynced = true; //чтобы не делать очередную итерацию цикла While
						//} else if (parsedMessage.Stage == 'Finish' && parsedMessage.Status == '-1') {
							//// Эта служебка уже отклонена в ИТ, поэтому отклоним этот запрос и тут (Final Reject)
							//pwr.setAction('Reject');
							//pwr.setComments('The request was rejected in the ERP system');
							//currentApprovalStatus = 'Rejected';
							//isSynced = true; //чтобы не делать очередную итерацию цикла While
						//} else {
							//// Запрос уже на более позднем шаге процесса согласования, поэтому утвердим этот шаг (перейдет на шаг Final_Approval).
							//pwr.setAction('Approve');
							//pwr.setComments('The request was approved in the ERP system');
							//currentApprovalStatus = 'Pending: Final_Approval';
						//}
						
						//Approval.ProcessResult apprResult = Approval.process(pwr);
						//System.assert(apprResult.isSuccess());
						//if (apprResult.getNewWorkItemIds().size() > 0) {
							//workItemId = apprResult.getNewWorkItemIds().get(0);
						//} else {
							//workItemId = null;
						//}
					//}
				//}

				//when 'Pending: Final_Approval' {
					////Значит есть активный Approval Process на шаге подтверждения служебки остальными уполномоченными в ИТ-Предприятии.
					//if (parsedMessage.Stage != 'BO' && parsedMessage.Stage != 'SalesRep' && parsedMessage.Stage != 'Finish') {
						//// Ничего не нужно делать, запрос и так уже на этом шаге процесса утверждения.
						//isSynced = true;
					//} else {
						//Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
						//pwr.setWorkItemId(workItemId);
						
						//if (parsedMessage.Stage == 'BO' || parsedMessage.Stage == 'SalesRep') {
							//// Отклоним служебку (вернем на шаг SalesRep)
							//pwr.setAction('Reject');
							//pwr.setComments('The request was rejected in the ERP system');
							//currentApprovalStatus = 'Pending: SalesRep';
						//} else if (parsedMessage.Stage == 'Finish' && parsedMessage.Status == '1') {
							//// Эта служебка уже согласована в ИТ, поэтому утвердим ее и тут (Final Approval)
							//pwr.setAction('Approve');
							//pwr.setComments('The request was approved in the ERP system');
							//currentApprovalStatus = 'Approved';
							//isSynced = true;
						//} else {
							//// Эта служебка уже отклонена в ИТ, поэтому отклоним этот запрос и тут (вернем на шаг SalesRep)
							//pwr.setAction('Reject');
							//pwr.setComments('The request was rejected in the ERP system');
							//currentApprovalStatus = 'Pending: SalesRep';
						//}
						
						//Approval.ProcessResult apprResult = Approval.process(pwr);
						//System.assert(apprResult.isSuccess());
						//if (apprResult.getNewWorkItemIds().size() > 0) {
							//workItemId = apprResult.getNewWorkItemIds().get(0);
						//} else {
							//workItemId = null;
						//}
					//}
				//}

				//when 'Approved', 'Rejected' {
					////Значит нет активного Approval Process, но уже есть завершенный Approval Process
					//if (parsedMessage.Stage == 'BO'
						//|| (parsedMessage.Stage == 'Finish' && 
								//((parsedMessage.Status == '1' && currentApprovalStatus == 'Approved')
								//|| (parsedMessage.Status == '-1' && currentApprovalStatus == 'Rejected')))) {
						//// Во всех этих случаях ничего делать не нужно
						//isSynced = true;
					//} else {
						////Сформируем запрос на подтверждение служебки продавцом:
						//Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
						//psr.setObjectId(par.Id);
						//psr.setProcessDefinitionNameOrId('Price_Approval_Request');
						//psr.setComments('Submitted in IT-Enterprise by ' + par.BOSpecialist__r.Name);
						////psr.setSubmitterId(par.BOSpecialist__c);
						////psr.setSkipEntryCriteria(true);
						//Approval.ProcessResult apprResult = Approval.process(psr);
						//System.assert(apprResult.isSuccess());
						//System.assertEquals('Pending', apprResult.getInstanceStatus());
						//if (apprResult.getNewWorkItemIds().size() > 0) {
							//workItemId = apprResult.getNewWorkItemIds().get(0);
						//} else {
							//workItemId = null;
						//}
						//currentApprovalStatus = 'Pending: SalesRep';
					//}
				//}
			//}
		//}
	//}



	//private static String getCurrentApprovalStatus(PriceApprovalRequest__c par) {
		//String curStep;
		//ProcessInstance lastProcess;

		//List<ProcessInstance> piList = [
											//SELECT Id, Status,
													//(
														//SELECT Id, ProcessNode.DeveloperName
														//FROM StepsAndWorkitems
														//WHERE isPending = true
													//)
											//FROM ProcessInstance
											//WHERE TargetObjectId = :par.Id
											//AND ProcessDefinition.DeveloperName = 'Price_Approval_Request'
											//ORDER BY CompletedDate DESC NULLS FIRST
										//];

		//if (piList.size() == 0) {
			//// Нет ни одной записи ProcessInstance, значит процесс согласования ни разу не запускался
			//return 'Not Started';
		//} else {
			//// Результаты запроса отсортированы по CompletetDate (Desc), при этом если есть активный процесс, то у него эта дата пустая и он будет первым в списке (Nulls First)
			//lastProcess = piList.get(0);
			//if (lastProcess.Status == 'Pending') {
				//return 'Pending: ' + lastProcess.StepsAndWorkitems.get(0).ProcessNode.DeveloperName;
			//} else {
				//return lastProcess.Status;
			//}
		//}
	//}


	//public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		//JSONGenerator gen = JSON.createGenerator(true);
		//gen.writeStartObject();
		//gen.writeNumberField('Status Code', statusCode);
		//gen.writeStringField('Status', statusCodesMap.get(statusCode));
		//if (error == NULL) {
			//gen.writeStringField('Processed message type', mpRes.MessageType);
			////gen.writeStringField('Number of created budget records', String.valueOf(mpRes.NumberOfCreatedRecords));
			////gen.writeStringField('Number of updated budget records', String.valueOf(mpRes.NumberOfUpdatedRecords));
			////gen.writeStringField('Number of deleted budget records', String.valueOf(mpRes.NumberOfDeletedRecords));
		//} else {
			//gen.writeStringField('Error Message', error);
		//}

		//gen.writeEndObject();
		
		//String res = gen.getAsString();
		//System.debug('Response body text generated: ' + res);
		//return Blob.valueOf(res);
	//}


	
	//public class MessageProcessingResult {
		//public String MessageType;
		////public Integer NumberOfCreatedRecords = 0;
		////public Integer NumberOfUpdatedRecords = 0;
		////public Integer NumberOfDeletedRecords = 0;

		//public Boolean isNewPriceApprovalRequestCreated = false;
		//public Set<String> newQuotesList = new Set<String>();
		//public Set<String> changedCurrencyQuotes = new Set<String>();
	//}



	//public class erpException extends Exception {}
}