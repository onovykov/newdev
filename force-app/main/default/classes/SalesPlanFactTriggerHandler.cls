public class SalesPlanFactTriggerHandler extends TriggerHandler implements ITrigger {
		
	Map<Id, RecordType> rtMap;
	
	
	public SalesPlanFactTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	
	
	public void bulkBefore() {
		System.debug('bulkBefore SalesPlanFact');

		if (Trigger.isInsert || Trigger.isUpdate) {
			// Сформируем список соответствий рекорд тайпов объекта SalesPlanFact__c
			rtMap = new Map<Id, RecordType>([select Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'SalesPlanFact__c']);
		}
	}

	
	
	public void beforeInsert(SObject so) {
		//System.debug('beforeInsert SalesPlanFact');
		
		setType((SalesPlanFact__c) so);
	}
	
	public void beforeUpdate(SObject oldSo, SObject so) {
		//System.debug('beforeUpdate SalesPlanFact');
		
		setType((SalesPlanFact__c) so);
	}
		
	public void beforeDelete(SObject so) {
		//System.debug('beforeDelete SalesPlanFact');
	}


	
	public void bulkAfter() {
		//System.debug('bulkAfter SalesPlanFact');
	}

	
			
	public void afterInsert(SObject so) {
		//System.debug('afterInsert SalesPlanFact');
	}
		
	public void afterUpdate(SObject oldSo, SObject so) {
		//System.debug('afterUpdate SalesPlanFact');
	}
	
	public void afterDelete(SObject so) {
		//System.debug('afterDelete SalesPlanFact');
	}

	
	
	public void postProcessing() {
		//System.debug('postProcessing SalesPlanFact');
	}

	
	// Пиклист Type__с дублирует значения Record Type, для того чтоб в отчетах данные выводились именно в том порядке, как в пиклисте
	public void setType(SalesPlanFact__c spf) {
		String rtDevName = rtMap.get(spf.RecordTypeId).DeveloperName;

		switch on rtDevName {
			when 'InitialBudget' {
				spf.Type__c = 'Initial Budget';
			}
			when 'CorrectedBudget' {
				spf.Type__c = 'Corrected Budget';
			}
			when 'ActualBudget' {
				spf.Type__c = 'Actual Budget';
			}
			when 'Opportunity' {
				spf.Type__c = 'Opportunity';
			}
			when 'Order' {
				spf.Type__c = 'Order';
			}
			when 'Plan' {
				spf.Type__c = 'Plan';
			}
			when 'Fact' {
				spf.Type__c = 'Fact';
			}
		}
	}
}