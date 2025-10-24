public class SalesBudgetRecordTriggerHandler extends TriggerHandler implements ITrigger {
		
	static Map<String, Id> sbrRtMap = new Map<String, Id>();
	static Map<String, Id> spfRtMap = new Map<String, Id>();
	List<Id> sbIdList = new List<Id>();
	Map<Id, SalesBudget__c> sbMap;
	List<SalesPlanFact__c> spfToInsert = new List<SalesPlanFact__c>();
	List<String> existingCorBudgetList;

	
	
	public SalesBudgetRecordTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	
	
	public void bulkBefore() {
		System.debug('bulkBefore');
		
		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
			// Сформируем мапу рекорд тайпов:
			for (RecordType rt :	[	SELECT	Id, SobjectType, DeveloperName
										FROM	RecordType
										WHERE	SobjectType = 'SalesBudgetRecord__c' OR SobjectType = 'SalesPlanFact__c'
									]){
				if (rt.SobjectType == 'SalesBudgetRecord__c') {
					sbrRtMap.put(rt.DeveloperName, rt.Id);
				} else {
					spfRtMap.put(rt.DeveloperName, rt.Id);
				}
			}
		}
		
		
		// Удалим все связанные записи из таблицы SalesPlanFact__c
		if (oldList != null) {
			deleteRelatedSPF();
		}
	}

	
	
	public void beforeInsert(SObject so) {
		System.debug('beforeInsert SalesBudgetRecord');
		setPeriod((SalesBudgetRecord__c) so);
	}
	
	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate SalesBudgetRecord');
		setPeriod((SalesBudgetRecord__c) so);
	}
		
	public void beforeDelete(SObject so) {
		System.debug('beforeDelete SalesBudgetRecord');
	}


	
	public void bulkAfter() {
		System.debug('bulkAfter SalesBudgetRecord');

		if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
			existingCorBudgetList = getExistingCorBudgetList();

			//Сформируем список соответствий, для мастер-объектов SalesBudget, чтоб потом считывать значения их полей.
			for (sObject sbr : newList) {
				sbIdList.add(((SalesBudgetRecord__c) sbr).SalesBudget__c);
			}
			sbMap = New Map<Id,SalesBudget__c>([select Id, Type__c, Approved__c from SalesBudget__c where Id In :sbIdList]);
		}
        
        if(Trigger.isInsert){
           // if (Test.isRunningTest()) {
           // Set<id> sbrIds = newMap.keyset();
           // ProductionQuoteCreateBatch pqcb = new ProductionQuoteCreateBatch(sbrIds);
			//Id aruId = Database.executeBatch(pqcb);
           // }    
            /*
            SalesBudgetRecord__c sbr = (SalesBudgetRecord__c) newList[0];
            String sbrQuotaType = sbr.QuotaType__c;
            String sbrMarketSegment = sbr.MarketSegment__c;
            Date sbrPeriod = sbr.Period__c;
            Decimal sbrProductionAmount = sbr.Production_Amount__c;
            String sbrSaleManager = sbr.SalesManager__c;
            String sbrProduct = sbr.Product__c;
            List<OpportunityLineItem> oppItemList = [SELECT id,Opportunity.id FROM OpportunityLineItem WHERE Product2Id=:sbrProduct 
                                                     AND Opportunity.OwnerId =:sbrSaleManager AND Opportunity.MarketSegment__c =:sbrMarketSegment
                                                    AND QuotaType__c =:sbrQuotaType]; 
            system.debug(oppItemList);
            String oppId = oppItemList[0].Opportunity.id;
            Shop_Quota__c sq = [SELECT Id FROM Shop_Quota__c WHERE Opportunity__c=:oppId AND Quota_Type__c=:sbrQuotaType];
            Production_Quota__c pq = new Production_Quota__c();
            pq.Quota_Type__c = sbrQuotaType;
            pq.Market_Segment__c = sbrMarketSegment;
            pq.Period__c = sbrPeriod;
            pq.Production_Amount_t__c = sbrProductionAmount;
            pq.Sales_Manager__c = sbrSaleManager;
            pq.Product__c = sbrProduct;
            pq.Shop_Quota__c = sq.id;
            pq.Opportunity_Product__c = oppItemList[0].id;
            insert pq;*/
        }
	}

	
			
	public void afterInsert(SObject so) {
		System.debug('afterInsert SalesBudgetRecord');

		createRelatedSPF((SalesBudgetRecord__c) so);
	}
		
	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate SalesBudgetRecord');

		createRelatedSPF((SalesBudgetRecord__c) so);
	}
	
	public void afterDelete(SObject so) {
		System.debug('After Delete');
	}

	
	
	public void postProcessing() {
		System.debug('Post Processing');
		
		// Запишем созданные записи в объекте SalesPlanFact__c
		insert spfToInsert;        
}

	
	
	public void setPeriod(SalesBudgetRecord__c sbr) {
		
		if (sbr.RecordTypeId == sbrRtMap.get('PlanMonth')) {
			sbr.Period__c = Date.newInstance((Integer)sbr.PeriodYear__c, Integer.valueOf(sbr.PeriodMonth__c), 1);
		} else {
			if (sbr.PeriodQuarter__c == '1') {
				sbr.Period__c = Date.valueOf(String.valueOf(sbr.PeriodYear__c) + '-01-01');
			} else if (sbr.PeriodQuarter__c == '2') {
				sbr.Period__c = Date.valueOf(String.valueOf(sbr.PeriodYear__c) + '-04-01');
			} else if (sbr.PeriodQuarter__c == '3') {
				sbr.Period__c = Date.valueOf(String.valueOf(sbr.PeriodYear__c) + '-07-01');
			} else if (sbr.PeriodQuarter__c == '4') {
				sbr.Period__c = Date.valueOf(String.valueOf(sbr.PeriodYear__c) + '-10-01');
			}
		}
	}

	
	
	public List<String> getExistingCorBudgetList() {
		
		// В этой мапу соберем существующие кор. бюджеты за интересующий нас период. Ключ к периоду в формате 'YYYY|<BudgetType>' (например: '2018|Q2')
		List<String> corBudgetList = new List<String>();

		// Cначала составим список годов, которые нас интересуют:
		List<Decimal> yearList = new List<Decimal>();
		for (SObject sbr : newMap.values()) {
			yearList.add(((SalesBudgetRecord__c)sbr).PeriodYear__c);
		}
		// Теперь получим все кор. бюджеты за эти года:
		List<SalesBudget__c> budgets = 
				[	Select Year__c, Type__c
					FROM SalesBudget__c
					WHERE Year__c in :yearList
					 AND Type__c != 'Y'
					 AND Approved__c = true
				];

		//И сформируем требуемую мапу:
		for (SalesBudget__c budget : budgets) {
			switch on budget.Type__c {
				when 'HY1' {
					corBudgetList.add(budget.Year__c + '|' + 'Q1');
					corBudgetList.add(budget.Year__c + '|' + 'Q2');
				}
				when 'HY2' {
					corBudgetList.add(budget.Year__c + '|' + 'Q3');
					corBudgetList.add(budget.Year__c + '|' + 'Q4');
				}
				when else {
					corBudgetList.add(budget.Year__c + '|' + budget.Type__c);
				}
			}
		}

		return corBudgetList;
	}
	

	public void deleteRelatedSPF() {
		
		// Соберем список текстовых Id, который будем использовать для фильтрации запроса
		List<String> textIdList = New List<String>();
		For (Integer i = 0; i < oldList.size(); i++) {
			textIdList.add(oldList[i].Id);
		}
		
		// Удалим старые связанные записи из таблицы SalesPlanFact__c
		delete [Select Id, InitialRecordId__c from SalesPlanFact__c where InitialRecordId__c in :textIdList];
	
	}

	
	
	public void createRelatedSPF(SalesBudgetRecord__c sbr) {
		
		if (sbMap.get(sbr.SalesBudget__c).Approved__c) {
			if (sbr.RecordTypeId == sbrRtMap.get('PlanMonth')) {
				//Месячный план просто запишем, как есть
				mapSPFFields(sbr, sbr.Period__c);
			} else {
				//Квартальный план разнесем на три месяца (поделив числовые значения на 3)
				for(Integer i = 0; i < 3; i++) {
					System.debug('---- sbr.Period: ' + sbr.period__c);
					mapSPFFields(sbr, sbr.Period__c.addMonths(i));
				}
			}
		}
	}


	public void mapSPFFields(SalesBudgetRecord__c sbr, Date sbrPeriod) {
		system.debug('map spf field');
		SalesPlanFact__c spf = new SalesPlanFact__c();
		String sbType = sbMap.get(sbr.SalesBudget__c).Type__c;
		Id sbId = sbMap.get(sbr.SalesBudget__c).Id;
		Id rtPlanMonthId = sbrRtMap.get('PlanMonth');
	
		// Сделаем запись типа Initial Budget или Corrected Budget
		spf.InitialRecordId__c = String.valueOf(sbr.Id);
		spf.InitialRecordURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sbr.Id;
		spf.Sales_Budget_Record__c = String.valueOf(sbr.Id);
		spf.Period__c = sbrPeriod;
		spf.RecordTypeId = sbType == 'Y' ? spfRtMap.get('InitialBudget') : spfRtMap.get('CorrectedBudget');
		setSpfData(spf,sbr, rtPlanMonthId);
		if(sbr.Period__c.month()<4 && sbType == 'Y'){
		  SalesPlanFact__c spfYearCorrected = spf.clone(false,false,false,false);
		  spfYearCorrected.RecordTypeId = spfRtMap.get('CorrectedBudget');
		  spfToInsert.add(spfYearCorrected);
		}
			
		spfToInsert.add(spf);
	
		// При необходимости сделаем запись типа Actual Budget:
		Boolean needABRecord = true;
		if (sbType == 'Y') {
		  //Если это initial budget, то запись нужно делать только при отсутствии кор. бюджета за этот квартал.
		  String sbrType;
		  switch on sbr.Period__c.month() {
			when 1, 2, 3 {
			  sbrType = 'Q1';
			}
			when 4, 5, 6 {
			  sbrType = 'Q2';
			}
			when 7, 8, 9 {
			  sbrType = 'Q3';
			}
			when 10, 11, 12 {
			  sbrType = 'Q4';
			}
		  }
		  String key = sbr.PeriodYear__c + '|' + sbrType;
		  if (existingCorBudgetList.contains(key)) {
			needABRecord = false;
		  }
		}
	
		if (needABRecord) {
		  spf = spf.clone();
		  spf.RecordTypeId = spfRtMap.get('ActualBudget');
		  spfToInsert.add(spf);
		}
	  }
	
	  public void setSpfData(SalesPlanFact__c spf,SalesBudgetRecord__c sbr, String rtPlanMonthId){
		spf.Shop__c = sbr.Shop__c;
		spf.MarketSegment__c = sbr.MarketSegment__c;
		spf.Region__c = sbr.Region__c;
		spf.Country__c = sbr.Country__c;
		spf.Account__c = sbr.Account__c;
		spf.OwnerId = sbr.SalesManager__c;
		spf.CurrencyIsoCode = 'USD';
		spf.Product2Id__c = sbr.Product__c;
			//dispathed amount field
		spf.ProductionAmount__c = sbr.ProductionAmount__c == null ? 0 : sbr.RecordTypeId == rtPlanMonthId ? sbr.ProductionAmount__c : sbr.ProductionAmount__c / 3;
			//production amount field
			spf.Production_Amount__c = sbr.Production_Amount__c == null ? 0 : sbr.RecordTypeId == rtPlanMonthId ? sbr.Production_Amount__c : sbr.Production_Amount__c / 3;
		spf.SalesAmount__c = sbr.SalesAmount__c == null ? 0 : sbr.RecordTypeId == rtPlanMonthId ? sbr.SalesAmount__c : sbr.SalesAmount__c / 3;
		spf.Revenue__c = sbr.Revenue__c == null ? 0 : sbr.RecordTypeId == rtPlanMonthId ? sbr.Revenue__c : sbr.Revenue__c / 3;
		spf.Margin__c = sbr.Margin__c == null ? 0 : sbr.RecordTypeId == rtPlanMonthId ? sbr.Margin__c : sbr.Margin__c / 3;
		spf.Margin_t__c = sbr.Margin_t__c;
		spf.QuotaType__c = sbr.QuotaType__c;
		
	  }
}