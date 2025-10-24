public without sharing class FilesDatatableController {

@AuraEnabled(cacheable=true)
public static List<ContentDocumentLink> getFiles(){
    try {
        String userId = UserInfo.getUserId();
        List<ContentDocument> conDoc = [SELECT Title, id,ContentModifiedDate, OwnerId, ContentSize FROM ContentDocument WHERE OwnerId =:userId];
        List<ContentDocumentLink> conLink =[SELECT ContentDocumentId, ContentDocument.Title, 
                                                    ContentDocument.Owner.Name, 
                                                    ContentDocument.ContentModifiedDate,
                                                    ContentDocument.ContentSize, LinkedEntityId
                                            FROM ContentDocumentLink 
                                            WHERE ContentDocumentId in:conDoc
                                            AND LinkedEntityId =:userId ORDER BY ContentDocument.ContentModifiedDate desc];
        system.debug(conLink);
        return conLink;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled(cacheable=false)
public static String viewFile(String cdl){
    try {
        Id contentDocId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE id =:cdl LIMIT 1].ContentDocumentId;
        List<ContentVersion> cv = [SELECT id, PathOnClient, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =:contentDocId ];

        ContentDistribution cd = new ContentDistribution();
            cd.PreferencesNotifyOnVisit = false;
            cd.ContentVersionId = cv[0].Id;
            cd.Name = cv[0].PathOnClient;
            cd.PreferencesAllowViewInBrowser = true;
            insert cd;

            return [SELECT DistributionPublicUrl FROM ContentDistribution WHERE Id =: cd.Id].DistributionPublicUrl;
        
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
	public static void deleteRelatedFile(String docId) {
		try {		
            system.debug(docId);
            List<ContentDocument> listToDelete = new List<ContentDocument>();
            List<ContentDocument> cdList = [SELECT Id FROM ContentDocument where Id = :docId];              
            Database.delete(cdList,false);
			System.debug('file has been deleted');		
		} catch(DMLException e) {
			System.debug('DMLException: ' + e.getMessage());
			
		}
	} 

    @AuraEnabled
    public static String uploadFile(String files) {
        // Decoding the base64Data
        
        List<Object> filesSf = (List<Object>) JSON.deserializeUntyped(files);
        
        for(Object file : filesSf){
            Map<String,Object> getFile = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(file));
            system.debug(getFile);           
            String fileName = String.valueof(getFile.get('name'));
            String base64Data = String.valueof(getFile.get('base64'));  
            system.debug(base64Data);
    
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient =fileName;
            cv.Origin = 'H';
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            Insert cv;
           
        }                	
        return 'File upload successfully!';
    }
}