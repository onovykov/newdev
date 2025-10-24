public class FalseSynchroService {
    public static void createFalseSynchroRecord(String methodName,String jsonText,String idRecord){
        False_Synchronization__c falseSynchroRecord = new False_Synchronization__c();
        falseSynchroRecord.Json_Text__c = jsonText;
        falseSynchroRecord.Method_name__c = methodName; 
        falseSynchroRecord.Record_id__c = idRecord;
        insert falseSynchroRecord;
    }
}