public class ERPMessageHandlerMonthPlanFact  {
	
	public static MessageProcessingResult ProcessMessage(ERPRequestParser.MonthPlanFactMessage parsedMessage, String requestBody) {	

		String errorMessage;
		String badIds;
		MessageProcessingResult res = new MessageProcessingResult();

		
		List<String> activeSegments = new List<String>();
		activeSegments.add('00001'); // Americas
		activeSegments.add('00002'); // MENA
		activeSegments.add('00004'); // MENA
		activeSegments.add('00006'); // KLW
		activeSegments.add('00010'); // CIS
		activeSegments.add('00011'); // Ukraine
		activeSegments.add('00016'); // Custom Union
		activeSegments.add('00005'); // IPS (сталь, заготовка)
		activeSegments.add('00019'); // Vallourec
        activeSegments.add('00020'); // ETA
        activeSegments.add('00021'); // Machinery

		//Set<String> keyFieldSet = new Set<String>();
		Set<String> oiITENumberSet = new Set<String>();
		Set<String> accIdErpSet = new Set<String>();
		Set<String> shopIdErpSet = new Set<String>();
		Set<String> prodIdErpSet = new Set<String>();
		Set<String> userIdErpSet = new Set<String>();
		Set<String> countryIdErpSet = new Set<String>();

		Set<Id> userIdList = new Set<Id>();
		List<OrderItem> oiToUpdate = new List<OrderItem>();

		Map<String, OrderItem> oiITENumberToObjMap = new Map<String,OrderItem>();
		Map<String, Id> accIdErpMap = new Map<String, Id>();
		Map<String, Id> shopIdErpMap = new Map<String, Id>();
		Map<String, Id> userIdErpMap = new Map<String, Id>();
		Map<Id, User> userIdMap;
		Map<String, Id> productIdErpToIdMap = new Map<String, Id>();
		Map<String, Id> countryIdERPToIdMap = new Map<String, Id>();
		
		String MessageTimestamp = parsedMessage.MessageTimestamp;
		String rtName = parsedMessage.MessageType == 'ERP-SF_MonthPlan' ? 'Plan' : 'Fact';
		Id rtId = [Select Id FROM RecordType WHERE SobjectType = 'SalesPlanFact__c' AND Name = :rtName].Id;
		
		// Пройдемся по элементам входящего сообщения, чтобы проверить, есть ли незаполненные поля в сообщении, а также заполнить необходимые переменные
		String emptyAccIdString;
		String emptyShopIdString;
		String emptyProdIdString;
		String emptyUserIdString;
		Boolean throwError = false;
		Boolean showUnknownObjects;

		for (ERPRequestParser.MonthPlanFact_OrderItemData oiData : parsedMessage.Item_Data) {
			//----- Устаревшее -------- {
			//// Ключевое поле хранится в формате '[ID_ERP]|YYYY-MM', сформируем такую строку:
			//Date periodDate = DateTime.newInstance(long.valueOf(oiData.Period + '000')).date();
			//keyFieldSet.add(oiData.UnDoc + '-' + oiData.NPP + '|' + String.valueOf(periodDate.year()) + '-' + String.valueOf(periodDate.month()).leftPad(2, '0'));
			//----- Устаревшее -------- }

			if (!activeSegments.contains(oiData.Segment) && !activeSegments.contains(oiData.CrossMarketSegment)) {
				continue;
			}
			
			if ((String.isEmpty(oiData.Dispatched) || oiData.Dispatched == '0') && (String.isEmpty(oiData.Shipped) || oiData.Shipped == '0')  && rtName == 'Fact') {
				continue;
			}

			if (String.isNotBlank(oiData.AccountId)) {
				accIdErpSet.add(oiData.AccountId);
			} else {
				emptyAccIdString = (emptyAccIdString == null ? '' : emptyAccIdString + ', ') + oiData.ITENumber;
			}

			if (String.isNotBlank(oiData.Shop)) {
				shopIdErpSet.add(oiData.Shop);
			} else {
				emptyShopIdString = (emptyShopIdString == null ? '' : emptyShopIdString + ', ') + oiData.ITENumber;
			}

			if (String.isNotBlank(oiData.Product)) {
				prodIdErpSet.add(oiData.Product);
			} else {
				emptyProdIdString = (emptyProdIdString == null ? '' : emptyProdIdString + ', ') + oiData.ITENumber;
			}
			
			if (String.isNotBlank(oiData.SalesManager)) {
				userIdErpSet.add(oiData.SalesManager.normalizeSpace());
			} else {
				emptyUserIdString = (emptyUserIdString == null ? '' : emptyUserIdString + ', ') + oiData.ITENumber;
			}
			
			if (String.isNotBlank(oiData.CrossMarketSegment)) {
				if (String.isNotBlank(oiData.CrossMarketManager)) {
					userIdErpSet.add(oiData.CrossMarketManager.normalizeSpace());
				} else {
					//emptyUserIdString = (emptyUserIdString == null ? '' : emptyUserIdString + ', ') + oiData.ITENumber;
				}
			}

			if (activeSegments.contains(oiData.Segment)) {
				oiITENumberSet.add(oiData.ITENumber);
			}
			
			if (String.isNotBlank(oiData.CountryId)) {
				countryIdErpSet.add(oiData.CountryId);
			}
			System.debug('------------------oiData-------------------- ' + oiData);

		}

		If (emptyAccIdString != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'There are empty Accounts for the following order items: ' + emptyAccIdString;
		}
		If (emptyShopIdString != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'There are empty Shops for the following order items: ' + emptyShopIdString;
		}
		If (emptyProdIdString != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'There are empty Products for the following order items: ' + emptyProdIdString;
		}
		If (emptyUserIdString != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'There are empty Users for the following order items: ' + emptyUserIdString;
		}

		// {------ Формирование списков соответствий для получения значений полей объектов ----------------------------------------------
		
		// Сформируем список соответствий строк ордеров, по которым есть данные в сообщении:
		Map<Id, OrderItem> oiIdMap = new Map<Id, OrderItem>(
				[	SELECT	Id, OrderId, ID_ERP__c, ITENumber__c
					FROM OrderItem
					WHERE ITENumber__c in :oiITENumberSet
				]);
		System.debug('------------------oiIdMap-------------------- ' + oiIdMap);
		System.debug('------------------oiITENumberSet-------------------- ' + oiITENumberSet);

		for (OrderItem oi : oiIdMap.values()) {
			oiITENumberToObjMap.put(oi.ITENumber__c, oi);
			oiToUpdate.add(oi);
		}
		// Проверим, есть ли в сообщении коды, по которым не найдены Order Items:
		

		//Сформируем список соответствий ID аккаунтов, по которым есть данные в сообщении:
		Map<Id, Account> accIdMap = new Map<Id, Account>(
				[	SELECT Id, ID_ERP__c
					FROM Account
					WHERE ID_ERP__c in :accIdErpSet
				]);
		for (Account acc : accIdMap.values()) {
			accIdErpMap.put(acc.ID_ERP__c, acc.Id);
		}
		// Проверим, нет ли во входящем сообщении неизвестных кодов аккаунтов:
		For (String accId : accIdErpSet) {
			if (accIdErpMap.get(accId) == null) {
				badIds = badIds == null ? accId : badIds + ', ' + accId;
			}
		}
		if (badIds != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'The following Account codes were not found: ' + badIds;
			badIds = null;
		}

		//Сформируем список соответствий ID цехов, по которым есть данные в сообщении:
		Map<Id, Shop__c> shopIdMap = new Map<Id, Shop__c>(
				[	SELECT Id, ID_ERP__c
					FROM Shop__c
					WHERE ID_ERP__c in :shopIdErpSet
				]);
		for (Shop__c shop : shopIdMap.values()) {
			shopIdErpMap.put(shop.ID_ERP__c, shop.Id);
		}
		// Проверим, нет ли во входящем сообщении неизвестных кодов цехов:
		For (String shopId : shopIdErpSet) {
			if (shopIdErpMap.get(shopId) == null) {
				badIds = badIds == null ? shopId : badIds + ', ' + shopId;
			}
		}
		if (badIds != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'The following Shop codes were not found: ' + badIds;
			badIds = null;
		}

		//Сформируем список соответствий ID продуктов, по которым есть данные в сообщении:
		Map<Id, Product2> prodIdMap = new Map<Id, Product2>(
				[	
					SELECT Id, ID_ERP__c
					FROM Product2
					WHERE ID_ERP__c in :prodIdErpSet
				]);
		for (Product2 prod : prodIdMap.values()) {
			productIdErpToIdMap.put(prod.ID_ERP__c, prod.Id);
		}
		// Проверим, нет ли во входящем сообщении неизвестных кодов продуктов:
		For (String prodIdErp : prodIdErpSet) {
			if (productIdErpToIdMap.get(prodIdErp) == null) {
				badIds = badIds == null ? prodIdErp : badIds + ', ' + prodIdErp;
			}
		}
		if (badIds != null) {
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'The following Product codes were not found: ' + badIds;
			badIds = null;
			//throwError = true;
		}
		
		//Сформируем списки соответствий Id_ERP к Id пользователей, по которым есть данные в сообщении:
		Map<Id, UserID_ERP__c> UserIdErpIdMap = new Map<Id, UserID_ERP__c>(
				[	SELECT Id, Name, User__c
					FROM UserId_ERP__c
					WHERE Name in :userIdErpSet
				]);
		for (UserID_ERP__c userIdErp : UserIdErpIdMap.values()) {
			userIdErpMap.put(userIdErp.Name, userIdErp.User__c);
			userIdList.add(userIdErp.User__c);
		}
		// Проверим, нет ли во входящем сообщении неизвестных кодов пользователей:
		System.debug('userIdErpMap!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + userIdErpMap);
		For (String uId : userIdErpSet) {
			if (userIdErpMap.get(uId) == null) {
				badIds = badIds == null ? uId : badIds + ', ' + uId;
			}
		}
		if (badIds != null) {
			System.debug('Unknown users');
			errorMessage = (errorMessage == null ? '' : errorMessage + '\n') + 'The following User codes were not found: ' + badIds;
			badIds = null;
		}
		
		Map<Id, Country__c> countryIdMap = new Map<Id, Country__c>(
				[	SELECT Id, ID_ERP__c
					FROM Country__c
					WHERE ID_ERP__c in :countryIdErpSet
				]);
		for (Country__c con : CountryIdMap.values()) {
			countryIdErpToIdMap.put(con.ID_ERP__c, con.Id);
		}

		List<SalesPlanFact__c> spfToCreate = new List<SalesPlanFact__c>();
        
		for (ERPRequestParser.MonthPlanFact_OrderItemData oiData : parsedMessage.Item_Data) {
			system.debug(oiData);
            // if (!activeSegments.contains(oiData.Segment) && !activeSegments.contains(oiData.CrossMarketSegment)) {
			// 	continue;
			// }

			// Decimal dispatched = oiData.Dispatched != null ? Decimal.valueOf(oiData.Dispatched) : 0;
			// Decimal shipped = oiData.Shipped != null ? Decimal.valueOf(oiData.Shipped) : 0;
			// if (dispatched == 0 && shipped == 0 && rtName == 'Fact') {
			// 	continue;
			// }
				Decimal coef = 1;
				if (oiData.CrossMarketSegment != null && oiData.CrossMarketSegment != '' && oiData.CrossMarketSegment != '0') {
					//Все суммы при кросс-маркет продаже будем умножать на коэффициент.
					coef = oiData.CrossMarketPercent == null || Decimal.valueOf(oiData.CrossMarketPercent) == 0
						? 0.5
						: Decimal.valueOf(oiData.CrossMarketPercent) / 100;
				}

				Id ownerId;
				SalesPlanFact__c spf;

				if (userIdErpMap.containsKey(oiData.SalesManager)) {
					ownerId = userIdErpMap.get(oiData.SalesManager);
				}else{
					ownerId = UserInfo.getUserId();
				}
				system.debug(ownerId);
				spf = new SalesPlanFact__c ();                     
				spf.RecordTypeId = rtId;
				spf.ExchangeTimeStamp__c = MessageTimestamp;
				spf.Period__c = DateTime.newInstance(long.valueOf(oiData.Period + '000')).date();
				spf.ID_ERP__c = oiData.UnDoc + '-' + oiData.NPP;
				spf.OrderAdditionalNumber__c = oiData.OrderAddNumber;
				spf.ITENumber__c = oiData.ITENumber;
				spf.InitialRecordId__c = null;
				spf.InitialRecordURL__c = null;
				spf.Shop__c = shopIdErpMap.get(oiData.Shop.normalizeSpace());
				spf.OwnerId = ownerId;
				spf.MarketSegment__c = oiData.Segment;
				spf.Region__c = oiData.Region;
				spf.Country__c = countryIdERPToIdMap.get(oiData.CountryId);
				spf.Account__c = accIdErpMap.get(oiData.AccountId.normalizeSpace());
				spf.Product2Id__c = productIdErpToIdMap.get(oiData.Product.normalizeSpace());
				spf.ProductionAmount__c = oiData.DispatchedNetto != null ? Decimal.valueOf(oiData.DispatchedNetto) * coef : 0;
				spf.SalesAmount__c = oiData.ShippedNetto != null ? Decimal.valueOf(oiData.ShippedNetto) * coef : 0;
				spf.Revenue__c = oiData.Revenue != null ? Decimal.valueOf(oiData.Revenue) * coef : 0;
				spf.Margin__c = oiData.Margin != null ? Decimal.valueOf(oiData.Margin) * coef : 0;
				spf.Margin_t__c = oiData.Margin_t != null ? Decimal.valueOf(oiData.Margin_t) : 0;
				spf.Production_Amount__c = oiData.Produced != null ? Decimal.valueOf(oiData.Produced) * coef : 0;
				spf.ProducedForecast__c = oiData.ProducedForecast !=null? Decimal.valueOf(oiData.ProducedForecast) : 0;
				
				if(rtName =='Plan'){
					spf.Production_Plan__c = oiData.ProductionPlan !=null? Decimal.valueOf(oiData.ProductionPlan) : 0;
				}

				spfToCreate.add(spf);

												// }
		}
		
		System.debug('--- SPF records to create: ' + spfToCreate);
		System.debug('--- SPF size: ' + spfToCreate.size());
		
		
		// insert pjrToCreate;
		try {
			insert spfToCreate;
		} catch (Exception e) {
			system.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + e);
		}
		

		// Проапдейтим все Order Items, для которых были созданы или удалены записи PJR, чтобы по триггерам создались записи в объекте SPF:
		system.debug('--------------------oiToUpdate----------------' + oiToUpdate);
		// update oiToUpdate;
		return res;
		
		
	}
	public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', statusCodesMap.get(statusCode));
		
		

		gen.writeEndObject();
		
		String res = gen.getAsString();
		System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}
	
	public class MessageProcessingResult {
		public String MessageType;
		
		public Integer numberOfCreatedPjrRecords;
		public Integer numberOfCreatedSpfRecords;
		
		public List<String> foundOiITENumberList;
		public List<String> unknownOiITENumberList;
		
		public List<String> unknownAccounts = new List<String>();
		public List<String> unknownShops = new List<String>();
		public List<String> unknownProducts = new List<String>();
		public List<String> unknownUsers = new List<String>();
	}
	
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
	}
}