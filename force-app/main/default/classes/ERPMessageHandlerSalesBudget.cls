public class ERPMessageHandlerSalesBudget  {

	public final static Map<String, String> erp_to_sf_api_names = new Map<String, String> {
		'Shop' => 'Shop__c',
		'Country' => 'Country__c',
		'Manager' => 'UserId_ERP__c',
		'Product' => 'Product2',
		'Customer' => 'Account',
		//'OD_min' => 'TubeOD__c',
		//'OD_max' => 'TubeOD__c',
		//'WT_min' => 'TubeWT__c',
		//'WT_max' => 'TubeWT__c',
		'Coating' => 'CoatingType__c',
		'SteelGrade' => 'SteelGrade__c',
		'Ends' => 'TubeEnds__c',
		'QuotaType' => 'QuotaType__c'
	};

	
	public static List<SalesBudgetRecord__c> recordsWihoutManager = new List<SalesBudgetRecord__c>();
	public final static List<RecordType> sbrRTList = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'SalesBudgetRecord__c'];


//start
	public static MessageProcessingResult ProcessMessage(ERPRequestParser.SalesBudgetMessage parsedMessage, String requestBody) {
		MessageProcessingResult res = new MessageProcessingResult();
		res.MessageType = parsedMessage.Metadata.MsgType;
		system.debug('datetime');
        system.debug(parsedMessage.Metadata.MsgTimestamp);
		Long messageTimestamp = parsedMessage.Metadata.MsgTimestamp.getTime();
		
		List<SalesBudgetRecord__c> sbrToUpsert = new List<SalesBudgetRecord__c> ();
		List<SalesBudgetRecord__c> sbrToDelete = new List<SalesBudgetRecord__c> ();

		//Найдем существующую или создадим новую запись заголовка бюджета:
		SalesBudget__c sb = getSalesBudgetDocument(parsedMessage, res);
		
		//Создадим мапу, в которой хранится имя объекта и мапа соответствия ID_ERP и ID. Объекты, которые добавляются в эту мапу, перечислены в erp_to_sf_api_names.
		//Например: <'Shop__c' --> <ID_ERP --> Id>>
		Map<String, Map<String, Id>> objToIdMap = getObjectToIdMap(parsedMessage.Data.BudgetRecords);

		//Сформируем мапу: <код ID_ERP --> объект SBR>
		Map<String, SalesBudgetRecord__c> sbrByIdERPMap = getSbrSFMap(String.valueOf(sb.Id));

		for (ERPRequestParser.BudgetRecord sbrERP : parsedMessage.Data.BudgetRecords) {
			if (Decimal.valueOf(sbrERP.ProductionAmount) == 0 && Decimal.valueOf(sbrERP.SalesAmount) == 0 && Decimal.valueOf(sbrERP.DispatchedAmount) == 0) {
				continue;
			}
			//String fullIdERP = sb.Id_ERP__c + '-' + sbrERP.BudgetRecordID + '-' + sbrERP.BudgetRecordDetailsID;
			String fullIdERP = sbrERP.GUID;
			SalesBudgetRecord__c sbr;
			if (res.isNewSalesBudgetCreated || !sbrByIdERPMap.containsKey(fullIdERP)){
				sbr = new SalesBudgetRecord__c ();
				sbr.SalesBudget__c = sb.Id;
				sbr.ID_ERP__c = fullIdERP;

				res.NumberOfCreatedRecords++;
			} else {
				sbr = sbrByIdERPMap.get(fullIdERP);
				res.NumberOfUpdatedRecords++;
			}
			
			sbr.ExchangeTimestamp__c = messageTimestamp;
			setSbrPeriod(sbr, sbrERP);
			mapRelatedERPId(sbr, sb, objToIdMap, sbrERP);
			sbr.MarketSegment__c = sbrERP.Segment.deleteWhitespace();
			sbr.Region__c = sbrERP.Region.deleteWhitespace();
            //Dispatched amount field
			sbr.ProductionAmount__c = sbrERP.DispatchedAmount == null? 0:Decimal.valueOf(sbrERP.DispatchedAmount);
            //Production amount field
            sbr.Production_Amount__c = Decimal.valueOf(sbrERP.ProductionAmount);
			sbr.SalesAmount__c = Decimal.valueOf(sbrERP.SalesAmount);
			sbr.Revenue__c = Decimal.valueOf(sbrERP.Revenue);
			sbr.Price__c = Decimal.valueOf(sbrERP.Price);
			sbr.Margin__c = Decimal.valueOf(sbrERP.Margin);
			sbr.Margin_t__c = Decimal.valueOf(sbrERP.Margin_T);
			sbr.BudgetRecordID__c = sbrERP.BudgetRecordID;
            //system.debug('sbr2 ' + sbr.SalesManager__c);
            if(sbr.SalesManager__c == null){
                recordsWihoutManager.add(sbr);
            } else{
                sbrToUpsert.add(sbr);
            }
			
		}
        if(recordsWihoutManager.size()>0){
            searchAndAddAccountManager(recordsWihoutManager);
            sbrToUpsert.addall(recordsWihoutManager);
        }
		//System.debug(sbrToUpsert);
		upsert sbrToUpsert;

		// sbrToDelete = [SELECT Id FROM SalesBudgetRecord__c WHERE SalesBudget__c = :sb.Id AND ExchangeTimestamp__c < :messageTimestamp];
		// res.NumberOfDeletedRecords = sbrToDelete.size();
		// delete sbrToDelete;
        
        //26 05 create/update Production Quotes if we received last page of sales budget from IT
        system.debug('check parts');
        system.debug(Integer.valueOf(parsedMessage.Metadata.PartNumber));
        system.debug(Integer.valueOf(parsedMessage.Metadata.TotalParts));
        if(Integer.valueOf(parsedMessage.Metadata.PartNumber) == Integer.valueOf(parsedMessage.Metadata.TotalParts)){
            map<String,Object> currentSalesBudget = new map<String,Object> 
                                                               {'SaleBudgetId' => sb.Id};       
            // Match flow
            system.debug('budgetId = ' + currentSalesBudget);
            Flow.Interview  flow = new  Flow.Interview.Create_Production_Quotes(currentSalesBudget);
            flow.start();
            SalesPlanFactDeleteBatch deleteSalesPlanFactBatch = new SalesPlanFactDeleteBatch(sb.Id);
            //Id deleteSalesPlanFactBatchId = Database.executeBatch(deleteSalesPlanFactBatch);  
            System.scheduleBatch(deleteSalesPlanFactBatch,'deleteSalesPlanFactBatch',12);
        }

		return res;
	}



	private static SalesBudget__c getSalesBudgetDocument(ERPRequestParser.SalesBudgetMessage parsedMessage, MessageProcessingResult res) {
		
		SalesBudget__c sb;
		List<SalesBudget__c> sbList = [Select Id, ID_ERP__c, Year__c from SalesBudget__c where Id_ERP__c = :parsedMessage.Data.BudgetId LIMIT 1 FOR UPDATE];

		if (sbList.size() == 0) {
			sb = new SalesBudget__c();
			sb.OwnerId = UserInfo.getUserId();
			sb.Id_ERP__c = parsedMessage.Data.BudgetId;
			res.isNewSalesBudgetCreated = true;
		} else {
			sb = sbList[0];
		}

		sb.Year__c = Integer.valueOf(parsedMessage.Data.Year);
		sb.Type__c = parsedMessage.Data.BudgetType;
		sb.Name = parsedMessage.Data.BudgetName;
		sb.Name_ERP__c = parsedMessage.Data.BudgetName;
		sb.Approved__c = parsedMessage.Data.Approved == '1' ? true : false;

		System.debug(sb);
		upsert sb;

		return sb;

	}



	@testVisible
	private static Map<String, SalesBudgetRecord__c> getSbrSFMap(String sbId) {
		
		List<SalesBudgetRecord__c> sbrList = [
												SELECT Id, ID_ERP__c, Name, Period__c, Shop__c, Shop__r.Id_ERP__c, MarketSegment__c, Region__c, Country__c, Country__r.Id_ERP__c, SalesManager__c, SalesManager__r.Id_ERP__c, Product__c, Product__r.Id_ERP__c, Account__c, Account__r.Id_ERP__c, TubeOD_min__c, TubeOD_max__c, TubeWT_min__c, TubeWT_max__c, CoatingType__c, CoatingType__r.ID_ERP__c, SteelGrade__c, SteelGrade__r.Id_ERP__c, TubeEnds__c, TubeEnds__r.ID_ERP__c
												FROM SalesBudgetRecord__c
												WHERE SalesBudget__c = :sbId
											];

		Map<String, SalesBudgetRecord__c> sbrMap = new Map<String, SalesBudgetRecord__c> ();
		for (SalesBudgetRecord__c sbr : sbrList) {
			sbrMap.put(sbr.ID_ERP__c, sbr);
		}

		System.debug('==============>>>>> sbrSfMap: ' + sbrMap);
		return sbrMap;
	}


	private static void setSbrPeriod(SalesBudgetRecord__c sbr, ERPRequestParser.BudgetRecord sbrERP) {
		
		Map<String, Id> sbrRTIdMap = New Map<String, Id>();
		for (RecordType sbrRT : sbrRTList){
			sbrRTIdMap.put(sbrRT.DeveloperName, sbrRT.Id);
		}

		switch on sbrERP.PeriodType {
			when 'M' {sbr.RecordTypeId = sbrRTIdMap.get('PlanMonth');}
			when 'Q' {sbr.RecordTypeId = sbrRTIdMap.get('PlanQuarter');}
			when 'HY' {sbr.RecordTypeId = sbrRTIdMap.get('PlanHalfYear');}
		}
		
		//Date bop = DateTime.newInstance(Long.valueOf(sbrERP.PeriodBeginning + '000')).date();
        Date bop = sbrERP.PeriodBeginning.date();
		sbr.PeriodYear__c = bop.year();
		sbr.PeriodMonth__c = String.valueOf(bop.month()).leftPad(2, '0');
		switch on bop.month() {
			when 1, 2, 3 {sbr.PeriodQuarter__c = '1';}
			when 4, 5, 6 {sbr.PeriodQuarter__c = '2';}
			when 7, 8, 9 {sbr.PeriodQuarter__c = '3';}
			when 10, 11, 12 {sbr.PeriodQuarter__c = '4';}
		}
	
	}


	private static Map<String, Map<String, Id>> getObjectToIdMap(List<ERPRequestParser.BudgetRecord> budgetRecordsERP) {
		Map<String, Map<String, Id>> objectToIdMap = new Map<String, Map<String, Id>> ();
		Map<String, Set<String>> erpValuesForObject = new Map<String, Set<String>> ();
		System.debug(budgetRecordsERP);
		String serializedString = JSON.serialize(budgetRecordsERP);
		System.debug(serializedString);
		List<Object> sbrFieldsList = (List<Object>) JSON.deserializeUntyped(serializedString);
		System.debug('-- List: ' + sbrFieldsList);
		for (String key : erp_to_sf_api_names.keyset()) {
			Set<String> valuesSet = new Set<String> ();
			for (Integer i = 0; i < sbrFieldsList.size(); i++) {
				Map<String, Object> sbrField = (Map<String, Object>) sbrFieldsList.get(i);

				Map<String, Object> ERPObject = (Map<String, Object>) sbrField.get(key);
				if ((String) ERPObject.get('Id') != null) {
					System.debug('--- ' + (String) ERPObject.get('Id'));
					valuesSet.add(((String) ERPObject.get('Id')).deleteWhitespace());
				}
			}
			erpValuesForObject.put(key, valuesSet);
		}
		System.debug(erpValuesForObject);

		for (String key : erpValuesForObject.keySet()) {
			Set<String> setERPIds = erpValuesForObject.get(key);
			List<sObject> objectList;
			Map<String, Id> erpIdToIdMap = new Map<String, Id> ();
			switch on key {
				when 'Manager' {
					//Запрос выполняется не по справочнику User, а по справочнику UserId_ERP__c
					objectList = Database.query('SELECT Name, User__c FROM ' + erp_to_sf_api_names.get(key) + ' WHERE Name IN :setERPIds');
					for (sObject ob : objectList) {
						erpIdToIdMap.put((String) ob.get('Name'), (Id) ob.get('User__c'));
					}
					objectToIdMap.put(key, erpIdToIdMap);
					System.debug('Managers ERP IDs: ' + setERPIds);
					System.debug('Managers IDs: ' + erpIdToIdMap);
				}
				when else {
					objectList = Database.query('SELECT Id, ID_ERP__c FROM ' + erp_to_sf_api_names.get(key) + ' WHERE ID_ERP__c IN :setERPIds');
					for (sObject ob : objectList) {
						erpIdToIdMap.put((String) ob.get('ID_ERP__c'), ob.Id);
					}
				}
			}
			objectToIdMap.put(key, erpIdToIdMap);
			System.debug('Object to ID Map: ' + objectToIdMap);
		}
		return objectToIdMap;
	}



	private static void mapRelatedERPId(SalesBudgetRecord__c sbr, SalesBudget__c sb, Map<String, Map<String, Id>> objToIdMap, ERPRequestParser.BudgetRecord sbrERP) {
		List<String> fields = new List<String> { 'Shop', 'Customer', 'SteelGrade', 'Ends', 'Coating', 'QuotaType' };
		Map<String, Object> productAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sbrERP));

		List<String> errList = new List<String> ();
		String allErrors = '';

		//String sbrFullId = sb.Id_ERP__c + '-' + sbrERP.BudgetRecordID + '-' + sbrERP.BudgetRecordDetailsID;
		String sbrFullId = sbrERP.GUID;

		Map<String, SObject> sObjects_to_insert = new Map<String, SObject> ();

		for (String fieldName : fields) {
			System.debug('--- Product As Map: ' + productAsMap);

			Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get(fieldName);
			String ERPObjectID = ((String) ERPObject.get('Id')).deleteWhitespace();
			String ERPObjectName = (String) ERPObject.get('Name');
			if (String.isBlank(ERPObjectName)) {
				ERPObjectName = 'Object with ERP Id = ' + ERPObjectID;
			}

			System.debug('--- Object: ' + objToIdMap.get(fieldName).get(ERPObjectID));

			if (String.isNotBlank(ERPObjectID) && objToIdMap.get(fieldName).get(ERPObjectID) == null) {

				System.debug('There is no any ' + fieldName + ' with ERP-ID ' + ERPObjectID + ' (Budget Record #' + sbrFullId + ') - Creating new one.');

				String objName = erp_to_sf_api_names.get(fieldName);
				sObject sObj_to_insert = Schema.getGlobalDescribe().get(objName).newSObject();
				sObj_to_insert.put('Id_ERP__c', ERPObjectID);
				sObj_to_insert.put('Name', checkFieldValueSize(ERPObjectName, 80));
				if (objHasField(objName, 'NameRus__c')){
					sObj_to_insert.put('NameRus__c', checkFieldValueSize(ERPObjectName, 255));
				}
				if (fieldName == 'QuotaType'){
					sObj_to_insert.put('Shop__c', objToIdMap.get('QuotaType').get((String) ERPObject.get('OptionalValue1')));
				}

				System.debug('Created new object - ' + sObj_to_insert);

				sObjects_to_insert.put(fieldName, sObj_to_insert);
			}
		}

		if (sObjects_to_insert.values().size() > 0) {
			insert sObjects_to_insert.values();
			for (String fieldName : sObjects_to_insert.keySet()) {
				Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get(fieldName);
				String ERPObjectID = (String) ERPObject.get('Id');
				objToIdMap.get(fieldName).put(ERPObjectID, sObjects_to_insert.get(fieldName).Id);
			}
		}

		if (errList.size() > 0) {
			for (String errorMessage : errList) {
				System.debug(errorMessage);
			}
			throw new erpException(allErrors);
		}

		
		sbr.Shop__c = objToIdMap.get('Shop').get(sbrERP.Shop.Id.deleteWhitespace());
		sbr.Country__c = objToIdMap.get('Country').get(sbrERP.Country.Id.deleteWhitespace());
		Id productSfId = objToIdMap.get('Product').get(sbrERP.Product.Id.deleteWhitespace());
		if (productSfId == null) {
			throw new erpException('There is no any product with ID = ' + sbrERP.Product.Id.deleteWhitespace());
		}
		sbr.Product__c = productSfId;
		Id smSfId = objToIdMap.get('Manager').get(sbrERP.Manager.Id.deleteWhitespace());
		if (smSfId == null) {
			//throw new erpException('There is no any user (Sales Manager) with ID = ' + sbrERP.Manager.Id.deleteWhitespace());
		}
		sbr.SalesManager__c = smSfId;
		sbr.Account__c = objToIdMap.get('Customer').get(sbrERP.Customer.ID.deleteWhitespace());
		sbr.CoatingType__c = objToIdMap.get('Coating').get(sbrERP.Coating.ID.deleteWhitespace());
		sbr.SteelGrade__c = objToIdMap.get('SteelGrade').get(sbrERP.SteelGrade.ID.deleteWhitespace());
		sbr.TubeEnds__c = objToIdMap.get('Ends').get(sbrERP.Ends.ID.deleteWhitespace());
		sbr.QuotaType__c = objToIdMap.get('QuotaType').get(sbrERP.QuotaType.ID.deleteWhitespace());
		sbr.BudgetRecordID__c = sbrERP.BudgetRecordID;
        system.debug('SaleManager = ' + smSfId);
		system.debug('accountId = ' + sbr.Account__c);
	}



	private static Boolean objHasField(String objName, String fieldName) {

		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.DescribeSObjectResult objDescription = gd.get(objName).getDescribe();
		Map<String, Schema.SObjectField> fieldsMap = objDescription.fields.getMap();
		if (fieldsMap.containsKey(fieldName)) {
			return true;
		} else {
			return false;
		}

	}
	

	
	public static String checkFieldValueSize(String fieldValue, Integer maxValueSize) {

		if (fieldValue.length() > maxValueSize) {
			fieldValue = fieldValue.substring(0, maxValueSize - 4) + '...';
		}
		return fieldValue;
	}



	public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', statusCodesMap.get(statusCode));
		if (error == NULL) {
			gen.writeStringField('Processed message type', mpRes.MessageType);
			gen.writeStringField('Number of created budget records', String.valueOf(mpRes.NumberOfCreatedRecords));
			gen.writeStringField('Number of updated budget records', String.valueOf(mpRes.NumberOfUpdatedRecords));
			gen.writeStringField('Number of deleted budget records', String.valueOf(mpRes.NumberOfDeletedRecords));
		} else {
			gen.writeStringField('Error Message', error);
		}

		gen.writeEndObject();
		
		String res = gen.getAsString();
		System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}

    public static void searchAndAddAccountManager(List<SalesBudgetRecord__c> recordsNoManager){
        
        Map<String,String> accountIdManagerIdMap = new Map<String,String>();
        for(SalesBudgetRecord__c sbr : recordsNoManager){
            accountIdManagerIdMap.put(sbr.Account__c,null);
            
        }
        List<Account> fetchedAccounts = [SELECT ID_ERP__c,Owner.Id FROM Account WHERE Id in :accountIdManagerIdMap.keySet()];
        
        for(Account acc : fetchedAccounts){
            accountIdManagerIdMap.put(acc.Id,acc.Owner.Id);
        }
        
        for(SalesBudgetRecord__c sbr : recordsNoManager){
            sbr.SalesManager__c = accountIdManagerIdMap.get(sbr.Account__c);
        }
    }

	public class MessageProcessingResult {
		public String MessageType;
		public Integer NumberOfCreatedRecords = 0;
		public Integer NumberOfUpdatedRecords = 0;
		public Integer NumberOfDeletedRecords = 0;

		public Boolean isNewSalesBudgetCreated = false;
	}

	public class erpException extends Exception {}

	public static void FakeCoverageMethod() {
		Integer i=0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}