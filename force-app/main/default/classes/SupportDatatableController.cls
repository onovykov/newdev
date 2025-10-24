public with sharing class SupportDatatableController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getCases(){
        try {
            String userId = UserInfo.getUserId();
            String idContactUser = [SELECT Contactid FROM User WHERE Id=:userId LIMIT 1].contactid;
            system.debug(idContactUser);
            return [SELECT Id,Subject,Status,CreatedDate,Status_Date__c,Owner.Email FROM Case WHERE ContactId=:idContactUser ORDER BY CreatedDate DESC];  
            //return [SELECT Id,Subject,Status,CreatedDate,Status_Date__c,Owner.Email FROM Case ORDER BY CreatedDate DESC LIMIT 3];  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Case getCase(String caseId){
        try {
            String userId = UserInfo.getUserId();
            String idContactUser = [SELECT Contactid FROM User WHERE Id=:userId LIMIT 1].contactid;
            system.debug(idContactUser);
            return [SELECT Id,Subject,Status,CreatedDate,Status_Date__c,Description,CaseNumber FROM Case WHERE ContactId=:idContactUser AND id=:caseId  LIMIT 1];  
            //return [SELECT Id,Subject,Status,CreatedDate,Status_Date__c,Owner.Email FROM Case ORDER BY CreatedDate DESC LIMIT 3];  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=false)
	public static List<ContentDocumentLink> getCaseFiles(String caseId){
    try {
        String userId = UserInfo.getUserId();
        List<ContentDocument> conDoc = [SELECT Title, id,ContentModifiedDate, OwnerId, ContentSize FROM ContentDocument WHERE OwnerId =:userId];
        List<ContentDocumentLink> conLink =[SELECT ContentDocumentId, ContentDocument.Title, 
                                                    ContentDocument.Owner.Name, 
                                                    ContentDocument.ContentModifiedDate,
                                                    ContentDocument.ContentSize, LinkedEntityId
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId in 
                                                    (SELECT Id FROM Case WHERE id=:caseId) //reclamation Id
                                                     AND ContentDocumentId in:conDoc];
        system.debug(conLink);
        return conLink;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
}