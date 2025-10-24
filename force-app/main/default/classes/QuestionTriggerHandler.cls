public class QuestionTriggerHandler extends TriggerHandler implements ITrigger {
    public static Map<Id, Questionnaire__c> QuestionnaireMap;

    public QuestionTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public void bulkBefore() {
		System.debug('bulkBefore Question');
        getQuestionnaireMap(newList);
	}
	
	public void bulkAfter() {
		System.debug('bulkAfter Question');
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert Question');
        checkQuestionnaireStatus(so);
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate Question');
		checkQuestionnaireStatus(so);
	}

	public void beforeDelete(SObject so) {
		System.debug('beforeDelete Question');
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert Question');
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate Question');
	}

	public void afterDelete(SObject so) {
		System.debug('AfterDelete Question');
	}

	public void postProcessing() {
		System.debug('PostProcessing Question');
	}

    private void getQuestionnaireMap(List<SObject> newList) {
        Set<Id> questionnaireIdSet = new Set<Id>();
        for(SObject question : newList) {
            questionnaireIdSet.add(((Question__c) question).Questionnaire__c);
        }
        QuestionnaireMap = new Map<Id, Questionnaire__c>([SELECT Id, Status__c FROM Questionnaire__c WHERE Id IN :questionnaireIdSet]);
    }

    private void checkQuestionnaireStatus(SObject so) {
        Question__c newQuestion = (Question__c)so;
        if(QuestionnaireMap.get(newQuestion.Questionnaire__c).Status__c == 'Sent') {
            newQuestion.addError('Question with Sent Questionnaire can not be created/updated.');
        }
    }
}