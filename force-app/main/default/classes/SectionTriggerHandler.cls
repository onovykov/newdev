public class SectionTriggerHandler extends TriggerHandler implements ITrigger {
    public static Map<Id, Questionnaire__c> QuestionnaireMap;

    public SectionTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public void bulkBefore() {
		System.debug('bulkBefore Section');
		if(!Trigger.isDelete) {
			getQuestionnaireMap(newList);
		}
	}
	
	public void bulkAfter() {
		System.debug('bulkAfter Section');
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert Section');
        checkQuestionnaireStatus(so);
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate Section');
		checkQuestionnaireStatus(so);
	}

	public void beforeDelete(SObject so) {
		System.debug('beforeDelete Section');
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert Section');
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate Section');
	}

	public void afterDelete(SObject so) {
		System.debug('AfterDelete Section');
	}

	public void postProcessing() {
		System.debug('PostProcessing Section');
	}

    private void getQuestionnaireMap(List<SObject> newList) {
        Set<Id> questionnaireIdSet = new Set<Id>();
        for(SObject question : newList) {
            questionnaireIdSet.add(((Section__c) question).Questionnaire__c);
        }
        QuestionnaireMap = new Map<Id, Questionnaire__c>([SELECT Id, Status__c FROM Questionnaire__c WHERE Id IN :questionnaireIdSet]);
    }

    private void checkQuestionnaireStatus(SObject so) {
        Section__c newSection = (Section__c)so;
        if(QuestionnaireMap.get(newSection.Questionnaire__c).Status__c == 'Sent') {
            newSection.addError('Section with Sent Questionnaire can not be created/updated.');
        }
    }
}