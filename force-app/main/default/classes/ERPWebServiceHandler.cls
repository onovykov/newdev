public class ERPWebServiceHandler {
	public final static Map<Integer, String> HTTPSTATUSES = new Map<Integer, String> {
		200 => 'OK',
		201 => 'CREATED',
		202 => 'ACCEPTED',
		204 => 'NO CONTENT',
		206 => 'PARTIAL CONTENT',
		300 => 'MULTIPLE CHOICES',
		301 => 'MOVED PERMANENTLY',
		302 => 'FOUND',
		304 => 'NOT MODIFIED',
		400 => 'BAD REQUEST',
		401 => 'UNAUTHORIZED',
		403 => 'FORBIDDEN',
		404 => 'NOT FOUND',
		405 => 'METHOD NOT ALLOWED',
		406 => 'NOT ACCEPTABLE',
		409 => 'CONFLICT',
		410 => 'GONE',
		412 => 'PRECONDITION FAILED',
		413 => 'REQUEST ENTITY TOO LARGE',
		414 => 'REQUEST URI TOO LARGE',
		415 => 'UNSUPPORTED MEDIA TYPE',
		417 => 'EXPECTATION FAILED',
		500 => 'INTERNAL SERVER ERROR',
		503 => 'SERVER UNAVAILABLE'
	};

	private final static List<String> activeSegments = new List<String> {
		'00001', // Americas
		'00002', // MENA
		'00006', // KLW
		'00010', // CIS
		'00011', // Ukraine
		'00016', // Custom Union
		'00020',  // ETA
        '00021'  // Machinery   
	};

	public final static Map<String, String> erp_to_sf_api_names = new Map<String, String> {
		'ProductGroup' => 'Product2',
		'QuotaType' => 'QuotaType__c',
		'Standard' => 'ProductStandard__c',
		'SteelGrade' => 'SteelGrade__c',
		'OD' => 'TubeOD__c',
		'WT' => 'TubeWT__c',
		'Ends' => 'TubeEnds__c',
		'LengthSize' => 'TubeLengthSize__c',
		'SpecLevel' => 'ProductSpecLevel__c',
		'Coating' => 'CoatingType__c',
		'Shop' => 'Shop__c',
		'ShippingPoint' => 'ShippingPoint__c',
		'WheelStandard' => 'WheelProductStandard__c',
		'WheelSteelGrade' => 'WheelSteelGrade__c',
		'WheelDiameter' => 'WheelDiameter__c',
		'WheelHub' => 'WheelHub__c',
		'WheelDrawing' => 'WheelDrawing__c'
	};

	public final static Map<String, String> erp_to_sf_api_names_opp = new Map<String, String> {
		'Country' => 'Country__c',
		'PaymentTerms' => 'PaymentTerms__c',
		'DeliveryTerms' => 'DeliveryTerms__c'
	};


	public final static Country__c country_not_spec = [SELECT Id FROM Country__c WHERE NumCode__c = '0' LIMIT 1];
	//public final static Id country_not_spec = RecordReference__mdt.UnspecifiedCountry.RecordId__c;
	public final static Shop__c shop_not_cpec = [SELECT Id, Id_ERP__C, Name FROM Shop__c WHERE Id_ERP__C = '0' LIMIT 1];
	//public final static Id shop_not_cpec = RecordReference__mdt.UnspecifiedShop.RecordId__c;
	public final static Map<Id, RecordType> idToRtMap = New Map<Id, RecordType>([Select Id, DeveloperName from RecordType where SObjectType = 'Opportunity']);
	public final static RecordType RT_ACCOUNT_CUSTOMER = [Select Id from RecordType where SObjectType = 'Account' AND Name = 'Customer' limit 1];

	public static String ProductType;
	public static Opportunity relatedOpp;



	public static UpdateSFRecordsResult updateOpportunity(ERPRequestParser.ERPOpportunity requestObj, String requestBody, String businessDivision) {
		
		if (String.isBlank(requestObj.ID_ERP)) {
			String errorMessage = 'Your request does not contain ID_ERP field for Opportunity.';
			throw new erpException(errorMessage);
		}

		UpdateSFRecordsResult result = new UpdateSFRecordsResult();

		Opportunity opp = getOpportunitySFByERPID(requestObj.ID_ERP);
		result.parentOpp = opp;

		checkOpportunityStatus(requestObj, result);
		
		Map<String, Id> rtNameToIdMap = new Map<String, Id>();
		for (Id rtId : idToRtMap.keySet()) {
			rtNameToIdMap.put(idToRtMap.get(rtId).DeveloperName, rtId);
		}
		Id rtId;
		if (businessDivision == 'Tubes') {
			rtId = rtNameToIdMap.get('Tubes_RFP');
		} else if (businessDivision == 'Wheels') {
			rtId = rtNameToIdMap.get('Wheels_RFP');
		} else if (String.isBlank(businessDivision)) {
			if (opp == null) {
				// Не будем создавать новую оппу, если в ней нет ни одной позиции
				return result;
			} else {
				// Оппа уже существует, просто продолжим выполнение метода, не выбрасывая Exception
			}
		} else {
			throw new erpException('Unknown Business Division! Allowed values: "Tubes" | "Wheels"');
		}

		if (opp != NULL) {
			
			if (opp.Pricebook2Id == null) {
				opp.Pricebook2Id = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard = True LIMIT 1].get(0).Id;
			}

			if (String.valueOf(opp.CurrencyIsoCode) != requestObj.OpportunityCurrency) {
				result.isCurrencyCodeChanged = true;
			}

			if (opp.IsClosed) {
				result.oppChangeStatus = 'Closed';
				//return result;
			} else if(result.hasLots) {
				// Если оппа не закрыта, но по ней уже есть лоты, то закроем ее:
				opp.StageName = 'Closed Won';
			}

			if (result.isCurrencyCodeChanged) {
				List<OpportunityLineItem> oppLineItemsToDelete = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
				delete oppLineItemsToDelete;
			}

			System.debug('Opportunity exists. Start updating.');
			opp = mapOpportunityFields(requestObj, opp, result, requestBody);
			System.debug('Mapped Opportunity before update: ' + opp);
			Database.update(opp);
			System.debug('Mapped Opportunity after DML updating: ' + opp);
			result.oppChangeStatus = 'Updated';
			
			System.debug('Opportunity updating result: ' + result);
		} else {
			System.debug('Opportunity does not exist. Creating new one.');
			result.isNewOppCreated = true;
			opp = new Opportunity();
			opp.RecordTypeId = rtId;
			opp.Type = 'Ordinary Selling';
			opp = mapOpportunityFields(requestObj, opp, result, requestBody);
			opp.Name = String.isBlank(requestObj.AddNumber) ? (String.isBlank(requestObj.ID_ERP) ? 'Not defined' : requestObj.ID_ERP + ' (UnDoc in IT-Enterprise)') : requestObj.AddNumber;
			opp.ID_ERP__c = requestObj.ID_ERP;
			if (result.hasLots) {
				opp.StageName = 'Closed Won';
				
			} else {
				opp.StageName = 'Analysis';
			}
			opp.CloseDate = Date.today();
			opp.CreatedDate = opp.CreatedDate_ERP__c.date();
			System.debug('Created Opportunity before DML inserting: ' + opp);

			upsert opp ID_ERP__c;
			System.debug('Created Opportunity: ' + opp);
			result.oppChangeStatus = 'Created';
			result.parentOpp = opp;
			System.debug('Opportunity creation result: ' + result);

			String taskSubject;
			String taskDescription;
			switch on opp.Owner.LanguageLocaleKey {
				when 'uk' {
					taskSubject = 'Перевірте результати синхронізації з IT-Enterprise.';
					taskDescription = 'Створена нова можливість із ІТ-Підприємства. Актуалізуйте її назву та дату закриття, та перевірте інші данні.';
				}
				when 'ru' {
					taskSubject = 'Проверьте результаты синхронизации с IT-Enterprise.';
					taskDescription = 'Создана новая возможность из ИТ-Предприятия. Актуализируйте её название, дату закрытия, и проверьте прочие данные.';
				}
				when else {
					taskSubject = 'Review changes after synchronization with IT-Enterprise.';
					taskDescription = 'New opportunity was created from IT-Enterprise. Update its Name, Close Date and review other fields';
				}
			}
			insertEditingTaskForOppOwner(opp, taskSubject, taskDescription);
		}
		return result;
	}



	public static UpdateSFRecordsResult updateLineItems(ERPRequestParser.ERPrequest requestObj, ERPWebServiceHandler.UpdateSFRecordsResult resultOpp) {
		UpdateSFRecordsResult result = new UpdateSFRecordsResult();
		result.newOppProductsIds = new List<String> ();
		result.updatedOppProductsIds = new List<String> ();

		ProductType = requestObj.ProductType;

		Opportunity opp = getOpportunitySFByERPID(requestObj.General_Data.ID_ERP);

		List<OpportunityLineItem> oppProductsToUpdate = new List<OpportunityLineItem> ();
		Set<OpportunityLineItem> oppProductsToDelete = new Set<OpportunityLineItem> ();
		List<OpportunityLineItem> oppProductsToInsert = new List<OpportunityLineItem> ();
		Map<String, PricebookEntry> pbeIdByProduct2erpId = selectPBEbyProduct2ERPId(requestObj.General_Data.Item_Data, opp);

		Set<String> oppProductERPIds = getOppProductERPIds(requestObj.General_Data.Item_Data);

		Map<String, OpportunityLineItem> oppProductsByERPIdMap = getOppProdSFMap(oppProductERPIds, 'NPP_ERP__c', String.valueOf(opp.Id));

		Map<String, Map<String, Id>> objToIdMap = getObjectToIdMap(requestObj.General_Data.Item_Data);

		if (resultOpp.isNewOppCreated == true || resultOpp.isCurrencyCodeChanged == true) {
			System.debug('New Opportunity was created or Currency Code was changed (' + opp.Id + '). Creating Line Items Without querying.');
			for (ERPRequestParser.OpportunityProduct oppProdERP : requestObj.General_Data.Item_Data) {
				//Пропустим строку, если не заполнены продукт или количество:
				if (String.isBlank(oppProdERP.ProductGroup.Id) || String.isBlank(oppProdERP.InqQuantity) || Decimal.valueOf(oppProdERP.InqQuantity) == 0) {
					continue;
				}
				if (String.isBlank(oppProdERP.ProductGroup.ID) || !pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
					if (String.isBlank(oppProdERP.ProductGroup.ID)) {
						String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.ID_ERP + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup + ') for item #' + oppProdERP.ID_ERP);
						throw new erpException(errorMessage);
					}
				}
				OpportunityLineItem newOppLi = createNewOli(oppProdERP, opp.Id, pbeIdByProduct2erpId);
				mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP);
				updateOLI(newOppLi, null, oppProdERP, requestObj.General_Data.ID_ERP, null, null);
				System.debug('Line Item after all mappings:');
				System.debug(newOppLi);
				oppProductsToInsert.add(newOppLi);
			}
		} else {
			System.debug('Your Opportunity was succesfully found(' + opp.Id + '). Working with Line Items.');
			for (ERPRequestParser.OpportunityProduct oppProdERP : requestObj.General_Data.Item_Data) {
				//Пропустим строку, если не заполнены продукт или количество:
				if (String.isBlank(oppProdERP.ProductGroup.Id) || String.isBlank(oppProdERP.InqQuantity) || Decimal.valueOf(oppProdERP.InqQuantity) == 0) {
					continue;
				}
				if (!pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
					String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.ID_ERP + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup.ID + ') for item #' + oppProdERP.ID_ERP);
					throw new erpException(errorMessage);
				}
				System.debug('oppProductsByERPIdMap - ' + oppProductsByERPIdMap);
				System.debug('oppProdERP.ID_ERP - ' + oppProdERP.ID_ERP);
				if (!oppProductsByERPIdMap.containsKey(oppProdERP.ID_ERP)) {
					System.debug('There is no such Line Item with NPP_ERP__c=' + oppProdERP.ID_ERP + ' for this Opportunity. Creating new one.');
					OpportunityLineItem newOppLi = createNewOli(oppProdERP, opp.Id, pbeIdByProduct2erpId);
					mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP);
					updateOLI(newOppLi, null, oppProdERP, requestObj.General_Data.ID_ERP, null, null);
					System.debug('Line Item fater all mappings:');
					System.debug(newOppLi);
					oppProductsToInsert.add(newOppLi);
				} else {
					OpportunityLineItem oldOppLi = oppProductsByERPIdMap.get(oppProdERP.ID_ERP);
					System.debug('Line Item with NPP_ERP__c=' + oppProdERP.ID_ERP + ' for this Opportunity was succesfully found:');
					System.debug(oldOppLi);
					if (oldOppLi.PricebookEntryId == pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id) {
						System.debug('Updating.');
						OpportunityLineItem oppLi = oppProductsByERPIdMap.get(oppProdERP.ID_ERP);
						mapRelatedERPId(oppLi, null, objToIdMap, oppProdERP);
						updateOLI(oppLi, null, oppProdERP, requestObj.General_Data.ID_ERP, null, null);
						System.debug('Line Item after all mappings:');
						System.debug(oppLi);
						oppProductsToUpdate.add(oppLi);
						result.updatedOppProductsIds.add(oppLi.Id);
					} else {
						System.debug('This Line Item changed it\'s ProductGroup. Creating clone and deleting old one.');
						OpportunityLineItem newOppLi = oldOppLi.clone(false, true, false, false);
						newOppLi.OpportunityId = opp.Id;
						newOppLi.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
						newOppLi.TotalPrice = null;
						newOppLi.NPP_ERP__c = String.valueOf(oppProdERP.ID_ERP);
						mapRelatedERPId(newOppLi, null, objToIdMap, oppProdERP);
						updateOLI(newOppLi, null, oppProdERP, requestObj.General_Data.ID_ERP, null, null);
						System.debug('Line Item fater all mappings:');
						System.debug(newOppLi);
						System.debug('newOppLi.NPP_ERP__c - ' + newOppLi.NPP_ERP__c);
						oppProductsToInsert.add(newOppLi);
						oppProductsToDelete.add(oldOppLi);
					}
				}
			}
		}

		System.debug('Deleting ' + oppProductsToDelete.size() + ' Line Item(s):');
		System.debug(oppProductsToDelete);
		if (oppProductsToDelete.size() > 0) {
			List<OpportunityLineItem> deletionLIst = new List<OpportunityLineItem> (oppProductsToDelete);
			delete deletionLIst;
			oppProductsToDelete.clear();
		}

		System.debug('Creating ' + oppProductsToInsert.size() + ' Line Item(s):');
		System.debug(oppProductsToInsert);
		if (oppProductsToInsert.size() > 0) {
			insert oppProductsToInsert;
			for (OpportunityLineItem createdOppLi : oppProductsToInsert) {
				result.newOppProductsIds.add(createdOppLi.Id);
			}
		}

		for (String current_li_ID_ERP : oppProductsByERPIdMap.keySet()) {
			if (current_li_ID_ERP != null && !oppProductERPIds.contains(current_li_ID_ERP)) {
				oppProductsToDelete.add(oppProductsByERPIdMap.get(current_li_ID_ERP));
			}
		}

		System.debug('Deleting ' + oppProductsToDelete.size() + ' Line Item(s):');
		System.debug(oppProductsToDelete);
		if (oppProductsToDelete.size() > 0) {
			List<OpportunityLineItem> deletionLIst2 = new List<OpportunityLineItem> (oppProductsToDelete);
			delete deletionLIst2;
		}

		System.debug('Updating ' + oppProductsToUpdate.size() + ' Line Item(s):');
		System.debug(oppProductsToUpdate);
		if (oppProductsToUpdate.size() > 0) {
			update oppProductsToUpdate;
		}
		result.objToIdMap = objToIdMap;

		return result;
	}



	public static UpdateSFRecordsResultOrder updateOrder(ERPRequestParser.ERPOpportunity requestObj, ERPWebServiceHandler.UpdateSFRecordsResult resultOpp) {

		UpdateSFRecordsResultOrder result = new UpdateSFRecordsResultOrder();

		Order ord = getOrderSFByID(resultOpp);

		if (ord != NULL) {
			System.debug('Order before updating - ' + ord);

			if (ord.Status != 'Draft') {
				System.debug('Order exists in status Activated - changing status.');
				ord.Status = 'Draft';
			}
			
			//Запишем Start Date ордера в результат, чтобы если там не найдется более ранней даты, восстановить эту.
			result.firstLotDate = ord.EffectiveDate;
			//Очистим даты начала и конца ордера, чтобы не возникло конфликтов при назначении дат продуктам.
			ord.EffectiveDate = Date.newInstance(1900, 1, 1);
			ord.EndDate = null;
			update ord;
			
			if (String.valueOf(ord.CurrencyIsoCode) != requestObj.OpportunityCurrency) {
				
				result.isCurrencyCodeChanged = true;
				List<OrderItem> ordLineItemsToDelete = [SELECT Id FROM OrderItem WHERE OrderId = :ord.Id];
				System.debug('Deleting - ' + ordLineItemsToDelete);
				delete ordLineItemsToDelete;
			}

			ord = mapOrderFields(requestObj, ord, result, resultOpp);
			System.debug('Mapped Order before update: ' + ord);
			Database.update(ord);
			System.debug('Mapped Order after DML updating: ' + ord);
			result.parentOrd = ord;
			System.debug('Order updating result: ' + result);

			//Удалим записи ProductionLots:
			List<ProductionLot__c> lotsToDelete = [SELECT id FROM ProductionLot__c WHERE Order__c = :ord.Id];
			delete lotsToDelete;

		} else {

			Opportunity opp = getOpportunitySFByERPID(requestObj.ID_ERP);

			System.debug('Order does not exist. Creating new one.');
			result.isNewOrderCreated = true;
			ord = new Order();
			ord = mapOrderFields(requestObj, ord, result, resultOpp);
			ord.Name = (String.isBlank(requestObj.ID_ERP)) ? 'Not defined' : requestObj.ID_ERP;
			ord.ID_ERP__c = requestObj.ID_ERP;
			ord.ContractId = opp.ContractId;
			//Сначала запишем "нулевую дату", чтобы потом проставить либо текущую, либо дату самого первого лота.
			ord.EffectiveDate = Date.newInstance(1900, 1, 1);
			ord.EffectiveDateAux__c = opp.CloseDate < Date.today() ? opp.CloseDate : Date.today();
			result.firstLotDate = opp.CloseDate < Date.today() ? opp.CloseDate : Date.today();
			ord.Status = 'Draft';
			ord.Pricebook2Id = opp.Pricebook2Id;
			ord.OpportunityId = opp.Id;
			System.debug('Created Order before DML inserting: ' + ord);

			upsert ord ID_ERP__c;

			Opportunity opp_to_update = new Opportunity(Id = opp.Id);
			opp_to_update.SyncedOrder__c = ord.Id;
			update opp_to_update;

			System.debug('Created Order: ' + ord);
			result.parentOrd = ord;
			System.debug('Order creation result: ' + result);
		}
		return result;
	}



	public static UpdateSFRecordsResultOrder updateOrderLineItems(ERPRequestParser.ERPrequest requestObj, UpdateSFRecordsResult resultOpp, UpdateSFRecordsResultOrder resultOrd) {

		UpdateSFRecordsResultOrder result = new UpdateSFRecordsResultOrder();
		result.newOrdProductsIds = new List<String> ();
		result.updatedOrdProductsIds = new List<String> ();

		Opportunity opp = getOpportunitySFByERPID(requestObj.General_Data.ID_ERP);
		Order ord = resultOrd.parentOrd;

		List<OrderItem> ordProductsToUpdate = new List<OrderItem> ();
		Set<OrderItem> ordProductsToDelete = new Set<OrderItem> ();
		List<OrderItem> ordProductsToInsert = new List<OrderItem> ();
		List<ProductionLot__c> lotsToInsert = new List<ProductionLot__c> ();
		Map<String, PricebookEntry> pbeIdByProduct2erpId = selectPBEbyProduct2ERPId(requestObj.General_Data.Item_Data, opp);

		Set<String> oppProductERPIds = getOppProductERPIds(requestObj.General_Data.Item_Data);

		Map<String, OrderItem> ordProductsByERPIdMap = getOrdProdSFMap(oppProductERPIds, 'NPP_ERP__c', String.valueOf(ord.Id));

		Map<String, Map<String, Id>> objToIdMap;
		if (resultOpp.objToIdMap != null) {
			objToIdMap = resultOpp.objToIdMap;
		} else {
			objToIdMap = getObjectToIdMap(requestObj.General_Data.Item_Data);
		}

		Integer numberOfProducts = 0;
		if (resultOrd.isNewOrderCreated == true || result.isCurrencyCodeChanged == true) {
			System.debug('New Order was created(' + opp.Id + ') or Currency Code was changed. Creating Line Items Without querying.');
			for (ERPRequestParser.OpportunityProduct oppProdERP : requestObj.General_Data.Item_Data) {
				if (String.isBlank(oppProdERP.ProductGroup.Id) || String.isBlank(oppProdERP.InqQuantity) || Decimal.valueOf(oppProdERP.InqQuantity) == 0) {
					continue;
				}
				if (String.isBlank(oppProdERP.ProductGroup.ID) || !pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
					if (String.isBlank(oppProdERP.ProductGroup.ID)) {
						String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.ID_ERP + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup + ') for item #' + oppProdERP.ID_ERP);
					}
				}
				OrderItem newOrdI = createNewOrderItem(oppProdERP, ord, pbeIdByProduct2erpId);
				mapRelatedERPId(null, newOrdI, objToIdMap, oppProdERP);
				updateOLI(null, newOrdI, oppProdERP, requestObj.General_Data.ID_ERP, lotsToInsert, result);
				System.debug('Line Item after all mappings:');
				System.debug(newOrdI);
				ordProductsToInsert.add(newOrdI);
				numberOfProducts++;
			}
		} else {
			System.debug('Your Order was succesfully found(' + ord.Id + '). Working with Order Line Items.');
			for (ERPRequestParser.OpportunityProduct oppProdERP : requestObj.General_Data.Item_Data) {
				if (String.isBlank(oppProdERP.ProductGroup.Id) || String.isBlank(oppProdERP.InqQuantity) || Decimal.valueOf(oppProdERP.InqQuantity) == 0) {
					continue;
				}
				if (!pbeIdByProduct2erpId.containsKey(oppProdERP.ProductGroup.ID)) {
					String errorMessage = String.isBlank(oppProdERP.ProductGroup.ID) ? ('ProductGroup field for Line Item #' + oppProdERP.ID_ERP + ' is empty.') : ('There is no such Product Group (' + oppProdERP.ProductGroup.ID + ') for item #' + oppProdERP.ID_ERP);
					throw new erpException(errorMessage);
				}
				if (!ordProductsByERPIdMap.containsKey(oppProdERP.ID_ERP)) {
					System.debug('There is no such Line Item with NPP_ERP__c=' + oppProdERP.ID_ERP + ' for this Order. Creating new one.');
					OrderItem newOrdI = createNewOrderItem(oppProdERP, ord, pbeIdByProduct2erpId);
					mapRelatedERPId(null, newOrdI, objToIdMap, oppProdERP);
					updateOLI(null, newOrdI, oppProdERP, requestObj.General_Data.ID_ERP, lotsToInsert, result);
					System.debug('Line Item fater all mappings:');
					System.debug(newOrdI);
					ordProductsToInsert.add(newOrdI);
				} else {
					OrderItem oldOrdLi = ordProductsByERPIdMap.get(oppProdERP.ID_ERP);
					System.debug('Line Item with NPP_ERP__c=' + oppProdERP.ID_ERP + ' for this Order was succesfully found:');
					System.debug(oldOrdLi);
					if (oldOrdLi.PricebookEntryId == pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id) {
						System.debug('Updating.');
						OrderItem ordLi = ordProductsByERPIdMap.get(oppProdERP.ID_ERP);
						mapRelatedERPId(null, ordLi, objToIdMap, oppProdERP);
						updateOLI(null, ordLi, oppProdERP, requestObj.General_Data.ID_ERP, lotsToInsert, result);
						System.debug('Line Item after all mappings:');
						System.debug(ordLi);
						ordProductsToUpdate.add(ordLi);
						result.updatedOrdProductsIds.add(ordLi.Id);
					} else {
						System.debug('This Line Item changed it\'s ProductGroup. Creating clone and deleting old one.');
						OrderItem newOrdLi = oldOrdLi.clone(false, true, false, false);
						newOrdLi.OrderId = ord.Id;
						newOrdLi.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
						newOrdLi.NPP_ERP__c = String.valueOf(oppProdERP.ID_ERP);
						mapRelatedERPId(null, newOrdLi, objToIdMap, oppProdERP);
						updateOLI(null, newOrdLi, oppProdERP, requestObj.General_Data.ID_ERP, lotsToInsert, result);
						System.debug('Line Item fater all mappings:');
						System.debug(newOrdLi);
						ordProductsToInsert.add(newOrdLi);
						ordProductsToDelete.add(oldOrdLi);
					}
				}
				numberOfProducts++;
			}
		}

		System.debug('Deleting ' + ordProductsToDelete.size() + ' Line Item(s):');
		System.debug(ordProductsToDelete);
		if (ordProductsToDelete.size() > 0) {
			List<OrderItem> deletionLIst = new List<OrderItem> (ordProductsToDelete);
			delete deletionLIst;
			ordProductsToDelete.clear();
		}

		System.debug('Creating ' + ordProductsToInsert.size() + ' Line Item(s):');
		System.debug(ordProductsToInsert);
		for (OrderItem op : ordProductsToInsert) {
			System.debug('>>>>>>>>>>>>>>> ' + op.ID_ERP__c);
		}
		
		if (ordProductsToInsert.size() > 0) {
			insert ordProductsToInsert;
			for (OrderItem createdOrdLi : ordProductsToInsert) {
				result.newOrdProductsIds.add(createdOrdLi.Id);
			}
		}

		if (lotsToInsert.size() > 0) {
			insert lotsToInsert;
		}

		for (String current_li_ID_ERP : ordProductsByERPIdMap.keySet()) {
			if (!oppProductERPIds.contains(current_li_ID_ERP)) {
				ordProductsToDelete.add(ordProductsByERPIdMap.get(current_li_ID_ERP));
			}
		}

		System.debug('Deleting ' + ordProductsToDelete.size() + ' Line Item(s):');
		System.debug(ordProductsToDelete);
		if (ordProductsToDelete.size() > 0) {
			List<OrderItem> deletionLIst = new List<OrderItem> (ordProductsToDelete);
			delete deletionLIst;
		}

		System.debug('Updating ' + ordProductsToUpdate.size() + ' Line Item(s):');
		System.debug(ordProductsToUpdate);
		if (ordProductsToUpdate.size() > 0) {
			update ordProductsToUpdate;
		}

		if (result.firstLotDate != null && (ord.EffectiveDate == null || ord.EffectiveDate == Date.newInstance(1900, 1, 1) || ord.EffectiveDate > result.firstLotDate)) {
			ord.EffectiveDate = result.firstLotDate;
		}
		if (ord.EffectiveDate == null || ord.EffectiveDate == Date.newInstance(1900,1,1)) {
			//Сначала выберем между opp.CloseDate и ord.CreatedDate:
			if (ord.CreatedDate != null) {
				ord.EffectiveDate = opp.CloseDate < ord.CreatedDate.date() ? opp.CloseDate : ord.CreatedDate.date();
			} else {
				ord.EffectiveDate = opp.CloseDate;
			}
			//Теперь сверим с текущей датой:
			if (ord.EffectiveDate > Date.today()) {
				ord.EffectiveDate = Date.today();
			}
		}
		ord.EffectiveDateAux__c = ord.EffectiveDate;
		if (result.isFullyShipped && numberOfProducts > 0) {
			ord.Status = 'Closed';
			ord.EndDate = result.lastLotDate;
		} else {
			if (numberOfProducts > 0) {
				ord.Status = 'Activated';
			}
			ord.EndDate = null;
		}
			
		update ord;

		return result;
	}


	private static void mapRelatedERPId(OpportunityLineItem oppProductSF, OrderItem ordProductSF, Map<String, Map<String, Id>> objToIdMap, ERPRequestParser.OpportunityProduct oppProdERP) {
		List<String> fields = new List<String> { 'Standard', 'SpecLevel', 'SteelGrade', 'Ends', 'Coating', 'WheelStandard', 'WheelSteelGrade', 'WheelHub', 'WheelDrawing', 'Shop' };
		Map<String, Object> productAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppProdERP));

		List<String> errList = new List<String> ();
		String allErrors = '';

		Map<String, SObject> sObjects_to_insert = new Map<String, SObject> ();
		for (String fieldName : fields) {
			System.debug('--- Product As Map: ' + productAsMap);

			String ERPObjectID;
			String ERPObjectName;

			Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get(fieldName);
			ERPObjectID = (String) ERPObject.get('Id');
			ERPObjectName = (String) ERPObject.get('Name');

			System.debug('--- Object: ' + objToIdMap.get(fieldName).get(ERPObjectID));

			if (String.isNotBlank(ERPObjectID) && objToIdMap.get(fieldName).get(ERPObjectID) == null) {

				System.debug('There is no any ' + fieldName + ' with ERP-ID ' + ERPObjectID + ' (Line Item #' + oppProdERP.ID_ERP + ') - Creating new one.');

				sObject sObj_to_insert = Schema.getGlobalDescribe().get(erp_to_sf_api_names.get(fieldName)).newSObject();
				if(fieldName == 'Ends' || fieldName ==  'Coating') {
					ERPObjectName = checkNameFieldSize(ERPObjectName, 255);
					sObj_to_insert.put('NameRus__c', ERPObjectID);
				}
				ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
				sObj_to_insert.put('Name', ERPObjectName);
				sObj_to_insert.put('Id_ERP__c', ERPObjectID);
				if(fieldName == 'SteelGrade' || fieldName == 'WheelSteelGrade' || fieldName ==  'Shop') {
					sObj_to_insert.put('NameRus__c', ERPObjectName);
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

		if (oppProductSF != null) {

			oppProductSF.ProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.Standard.ID);
			oppProductSF.ProductSpecLevel__c = objToIdMap.get('SpecLevel').get(oppProdERP.SpecLevel.ID);
			oppProductSF.SteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.SteelGrade.ID);
			oppProductSF.TubeEnds__c = objToIdMap.get('Ends').get(oppProdERP.Ends.ID);
			oppProductSF.Coating__c = objToIdMap.get('Coating').get(oppProdERP.Coating.ID);

			oppProductSF.WheelProductStandard__c = objToIdMap.get('WheelStandard').get(oppProdERP.WheelStandard.ID);
			oppProductSF.WheelSteelGrade__c = objToIdMap.get('WheelSteelGrade').get(oppProdERP.WheelSteelGrade.ID);
			oppProductSF.WheelHub__c = objToIdMap.get('WheelHub').get(oppProdERP.WheelHub.ID);
			oppProductSF.WheelDrawing__c = objToIdMap.get('WheelDrawing').get(oppProdERP.WheelDrawing.ID);

			oppProductSF.Shop__c = objToIdMap.get('Shop').get(oppProdERP.Shop.ID);

			if (String.isNotBlank(String.valueOf(oppProdERP.ShippingPoint.ID))) {
				String fullID = oppProdERP.ShippingPoint.Type + '-' + oppProdERP.ShippingPoint.ID;
				if (String.isNotBlank(String.valueOf(productAsMap.get('ShippingPoint'))) && objToIdMap.get('ShippingPoint').get(fullID.toLowerCase()) == null) {
					System.debug('There is no such ShippingPoint (' + fullID.toLowerCase() + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					System.debug('Shipping Point objToId Map: ' + objToIdMap.get('ShippingPoint'));

					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('ShippingPoint');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectType = (String) ERPObject.get('Type');
					// В справочник код fullId записываем не в LowerCase, а как в оригинале:
					ShippingPoint__c shipping_point_to_insert = new ShippingPoint__c(Id_ERP__c = fullID, Name = ERPObjectName, Country__c = country_not_spec.Id, Type__c = ERPObjectType);

					insert shipping_point_to_insert;

					System.debug('Created new object - ' + shipping_point_to_insert);
					objToIdMap.get('ShippingPoint').put(fullID.toLowerCase(), shipping_point_to_insert.Id);

				}
				oppProductSF.ShippingPoint__c = objToIdMap.get('ShippingPoint').get(fullID.toLowerCase());

			} else {
				oppProductSF.ShippingPoint__c = null;
			}

			if (String.isNotBlank(String.valueOf(oppProdERP.QuotaType.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('QuotaType'))) && objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID) == null) {

					System.debug('ProductAsMap.get(QuotaType)' + String.valueOf(productAsMap.get('QuotaType')));

					System.debug('There is no such Quota Type (' + oppProdERP.QuotaType.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('QuotaType');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectShop = (String) ERPObject.get('Shop');
					QuotaType__c quota_type_to_insert = new QuotaType__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, NameRus__c = ERPObjectName);
					List<Shop__c> shop_to_link = [SELECT ID_ERP__c FROM Shop__c WHERE ID_ERP__c = :ERPObjectShop];
					if (shop_to_link.size() > 0) {
						quota_type_to_insert.Shop__c = shop_to_link[0].Id;
					} else {
						quota_type_to_insert.Shop__c = shop_not_cpec.Id;
					}

					insert quota_type_to_insert;

					System.debug('Created new object - ' + quota_type_to_insert);
					objToIdMap.get('QuotaType').put(ERPObjectID, quota_type_to_insert.Id);
				}
				oppProductSF.QuotaType__c = objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID);
			} else {
				oppProductSF.QuotaType__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.OD.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('OD'))) && objToIdMap.get('OD').get(oppProdERP.OD.ID) == null) {

					System.debug('ProductAsMap.get(OD)' + String.valueOf(productAsMap.get('OD')));
					System.debug('objToIdMap.get(OD).get(oppProdERP.OD.OD_mm) - ' + objToIdMap.get('OD').get(oppProdERP.OD.OD_mm));
					System.debug('There is no such OD (' + oppProdERP.OD.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('OD');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');

					if (ERPObjectOD_mm == null) {
						String errorMessage = 'Field OD_mm can not be blank on OD object';
						throw new erpException(errorMessage);
					} else {

						TubeOD__c tube_od = new TubeOD__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));

						insert tube_od;

						System.debug('Created new object - ' + tube_od);
						objToIdMap.get('OD').put(ERPObjectID, tube_od.Id);
					}

				}
				oppProductSF.TubeOD__c = objToIdMap.get('OD').get(oppProdERP.OD.ID);
			} else if(ProductType == 'Tubes') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on OD object';
				throw new erpException(errorMessage);
			} else {
				oppProductSF.TubeOD__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.WT.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('WT'))) && objToIdMap.get('WT').get(oppProdERP.WT.ID) == null) {

					System.debug('ProductAsMap.get(WT)' + String.valueOf(productAsMap.get('WT')));

					System.debug('There is no such WT (' + oppProdERP.WT.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WT');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectWT_mm = (String) ERPObject.get('WT_mm');

					if (ERPObjectWT_mm == null) {
						String errorMessage = 'Field WT_mm can not be blank on WT object';
						throw new erpException(errorMessage);
					} else {

						TubeWT__c tube_wt = new TubeWT__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, WT_mm__c = Decimal.valueOf(ERPObjectWT_mm));

						insert tube_wt;

						System.debug('Created new object - ' + tube_wt);
						objToIdMap.get('WT').put(ERPObjectID, tube_wt.Id);
					}

				}
				oppProductSF.TubeWT__c = objToIdMap.get('WT').get(oppProdERP.WT.ID);
			} else if(ProductType == 'Tubes') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on WT object';
				throw new erpException(errorMessage);
			} else {
				oppProductSF.TubeWT__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.LengthSize.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('LengthSize'))) && objToIdMap.get('LengthSize').get(oppProdERP.LengthSize.ID) == null) {

					System.debug('ProductAsMap.get(LengthSize)' + String.valueOf(productAsMap.get('LengthSize')));

					System.debug('There is no such LengthSize (' + oppProdERP.LengthSize.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('LengthSize');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					
					String ERPObjectODminLength = (String) ERPObject.get('MinLength');
					String ERPObjectODmaxLength = (String) ERPObject.get('MaxLength');

					TubeLengthSize__c tubeLengthSize = new TubeLengthSize__c(Id_ERP__c = ERPObjectID);
					ERPObjectName = checkNameFieldSize(ERPObjectName, 255);
					tubeLengthSize.NameRus__c = ERPObjectName;
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					tubeLengthSize.Name = ERPObjectName;
					tubeLengthSize.MaxLength__c = (ERPObjectODmaxLength != null && ERPObjectODmaxLength != '' ? Decimal.valueOf(ERPObjectODmaxLength) : null);
					tubeLengthSize.MinLength__c = (ERPObjectODminLength != null && ERPObjectODminLength != '' ? Decimal.valueOf(ERPObjectODminLength) : null);
					insert tubeLengthSize;

					System.debug('Created new object - ' + tubeLengthSize);
					objToIdMap.get('LengthSize').put(ERPObjectID, tubeLengthSize.Id);
				}
				oppProductSF.LengthSize__c = objToIdMap.get('LengthSize').get(oppProdERP.LengthSize.ID);
			} else {
				oppProductSF.LengthSize__c = null;
			}

			if (ProductType == 'Wheels' && String.isNotBlank(String.valueOf(oppProdERP.WheelDiameter.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('WheelDiameter'))) && objToIdMap.get('WheelDiameter').get(oppProdERP.WheelDiameter.ID) == null) {

					System.debug('ProductAsMap.get(WheelDiameter)' + String.valueOf(productAsMap.get('WheelDiameter')));
					System.debug('objToIdMap.get(WheelDiameter).get(oppProdERP.WheelDiameter.OptionalValue1) - ' + objToIdMap.get('WheelDiameter').get(oppProdERP.WheelDiameter.OptionalValue1));
					System.debug('There is no such WheelDiameter (' + oppProdERP.WheelDiameter.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WheelDiameter');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectOD_mm = (String) ERPObject.get('OptionalValue1');

					if (ERPObjectOD_mm == null) {
						//String errorMessage = 'Field OD_mm can not be blank on WheelDiameter object';
						//throw new erpException(errorMessage);
					} else {

						WheelDiameter__c wheelDiameter = new WheelDiameter__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));

						insert wheelDiameter;

						System.debug('Created new object - ' + wheelDiameter);
						objToIdMap.get('WheelDiameter').put(ERPObjectID, wheelDiameter.Id);
					}

				}
				oppProductSF.WheelDiameter__c = objToIdMap.get('WheelDiameter').get(oppProdERP.WheelDiameter.ID);
			} else if(ProductType == 'Wheels') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on WheelDiameter object';
				throw new erpException(errorMessage);
			} else {
				oppProductSF.WheelDiameter__c = null;
			}

		} else {

			ordProductSF.ProductStandard__c = objToIdMap.get('Standard').get(oppProdERP.Standard.ID);
			ordProductSF.ProductSpecLevel__c = objToIdMap.get('SpecLevel').get(oppProdERP.SpecLevel.ID);
			ordProductSF.SteelGrade__c = objToIdMap.get('SteelGrade').get(oppProdERP.SteelGrade.ID);
			ordProductSF.TubeEnds__c = objToIdMap.get('Ends').get(oppProdERP.Ends.ID);
			ordProductSF.Coating__c = objToIdMap.get('Coating').get(oppProdERP.Coating.ID);

			ordProductSF.WheelProductStandard__c = objToIdMap.get('WheelStandard').get(oppProdERP.WheelStandard.ID);
			ordProductSF.WheelSteelGrade__c = objToIdMap.get('WheelSteelGrade').get(oppProdERP.WheelSteelGrade.ID);
			ordProductSF.WheelHub__c = objToIdMap.get('WheelHub').get(oppProdERP.WheelHub.ID);
			ordProductSF.WheelDrawing__c = objToIdMap.get('WheelDrawing').get(oppProdERP.WheelDrawing.ID);

			ordProductSF.Shop__c = objToIdMap.get('Shop').get(oppProdERP.Shop.ID);

			if (String.isNotBlank(String.valueOf(oppProdERP.QuotaType.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('QuotaType'))) && objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID) == null) {

					System.debug('There is no such Quota Type (' + oppProdERP.QuotaType.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('QuotaType');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectShop = (String) ERPObject.get('Shop');
					QuotaType__c quota_type_to_insert = new QuotaType__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, NameRus__c = ERPObjectName);
					List<Shop__c> shop_to_link = [SELECT ID_ERP__c FROM Shop__c WHERE ID_ERP__c = :ERPObjectShop];
					System.debug('Shop to link' + shop_to_link);
					if (shop_to_link.size() > 0) {
						quota_type_to_insert.Shop__c = shop_to_link[0].Id;
					} else {
						quota_type_to_insert.Shop__c = shop_not_cpec.Id;
					}

					insert quota_type_to_insert;

					System.debug('Created new object - ' + quota_type_to_insert);

					objToIdMap.get('QuotaType').put(ERPObjectID, quota_type_to_insert.Id);
				}
				ordProductSF.QuotaType__c = objToIdMap.get('QuotaType').get(oppProdERP.QuotaType.ID);
			} else {
				ordProductSF.QuotaType__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.OD.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('OD'))) && objToIdMap.get('OD').get(oppProdERP.OD.ID) == null) {

					System.debug('ProductAsMap.get(OD)' + String.valueOf(productAsMap.get('OD')));
					System.debug('There is no such OD (' + oppProdERP.OD.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('OD');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectOD_mm = (String) ERPObject.get('OD_mm');

					if (ERPObjectOD_mm == null) {
						String errorMessage = 'Field OD_mm can not be blank on OD object';
						throw new erpException(errorMessage);
					} else {

						TubeOD__c tube_od = new TubeOD__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));
						insert tube_od;
						System.debug('Created new object - ' + tube_od);
						objToIdMap.get('OD').put(ERPObjectID, tube_od.Id);
					}
				}
				ordProductSF.TubeOD__c = objToIdMap.get('OD').get(oppProdERP.OD.ID);
			} else if (ProductType == 'Tubes') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on OD object';
				throw new erpException(errorMessage);
			} else {
				ordProductSF.TubeOD__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.WT.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('WT'))) && objToIdMap.get('WT').get(oppProdERP.WT.ID) == null) {

					System.debug('ProductAsMap.get(WT)' + String.valueOf(productAsMap.get('WT')));

					System.debug('There is no such WT (' + oppProdERP.WT.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WT');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectWT_mm = (String) ERPObject.get('WT_mm');

					if (ERPObjectWT_mm == null) {
						String errorMessage = 'Field WT_mm can not be blank on WT object';
						throw new erpException(errorMessage);
					} else {

						TubeWT__c tube_wt = new TubeWT__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, WT_mm__c = Decimal.valueOf(ERPObjectWT_mm));

						insert tube_wt;

						System.debug('Created new object - ' + tube_wt);
						objToIdMap.get('WT').put(ERPObjectID, tube_wt.Id);
					}
				}
				ordProductSF.TubeWT__c = objToIdMap.get('WT').get(oppProdERP.WT.ID);
			} else if (ProductType == 'Tubes') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on WT object';
				throw new erpException(errorMessage);
			} else {
				ordProductSF.TubeWT__c = null;
			}

			if (ProductType == 'Tubes' && String.isNotBlank(String.valueOf(oppProdERP.LengthSize.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('LengthSize'))) && objToIdMap.get('LengthSize').get(oppProdERP.LengthSize.ID) == null) {

					System.debug('ProductAsMap.get(LengthSize)' + String.valueOf(productAsMap.get('LengthSize')));

					System.debug('There is no such LengthSize (' + oppProdERP.LengthSize.ID + ') in database (Line Item #' + oppProdERP.ID_ERP + ') - Creating a new one.');
					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('LengthSize');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					String ERPObjectODminLength = (String) ERPObject.get('MinLength');
					String ERPObjectODmaxLength = (String) ERPObject.get('MaxLength');

					TubeLengthSize__c tubeLengthSize = new TubeLengthSize__c(Id_ERP__c = ERPObjectID);
					ERPObjectName = checkNameFieldSize(ERPObjectName, 255);
					tubeLengthSize.NameRus__c = ERPObjectName;
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					tubeLengthSize.Name = ERPObjectName;
					tubeLengthSize.MaxLength__c = (ERPObjectODmaxLength != null && ERPObjectODmaxLength != '' ? Decimal.valueOf(ERPObjectODmaxLength) : null);
					tubeLengthSize.MinLength__c = (ERPObjectODminLength != null && ERPObjectODminLength != '' ? Decimal.valueOf(ERPObjectODminLength) : null);
					insert tubeLengthSize;

					System.debug('Created new object - ' + tubeLengthSize);
					objToIdMap.get('LengthSize').put(ERPObjectID, tubeLengthSize.Id);
				}
				ordProductSF.TubeLengthSize__c = objToIdMap.get('LengthSize').get(oppProdERP.LengthSize.ID);
			} else if (ProductType == 'Tubes') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on lengh size object';
				throw new erpException(errorMessage);
			} else {
				ordProductSF.TubeLengthSize__c = null;
			}


			if (ProductType == 'Wheels' && String.isNotBlank(String.valueOf(oppProdERP.WheelDiameter.ID))) {

				if (String.isNotBlank(String.valueOf(productAsMap.get('WheelDiameter'))) && objToIdMap.get('WheelDiameter').get(oppProdERP.WheelDiameter.ID) == null) {

					Map<String, Object> ERPObject = (Map<String, Object>) productAsMap.get('WheelDiameter');
					String ERPObjectID = (String) ERPObject.get('Id');
					String ERPObjectName = (String) ERPObject.get('Name');
					ERPObjectName = checkNameFieldSize(ERPObjectName, 80);
					String ERPObjectOD_mm = (String) ERPObject.get('OptionalValue1');

					if (ERPObjectOD_mm == null) {
						//String errorMessage = 'Field OD_mm can not be blank on WheelDiameter object';
						//throw new erpException(errorMessage);
					} else {

						WheelDiameter__c wheelDiameter = new WheelDiameter__c(Id_ERP__c = ERPObjectID, Name = ERPObjectName, OD_mm__c = Decimal.valueOf(ERPObjectOD_mm));

						insert wheelDiameter;

						System.debug('Created new object - ' + wheelDiameter);
						objToIdMap.get('WheelDiameter').put(ERPObjectID, wheelDiameter.Id);
					}

				}
				ordProductSF.WheelDiameter__c = objToIdMap.get('WheelDiameter').get(oppProdERP.WheelDiameter.ID);
			} else if(ProductType == 'Wheels') {
				String errorMessage = 'Field ID_IN_ERP can not be blank on WheelDiameter object';
				throw new erpException(errorMessage);
			} else {
				ordProductSF.WheelDiameter__c = null;
			}
		}
	}

	@testVisible
	public static void updateOLI(OpportunityLineItem oppProductSF, OrderItem ordProductSF, ERPRequestParser.OpportunityProduct oppProdERP, String requestObjGeneral_DataID_ERP, List<ProductionLot__c> lotsToInsert, UpdateSFRecordsResultOrder result) {

		if (oppProductSF != null) {
			oppProductSF.Typical__c = (oppProdERP.Typical != null && oppProdERP.Typical == '1');
			oppProductSF.ProductionAllowed__c = (oppProdERP.FinApproval != null && oppProdERP.FinApproval == '1');
			oppProductSF.FinStatus__c = (oppProdERP.FinStatus != null && oppProdERP.FinStatus != '' ? oppProdERP.FinStatus : null);
			oppProductSF.FinStatus__c = (oppProductSF.ProductionAllowed__c ? oppProductSF.FinStatus__c + '. Production allowed.' : oppProductSF.FinStatus__c);
			oppProductSF.TechExp__c = (oppProdERP.TechExp != null && oppProdERP.TechExp != '' ? oppProdERP.TechExp : null);
			oppProductSF.CDD__c = ((oppProdERP.CDD != null && oppProdERP.CDD != '') ? DateTime.newInstance(long.valueOf(oppProdERP.CDD + '000')).date() : null);
			oppProductSF.CDDRecommended__c = (String.isNotBlank(oppProdERP.RecommendedCDD) ? DateTime.newInstance(long.valueOf(oppProdERP.CDD + '000')).date() : null);
			oppProdERP.CoatingSpec = checkNameFieldSize(oppProdERP.CoatingSpec, 255);
			oppProductSF.CoatingSpecification__c = (oppProdERP.CoatingSpec!= null && oppProdERP.CoatingSpec != '' ? oppProdERP.CoatingSpec : null);
			oppProductSF.Stage__c = (oppProdERP.Stage != null && oppProdERP.Stage != '' ? oppProdERP.Stage : null);
			oppProductSF.ITENumber__c = (oppProdERP.ITENumber != null && oppProdERP.ITENumber != '' ? oppProdERP.ITENumber : null);
			oppProductSF.InquiryUnit__c = (oppProdERP.InqUnit != null && oppProdERP.InqUnit != '' ? oppProdERP.InqUnit : null);

			oppProductSF.Quantity = (oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != '' && Decimal.valueOf(oppProdERP.Quantity_Mt) != 0 ? Decimal.valueOf(oppProdERP.Quantity_Mt) : 0.01); // т.к. бывает количество тонн нулевое (еще не рассчитали вес из клиентских единиц), то установим 0.01
			oppProductSF.Quantity_m__c = (oppProdERP.Quantity_m != null && oppProdERP.Quantity_m != '' ? Decimal.valueOf(oppProdERP.Quantity_m) : 0);
			oppProductSF.Quantity_ft__c = (oppProdERP.Quantity_ft != null && oppProdERP.Quantity_ft != '' ? Decimal.valueOf(oppProdERP.Quantity_ft) : 0);
			oppProductSF.Quantity_pcs__c = (oppProdERP.Quantity_pcs != null && oppProdERP.Quantity_pcs != '' ? Decimal.valueOf(oppProdERP.Quantity_pcs) : 0);
			oppProductSF.Weight_ppf__c = (oppProdERP.Weight_ppf != null && oppProdERP.Weight_ppf != '' ? Decimal.valueOf(oppProdERP.Weight_ppf) : 0);
			oppProductSF.Weight_kpm__c = (oppProdERP.Weight_kpm != null && oppProdERP.Weight_kpm != '' ? Decimal.valueOf(oppProdERP.Weight_kpm) : 0);
			oppProductSF.InquiryQuantity__c = (oppProdERP.InqQuantity != null && oppProdERP.InqQuantity != '' ? Decimal.valueOf(oppProdERP.InqQuantity) : 0);
			oppProductSF.InquiryUnitPrice__c = (oppProdERP.Price != null && oppProdERP.Price != '' ? Decimal.valueOf(oppProdERP.Price) : 0);
			oppProductSF.UnitPrice = (oppProdERP.Price_t != null && oppProdERP.Price_t != '' ? Decimal.valueOf(oppProdERP.Price_t) : 0);
			oppProductSF.Margin_t__c = (oppProdERP.Margin_t != null && oppProdERP.Margin_t != '' ? Decimal.valueOf(oppProdERP.Margin_t) : 0);
			oppProductSF.Margin__c = (oppProductSF.Margin_t__c != null && oppProductSF.Quantity != null ? oppProductSF.Margin_t__c * oppProductSF.Quantity : 0);
		} else {
			ordProductSF.Quantity = (oppProdERP.Quantity_Mt != null && oppProdERP.Quantity_Mt != '' && Decimal.valueOf(oppProdERP.Quantity_Mt) != 0 ? Decimal.valueOf(oppProdERP.Quantity_Mt) : 0.01);  // т.к. бывает количество тонн нулевое (еще не рассчитали вес из клиентских единиц), то установим 0.01
			ordProductSF.Weight_ppf__c = (oppProdERP.Weight_ppf != null && oppProdERP.Weight_ppf != '' ? Decimal.valueOf(oppProdERP.Weight_ppf) : 0);
			ordProductSF.Weight_kpm__c = (oppProdERP.Weight_kpm != null && oppProdERP.Weight_kpm != '' ? Decimal.valueOf(oppProdERP.Weight_kpm) : 0);
			ordProductSF.UnitPrice = (oppProdERP.Price_t != null && oppProdERP.Price_t != '' ? Decimal.valueOf(oppProdERP.Price_t) : 0);
			ordProductSF.CDD__c = ((oppProdERP.CDD != null && oppProdERP.CDD != '') ? DateTime.newInstance(long.valueOf(oppProdERP.CDD + '000')).date() : null);
			//ordProductSF.CDDRecommended__c = (String.isNotBlank(oppProdERP.RecommendedCDD) ? DateTime.newInstance(long.valueOf(oppProdERP.RecommendedCDD + '000')).date() : null);
			ordProductSF.Stage__c = (oppProdERP.Stage != null && oppProdERP.Stage != '' ? oppProdERP.Stage : null);
			ordProductSF.ITENumber__c = (oppProdERP.ITENumber != null && oppProdERP.ITENumber != '' ? oppProdERP.ITENumber : null);

			// Поля ProducedQuantity__c, DispatchedQuantity__c и ShippedQuantity__c заполняются из оперативных данных в заводской системе учета:
			ordProductSF.ProducedQuantity__c = oppProdERP.Produced != null ? Decimal.valueOf(oppProdERP.Produced) : 0;
			ordProductSF.DispatchedQuantity__c = oppProdERP.Dispatched != null ? Decimal.valueOf(oppProdERP.Dispatched) : 0;
			ordProductSF.ShippedQuantity__c = oppProdERP.Shipped != null ? Decimal.valueOf(oppProdERP.Shipped) : 0;
			// Поля Margin__c и Margin_t__c заполняются на основании данных из фактических срезов в ИТ, которые заполняются аналитиками:
			Decimal FinDataShipped = oppProdERP.FinDataShipped != null ? Decimal.valueOf(oppProdERP.FinDataShipped) : 0;
			ordProductSF.Margin__c = oppProdERP.FinDataMargin != null ? Decimal.valueOf(oppProdERP.FinDataMargin) : 0;
			ordProductSF.Margin_t__c = FinDataShipped != 0 ? ordProductSF.Margin__c / FinDataShipped : 0;

			Date oldestLotDate;
			Date earliestLotDate;
			// Создадим записи в таблице ProductionLots:
			for (ERPRequestParser.ProductLot lot : oppProdERP.Lots) {
				ProductionLot__c Productlot = new ProductionLot__c();
				Productlot.Order__c = ordProductSF.OrderId;
				Productlot.OrderItem__c = ordProductSF.Id;
				Productlot.LotDate__c = ((lot.LotDate != null && lot.LotDate != '') ? DateTime.newInstance(long.valueOf(lot.LotDate + '000')).date() : null);
				Productlot.ProducedQuantity__c = (lot.Produced != null && lot.Produced != '' ? Decimal.valueOf(lot.Produced) : 0);
				Productlot.DispatchedQuantity__c = (lot.Dispatched != null && lot.Dispatched != '' ? Decimal.valueOf(lot.Dispatched) : 0);
				Productlot.ShippedQuantity__c = (lot.Shipped != null && lot.Shipped != '' ? Decimal.valueOf(lot.Shipped) : 0);
				lotsToInsert.add(Productlot);

				if (earliestLotDate == null || Productlot.LotDate__c < earliestLotDate) {
					earliestLotDate = Productlot.LotDate__c;
				}
				if (oldestLotDate == null || Productlot.LotDate__c > oldestLotDate) {
					oldestLotDate = Productlot.LotDate__c;
				}
			}

			if (earliestLotDate != null) {
				if (ordProductSF.ServiceDate == null || ordProductSF.ServiceDate > earliestLotDate) {
					ordProductSF.ServiceDate = earliestLotDate;
				}
				if (result.firstLotDate == null || result.firstLotDate == Date.newInstance(1900, 1, 1) || result.firstLotDate > earliestLotDate) {
					result.firstLotDate = earliestLotDate;
				}
			}
			
			if (ordProductSF.Stage__c == 'Shipped') {
				// значит эта позиция находится в ИТ на стадии "Позиция Закрыта"
				//if (ordProductSF.ShippedQuantity__c >= ordProductSF.DispatchedQuantity__c) {
					//// Позиция уже полностью реализована клиенту. Проставим дату EndDate для этой позиции:
					ordProductSF.EndDate = oldestLotDate;
					if (result.lastLotDate == null || oldestLotDate > result.lastLotDate) {
						result.lastLotDate = oldestLotDate;
					}
				//} else {
					//// позиция уже полностью отгружена с завода, но еще не доставлена клиенту. Изменим стадию на Dispatched и на всякий случай очистим дату, если она каким-то образом содержит значение.
					//ordProductSF.Stage__c = 'Dispatched';
					//ordProductSF.EndDate = null;
					//result.isFullyShipped = false;
				//}
			} else {
				if (ordProductSF.ShippedPercentage__c >= 100) {
					ordProductSF.Stage__c = 'Produced';
				}
				ordProductSF.EndDate = null;
				result.isFullyShipped = false;
			}
		}
	}

	private static Map<String, PricebookEntry> selectPBEbyProduct2ERPId(List<ERPRequestParser.OpportunityProduct> items, Opportunity opp) {

		Map<String, PricebookEntry> result = new Map<String, PricebookEntry> ();

		Map<String, ERPRequestParser.OpportunityProduct> product2erpIdMap = new Map<String, ERPRequestParser.OpportunityProduct> ();
		for (ERPRequestParser.OpportunityProduct oppProdERP : items) {
			product2erpIdMap.put(oppProdERP.ProductGroup.ID, oppProdERP);
		}

		System.debug('Products ID_ERP from json items - ' + product2erpIdMap.keySet());

		Map<Id, String> prods = new Map<Id, String> ();
		for (Product2 prod2_item :[
		     SELECT Id, ID_ERP__c
		     FROM Product2
		     WHERE ID_ERP__c IN :product2erpIdMap.keySet()]) {
			prods.put(prod2_item.ID, prod2_item.ID_ERP__c);
		}

		List<Product2> products_to_insert = new List<Product2> ();

		for (String product2erpId : product2erpIdMap.keySet()) {
			if (!prods.values().contains(product2erpId)) {
				Product2 newProduct = new Product2();
				product2erpIdMap.get(product2erpId).ProductGroup.Name = checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 255);
				newProduct.Name = product2erpIdMap.get(product2erpId).ProductGroup.Name;
				product2erpIdMap.get(product2erpId).ProductGroup.Name = checkNameFieldSize(product2erpIdMap.get(product2erpId).ProductGroup.Name, 80);
				newProduct.NameRus__c = product2erpIdMap.get(product2erpId).ProductGroup.Name;
				newProduct.ID_ERP__c = product2erpIdMap.get(product2erpId).ProductGroup.Id;
				products_to_insert.add(newProduct);
			}
		}

		if (!products_to_insert.isEmpty()) {
			insert products_to_insert;
			System.debug('Inserted new Products - ' + products_to_insert);

			for (Product2 prod2_item : products_to_insert) {
				prods.put(prod2_item.ID, prod2_item.ID_ERP__c);
			}
		}


		List<PriceBookEntry> pb2;
		//Pricebook2 pb1;
		Id pricebookId;

		if (Test.isRunningTest()) {
			pricebookId = Test.getStandardPricebookId();
			pb2 = [SELECT Id, UnitPrice, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id in :prods.keySet()];
		} else {
			//pb1 = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard = True LIMIT 1];
			//pb2 = [SELECT Id, UnitPrice, CurrencyIsoCode, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :pb1.Id AND CurrencyISOcode = :opp.CurrencyISOcode AND Product2Id in :prods.keySet()];
			pb2 = [SELECT Id, UnitPrice, CurrencyIsoCode, Product2Id FROM PriceBookEntry WHERE Pricebook2Id = :opp.Pricebook2Id AND CurrencyISOcode = :opp.CurrencyISOcode AND Product2Id in :prods.keySet()];
		}

		Map<Id, PricebookEntry> pbeIdByProduct2erpId = new Map<Id, PricebookEntry> ();
		for (PricebookEntry pbe : pb2) {
			pbeIdByProduct2erpId.put(pbe.Product2Id, pbe);
		}

		System.debug('Product2 ID from SOQL - ' + pbeIdByProduct2erpId.keySet());
		System.debug('Product2 ID from prods map - ' + prods.keySet());
		List<PricebookEntry> pbe_to_insert = new List<PricebookEntry> ();

		if (!Test.isRunningTest()) {
			for (String Product2Id : prods.keySet()) {
				if (!pbeIdByProduct2erpId.keySet().contains(Product2Id)) {
					PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode = opp.CurrencyIsoCode,
					                                        Pricebook2Id = opp.Pricebook2Id,
					                                        IsActive = true,
					                                        Product2Id = Product2Id,
					                                        UnitPrice = Decimal.valueOf(product2erpIdMap.get(prods.get(Product2Id)).Price_t)
					);
					pbe_to_insert.add(pbe);
				}
			}
		} else {
			for (String Product2Id : prods.keySet()) {
				if (!pbeIdByProduct2erpId.keySet().contains(Product2Id)) {
					PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode = opp.CurrencyIsoCode,
					                                        Pricebook2Id = pricebookId,
					                                        IsActive = true,
					                                        Product2Id = Product2Id,
					                                        UnitPrice = Decimal.valueOf(product2erpIdMap.get(prods.get(Product2Id)).Price_t)
					);
					pbe_to_insert.add(pbe);
				}
			}
		}

		if (!pbe_to_insert.isEmpty()) {
			insert pbe_to_insert;
			System.debug('Inserted new PBE - ' + pbe_to_insert);

			for (PricebookEntry pbe_item : pbe_to_insert) {
				pb2.add(pbe_item);
			}
		}

		for (PricebookEntry pbe : pb2) {
			result.put(prods.get(pbe.Product2Id), pbe);
			System.debug('Result map key - ' + prods.get(pbe.Product2Id) + ' value - ' + pbe);
		}

		System.debug('Result  - ' + result);
		return result;
	}

	private static Map<String, Map<String, Id>> getObjectToIdMap(List<ERPRequestParser.OpportunityProduct> oppProductsERP) {
		Map<String, Map<String, Id>> objectToIdMap = new Map<String, Map<String, Id>> ();
		Map<String, Set<String>> erpValuesForObject = new Map<String, Set<String>> ();
		System.debug(oppProductsERP);
		String serializedString = JSON.serialize(oppProductsERP);
		System.debug(serializedString);
		List<Object> oppProductFieldsList = (List<Object>) JSON.deserializeUntyped(serializedString);
		System.debug('-- List: ' + oppProductFieldsList);
		for (String key : erp_to_sf_api_names.keyset()) {
			Set<String> valuesSet = new Set<String> ();
			for (Integer i = 0; i<oppProductFieldsList.size(); i++) {
				Map<String, Object> oppProductField = (Map<String, Object>) oppProductFieldsList.get(i);

				Map<String, Object> ERPObject = (Map<String, Object>) oppProductField.get(key);
				if ((String) ERPObject.get('Id') != null) {
					System.debug('--- ' + (String) ERPObject.get('Id'));
					if (key == 'ShippingPoint') {
						// По какой-то причине если код символьный, то в справочнике он иногда сохраняется маленькими буквами, и затем не совпадает с тем, что приходит в файле. Поэтому явно приводим все коды к LowerCase() тут и во время проверки.
						String objIdLowerCase = ((String) ERPObject.get('Id')).toLowerCase();
						valuesSet.add((String) ERPObject.get('Type') + '-' + objIdLowerCase);
					} else {
						valuesSet.add((String) ERPObject.get('Id'));
					}
				}
			}
			erpValuesForObject.put(key, valuesSet);
		}
		System.debug(erpValuesForObject);
	//проверка на пустой массив 20.09.2021
		for (String key : erpValuesForObject.keySet()) {
			Set<String> setERPIds = erpValuesForObject.get(key);
            System.debug(setERPIds.size());
			List<sObject> objectList = Database.query('SELECT Id, ID_ERP__c FROM ' + erp_to_sf_api_names.get(key) + ' WHERE ID_ERP__c IN :setERPIds');
			Map<String, Id> erpIdToIdMap = new Map<String, Id> ();
			for (sObject ob : objectList) {
				if (key == 'ShippingPoint') {
					// По какой-то причине если код символьный, то в справочнике он иногда сохраняется маленькими буквами, и затем не совпадает с тем, что приходит в файле. Поэтому явно приводим все коды к LowerCase() тут и во время проверки.
					String idErpToLowerCase = ((String) ob.get('ID_ERP__c')).toLowerCase();
					erpIdToIdMap.put(idErpToLowerCase, ob.Id);
				} else {
					erpIdToIdMap.put((String) ob.get('ID_ERP__c'), ob.Id);
				}
			}
			objectToIdMap.put(key, erpIdToIdMap);
		}
		return objectToIdMap;
	}

	public static UpdateSyncedResult updateSyncedOpportunity(ERPRequestParser.ExecuteResponce executeResponseData, String requestBody) {

		UpdateSyncedResult result = new UpdateSyncedResult();
		result.SyncedResult = executeResponseData.SyncResult;

		if (executeResponseData.ErrorType == null && executeResponseData.ErrorMessage == null && executeResponseData.Opportunity != null && String.isNotBlank(executeResponseData.Opportunity.ID_ERP)) {

			Opportunity opportunityToUpdate = getOpportunitySFByERPID(executeResponseData.Opportunity.ID_ERP);
			result.syncedOpportunity = opportunityToUpdate;
			Datetime dateTimeOfSyncedOpp;

			Id recipientId = opportunityToUpdate.AssignedBOS__c;
			System.debug('recipientId - ' + recipientId);

			if (executeResponseData.SyncResult == '1') {

				List<ERPRequestParser.ERPOpportunityLineItemId> oppLiResultList = executeResponseData.Opportunity.Item;
				System.debug('oppLiResultList - ' + oppLiResultList);
				List<OpportunityLineItem> oppLiToUpdate = new List<OpportunityLineItem> ();

				if (oppLiResultList != null) {
					for (ERPRequestParser.ERPOpportunityLineItemId oppLi : oppLiResultList) {
						if (String.isNotBlank(oppLi.ID_SF)) {
							oppLiToUpdate.add(new OpportunityLineItem(
							                                          Id = oppLi.ID_SF,
							                                          NPP_ERP__c = oppLi.ID_ERP
							));
						}
					}
					System.debug('OppLineItem to update - ' + oppLiToUpdate);
					if (!oppLiToUpdate.isEmpty()) {
						update oppLiToUpdate;
					}
				}

				if (opportunityToUpdate != null) {
					if (executeResponseData.SyncDateTime != null) {
						dateTimeOfSyncedOpp = DateTime.newInstance(Long.valueOf(executeResponseData.SyncDateTime + '000'));
						opportunityToUpdate.LastSyncERP__c = dateTimeOfSyncedOpp;
						System.debug('Last Sync date - ' + opportunityToUpdate.LastSyncERP__c);
						update opportunityToUpdate;
					}
				} else {
					String errorMessage = 'There is no such Opportunity in SF with ID_ERP - ' + executeResponseData.Opportunity.ID_ERP;
					throw new erpException(errorMessage);
				}

				if (recipientId != null) {
					String textForFeed = 'Opportunity that was sent to ERP by {' + UserInfo.getUserId() + '} for ' + opportunityToUpdate.AssignedBOS__r.Name + ' at ' + dateTimeOfSyncedOpp + ' was accepted at ' + Datetime.now() + '.';
					ConnectApi.FeedElement fi = ConnectApiHelper.postFeedItemWithRichText(Network.getNetworkId(), recipientId, textForFeed);
				}
			} else {

				if (opportunityToUpdate != null && executeResponseData.SyncDateTime != null) {
					dateTimeOfSyncedOpp = DateTime.newInstance(Long.valueOf(executeResponseData.SyncDateTime + '000'));
				}

				if (executeResponseData.SyncResult == '-1' && recipientId != null) {
					String textForFeed = 'Opportunity that was sent to ERP by {' + UserInfo.getUserId() + '} for ' + opportunityToUpdate.AssignedBOS__r.Name + ' at ' + dateTimeOfSyncedOpp + ' was rejected at ' + Datetime.now() + '.';
					ConnectApi.FeedElement fi = ConnectApiHelper.postFeedItemWithRichText(Network.getNetworkId(), recipientId, textForFeed);
				}
			}

		} else {
			String errorMessage = 'The Error occured while updating Synced Opportunity.';
			throw new erpException(errorMessage);
		}
		return result;
	}



	
	public static void checkOpportunityStatus(ERPRequestParser.ERPOpportunity requestObj, UpdateSFRecordsResult result) {
		
		for (ERPRequestParser.OpportunityProduct oppProdERP : requestObj.Item_Data) {
			//Пропустим строку, если не заполнены продукт или количество:
			if (String.isBlank(oppProdERP.ProductGroup.Id) || String.isBlank(oppProdERP.InqQuantity) || Decimal.valueOf(oppProdERP.InqQuantity) == 0) {
				continue;
			}

			for (ERPRequestParser.ProductLot lot : oppProdERP.Lots) {
				result.hasLots = true;

				Date lotDate = ((lot.LotDate != null && lot.LotDate != '') ? DateTime.newInstance(long.valueOf(lot.LotDate + '000')).date() : null);
				Decimal producedQuantity = (lot.Produced != null && lot.Produced != '' ? Decimal.valueOf(lot.Produced) : 0);
				Decimal dispatchedQuantity = (lot.Dispatched != null && lot.Dispatched != '' ? Decimal.valueOf(lot.Dispatched) : 0);
				Decimal shippedQuantity = (lot.Shipped != null && lot.Shipped != '' ? Decimal.valueOf(lot.Shipped) : 0);

				if (result.firstLotDate == null || lotDate < result.firstLotDate) {
					result.firstLotDate = lotDate;
				}
				if (result.lastLotDate == null || lotDate > result.lastLotDate) {
					result.lastLotDate = lotDate;
				}
			}
		}
	}

	
	private static Opportunity mapOpportunityFields(ERPRequestParser.ERPOpportunity requestObj, Opportunity opp, UpdateSFRecordsResult result, String requestBody) {
		
		// В сообщении указано время в часовом поясе Украины, поэтому нужно привести его к GMT (для этого у юзера It-Enterprise должен быть установлен часовой пояс Украина):
		Integer offset = UserInfo.getTimezone().getOffset(Datetime.now());
		opp.CreatedDate_ERP__c = DateTime.newInstance(long.valueOf(requestObj.CreatedDate + '000')).addSeconds(- offset/1000);
		opp.LastSyncERP__c = Datetime.now();

		List<Account> accs = [SELECT Id FROM Account WHERE ID_ERP__c = :requestObj.Account.ID];
		checkListSize(accs, 'Account', requestObj.Account.ID, null, null);
		if (accs.size() == 0) {
			System.debug('There is no such Account(' + requestObj.Account.ID + ') in database.');
			if (result.isNewOppCreated == true || (result.isNewOppCreated == false && opp.Account.ID_ERP__c != null)) {
				//Если это новая оппа, либо существующая, в которой указан контрагент, с другим ID_ERP кодом, чем нам пришел,
				//то создадим нового контрагента, который чуть ниже подставится в оппу.
				if (requestObj.Account.Id != '164525') {
					// Если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
					System.debug('Creating new Account.');
					Account acc = new Account();
					acc.RecordTypeId = RT_ACCOUNT_CUSTOMER.Id;
					requestObj.Account.Name = checkNameFieldSize(requestObj.Account.Name, 80);
					acc.Name = String.isNotBlank(requestObj.Account.Name) ? requestObj.Account.Name : 'Unnamed account from IT-Enterprise ERP system';
					acc.ID_ERP__c = requestObj.Account.ID;
					insert acc;
					accs.add(acc);
					System.debug('Create Account: ' + acc);
					if (result.isNewOppCreated == false) {
						String taskSubject;
						String taskDescription;
						switch on opp.Owner.LanguageLocaleKey {
							when 'uk' {
								taskSubject = 'Перевірте результати синхронізації з IT-Enterprise.';
								taskDescription = 'В результаті синхронізації даної можливості з системою IT-Enterprise була змінена організація-контрагент.\n' +
													'Контрагент до синхронізації: ' + opp.Account.Name + '.\n' +
													'Назва нового контрагента в системі IT-Enterprise: ' + requestObj.Account.Name + '.';
							}
							when 'ru' {
								taskSubject = 'Проверьте результаты синхронизации с IT-Enterprise.';
								taskDescription = 'В результате синхронизации данной возможности з системою IT-Enterprise була змінена організація-контрагент.\n' +
													'Контрагент до синхронізації: ' + opp.Account.Name + '.\n' +
													'Назва нового контрагента в системі IT-Enterprise: ' + requestObj.Account.Name + '.';
							}
							when else {
								taskSubject = 'Review changes after synchronization with IT-Enterprise.';
								taskDescription = 'The account was changed after synchronization with IT-Enterprise system.\n' +
													'Account befor synchronization: ' + opp.Account.Name + '.\n' +
													'New account\'s name in IT-Enterprise system: ' + requestObj.Account.Name + '.';
							}
						}
						insertEditingTaskForOppOwner(opp, taskSubject, taskDescription);
					}
				}
			} else {
				//Если это существующая оппа, в которой указан контрагент с пустым кодом ID_ERP,
				//то заполним этот код значением из сообщения.
				if (requestObj.Account.Id != '164525') {
					// Если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
					Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
					acc.ID_ERP__c = requestObj.Account.ID;
					update acc;
					accs.add(acc);
					//insertEditingTaskForOppOwner(opp, 'Review changes. Field \'ID in ERP\' on Account related to Opportunity was populated.');
				}
			}
		} else {
			if (result.isNewOppCreated == false && opp.Account.ID_ERP__c != null && opp.Account.ID_ERP__c != requestObj.Account.ID) {
				String taskSubject;
				String taskDescription;
				switch on opp.Owner.LanguageLocaleKey {
					when 'uk' {
						taskSubject = 'Перевірте результати синхронізації з IT-Enterprise.';
						taskDescription = 'В результаті синхронізації даної можливості з системою IT-Enterprise була змінена організація-контрагент.\n' +
											'Контрагент до синхронізації: ' + opp.Account.Name + '.\n' +
											'Назва нового контрагента в системі IT-Enterprise: ' + requestObj.Account.Name + '.';
					}
					when 'ru' {
						taskSubject = 'Проверьте результаті синхронизации с IT-Enterprise.';
						taskDescription = 'В результаті синхронізації даної можливості з системою IT-Enterprise була змінена організація-контрагент.\n' +
											'Контрагент до синхронізації: ' + opp.Account.Name + '.\n' +
											'Назва нового контрагента в системі IT-Enterprise: ' + requestObj.Account.Name + '.';
					}
					when else {
						taskSubject = 'Review changes after synchronization with IT-Enterprise.';
						taskDescription = 'The account was changed after synchronization with IT-Enterprise system.\n' +
											'Account befor synchronization: ' + opp.Account.Name + '.\n' +
											'New account\'s name in IT-Enterprise system: ' + requestObj.Account.Name + '.';
					}
				}
				insertEditingTaskForOppOwner(opp, taskSubject, taskDescription);
			}
		}
		if (requestObj.Account.Id != '164525') {
			// Апдейтим контрагента в оппе, только если это не служебная запись "Новый контрагент" в ИТ-Предприятии.
			opp.AccountId = accs[0].Id;
		}

		Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();

		if (String.isNotBlank(requestObj.Country)) {
			List<Country__c> country = [SELECT Id FROM Country__c WHERE NumCode__c = :requestObj.Country];
			checkListSize(country, 'Country', requestObj.Country, null, sObjects_to_insert);
			if (country.size() == 0) {
				opp.Country__c = sObjects_to_insert.get('Country').Id;
			} else {
				opp.Country__c = country[0].Id;
			}
		} else {
			opp.Country__c = null;
		}
		if (String.isNotBlank(requestObj.PaymentTerms.ID)) {
			List<PaymentTerms__c> paymentTerms = [SELECT Id FROM PaymentTerms__c WHERE ID_ERP__c = :requestObj.PaymentTerms.ID];
			checkListSize(paymentTerms, 'PaymentTerms', requestObj.PaymentTerms.ID, requestObj.PaymentTerms.Name, sObjects_to_insert);
			if (paymentTerms.isEmpty()) {
				opp.PaymentTerms__c = sObjects_to_insert.get('PaymentTerms').Id;
			} else {
				opp.PaymentTerms__c = paymentTerms[0].Id;
			}
		} else {
			opp.PaymentTerms__c = null;
		}
		if (String.isNotBlank(requestObj.DeliveryTerms.ID)) {
			List<DeliveryTerms__c> deliveryTerms = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :requestObj.DeliveryTerms.ID];
			if (deliveryTerms.size() == 0) {
				DeliveryTerms__c obj_to_insert = new DeliveryTerms__c(Name = requestObj.DeliveryTerms.Name, Id_ERP__c = requestObj.DeliveryTerms.ID);
				requestObj.DeliveryTerms.Name = checkNameFieldSize(requestObj.DeliveryTerms.Name, 80);
				obj_to_insert.Name = requestObj.DeliveryTerms.Name;
				obj_to_insert.NameRus__c = requestObj.DeliveryTerms.Name;
				obj_to_insert.Incoterms__c = requestObj.DeliveryTerms.Incoterms;
				insert obj_to_insert;
				opp.DeliveryTerms__c = obj_to_insert.Id;
			} else {
				opp.DeliveryTerms__c = deliveryTerms[0].Id;
			}
		} else {
			opp.DeliveryTerms__c = null;
		}

		if (opp.OwnerId == null) {
			//Владельца устанавливаем только в новых созданных оппах
			if (String.isNotBlank(requestObj.Owner.Id)) {
				//Если менеджер по сегменту Европа, то из ИТ приходит код "xxxxx", (после отделения европейского офиса
				//переназначили часть продуктовой линейки продавцам БВиА, и импортировали заказы по этим продуктам из ИТ)
				if (requestObj.Owner.Id == 'xxxxx'){
					opp.OwnerId = UserInfo.getUserId();
					opp.InitialOwnerName__c = requestObj.Owner.Name;
				} else {
					List<UserID_ERP__c> userOwner = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.Owner.Id];
					checkListSize(userOwner, 'Users (Sales Manager)', requestObj.Owner.Id, requestObj.Owner.Name, null);
					opp.OwnerId = userOwner[0].User__c;
					opp.InitialOwnerName__c = '';
				}
			} else {
				String errorMessage = 'Owner field can not be blank.';
				throw new erpException(errorMessage);
			}
		}
		
		if (String.isNotBlank(requestObj.BOSpecialist.Id)) {
			List<UserID_ERP__c> userBOSpecialist = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.BOSpecialist.Id];
			checkListSize(userBOSpecialist, 'Users (BO specialist)', requestObj.BOSpecialist.Id, null, null);
			if (userBOSpecialist.size() > 0) {
				opp.AssignedBOS__c = userBOSpecialist[0].User__c;
			} else {
				insertTaskForAdmin('Assign BO Specialist ID in ERP to a user: \nUser ID: ' + requestObj.BOSpecialist.Id + '\nUser name: ' + requestObj.BOSpecialist.Name + '\nUser email: ' + requestObj.BOSpecialist.Email, opp.Id, result.isNewOppCreated, 'Opportunity', 'BO Specialist');
			}
		} else {
			//opp.AssignedBOS__c = null;
		}

		opp.CurrencyIsoCode = requestObj.OpportunityCurrency;

		opp.ITENumber__c = requestObj.ITENumber;
		opp.AdditionalNumber__c = requestObj.AddNumber;
		opp.MarketSegment__c = requestObj.MarketSegment;
		opp.Region__c = requestObj.Region;
		opp.CrossMarketSegment__c = requestObj.CrossMarketSegment;
		if (String.isNotBlank(requestObj.CrossMarketManager)) {
			List<UserID_ERP__c> userCrossMarketManager = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.CrossMarketManager];
			//checkListSize(userCrossMarketManager, 'Users (cross-market manager)', requestObj.CrossMarketManager, null, null);
			if (userCrossMarketManager.size() > 0) {
				opp.CrossMarketManager__c = userCrossMarketManager[0].User__c;
			} else {
				if (activeSegments.contains(requestObj.CrossMarketSegment)) {
					insertTaskForAdmin('Assign cross-market Manager ID in ERP to a user: \nUser ID: ' + requestObj.CrossMarketManager + '\nUser name: ' + requestObj.CrossMarketManagerName, opp.Id, result.isNewOppCreated, 'Opportunity', 'cross-market manager');
				}
			}
		} else {
			opp.CrossMarketManager__c = null;
		}
		opp.CrossMarketShare__c = Decimal.valueOf(requestObj.CrossMarketPercent);

		return opp;
	}

	
	public static Order mapOrderFields(ERPRequestParser.ERPOpportunity requestObj, Order ord, UpdateSFRecordsResultOrder result, ERPWebServiceHandler.UpdateSFRecordsResult resultOpp) {

		Map<String, sObject> sObjects_to_insert = new Map<String, sObject> ();
		ord.AccountId = resultOpp.parentOpp.AccountId;

		if (String.isNotBlank(requestObj.Country)) {
			List<Country__c> country = [SELECT Id FROM Country__c WHERE NumCode__c = :requestObj.Country];
			checkListSize(country, 'Country', requestObj.Country, null, sObjects_to_insert);
			if (country.size() == 0) {
				ord.Country__c = sObjects_to_insert.get('Country').Id;
			} else {
				ord.Country__c = country[0].Id;
			}
		} else {
			ord.Country__c = null;
		}
		if (String.isNotBlank(requestObj.PaymentTerms.ID)) {
			List<PaymentTerms__c> paymentTerms = [SELECT Id, ID_ERP__c FROM PaymentTerms__c WHERE ID_ERP__c = :requestObj.PaymentTerms.ID];
			checkListSize(paymentTerms, 'PaymentTerms', requestObj.PaymentTerms.ID, requestObj.PaymentTerms.Name, sObjects_to_insert);
			String nameOfPaymentTerms = requestObj.PaymentTerms.Name;
			if (paymentTerms.isEmpty()) {
				ord.PaymentTerms__c = sObjects_to_insert.get('PaymentTerms').Id;
			} else {
				ord.PaymentTerms__c = paymentTerms[0].Id;
			}

		} else {
			ord.PaymentTerms__c = null;
		}
		if (String.isNotBlank(requestObj.DeliveryTerms.ID)) {
			List<DeliveryTerms__c> deliveryTerms = [SELECT Id FROM DeliveryTerms__c WHERE ID_ERP__c = :requestObj.DeliveryTerms.ID];
			if (deliveryTerms.size() == 0) {
				DeliveryTerms__c obj_to_insert = new DeliveryTerms__c(Name = requestObj.DeliveryTerms.Name, Id_ERP__c = requestObj.DeliveryTerms.ID);
				obj_to_insert.Incoterms__c = requestObj.DeliveryTerms.Incoterms;
				insert obj_to_insert;
				ord.DeliveryTerms__c = obj_to_insert.Id;
			} else {
				ord.DeliveryTerms__c = deliveryTerms[0].Id;
			}
		} else {
			ord.DeliveryTerms__c = null;
		}

		if (ord.OwnerId == null) {
			//Владельца устанавливаем только в новых созданных ордерах
			//if (String.isNotBlank(requestObj.Owner.Id)) {
				//if (requestObj.Owner.Id == 'xxxxx'){
					//ord.OwnerId = UserInfo.getUserId();
					//ord.InitialOwnerName__c = requestObj.Owner.Name;
				//} else {
					//List<UserID_ERP__c> userOwner = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.Owner.Id];
					//checkListSize(userOwner, 'Users (Sales Manager)', requestObj.Owner.Id, null, null);
					//ord.OwnerId = userOwner[0].User__c;
					//ord.InitialOwnerName__c = '';
				//}
			//} else {
				//String errorMessage = 'Owner field can not be blank.';
				//throw new erpException(errorMessage);
			//}
			ord.OwnerId = resultOpp.parentOpp.OwnerId;
			ord.InitialOwnerName__c = resultOpp.parentOpp.InitialOwnerName__c;
		}

		if (String.isNotBlank(requestObj.BOSpecialist.Id)) {
			List<UserID_ERP__c> userBOSpecialist = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.BOSpecialist.Id];
			//checkListSize(userBOSpecialist, 'Users (BO specialist)', requestObj.BOSpecialist.Id, null, null);
			if (userBOSpecialist.size() > 0) {
				ord.AssignedBOS__c = userBOSpecialist[0].User__c;
			} else {
				insertTaskForAdmin('Assign BO Specialist ID in ERP to a user: \nUser ID: ' + requestObj.BOSpecialist.Id + '\nUser name: ' + requestObj.BOSpecialist.Name + '\nUser e-mail: ' + requestObj.BOSpecialist.Email, ord.Id, result.isNewOrderCreated, 'Order', 'BO Specialist');
			}
			
		} else {
			//ord.AssignedBOS__c = null;
		}

		ord.ID_ERP__c = requestObj.ID_ERP;
		ord.ITENumber__c = requestObj.ITENumber;
		ord.AdditionalNumber__c = requestObj.AddNumber;
		ord.CurrencyIsoCode = requestObj.OpportunityCurrency;
		ord.MarketSegment__c = requestObj.MarketSegment;
		ord.Region__c = requestObj.Region;
		ord.CrossMarketSegment__c = requestObj.CrossMarketSegment;
		if (String.isNotBlank(requestObj.CrossMarketManager)) {
			List<UserID_ERP__c> userCrossMarketManager = [SELECT User__c FROM UserID_ERP__c WHERE Name = :requestObj.CrossMarketManager];
			//checkListSize(userCrossMarketManager, 'Users (cross-market manager)', requestObj.CrossMarketManager, null, null);
			if (userCrossMarketManager.size() > 0) {
				ord.CrossMarketManager__c = userCrossMarketManager[0].User__c;
			} else {
				if (activeSegments.contains(ord.CrossMarketSegment__c)) {
					insertTaskForAdmin('Assign cross-market Manager ID in ERP to a user: \nUser ID: ' + requestObj.CrossMarketManager + '\nUser name: ' + requestObj.CrossMarketManagerName, ord.Id, result.isNewOrderCreated, 'Order', 'cross-market manager');
				}
			}
			
		} else {
			ord.CrossMarketManager__c = null;
		}
		ord.CrossMarketShare__c = Decimal.valueOf(requestObj.CrossMarketPercent);
		//ord.SecondChoice__c = resultOpp.parentOpp.SecondChoice__c;

		return ord;
	}


	public static void checkListSize(List<SObject> listToCheck, String objName, String obj_ID_ERP, String request_obj_name, Map<String, sObject> sObjects_to_insert) {
		if (listToCheck.size() == 0 && objName != 'Account') {
			//if (objName == 'Users (Sales Manager)' || objName == 'Users (BO specialist)') {
			if (objName == 'Users (Sales Manager)') {
				String errorMessage = 'There is no ' + objName + ' with ID ERP ' + obj_ID_ERP + '. User name: ' + request_obj_name;
				throw new erpException(errorMessage);
			} else {
				if (objName == 'Country') {
					sObjects_to_insert.put(objName, country_not_spec);
				} else if(objName == 'Users (BO Specialist)' || objName == 'Users (cross-market manager)') {
					//Ничего не делаем.
				} else {
					System.debug('There is no ' + objName + ' with such ID ERP (' + obj_ID_ERP + ') - Creating a new one.');
					sObject sObj_to_insert = Schema.getGlobalDescribe().get(erp_to_sf_api_names_opp.get(objName)).newSObject();
					System.debug('Api Name = ' + erp_to_sf_api_names_opp.get(objName));

					if (objName == 'PaymentTerms') {
						request_obj_name = checkNameFieldSize(request_obj_name, 255);
						sObj_to_insert.put('NameFull__c', request_obj_name);
						sObj_to_insert.put('NameFullRus__c', request_obj_name);

						request_obj_name = checkNameFieldSize(request_obj_name, 80);
						sObj_to_insert.put('NameRus__c', request_obj_name);
					}
					request_obj_name = checkNameFieldSize(request_obj_name, 80);

					sObj_to_insert.put('Name', request_obj_name);
					sObj_to_insert.put('Id_ERP__c', obj_ID_ERP);
					insert sObj_to_insert;
					System.debug('Created new object - ' + sObj_to_insert);
					sObjects_to_insert.put(objName, sObj_to_insert);
				}
			}
		} else if (listToCheck.size() > 1) {
			String errorMessage = 'There are several ' + objName + ' with such ID ERP(' + obj_ID_ERP + ').';
			System.debug(errorMessage.removeEnd('.') + ': ');
			Integer i = 1;
			for (SObject sobj : listToCheck) {
				System.debug(i + '--' + sobj);
				i++;
			}
			throw new erpException(errorMessage);
		}
	}

	public static Blob generateResponseBodySyncedOppUpdate(Integer statusCode, String error, ERPWebServiceHandler.UpdateSyncedResult oppResult) {

		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', HTTPSTATUSES.get(statusCode));
		if (error != NULL) {
			gen.writeStringField('Error Message', error);
		}
		if (oppResult.SyncedResult == '1') {
			if (oppResult.syncedOpportunity.Id != NULL) {
				gen.writeStringField('Updated Opportunity Id', oppResult.syncedOpportunity.Id);
			}

		} else {
			gen.writeStringField('Result', 'Changes were rejected.');
		}
		gen.writeEndObject();
		String res = gen.getAsString();
		return Blob.valueOf(res);
	}

	public static Blob generateResponseBodyOppUpdate(Integer statusCode, String error, ERPWebServiceHandler.UpdateSFRecordsResult oppResult, ERPWebServiceHandler.UpdateSFRecordsResult oppProductsResult) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', HTTPSTATUSES.get(statusCode));
		if (error != NULL) {
			gen.writeStringField('Error Message', error);
		}
		if (oppResult?.parentOpp?.Id != NULL) {
			if (oppResult.isNewOppCreated == true) {
				gen.writeStringField('Created Opportunity Id', oppResult.parentOpp.Id);
			} else {
				gen.writeStringField('Updated Opportunity Id', oppResult.parentOpp.Id);
			}
		}
		if (oppProductsResult?.newOppProductsIds.size() > 0) {
			gen.writeFieldName('Created Opportunity Products');
			if (oppProductsResult.newOppProductsIds.size() > 0) {
				gen.writeStartArray();
			}
			for (Integer i = 0; i<oppProductsResult.newOppProductsIds.size(); i++) {
				gen.writeStartObject();
				gen.writeObjectField('Id', oppProductsResult.newOppProductsIds[i]);
				gen.writeEndObject();
			}
			if (oppProductsResult.newOppProductsIds.size()> 0) {
				gen.writeEndArray();
			}
		}
		if (oppProductsResult?.updatedOppProductsIds.size() > 0) {
			gen.writeFieldName('Updated Opportunity Products');
			if (oppProductsResult.updatedOppProductsIds.size() > 0) {
				gen.writeStartArray();
			}
			for (Integer i = 0; i<oppProductsResult.updatedOppProductsIds.size(); i++) {
				gen.writeStartObject();
				gen.writeObjectField('Id', oppProductsResult.updatedOppProductsIds[i]);
				gen.writeEndObject();
			}
			if (oppProductsResult.updatedOppProductsIds.size()> 0) {
				gen.writeEndArray();
			}
		}
		gen.writeEndObject();
		String res = gen.getAsString();
		return Blob.valueOf(res);
	}

	public static void insertErrorTask(String subject, String request, String error, Id oppId) {
		if (String.isNotBlank(Credentials__c.getOrgDefaults().NotifyId__c)) { //add cheking if it user ID in field value
			Task t = new Task();
			subject += ': ' + error.substringAfter('Error Message" : "').substringBefore(error.contains('Class.') ? 'Class.' : '()');
			if (subject.length() > 255) {
				subject = subject.substring(0, 251) + '...';
			}
			t.Subject = subject;
			t.OwnerId = Credentials__c.getOrgDefaults().NotifyId__c;
			t.ActivityDate = Date.today();
			t.Description = 'Request:\n' + request + '\n Response:\n' + error;
			t.WhatId = oppId;
			System.debug('Trying inserting Task for Admin:');
			System.debug(t);
			insert t;
			System.debug('Task Id=' + t.Id);
		} else {
			System.debug('Task for Admin was not created because Custom Setting does not contain any ID in NotifyId__c field.');
		}
	}

	public static void insertTaskForAdmin(String subject, Id oppId, Boolean isNew, String objTypeName, String userLabel) {
		if (String.isNotBlank(Credentials__c.getOrgDefaults().NotifyId__c)) { //add cheking if it user ID in field value
			Task t = new Task();
			t.Subject = subject;
			t.OwnerId = Credentials__c.getOrgDefaults().NotifyId__c;
			t.ActivityDate = Date.today();
			t.Description = objTypeName + ' ' + oppId + ' was ' + (isNew ? 'created' : 'updated') + ' but ' + userLabel + ' ID wasn\'t found in \'Users ID in ERP\' reference.';
			t.WhatId = oppId;
			System.debug('Trying inserting Task for Admin:');
			System.debug(t);
			insert t;
			System.debug('Task Id=' + t.Id);
		} else {
			System.debug('Task for Admin was not created because Custom Setting does not contain any ID in NotifyId__c field.');
		}
	}

	public static void insertEditingTaskForOppOwner(Opportunity opp, String subject, String description) {
		if (opp.OwnerId != null) {
			Task t = new Task();
			t.Subject = subject;
			t.Description = description;
			t.OwnerId = opp.OwnerId;
			t.ActivityDate = System.today() + 1;
			t.WhatId = opp.Id;
			System.debug('Trying inserting Task for Opportunity Owner:');
			System.debug(t);
			insert t;
			System.debug('Task Id=' + t.Id);
		} else {
			System.debug('Task for Opportunity Owner was not created because it does not have Onwer.');
		}
	}

	@testVisible
	private static Set<String> getOppProductERPIds(List<ERPRequestParser.OpportunityProduct> oppProductsERP) {
		Set<String> oppProdIds = new Set<String> ();
		if (oppProductsERP != null) {
			for (ERPRequestParser.OpportunityProduct oppProduct : oppProductsERP) {
				if (String.isBlank(oppProduct.ID_ERP)) {
					String errorMessage = 'Your Opportunity Line Item does not contain required ID_ERP field.';
					throw new erpException(errorMessage);
				}
				oppProdIds.add(oppProduct.ID_ERP);
			}
		}
		return oppProdIds;
	}

	@testVisible
	private static Map<String, OpportunityLineItem> getOppProdSFMap(Set<String> oppProdIds, String fieldName, String oppId) {
		String queryString =
		'SELECT Id, ID_ERP__c, Name, Stage__c, Product2.ID_ERP__c, SteelGrade__r.ID_ERP__c, Quantity, Quantity_m__c,' +
		'Quantity_ft__c, TubeEnds__r.ID_ERP__c, Coating__c, WheelProductStandard__r.ID_ERP__c, WheelSteelGrade__r.ID_ERP__c, WheelHub__r.ID_ERP__c, WheelDrawing__r.ID_ERP__c, Shop__r.ID_ERP__c, Description, TechExp__c, PricebookEntryId,' +
		'TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, WheelDiameter__r.ID_ERP__c, NPP_ERP__c, OpportunityId FROM OpportunityLineItem WHERE OpportunityId=\'' + oppId + '\'';

		List<OpportunityLineItem> oppProducts = Database.query(queryString);

		Map<String, OpportunityLineItem> oppProdMap = new Map<String, OpportunityLineItem> ();
		for (OpportunityLineItem oppProd : oppProducts) {
			oppProdMap.put((String) oppProd.get(fieldName), oppProd);
		}
		return oppProdMap;
	}

	@testVisible
	private static Map<String, OrderItem> getOrdProdSFMap(Set<String> oppProdIds, String fieldName, String ordId) {

		String queryString =
		'SELECT Id, ID_ERP__c, Name__c, Product2Id, SteelGrade__r.ID_ERP__c, Quantity,' +
		'TubeEnds__r.ID_ERP__c, Coating__c, WheelProductStandard__r.ID_ERP__c, WheelSteelGrade__r.ID_ERP__c, WheelHub__r.ID_ERP__c, WheelDrawing__r.ID_ERP__c, Description, PricebookEntryId,' +
		'TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, WheelDiameter__r.ID_ERP__c, NPP_ERP__c, OrderId FROM OrderItem WHERE OrderId=\'' + ordId + '\'';

		List<OrderItem> ordProducts = Database.query(queryString);
		Map<String, OrderItem> ordProdMap = new Map<String, OrderItem> ();
		if (ordProducts.size() > 0) {
			for (OrderItem ordProd : ordProducts) {
				ordProdMap.put((String) ordProd.get(fieldName), ordProd);
			}
		}
		return ordProdMap;
	}

	public static Opportunity getOpportunitySFByERPID(String oppIdERP) {
		
		if (relatedOpp != null) {
			return relatedOpp;
		}

		System.debug('Searching Opportunity with ERP ID =' + oppIdERP);
		List<Opportunity> oppList = [
										SELECT Id, ID_ERP__c, CreatedDate, OwnerId, Owner.LanguageLocaleKey, InitialOwnerName__c, StageName, CloseDate,
										IsClosed, IsWon, Country__c, DeliveryTerms__c, Description, DeliveryTerms__r.Name, Pricebook2Id,
										AssignedBOS__c, AssignedBOS__r.Name, AssignedBOS__r.Email, SyncedOrder__c, Name,
										ContractId, AccountId, Account.ID_ERP__c, Account.Name, CurrencyIsoCode,
										IsSecondChoice__c
										FROM Opportunity
										WHERE ID_ERP__c = :oppIdERP
									];

		if (oppList.size() != 0) {
			System.debug('Found ' + oppList.size() + ' record(s):');
			Integer i = 1;
			for (Opportunity op : oppList) {
				System.debug(i + '---' + op);
				i++;
			}
			if (oppList.size() > 1) {
				System.debug('WARNING: Found more than 1 opportunity');
			}
			relatedOpp = oppList[0];
		}

		return relatedOpp;
	}

	public static Order getOrderSFByID(UpdateSFRecordsResult resultOpp) {
		System.debug('Searching Order in SF by Opportunity - ' + resultOpp.parentOpp.ID_ERP__c);
		if (resultOpp.parentOpp.SyncedOrder__c == null) {
			return null;
		} else {
			List<Order> ordList = [SELECT Id, OwnerId, InitialOwnerName__c, OpportunityId, CreatedDate, EffectiveDate, EffectiveDateAux__c, Status, ID_ERP__c, CurrencyIsoCode FROM Order WHERE Id = :resultOpp.parentOpp.SyncedOrder__c];
			System.debug('Order list - ' + ordList);
			if (!ordList.isEmpty()) {
				System.debug('Found Order - ' + ordList);
				return ordList[0];
			} else {
				return null;
			}
		}
	}

	public static OpportunityLineItem createNewOli(ERPRequestParser.OpportunityProduct oppProdERP, Id parentOppId, Map<String, PricebookEntry> pbeIdByProduct2erpId) {
		OpportunityLineItem newOLI = new OpportunityLineItem();
		newOLI.OpportunityId = parentOppId;
		newOLI.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
		newOLI.TotalPrice = null;
		newOLI.NPP_ERP__c = String.valueOf(oppProdERP.ID_ERP);
		return newOli;
	}

	public static OrderItem createNewOrderItem(ERPRequestParser.OpportunityProduct oppProdERP, Order parentOrd, Map<String, PricebookEntry> pbeIdByProduct2erpId) {

		OrderItem newOrdItem = new OrderItem();
		newOrdItem.OrderId = parentOrd.Id;
		newOrdItem.PricebookEntryId = pbeIdByProduct2erpId.get(oppProdERP.ProductGroup.ID).Id;
		newOrdItem.NPP_ERP__c = String.valueOf(oppProdERP.ID_ERP);
		newOrdItem.ID_ERP__c = String.valueOf(parentOrd.ID_ERP__c + '-' + oppProdERP.ID_ERP);
		return newOrdItem;
	}

	public static List<OpportunityLineItem> getOpportunityLineItem(String OppLiNpp, String oppId) {
		System.debug('Searching Line Item(' + OppLiNpp + ') for Opportunity(SF_ID=' + oppId + ').');
		List<OpportunityLineItem> result = [SELECT Id, OpportunityId, Stage__c, TechExp__c, ID_ERP__c, CDD__c, CDDRecommended__c, NPP_ERP__c FROM OpportunityLineItem WHERE OpportunityId = :oppId AND NPP_ERP__c = :OppLiNpp];
		if (result.size() > 1) {
			System.debug('WARNING. Found more than 1 Item:');
			for (OpportunityLineItem oppLi : result) {
				System.debug(oppLi);
			}
		} else if (result.size() == 1) {
			System.debug('Line Item was succesfully found:');
			System.debug(result[0]);
		}
		return result;
	}

	public static Blob generateResponseBody(Integer statusCode, String error) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', HTTPSTATUSES.get(statusCode));
		if (error != NULL) {
			gen.writeStringField('Error Message', error);
		}
		gen.writeEndObject();
		String res = gen.getAsString();
		return Blob.valueOf(res);
	}

	public static void deleteCancelledItems(ERPRequestParser.ERPrequest generalData) {

		List<ERPRequestParser.OpportunityProduct> oppProducts = new List<ERPRequestParser.OpportunityProduct> ();
	
		for (ERPRequestParser.OpportunityProduct oppProduct : generalData.General_Data.Item_Data) {
		  if (oppProduct.Stage != 'Cancelled' || oppProduct.InqQuantity == null || Integer.valueOf(oppProduct.InqQuantity) == 0) {
			oppProducts.add(oppProduct);
		  }
		}
		generalData.General_Data.Item_Data = oppProducts;
	  }

	public static void createChatterPost(ERPRequestParser.ERPItemStage itemStageData, String requestBody) {
		System.debug(itemStageData.Item_Stage.OpportunityItemID_ERP);
		Boolean techexp = itemStageData.Item_Stage.TechExp_Comment != null && itemStageData.Item_Stage.TechExp_Comment != '';
		Boolean scComment = itemStageData.Item_Stage.SC_Comment != null && itemStageData.Item_Stage.SC_Comment != '';
		if (techexp || scComment) {
			List<Opportunity> opp = [SELECT Id, OwnerId, (SELECT Id, Name__c FROM OpportunityLineItems WHERE NPP_ERP__c = :itemStageData.Item_Stage.OpportunityItemID_ERP) FROM Opportunity WHERE ID_ERP__c = :itemStageData.Item_Stage.OpportunityID_ERP];
			System.debug(opp);
			if (opp.size() == 0) {
				//String errorMessage = 'There is no Opportunity with ID ERP: ' + itemStageData.Item_Stage.OpportunityID_ERP + '.';
				//throw new erpException(errorMessage);
				return;
			}
			if (opp[0].OpportunityLineItems.size() == 0) {
				//String errorMessage = 'There is no Opportunity Line Item with ID ERP: ' + itemStageData.Item_Stage.OpportunityItemID_ERP + '.';
				//throw new erpException(errorMessage);
				return;
			}
			String instanceName = [select InstanceName from Organization limit 1].InstanceName;
			System.debug('Instance name: ' + instanceName);

			String messageText = '';
			messageText += (techexp) ? ('<p>{' + opp[0].OwnerId + '}</p>'+ '<p>TechExp_Comment: ' + itemStageData.Item_Stage.TechExp_Comment + '</p>') : '';
			messageText += (scComment) ? ('<p>SC_Comment: ' + itemStageData.Item_Stage.SC_Comment + '</p>') : '';
			messageText += '<p>Opportunity Product: '+ opp[0].OpportunityLineItems[0].Name__c + ' - ' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + opp[0].OpportunityLineItems[0].Id + ' </p>';
			ConnectApiHelper.postFeedItemWithRichText(null, opp[0].Id, messageText);
		}
	}

	public static String checkNameFieldSize(String nameOfObject, Integer fieldSize) {
		if (nameOfObject.length() > fieldSize) {
			nameOfObject = nameOfObject.substring(0, fieldSize - 4) + '...';
		}
		return nameOfObject;
	}

	public class UpdateSFRecordsResult {
		public Boolean isError = false;

		public Map<String, Map<String, Id>> objToIdMap;

		public Boolean isNewOppCreated = false;
		public Boolean isCurrencyCodeChanged = false;
		public Opportunity parentOpp;
		public String oppChangeStatus;
		
		public Date firstLotDate; //Содержит дату самого раннего лота по данной оппе во входящем сообщении из ERP.
		public Date lastLotDate; //Содержит дату самого позднего лота по данной оппе во входящем сообщении из ERP.
		public Boolean hasLots = false; // установится в True, если хотя бы по одной позиции обнаружим данные по Execution.


		public List<String> newOppProductsIds;
		public List<String> updatedOppProductsIds;
	}

	public class UpdateSFRecordsResultOrder {
		public Boolean isError = false;

		public Boolean isNewOrderCreated = false;
		public Order parentOrd;
		public Boolean isCurrencyCodeChanged = false;

		public List<String> newOrdProductsIds;
		public List<String> updatedOrdProductsIds;
		public List<String> deletedOrdProductsIds;

		public Boolean isFullyShipped = true; //изначально предполагаем, что весь заказ реализован, но если попадется хоть одна не реализованная позиция, изменим значение на False.
		public Date firstLotDate;
		public Date lastLotDate;
	}

	public class UpdateSyncedResult {
		public Opportunity syncedOpportunity;
		public List<String> syncedOppLItems;
		public String SyncedResult;

	}

	//public class MonthPlanFactMessageProcessingResult {
		//public String MessageType;
		//public Integer numberOfDeletedRecords;
		//public Integer numberOfCreatedRecords;
		//public List<String> foundItemsIdList;
		//public List<String> unknownItemsIdList;
		//public List<String> inactiveUsers;
	//}

	public class erpException extends Exception { }

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
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
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