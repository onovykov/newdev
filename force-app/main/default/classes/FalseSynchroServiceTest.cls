@isTest
private class FalseSynchroServiceTest {
	@IsTest
	public static void createFalseSynchroRecordTest() {
        FalseSynchroService.createFalseSynchroRecord('test name','test data','testid'); 
        List<False_Synchronization__c> fsList = [SELECT id FROM False_Synchronization__c];
		System.assertEquals(1, fsList.size());
	}
}