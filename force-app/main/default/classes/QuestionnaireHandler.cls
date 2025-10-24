public class QuestionnaireHandler extends TriggerHandler implements ITrigger {

    public QuestionnaireHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public void bulkBefore() {
		System.debug('bulkBefore Questionnaire');
	}
	
	public void bulkAfter() {
		System.debug('bulkAfter Questionnaire');
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert Questionnaire');
	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate Questionnaire');
        
		Questionnaire__c oldQuestionnaire = (Questionnaire__c)oldSo;
		Questionnaire__c newQuestionnaire = (Questionnaire__c)so;

        if(oldQuestionnaire.Status__c == 'Sent') {
            newQuestionnaire.addError('Questionnaire with Sent status can not be updated.');
        }
	}

	public void beforeDelete(SObject so) {
		System.debug('beforeDelete Questionnaire');
	}

	public void afterInsert(SObject so) {
		System.debug('afterInsert Questionnaire');
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate Questionnaire');
	}

	public void afterDelete(SObject so) {
		System.debug('AfterDelete Questionnaire');
	}

	public void postProcessing() {
		System.debug('PostProcessing Questionnaire');
	}
}