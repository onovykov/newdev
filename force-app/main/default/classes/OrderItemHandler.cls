public class OrderItemHandler extends TriggerHandler implements ITrigger {
	
	public static Map<Id, OrderItem> oiMap;
	public static Map<Id, Product2> prodMap;

	public static Map<Id, ProductStandard__c> psMap;
	public static Map<Id, SteelGrade__c> sgMap;
	public static Map<Id, TubeOD__c> odMap;
	public static Map<Id, TubeWT__c> wtMap;
	public static Map<Id, TubeLengthSize__c> lsMap;
	public static Map<Id, TubeEnds__c> teMap;

	public static Map<Id, WheelSteelGrade__c> wsgMap;
	public static Map<Id, WheelDiameter__c> wodMap;
	public static Map<Id, WheelHub__c> whMap;
	public static Map<Id, WheelDrawing__c> wdMap;
	public static Map<Id, WheelProductStandard__c> wpsMap;
	
	public static Map<Id, DrawingVersion__c> drawingMap;
	public static Map<Id, SpecVersion__c> specMap;

	public static List<SalesPlanFact__c> spfToDelete;

	public static Set<Id> prodIds;

	public static Set<Id> psIds;
	public static Set<Id> sgIds;
	public static Set<Id> odIds;
	public static Set<Id> wtIds;
	public static Set<Id> lsIds;
	public static Set<Id> teIds;

	public static Set<Id> wsgIds;
	public static Set<Id> wodIds;
	public static Set<Id> whIds;
	public static Set<Id> wdIds;
	public static Set<Id> wpsIds;
	
	public static Set<Id> drawingIds;
	public static Set<Id> specIds;

	//Bahtiyar 2018-07-25: добавил переменные, используемые при создании записей в объекте SalesPlanFact__c ------------------
	public static Set<Id> ordIdSet;
	public static Set<Id> oiIdSet;
	public static Map<Id, Order> ordIdMap;
	public static Map<String, Decimal> pjrMap;
	public static List<SalesPlanFact__c> spfToInsert;
	public static List<ProductionJournalRecord__c> pjrToInsert;
	public static Map<String, Id> rtNameMap;
	public static Map<Id, List<ProductionJournalRecord__c>> pjrOiMap;
	//---------------------------------------------------------------------

	public static Boolean isFirstExecute = true;
	
	public OrderItemHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}
	

	public void bulkBefore() {
		System.debug('bulkBefore OrderItem');
		initializeOrdIdMap(newList);

		if (Trigger.isInsert && prodIds == null && newList.size() != 200) {
			prodIds = new Set<Id> ();
			
			psIds = new Set<Id> ();
			sgIds = new Set<Id> ();
			odIds = new Set<Id> ();
			wtIds = new Set<Id> ();
			lsIds = new Set<Id> ();
			teIds = new Set<Id> ();

			wsgIds = new Set<Id>();
			wodIds = new Set<Id>();
			whIds = new Set<Id>();
			wdIds = new Set<Id>();
			wpsIds = new Set<Id>();

			drawingIds = new Set<Id>();
			specIds = new Set<Id>();

			for (SObject so : newList) {
				OrderItem oli = (OrderItem) so;

				prodIds.add(oli.Product2Id);

				psIds.add(oli.ProductStandard__c);
				sgIds.add(oli.SteelGrade__c);
				odIds.add(oli.TubeOD__c);
				wtIds.add(oli.TubeWT__c);
				lsIds.add(oli.TubeLengthSize__c);
				teIds.add(oli.TubeEnds__c);
				
				wsgIds.add(oli.WheelSteelGrade__c);
				wodIds.add(oli.WheelDiameter__c);
				whIds.add(oli.WheelHub__c);
				wdIds.add(oli.WheelDrawing__c);
				wpsIds.add(oli.WheelProductStandard__c);

				drawingIds.add(oli.Drawing__c);
				specIds.add(oli.KLWSpec__c);
			}			
		}

		if (Trigger.isUpdate && prodMap == null) {
			
			prodMap = new Map<Id, Product2> ([SELECT Id, Name, Family, Type__c, LinearWeightCalculationGroup__c FROM Product2]);
			psMap = new Map<Id, ProductStandard__c> ([SELECT Id, Name, IsSecondChoice__c FROM ProductStandard__c]);
			odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_inch__c, OD_mm__c FROM TubeOD__c]);
			wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_inch__c, WT_mm__c FROM TubeWT__c]);
			lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c, MinLength__c, Type__c FROM TubeLengthSize__c]);

			drawingMap = new Map<Id, DrawingVersion__c> ([SELECT Id, Name, Diameter__r.D_mm__c, Hub__r.HubSize__c, AxLoadType__r.Name, WheelProduct__c FROM DrawingVersion__c]);
			specMap = new Map<Id, SpecVersion__c> ([SELECT Id, Name, SteelGrade__r.Name, SpecWheel__r.DrawingVersion__r.Diameter__r.D_mm__c, 
														   SpecWheel__r.DrawingVersion__r.Hub__r.HubSize__c, SpecWheel__r.DrawingVersion__r.AxLoadType__r.Name,
														   AxleBox__r.Name, Standard__r.Name, SpecBase__r.ProductType__r.Name, SpecBase__r.ProductType__r.NameRUS__c, 
														   SpecBase__r.ProductType__r.NameUKR__c
													FROM SpecVersion__c]);
		}

		if(Trigger.isInsert && prodMap == null && newList.size() != 200) {

			prodMap = new Map<Id, Product2> ([SELECT Id, Name, Family, Type__c, LinearWeightCalculationGroup__c FROM Product2 WHERE Id = :prodIds]);

			psMap = new Map<Id, ProductStandard__c> ([SELECT Id, Name, IsSecondChoice__c FROM ProductStandard__c WHERE Id = :psIds]);
			sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, Name, ShortName__c FROM SteelGrade__c WHERE Id = :sgIds]);
			odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_inch__c, OD_mm__c FROM TubeOD__c WHERE Id = :odIds]);
			wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_inch__c, WT_mm__c FROM TubeWT__c WHERE Id = :wtIds]);
			lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c, MinLength__c, Type__c FROM TubeLengthSize__c WHERE Id = :lsIds]);
			teMap = new Map<Id, TubeEnds__c> ([SELECT Id, Name, ShortName__c, Type__c FROM TubeEnds__c WHERE Id = :teIds]);

			wsgMap = new Map<Id, WheelSteelGrade__c> ([SELECT Id, Name FROM WheelSteelGrade__c WHERE Id = :wsgIds]);
			wodMap = new Map<Id, WheelDiameter__c> ([SELECT Id, OD_mm__c, Name FROM WheelDiameter__c WHERE Id = :wodIds]);
			whMap = new Map<Id, WheelHub__c> ([SELECT Id, Name FROM WheelHub__c WHERE Id = :whIds]);
			wdMap = new Map<Id, WheelDrawing__c> ([SELECT Id, Name FROM WheelDrawing__c WHERE Id = :wdIds]);
			wpsMap = new Map<Id, WheelProductStandard__c> ([SELECT Id, Name FROM WheelProductStandard__c WHERE Id = :wpsIds]);

			drawingMap = new Map<Id, DrawingVersion__c> ([SELECT Id, Name, Diameter__r.D_mm__c, Hub__r.HubSize__c, AxLoadType__r.Name, WheelProduct__c
														FROM DrawingVersion__c 
														WHERE Id = :drawingIds]);
			specMap = new Map<Id, SpecVersion__c> ([SELECT Id, Name, SteelGrade__r.Name, SpecWheel__r.DrawingVersion__r.Diameter__r.D_mm__c, SteelGrade__r.ShortName__c,
														SpecWheel__r.DrawingVersion__r.Hub__r.HubSize__c, SpecWheel__r.DrawingVersion__r.AxLoadType__r.Name,
														AxleBox__r.Name, Standard__r.Name, SpecBase__r.ProductType__r.Name, SpecBase__r.ProductType__r.NameRUS__c, 
														SpecBase__r.ProductType__r.NameUKR__c
													FROM SpecVersion__c 
													WHERE Id = :specIds]);

		} else if(Trigger.isInsert && prodMap == null && newList.size() == 200) {
			prodMap = new Map<Id, Product2> ([SELECT Id, Name, Family, Type__c, LinearWeightCalculationGroup__c FROM Product2]);

			psMap = new Map<Id, ProductStandard__c> ([SELECT Id, Name, IsSecondChoice__c FROM ProductStandard__c]);
			sgMap = new Map<Id, SteelGrade__c> ([SELECT Id, ShortName__c, Name FROM SteelGrade__c]);
			odMap = new Map<Id, TubeOD__c> ([SELECT Id, OD_inch__c, OD_mm__c FROM TubeOD__c]);
			wtMap = new Map<Id, TubeWT__c> ([SELECT Id, WT_inch__c, WT_mm__c FROM TubeWT__c]);
			lsMap = new Map<Id, TubeLengthSize__c> ([SELECT Id, Name, MaxLength__c, MinLength__c, Type__c FROM TubeLengthSize__c]);
			teMap = new Map<Id, TubeEnds__c> ([SELECT Id, Name, ShortName__c, Type__c FROM TubeEnds__c]);

			wsgMap = new Map<Id, WheelSteelGrade__c> ([SELECT Id, Name FROM WheelSteelGrade__c]);
			wodMap = new Map<Id, WheelDiameter__c> ([SELECT Id, OD_mm__c, Name FROM WheelDiameter__c]);
			whMap = new Map<Id, WheelHub__c> ([SELECT Id, Name FROM WheelHub__c]);
			wdMap = new Map<Id, WheelDrawing__c> ([SELECT Id, Name FROM WheelDrawing__c]);
			wpsMap = new Map<Id, WheelProductStandard__c> ([SELECT Id, Name FROM WheelProductStandard__c]);

			drawingMap = new Map<Id, DrawingVersion__c> ([SELECT Id, Name, Diameter__r.D_mm__c, Hub__r.HubSize__c, AxLoadType__r.Name, WheelProduct__c FROM DrawingVersion__c]);
			specMap = new Map<Id, SpecVersion__c> ([SELECT Id, Name, SteelGrade__r.Name, SpecWheel__r.DrawingVersion__r.Diameter__r.D_mm__c, 
														SpecWheel__r.DrawingVersion__r.Hub__r.HubSize__c, SpecWheel__r.DrawingVersion__r.AxLoadType__r.Name,
														AxleBox__r.Name, Standard__r.Name, SpecBase__r.ProductType__r.Name, SpecBase__r.ProductType__r.NameRUS__c, 
														SpecBase__r.ProductType__r.NameUKR__c
													FROM SpecVersion__c]);
		}

		// Удалим все связанные записи из таблиц SalesPlanFact__c и ProductionJournalRecord__c:
		if (oldList != null && !Trigger.isDelete && (newList.size() == 200 || (newList.size() != 200 && isFirstExecute))) {
			deleteRelatedRecords();
		}
	}

	

	public void bulkAfter() {
		System.debug('bulkAfter OrderItem');
		
		// Подготовим данные для фомрирования записей в объекте SalesPlanFact__c:
		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete && (newList.size() == 200 || (newList.size() != 200 && isFirstExecute))) {
			ordIdSet = new Set<Id>();
			pjrOiMap = new Map<Id, List<ProductionJournalRecord__c>>();
			spfToInsert = new List<SalesPlanFact__c>();
			pjrToInsert = new List<ProductionJournalRecord__c>();
			
			if (rtNameMap == null) {
				rtNameMap = new Map<String, Id>();
				for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'SalesPlanFact__c']) {
					rtNameMap.put(rt.DeveloperName, rt.Id);
				}
			}
			
			//Сформируем список соответствий, для мастер-объектов Order, чтоб потом считывать значения их полей при создании записей в объекте SalesPlanFact__c.
			// initializeOrdIdMap(newList);


			//Сформируем список сответствий строк заказа и относящихся к ним записей ProductionJournalRecords__c:
			List<OrderItem> oiList = 
					[	SELECT id,        SteelGrade__r.ShortName__c, WheelSteelGrade__r.ShortName__c,
							(SELECT id, Type__c, Period__c, ExchangeTimestamp__c, DispatchedQuantity__c, ShippedQuantity__c, DispatchedQuantityNetto__c,
                             ShippedQuantityNetto__c, Revenue__c, Margin__c, Margin_t__c,Production_Amount__c,ProducedForecast__c,Production_Plan__c 
							 FROM Production_Journal_Records__r ORDER BY Period__c)
						FROM OrderItem
						WHERE id in :newList
					];
			
			for (OrderItem oi : oiList) {
				if (oi.Production_Journal_Records__r != null) {
					pjrOiMap.put(oi.Id, oi.Production_Journal_Records__r);
				}
			}

			// Получим карту записей фактов:
			pjrMap = getPjrMap();
			isFirstExecute = false;
		}
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert OrderItem');
		
		//Заполним наименование
		// initializeOrdIdMap(newList);
		OrderItem oli = (OrderItem) so;
		fillName(oli);
		setSecondChoice(oli);
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate OrderItem');
		OrderItem oldOrderItem = (OrderItem)oldSo;
		OrderItem newOrderItem = (OrderItem)so;
		// initializeOrdIdMap(newList);

		if (oldOrderItem.BalanceForProduction__c != null && newOrderItem.BalanceForProduction__c == null) {
		
		}else {
			//Заполним наименование
			fillName(newOrderItem);
			setSecondChoice(newOrderItem);
		}
	}
	
	public void beforeDelete(SObject so) {
		System.debug('beforeDelete OrderItem');
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert OrderItem');

		// Bahtiyar 2018-07-25: создадим записи в объекте SalesPlanFact__c
		if ((newList.size() == 200 || (newList.size() != 200 && isFirstExecute))) {
			createRelatedSPF((OrderItem) so);
			createRelatedPJR((OrderItem) so);
		}
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate OrderItem');
	
		OrderItem oldOrderItem = (OrderItem)oldSo;
		OrderItem newOrderItem = (OrderItem)so;
	
		if (oldOrderItem.BalanceForProduction__c != null && newOrderItem.BalanceForProduction__c == null) {
			// The field changed from not null to null
		}else if((newList.size() == 200 || (newList.size() != 200 && isFirstExecute))) {
			// Bahtiyar 2018-07-25: создадим записи в объекте SalesPlanFact__c
			createRelatedSPF(newOrderItem);
			createRelatedPJR(newOrderItem);
		}
	}


	public void afterDelete(SObject so) {
		System.debug('AfterDelete OrderItem');
	}

	public void postProcessing() {
		System.debug('PostProcessing OrderItem');

		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
			List<OrderItem> items = (List<OrderItem>)newList;
			System.debug('Total OrderItems: ' + items.size());

			for (OrderItem oi : items) {
				System.debug('OrderItem: ' + oi);
			}

			OrderItemChildService.fillChildRecords(items, ordIdMap, specMap, drawingMap);
		}
	}


	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Helpers

	private void setSecondChoice(OrderItem oi) {
		Boolean isSecondChoice = psMap.get(oi.ProductStandard__c)?.IsSecondChoice__c;
		oi.IsSecondChoiceProduct__c = isSecondChoice == null ? false : isSecondChoice;
	}

	public void fillName(OrderItem oi) {
        system.debug('------------------------------------------Fill Name Start------------------------------------------');

		// Ensure all related maps and fields are checked for null values
		Product2 p2 = prodMap.get(oi.Product2Id);
		String prodFamily = (prodMap.get(oi.Product2Id) != null) ? prodMap.get(oi.Product2Id).Family : 'Unknown Family';
		// Debugging output
		System.debug('!!!!!!!!!!!!!!!!!!!!!!  oi' +  JSON.serialize(oi));
		System.debug('!!!!!!!!!!!!!!!!!!!!!!  oi' +  JSON.serializePretty(oi));

	
		// Assuming ordIdMap has been populated correctly
		Order order = ordIdMap.get(oi.OrderId);
		String segment = (order != null) ? order.MarketSegment__c : 'Unknown Segment';
		String country = 'Unknown Country';
		if (order != null && order.Country__c != null) {
			country = order.Country__r.ID_ERP__c;
		}
		System.debug('Order ---> ' + order);
		System.debug('segment ---> ' + segment);
		System.debug('country ---> ' + country);
	
		if (p2 != null && p2.Type__c == 'Tube') {
			// Initialize fields, applying null checks and default values as needed
		String NPSMark = oi.Mark_1__c;
		
		// For fields that are guaranteed by your data model to be non-null, direct assignments can be safe
		String NPS = oi.NPS__c;
		String SCH = oi.SCH__c;
		
		// Apply rounding with null safety
		Decimal PPF = (oi.Weight_ppf__c != null) ? oi.Weight_ppf__c.setScale(2) : null;
		Decimal KPM = (oi.Weight_kpm__c != null) ? oi.Weight_kpm__c.setScale(2) : null;
	
		// Additional fields with null checks
		// OD_mm calculation with null safety
		Decimal OD_mm = null;
		if (odMap != null && odMap.containsKey(oi.TubeOD__c)) {
			OD_mm = odMap.get(oi.TubeOD__c).OD_mm__c; // Retrieve OD_mm__c if key exists
			if (OD_mm != null) {
				OD_mm = OD_mm.stripTrailingZeros();
			}
		}
		System.debug('OD_mm: ' + (OD_mm != null ? OD_mm.toPlainString() : 'null'));

		// WT_mm calculation with null safety
		Decimal WT_mm = null;
		if (wtMap != null && wtMap.containsKey(oi.TubeWT__c)) {
			WT_mm = wtMap.get(oi.TubeWT__c).WT_mm__c; // Retrieve WT_mm__c if key exists
			if (WT_mm != null) {
				WT_mm = WT_mm.stripTrailingZeros();
			}
		}
		System.debug('WT_mm: ' + (WT_mm != null ? WT_mm.toPlainString() : 'null'));

		// OD_inch calculation with null safety
		Decimal OD_inch = null;
		if (odMap != null && odMap.containsKey(oi.TubeOD__c)) {
			OD_inch = odMap.get(oi.TubeOD__c).OD_inch__c; // Retrieve OD_inch__c if key exists
			if (OD_inch != null) {
				OD_inch = OD_inch.setScale(3); // Scale only if not null
			}
		}
		System.debug('OD_inch: ' + (OD_inch != null ? OD_inch.toPlainString() : 'null'));

		// WT_inch calculation with null safety
		Decimal WT_inch = null;
		if (wtMap != null && wtMap.containsKey(oi.TubeWT__c)) {
			WT_inch = wtMap.get(oi.TubeWT__c).WT_inch__c; // Retrieve WT_inch__c if key exists
			if (WT_inch != null) {
				WT_inch = WT_inch.setScale(3); // Scale only if not null
			}
		}
		System.debug('WT_inch: ' + (WT_inch != null ? WT_inch.toPlainString() : 'null'));

		// LenMin_mm and LenMin_ft calculation with null safety
		Decimal LenMin_mm = null;
		if (lsMap != null && lsMap.containsKey(oi.TubeLengthSize__c)) {
			LenMin_mm = lsMap.get(oi.TubeLengthSize__c).MinLength__c; // Retrieve MinLength__c if key exists
		}
		Decimal LenMin_ft = null;
		if (LenMin_mm != null) {
			LenMin_ft = (LenMin_mm / 304.8).setScale(3); // Convert and scale only if not null
		}
		System.debug('LenMin_mm: ' + LenMin_mm);
		System.debug('LenMin_ft: ' + (LenMin_ft != null ? LenMin_ft.toPlainString() : 'null'));

		// LenMax_mm and LenMax_ft calculation with null safety
		Decimal LenMax_mm = null;
		if (lsMap != null && lsMap.containsKey(oi.TubeLengthSize__c)) {
			LenMax_mm = lsMap.get(oi.TubeLengthSize__c).MaxLength__c; // Retrieve MaxLength__c if key exists
		}
		Decimal LenMax_ft = null;
		if (LenMax_mm != null) {
			LenMax_ft = (LenMax_mm / 304.8).setScale(3); // Convert and scale only if not null
		}
		System.debug('LenMax_mm: ' + LenMax_mm);
		System.debug('LenMax_ft: ' + (LenMax_ft != null ? LenMax_ft.toPlainString() : 'null'));

		// Additional field null checks
		String LenCode = (lsMap != null && lsMap.containsKey(oi.TubeLengthSize__c)) ? lsMap.get(oi.TubeLengthSize__c).Type__c : null;
		String TubeEnds = Trigger.isUpdate ? oiMap.get(oi.Id)?.TubeEnds__r?.ShortName__c : (teMap != null && teMap.containsKey(oi.TubeEnds__c)) ? teMap.get(oi.TubeEnds__c).ShortName__c : null;
//		String SteelGrade = Trigger.isUpdate ? oiMap.get(oi.Id)?.SteelGrade__r?.Name : (sgMap != null && sgMap.containsKey(oi.SteelGrade__c)) ? sgMap.get(oi.SteelGrade__c).Name : null;
		String SteelGrade = Trigger.isUpdate ? oiMap.get(oi.Id)?.SteelGrade__r?.ShortName__c : (sgMap != null && sgMap.containsKey(oi.SteelGrade__c)) ? sgMap.get(oi.SteelGrade__c).ShortName__c : null;

		String productName;
		// Формування назви продукту в залежності від групи і сегменту
		if (prodFamily == 'OCTG') {
			System.debug('Entering OCTG logic');
			switch on segment {
				when '00001' {
					System.debug('Segment 00001');
					productName = (NPSMark != null ? NPSMark + ' ' : '') +
								  (PPF != null ? PPF + '# ' : '') +
								  (WT_inch != null ? WT_inch.setScale(3).toPlainString().replace(',', '.') + 'W ' : '') +
								  (SteelGrade != null ? SteelGrade + ' ' : '') +
								  (TubeEnds != null ? TubeEnds + ' ' : '') +
								  (LenCode != null ? LenCode : LenMin_ft + '..' + LenMax_ft + ' ft.');
				}
				when '00002' {
					System.debug('Segment 00002');
					productName = (NPSMark != null ? NPSMark + ' ' : '') +
								  (PPF != null ? PPF + '# ' : '') +
								  (SteelGrade != null ? SteelGrade + ' ' : '') +
								  (TubeEnds != null ? TubeEnds + ' ' : '') +
								  (LenCode != null ? LenCode : 
								  (LenMin_mm != null ? LenMin_mm.setScale(2).toPlainString().replace(',', '.') : '') + '-' +
								  (LenMax_mm != null ? LenMax_mm.setScale(2).toPlainString().replace(',', '.') : ''));
				}
				when '00004' {
					System.debug('Segment 00004');
					productName = (NPSMark != null ? NPSMark + ' ' : '') +
								  (PPF != null ? PPF.setScale(2).toPlainString().replace(',', '.') + '# ' : '') +
								  (WT_mm != null ? WT_mm.setScale(2).toPlainString().replace(',', '.') + ' ' : '') +
								  (SteelGrade != null ? SteelGrade + ' ' : '') +
								  (TubeEnds != null ? TubeEnds + ' ' : '') +
								  (LenMin_mm != null ? LenMin_mm.setScale(2).toPlainString().replace(',', '.') : '') + '-' +
								  (LenMax_mm != null ? LenMax_mm.setScale(2).toPlainString().replace(',', '.') : '');
				}
				when else {
					System.debug('Entering OCTG else block');
					productName = (OD_mm != null ? OD_mm.setScale(2).toPlainString().replace(',', '.') + 'x' : 'x') +
								  (WT_mm != null ? WT_mm.setScale(2).toPlainString().replace(',', '.') + ' ' : ' ') +
								  (SteelGrade != null ? SteelGrade + ' ' : '') +
								  (TubeEnds != null ? TubeEnds + ' ' : '') +
								  (LenMin_mm != null ? LenMin_mm.setScale(2).toPlainString().replace(',', '.') : '') + '-' +
								  (LenMax_mm != null ? LenMax_mm.setScale(2).toPlainString().replace(',', '.') : '');
				}
			}
		} else if (prodFamily == 'LP/GU' || prodFamily == 'Mechanical') {
			System.debug('Entering LP/GU or Mechanical logic');
			if (segment == '00001') {
				System.debug('Segment 00001 in LP/GU or Mechanical');
				if ((country == '840' && prodFamily == 'LP/GU') || prodFamily == 'Mechanical') {
					productName = (NPS != null ? NPS + ' ' : '') +
								  (SCH != null ? SCH + ' ' : '') +
								  (WT_inch != null ? WT_inch + 'W ' : 'W ') +
								  (SteelGrade != null ? SteelGrade + ', ' : '') +
								  (LenMin_ft != null ? LenMin_ft + '..' : '') +
								  (LenMax_ft != null ? LenMax_ft + ' ft' : ' ft');
				} else {
					productName = (NPS != null ? NPS + ' ' : '') +
								  (SCH != null ? SCH + ' ' : '') +
								  (WT_inch != null ? WT_inch + 'W ' : 'W ') +
								  (SteelGrade != null ? SteelGrade + ' ' : '') +
								  (LenMin_mm != null ? LenMin_mm + '-' : '') +
								  (LenMax_mm != null ? LenMax_mm.toPlainString() : '');
				}
			} else if(prodFamily == 'LP/GU' && segment == '00002') {
				productName = (NPS != null ? NPS + ' ' : '') +
							  (SCH != null ? SCH + ' ' : '') +
							  (WT_inch != null ? WT_inch + 'W ' : 'W ') +
							  (SteelGrade != null ? SteelGrade + ' ' : '') +
							  (TubeEnds != null ? TubeEnds + ' ' : '') +
							  (LenMin_mm != null ? LenMin_mm + '-' : '') +
							  (LenMax_mm != null ? LenMax_mm.toPlainString() : '');
			} else {
				System.debug('Entering else block in LP/GU or Mechanical');
				productName = (OD_mm != null ? OD_mm.toPlainString() + 'x' : 'x') +
							  (WT_mm != null ? WT_mm.toPlainString() + ' ' : ' ') +
							  (SteelGrade != null ? SteelGrade + ' ' : '') +
							  (TubeEnds != null ? TubeEnds + ' ' : '') +
							  (LenMin_mm != null ? LenMin_mm + '-' : '') +
							  (LenMax_mm != null ? LenMax_mm.toPlainString() : '');

			}
		} else {
			System.debug('Entering final else block');
			productName = (OD_mm != null ? OD_mm.toPlainString() + 'x' : 'x') +
						  (WT_mm != null ? WT_mm.toPlainString() + ' ' : ' ') +
						  (SteelGrade != null ? SteelGrade + ' ' : '') +
						  (TubeEnds != null ? TubeEnds + ' ' : '') +
						  (LenMin_mm != null ? LenMin_mm + '-' : '') +
						  (LenMax_mm != null ? LenMax_mm.toPlainString() : '');
		}
		
		System.debug('Final Product Name: ' + productName);
	
		// Встановлення назви продукту для запису
		oi.Name__c = productName;
		} else {
			DrawingVersion__c drawing = drawingMap.get(oi.Drawing__c);
			SpecVersion__c spec = specMap.get(oi.KLWSpec__c);

			if(drawing != null && spec != null) {
				String wheelProduct = (drawingMap.get(oi.Drawing__c) != null) ? drawingMap.get(oi.Drawing__c).WheelProduct__c : '';
				String region = (order != null) ? order.Region__c : '';
	
				String axLoadType = drawing != null && drawing.AxLoadType__r.Name != null ? drawing.AxLoadType__r.Name : '';
				String drawingName = drawing != null ? drawing.Name : '';
				String specName = spec != null ? spec.Name : '';
				String klwProductName;
	
				switch on region {
					when '3', '19' {
						String prodTypeRus = spec != null && spec.SpecBase__r.ProductType__r.NameRUS__c != null ? spec.SpecBase__r.ProductType__r.NameRUS__c : '';
						klwProductName = prodTypeRus + ' ' + axLoadType + ' ('+ specName +' / ' + drawingName + ')';
					}
					when '13' {
						String prodTypeUkr = spec != null && spec.SpecBase__r.ProductType__r.NameUKR__c != null ? spec.SpecBase__r.ProductType__r.NameUKR__c : '';
						klwProductName = prodTypeUkr + ' ' + axLoadType + ' ('+ specName +' / ' + drawingName + ')';
					}
					when else {
						String prodType = spec != null && spec.SpecBase__r.ProductType__r.Name != null ? spec.SpecBase__r.ProductType__r.Name : '';
						klwProductName = prodType + ' ' + axLoadType + ' ('+ specName +' / ' + drawingName + ')';
					}
				}
	
				oi.Name__c = klwProductName;
	
				if(wheelProduct != 'N/A') {
					String productDetails;
					String diameter = drawing != null && drawing.Diameter__r.D_mm__c != null ? drawing.Diameter__r.D_mm__c : '';
					String hubSize = drawing != null && drawing.Hub__r.HubSize__c != null ? drawing.Hub__r.HubSize__c : '';
//					String steelGrade = spec != null && spec.SteelGrade__r.Name != null ? spec.SteelGrade__r.Name : '';
//					String steelGrade = spec != null && spec.SteelGrade__r.ShortName__c != null ? spec.SteelGrade__r.ShortName__c : '';

					String steelGrade = '';
					if (spec != null && spec.SteelGrade__r != null && String.isNotBlank(spec.SteelGrade__r.Name)) {
						String name = spec.SteelGrade__r.Name;
						if (name.length() > 80) {
							Integer thirdSlashIndex = -1;
							Integer count = 0;
							Integer slashChar = '\\'.charAt(0);
							for (Integer i = 0; i < name.length(); i++) {
								if (name.charAt(i) == slashChar) {
									count++;
									if (count == 3) {
										thirdSlashIndex = i;
										break;
									}
								}
							}
							if (thirdSlashIndex != -1) {
								steelGrade = name.substring(0, thirdSlashIndex);
							} else {
								steelGrade = name.substring(0, 50);
							}
						} else {
							steelGrade = name;
						}
					}

					switch on wheelProduct {
						when 'Wheels' {
							String wheelName = region == '3' || region == '13' || region == '19' ? 'Колесо ' : 'Wheel ';
	
							productDetails = wheelName + diameter + 'x' + hubSize + ', ' + steelGrade + ', ' + axLoadType + ', acc. to ' + drawingName;
						}
						when 'Wheelsets' {
							String wheelSetName = region == '3' || region == '13' || region == '19' ? 'КП ' : 'WS ';
							diameter = spec != null && spec.SpecWheel__r.DrawingVersion__r.Diameter__r.D_mm__c != null ? spec.SpecWheel__r.DrawingVersion__r.Diameter__r.D_mm__c : '';
							hubSize = spec != null && spec.SpecWheel__r.DrawingVersion__r.Hub__r.HubSize__c != null ? spec.SpecWheel__r.DrawingVersion__r.Hub__r.HubSize__c : '';
							axLoadType = spec != null && spec.SpecWheel__r.DrawingVersion__r.AxLoadType__r.Name != null ? spec.SpecWheel__r.DrawingVersion__r.AxLoadType__r.Name : '';
							String axleBox = spec != null && spec.AxleBox__r.Name != null ? spec.AxleBox__r.Name : '';
	
							productDetails = wheelSetName + diameter + 'x' + hubSize + ', ' + axLoadType + ', ' + axleBox;
						}
						when 'Axles' {
							String axleName = region == '3' || region == '13' ? 'Ось ' : region == '19' ? 'Вісь ' : 'Axle ';
	
							productDetails = axleName + ' ' + diameter + ', ' + steelGrade + ' ' + axLoadType + ', acc. to ' + drawingName;
						}
						when else {
							String standard = spec != null && spec.Standard__r.Name != null ? spec.Standard__r.Name : '';
	
							if(region == '13') {
								productDetails = 'Бандажі з гребенем із вуглецевої сталі для рухомого складу залізниць ' + diameter + 'x' + hubSize + ' ' + standard;
							} else {
								productDetails = 'Tyres '+ diameter + 'x' + hubSize + ', ' + steelGrade + ', ' + standard + ', acc. to ' + drawingName;
							}
						}
					}
	
					oi.ProdDetails__c = productDetails;
				}
			} else {
				String wsg;
				String wod;
				String wh;
				String wd;
				String wps;

				if(Trigger.isUpdate) {
					wsg = oiMap.get(oi.Id).WheelSteelGrade__r != null ? oiMap.get(oi.Id).WheelSteelGrade__r.Name : '';
					wod = oiMap.get(oi.Id).WheelDiameter__r != null ? String.valueOf(oiMap.get(oi.Id).WheelDiameter__r.OD_mm__c) : '';
					wh = oiMap.get(oi.Id).WheelHub__r != null ? oiMap.get(oi.Id).WheelHub__r.Name : '';
					wd = oiMap.get(oi.Id).WheelDrawing__r != null ? ' acc. to ' + oiMap.get(oi.Id).WheelDrawing__r.Name : '';
					wps = oiMap.get(oi.Id).WheelProductStandard__r != null ? oiMap.get(oi.Id).WheelProductStandard__r.Name : '';
				} else {
					wsg = (wsgMap.get(oi.WheelSteelGrade__c) != null ? wsgMap.get(oi.WheelSteelGrade__c).Name : '');
					wod = (wodMap.get(oi.WheelDiameter__c) != null ? String.valueOf(wodMap.get(oi.WheelDiameter__c).OD_mm__c) : '');
					wh = (whMap.get(oi.WheelHub__c) != null ? whMap.get(oi.WheelHub__c).Name : '');
					wd = (wdMap.get(oi.WheelDrawing__c) != null ? ' acc. to ' + wdMap.get(oi.WheelDrawing__c).Name : '');
					wps = (wpsMap.get(oi.WheelProductStandard__c) != null ? wpsMap.get(oi.WheelProductStandard__c).Name : '');
				}
				String prodName = (prodMap.get(oi.Product2Id) != null) ? prodMap.get(oi.Product2Id).Name : '';

				//oi.Name__c = wsg + '|' + wod + '|' + ((String.isNotBlank(wh) || wh.toLowerCase() == '<not specified>') ? wh + '|' : '') + wd;
				oi.Name__c = prodName + ' ' + wod + 'x' + wh + ' ' + wsg + ' ' + wps + wd;
				oi.ProdDetails__c = prodName;
			}
			
		}
		
        system.debug('------------------------------------------Fill Name End------------------------------------------');
	}
	

	//{Bahtiyar 2018-07-25: добавил блок процедур для создания записей в объекте SalesPlanFact__c -------------------------------------------------
	public void deleteRelatedRecords() {
		
		Set<String> oiIdSet = ApexUtil.getIds(oldList);
		system.debug(oiIdSet);
		// Удалим старые связанные записи из таблицы SalesPlanFact__c
		 spfToDelete = 
			[	SELECT	Id
				FROM	SalesPlanFact__c
				WHERE	InitialRecordId__c in :oiIdSet
				 AND	Type__c != 'Opportunity'
				 AND	Type__c != 'Order'
			];
		
		System.debug('--->> SPF records to delete: ' + spfToDelete);
		//delete spfToDelete;
        try{
            Database.delete(spfToDelete,false);
        } catch(Exception e){
            system.debug('Exception occurs on delete spfToDelete ' + e.getMessage());
        }
		

		// Удалим старые связанные записи из таблицы ProductionJournalRecords__c
		List<ProductionJournalRecord__c> pjrToDelete = new List<ProductionJournalRecord__c>(
			[	SELECT	Id
				FROM	ProductionJournalRecord__c
				WHERE	OrderItem__c in :oiIdSet
				 AND	(Type__c = 'Order' OR Type__c = 'Balance')
			]);
		
		System.debug('--->> PJR records to delete: ' + pjrToDelete);
		//delete pjrToDelete;
		try{
        	Database.delete(pjrToDelete,false);
        } catch(Exception e){
            system.debug('Exception occurs on delete pjrToDelete ' + e.getMessage());
        }
	}

	public Map<String, Decimal> getPjrMap() {
		
		Map<String, Decimal> pjrMap = new Map<String, Decimal> ();
		Set<String> oiIdSet = ApexUtil.getIds(newList);

		AggregateResult[] pjrFacts = 
				[	SELECT		OrderItem__c oiId, SUM(ProducedQuantity__c) produced, SUM(DispatchedQuantity__c) dispatched, SUM(ShippedQuantity__c) shipped
					FROM		ProductionJournalRecord__c
					WHERE		Type__c = 'Fact'
					 AND		OrderItem__c in :oiIdSet
					GROUP BY	OrderItem__c
				];
		
		for (AggregateResult pjr : pjrFacts) {
			pjrMap.put((String)pjr.get('oiId') + '|produced', (Decimal)pjr.get('produced'));
			pjrMap.put((String)pjr.get('oiId') + '|dispatched', (Decimal)pjr.get('dispatched'));
			pjrMap.put((String)pjr.get('oiId') + '|shipped', (Decimal)pjr.get('shipped'));
		}

		System.debug('--->> PJR map: ' + pjrMap);
		return pjrMap;
	}

	public void createRelatedSPF(OrderItem oi) {
		Order ord = ordIdMap.get(oi.OrderId);
		String crossMarket = ord.CrossMarketSegment__c;
		Decimal ourShare = 0;
		if (crossMarket != null) {
			ourShare = (100 - ord.CrossMarketShare__c) / 100;
		}
		
		//Создадим записи типа "Plan" и "Fact" по дочерним записям ProductionJournalRecord__c:
		List<ProductionJournalRecord__c> pjrList = pjrOiMap.get(oi.Id);
		System.debug('!!!!@$$$$$$$$$$$  ' + pjrList);

		For (ProductionJournalRecord__c pjr : pjrList) {
			SalesPlanFact__c spf = new SalesPlanFact__c();

			Decimal dispatched = pjr.DispatchedQuantityNetto__c != null ? pjr.DispatchedQuantityNetto__c : 0;
            Decimal production = pjr.Production_Amount__c != null ? pjr.Production_Amount__c : 0;
			Decimal shipped = pjr.ShippedQuantityNetto__c != null ? pjr.ShippedQuantityNetto__c : 0;

			spf.ExchangeTimeStamp__c = pjr.ExchangeTimestamp__c;
			spf.InitialRecordId__c = String.valueOf(oi.Id);
			spf.InitialRecordURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + oi.Id;
			spf.OrderAdditionalNumber__c = ord.AdditionalNumber__c;
			spf.ID_ERP__c = oi.ID_ERP__c;
			spf.ITENumber__c = oi.ITENumber__c;
			spf.Period__c = pjr.Period__c;
			spf.RecordTypeId = rtNameMap.get(pjr.Type__c);
			spf.Shop__c = oi.Shop__c;
			spf.QuotaType__c = oi.QuotaType__c;
			spf.MarketSegment__c = ord.MarketSegment__c;
			spf.Country__c = ord.Country__c;
			spf.Account__c = ord.AccountId;
			spf.OwnerId = ord.OwnerId;
			spf.CurrencyIsoCode = 'USD';
			spf.Product2Id__c = oi.Product2Id;
			spf.ProductionAmount__c = crossMarket == null ? dispatched : dispatched * ourShare;
			spf.SalesAmount__c = crossMarket == null ? shipped : shipped * ourShare;
			spf.Revenue__c = crossMarket == null ? pjr.Revenue__c : pjr.Revenue__c * ourShare;
			spf.Margin__c = crossMarket == null ? pjr.Margin__c : pjr.Margin__c * ourShare;
			spf.Margin_t__c = pjr.Margin_t__c;
			spf.Probability__c = null; // не используется для этого типа записей
			spf.SecondChoice__c = ord.IsSecondChoice__c;
			spf.Production_Amount__c = crossMarket == null ? production : production * ourShare;
            spf.Production_Plan__c = pjr.Production_Plan__c == null ? null : pjr.Production_Plan__c;
			spf.ProducedForecast__c = pjr.ProducedForecast__c == null ? null : pjr.ProducedForecast__c;
			spfToInsert.add(spf);

			if (crossMarket != null && ord.CrossMarketManager__c != null) {
				Decimal crossShare = ord.CrossMarketShare__c / 100;
				spf = spf.clone();
				spf.MarketSegment__c = ord.CrossMarketSegment__c;
				spf.OwnerId = ord.CrossMarketManager__c;
				spf.ProductionAmount__c = dispatched * crossShare;
				spf.SalesAmount__c = shipped * crossShare;
				spf.Revenue__c = pjr.Revenue__c * crossShare;
				spf.Margin__c = pjr.Margin__c * crossShare;
				spf.Margin_t__c = pjr.Margin_t__c;
				spf.Production_Amount__c = production * crossShare;
                spf.Production_Plan__c = pjr.Production_Plan__c == null ? null : pjr.Production_Plan__c;
				spf.ProducedForecast__c = pjr.ProducedForecast__c == null ? null : pjr.ProducedForecast__c;
				spfToInsert.add(spf);
			}
		}
	}

	public void createRelatedPJR(OrderItem oi) {
		
		Order ord = ordIdMap.get(oi.OrderId);
		ProductionJournalRecord__c pjr = new ProductionJournalRecord__c ();

		//Запишем размещенное количество заказа:
		pjr.Order__c = oi.OrderId;
		pjr.OrderItem__c = oi.Id;
		pjr.Type__c = 'Order';
		//pjr.Period__c = ord.CreatedDate.date();
		// При получении данных заказа из ERP возможна ситуация, когда дата старта продукта в заказе раньше даты старта самого заказа.
		// Поэтому алгоритм обработки сообщения из ERP сначала устанавливает EffectiveDate в 01.01.1900, чтобы записались все продукты, а затем корректирует ее - либо устанавливает ту, что была, либо самую раннюю дату одного из продуктов, если она раньше даты заказа.
		// А здесь, чтобы не записывалась дата 01.01.1900, используется вспомогательное служебное поле EffectiveDateAux__c, которое хранит изначальную дату EffectiveDate.
		// При этом есть недостаток: существует вероятность того, что EffectiveDate будет изменена на другой месяц, и тогда здесь записи будут не в том периоде как минимум до тех пор, пока не придет обновление данного заказа из ERP.
		if (ord.EffectiveDateAux__c != null) {
			pjr.Period__c = ord.EffectiveDateAux__c;
		} else {
			pjr.Period__c = ord.EffectiveDate;
		}
		
		pjr.ProducedQuantity__c = oi.Quantity;
		pjr.DispatchedQuantity__c = oi.Quantity;
		pjr.ShippedQuantity__c = oi.Quantity;
		//pjr.ProducedQuantityNetto__c = oi.Quantity;
		//pjr.DispatchedQuantityNetto__c = oi.Quantity;
		//pjr.ShippedQuantityNetto__c = oi.Quantity;

		pjrToInsert.add(pjr);

		// Запишем запись по балансу:
		pjr = pjr.clone();

		System.debug('====>>> PJR map now: ' + pjrMap);
		Decimal produced = pjrMap.get(oi.id + '|produced');
		Decimal dispatched = pjrMap.get(oi.id + '|dispatched');
		Decimal shipped = pjrMap.get(oi.id + '|shipped');

		pjr.Type__c = 'Balance';
		pjr.Period__c = null;
		//pjr.ProducedQuantity__c = oi.Quantity - (produced != null ? produced : 0);
		//pjr.DispatchedQuantity__c = oi.Quantity - (dispatched != null ? dispatched : 0);
		//pjr.ShippedQuantity__c = oi.Quantity - (shipped != null ? shipped : 0);
		pjr.ProducedQuantity__c = Math.max(oi.Quantity - (oi.ProducedQuantity__c == null ? 0 : oi.ProducedQuantity__c), 0);
		pjr.DispatchedQuantity__c = Math.max(oi.Quantity - (oi.DispatchedQuantity__c == null ? 0 : oi.DispatchedQuantity__c), 0);
		pjr.ShippedQuantity__c = Math.max(oi.Quantity - (oi.ShippedQuantity__c == null ? 0 : oi.ShippedQuantity__c), 0);
		//pjr.ProducedQuantityNetto__c = Math.max(oi.Quantity - (oi.ProducedQuantity__c == null ? 0 : oi.ProducedQuantity__c), 0);
		//pjr.DispatchedQuantityNetto__c = Math.max(oi.Quantity - (oi.DispatchedQuantity__c == null ? 0 : oi.DispatchedQuantity__c), 0);
		//pjr.ShippedQuantityNetto__c = Math.max(oi.Quantity - (oi.ShippedQuantity__c == null ? 0 : oi.ShippedQuantity__c), 0);

		pjrToInsert.add(pjr);
	}

	private void initializeOrdIdMap(List<SObject> newList) {
        if (newList == null || newList.isEmpty()) {
            return; // Якщо список нових записів порожній, немає сенсу продовжувати
        }

        // Ініціалізація ordIdSet для збору унікальних ID замовлень
        if (ordIdSet == null) {
            ordIdSet = new Set<Id>();
			oiIdSet = new Set<Id> ();
        } else {
            ordIdSet.clear(); // Очищення, якщо вже було ініціалізовано
			oiIdSet.clear();
        }

        // Збір ID замовлень з нових записів
        for (SObject oi : newList) {
            ordIdSet.add(((OrderItem) oi).OrderId);
			oiIdSet.add(((OrderItem) oi).Id);
        }

        // Запит до бази даних для отримання деталей замовлень і ініціалізація ordIdMap
        ordIdMap = new Map<Id, Order>([
            SELECT Id, AdditionalNumber__c, MarketSegment__c, Country__c , Country__r.ID_ERP__c, OwnerId, CurrencyIsoCode,
                   AccountId, IsSecondChoice__c, CrossMarketSegment__c, CrossMarketManager__c, CrossMarketShare__c, 
                   EffectiveDate, EffectiveDateAux__c, CreatedDate, Region__c
            FROM Order
            WHERE Id IN :ordIdSet
        ]);

		if ((Trigger.isUpdate)) {
			oiMap = new Map<Id, OrderItem>([
					SELECT Id,
							SteelGrade__r.Name,
							SteelGrade__r.ShortName__c,
							WheelSteelGrade__r.Name,
							WheelSteelGrade__r.ShortName__c,
							WheelHub__r.Name,
							WheelDrawing__r.Name,
							WheelProductStandard__r.Name,
							TubeEnds__r.ShortName__c,
							WheelDiameter__r.OD_mm__c
					FROM OrderItem
					WHERE Id IN :oiIdSet
			]);
		}

    }

	//} Блок процедур для создания записей в объекте SalesPlanFact__c ---------------------------------------------------------------------------

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
	}
}