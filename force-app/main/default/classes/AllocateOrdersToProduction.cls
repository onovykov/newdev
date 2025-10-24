global class AllocateOrdersToProduction implements Database.Batchable<SObject> {
	
	List<SalesPlanFact__c> spfToInsert = new List<SalesPlanFact__c>();

	//global AllocateOrdersToProduction() {
		
	//}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
		
		Date firstDayOfThisMonth = Date.today().toStartOfMonth();
		
		// Выберем все позиции заказов, которые есть в плане этого месяца, чтобы включить их в распределение на текущий месяц даже если они уже перешли в закрытую стадию
		List<SalesPlanFact__c> plannedOI = new List<SalesPlanFact__c> (
			[	SELECT	InitialRecordId__c
				FROM	SalesPlanFact__c
				WHERE	Period__c = :firstDayOfThisMonth
				 AND	Type__c = 'Plan'
				 AND	ProductionAmount__c > 0
			]);
		
		Set<String> plannedOIIdList = ApexUtil.getFieldValues(plannedOI, 'InitialRecordId__c');
		System.debug('----> Planned OI Ids: ' + plannedOIIdList);

		// Выберем все позиции заказов, по которым была отгрузка в этом месяце, чтобы включить их в распределение на текущий месяц даже если они перешли в закрытую стадию
		//List<ProductionJournalRecord__c> producedOI = new List<ProductionJournalRecord__c> (
			//[	SELECT	OrderItem__c
				//FROM	ProductionJournalRecord__c
				//WHERE	Period__c = :firstDayOfThisMonth
				 //AND	Type__c = 'Fact'
				 //AND	DispatchedQuantity__c > 0
			//]);

		//Set<String> producedOIIdList = ApexUtil.getFieldValues(producedOI, 'OrderItem__c');
		//System.debug('----> Planned OI Ids: ' + producedOIIdList);

		return Database.getQueryLocator(
				'	SELECT	Id, ID_ERP__c, Shop__c, QuotaType__c, OrderId, Quantity ' +
				'	FROM	OrderItem ' + 
				'	Where	((Stage__c != \'Dispatched\' And Stage__c != \'Shipped\' And Stage__c != \'Cancelled\' And Order.Status != \'Closed\') ' +
				'				OR Id in :plannedOIIdList) ' +
				'			AND	Quantity >= 2 ' +
				'			AND	Order.IsSecondChoice__c = False' + 
				'			AND	Order.MarketSegment__c = \'00002\'' +
				'			AND	Order.Owner.IsActive = true'
		);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<OrderItem> scope) {
		
		// Сформируем необходимые списки, мапы и т.п.
		Set<String> oiIdSet = ApexUtil.getFieldValues(scope, 'Id');
		Set<String> orderIdSet = ApexUtil.getFieldValues(scope, 'OrderId');
		Map<Id, Order> orderMap = new Map<Id, Order>([
			SELECT Id, AdditionalNumber__c, MarketSegment__c, Country__c, AccountId, OwnerId, IsSecondChoice__c
			FROM Order
			WHERE Id in :orderIdSet
		]);
		Map<Id, Map<Date, Decimal>> productionMap = getProductionMap(oiIdSet);
		Map<String, Decimal> budgetMap = getBudgetMap();
		Set<Date> plannedPeriods = getPlannedPeriods();

		System.debug('------->>> Production Map: ' + productionMap);
		System.debug('------->>> Budget Map: ' + budgetMap);

		Map<String, Id> rtNameMap = new Map<String, Id>();
		for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'SalesPlanFact__c']) {
			rtNameMap.put(rt.DeveloperName, rt.Id);
		}

		for (OrderItem oi : scope) {
			createRelatedSPF(oi, productionMap, budgetMap, orderMap, rtNameMap, plannedPeriods);
		}
		System.debug('---->> SPF to insert: ' + spfToInsert);
		insert spfToInsert;
		spfToInsert.clear();
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
	}


	private Set<Date> getPlannedPeriods() {
		
		Set<Date> plannedPeriods = new Set<Date>();

		//Узнаем, по каким периодам есть план, начиная с текущего месяца (за прошлые периоды он должен быть однозначно)
		Date firstDayOfThisMonth = Date.today().toStartOfMonth();
		AggregateResult[] plannedPeriodsInPJR = 
				[	SELECT		Period__c
					FROM		ProductionJournalRecord__c
					WHERE		Type__c = 'Plan'
					 AND		Period__c >= :firstDayOfThisMonth
					GROUP BY	Period__c
				];
		
		for (AggregateResult plan : plannedPeriodsInPJR) {
			plannedPeriods.add((Date)plan.get('Period__c'));
		}

		return plannedPeriods;
	}

	private Map<Id, Map<Date, Decimal>> getProductionMap(Set<String> oiIdSet) {
		Map<Id, Map<Date, Decimal>> productionMap = new Map<Id, Map<Date, Decimal>>();

		Date firstDayOfThisMonth = Date.today().toStartOfMonth();

		AggregateResult[] producedQuantity = 
				[	SELECT	OrderItem__c oiId, Type__c, Period__c per, SUM(DispatchedQuantity__c) sumDispatched
					FROM	ProductionJournalRecord__c
					WHERE	((Type__c = 'Fact' and Period__c < :firstDayOfThisMonth) OR (Type__c = 'Fact' and ApprovedFact__c = True) OR (Type__c = 'Plan' and Period__c >= :firstDayOfThisMonth))
					 And	OrderItem__c in :oiIdSet
					GROUP	BY OrderItem__c, Type__c, Period__c
					ORDER	BY Period__c
				];
		For (AggregateResult pq : producedQuantity) {
			Id oiId = (Id) pq.get('oiId');
			Decimal dispatched = (Decimal) pq.get('sumDispatched');
			Date per = (Date) pq.get('per');
			String prodType = (String) pq.get('Type__c');
			
			Map<Date, Decimal> oiProdMap = productionMap.get(oiId);
			if (oiProdMap == null) {
				oiProdMap = new Map<Date, Decimal>();
				oiProdMap.put(per, dispatched);
				productionMap.put(oiId, oiProdMap);
			} else {
				if (!(oiProdMap.containsKey(per)) || prodType == 'Fact') {
					oiProdMap.put(per, dispatched);
				}
			}
		}

		return productionMap;
	}

	private Map<String, Decimal> getBudgetMap() {
		Map<String, Decimal> budgetMap = new Map<String, Decimal>();
		Date firstDayOfThisMonth = Date.today().toStartOfMonth();
		AggregateResult[] spfAgg;

		// Получим данные по непокрытому бюджету: соберем данные по бюджету и вычтем из них уже раскиданные ордера
		spfAgg =
		[	SELECT		Type__c recType, Period__c per, MarketSegment__c ms, Shop__c shop, SUM(ProductionAmount__c) q
			FROM		SalesPlanFact__c
			WHERE		(Type__c = 'Actual Budget' OR Type__c = 'Order')
			 AND		Period__c >= :firstDayOfThisMonth
			GROUP BY	Type__c, Period__c, MarketSegment__c, Shop__c
		];

		for (AggregateResult bq : spfAgg) {
			Date per = (Date) bq.get('per');
			String ms = (String) bq.get('ms');
			Id shop = (Id) bq.get('shop');
			String recType = (String) bq.get('recType');
			Decimal q = recType == 'Actual Budget' ? (Decimal) bq.get('q') : - (Decimal) bq.get('q');

			String keyFields = per + '|' + ms + '|' + shop;
			Decimal currentQuantity = budgetMap.get(keyFields);
			if (currentQuantity == null) {
				budgetMap.put(keyFields, q);
			} else {
				budgetMap.put(keyFields, currentQuantity + q); // (Если это Budget, то q - положительное, если это Order, то q - отрицательное.
			}
		}

		
		return budgetMap;
	}

	private void createRelatedSPF(OrderItem oi, Map<Id, Map<Date, Decimal>> productionMap,
									Map<String, Decimal> budgetMap, Map<Id, Order> orderMap,
									Map<String, Id> rtNameMap, Set<Date> plannedPeriods) {
		
		// Распределим свободное количество по месяцам, начиная с текущего.
		
		Order ord = orderMap.get(oi.OrderId);
		Decimal oiQuantity = oi.Quantity;
		Decimal producedQuantity = 0;

		//Посчитаем, сколько было произведено продукции в прошлых периодах:
		Date per = Date.today().toStartOfMonth();
		Map<Date, Decimal> oiProdMap = productionMap.get(oi.Id);
		if (oiProdMap != null) {
			Set<Date> keySet = oiProdMap.keySet();
			for (Date key : keySet) {
				if (key < per) {
					producedQuantity += oiProdMap.get(key);
				}
			}
		} else {
			producedQuantity = 0;
		}
			
		Decimal restQuantity = oiQuantity - producedQuantity;
		if (restQuantity < 2) {
			// Количество меньше двух тонн попросили не распределять.
			return;
		}
		while (restQuantity > 0) {
			SalesPlanFact__c spf = new SalesPlanFact__c();

			spf.InitialRecordId__c = String.valueOf(oi.Id);
			spf.InitialRecordURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + oi.Id;
			spf.Period__c = per;
			spf.RecordTypeId = rtNameMap.get('Order');
			spf.OrderAdditionalNumber__c = ord.AdditionalNumber__c;
			spf.ID_ERP__c = oi.ID_ERP__c;
			spf.Shop__c = oi.Shop__c;
			spf.QuotaType__c = oi.QuotaType__c;
			spf.MarketSegment__c = ord.MarketSegment__c;
			spf.Country__c = ord.Country__c;
			spf.Account__c = ord.AccountId;
			spf.OwnerId = ord.OwnerId;
			spf.CurrencyIsoCode = 'USD';
			spf.ProductionAmount__c = restQuantity;
			spf.SalesAmount__c = 0;
			spf.Revenue__c = 0;
			spf.Margin__c = 0;
			spf.Probability__c = 100;
			spf.SecondChoice__c = ord.IsSecondChoice__c;

			spfToInsert.add(spf);

			spf = spf.clone();
			spf.RecordTypeId = rtNameMap.get('Opportunity');
			spfToInsert.add(spf);

			// Для следующего месяца учтем план производства текущего месяца, либо если его еще нет, то бюджет этого месяца.
			if (plannedPeriods.contains(per)) {
				// Для этого месяца есть планы производства. Значит мы должны учесть именно их для следующего месяца
				If (oiProdMap != null) {
					// Для этой строки заказа существуют записи PJR
					Decimal prodPlanForThisPer = oiProdMap.get(per);
					restQuantity -= (prodPlanForThisPer != null ? prodPlanForThisPer : 0);
				}
					
			} else {
				// Для этого месяца планов производства еще нет, поэтому учтем бюджет для этого месяца
				String keyFields = per + '|' + ord.MarketSegment__c + '|' + oi.Shop__c;
				Decimal budgetThisMonth = budgetMap.get(keyFields);
				if (budgetThisMonth != null) {
					restQuantity -= budgetThisMonth;
					// Вычтем из карты бюджетов учтенное только что количество:
					budgetMap.put(keyFields, budgetThisMonth - Math.min(spf.ProductionAmount__c, budgetThisMonth));
				}
			}
				
			per = per.addMonths(1);
			if (per > Date.today().addMonths(2)) {
				// Если мы уже раскидали количество на текущий месяц и два следующих, то остановимся
				break;
			}
		}
	}
}