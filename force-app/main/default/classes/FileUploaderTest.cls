public without sharing class FileUploaderTest {
	@AuraEnabled
    public static String uploadFile(String files, Id recordId,String caseData) {
        // Decoding the base64Data
        
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(caseData);
        
        String userName = String.valueOf(data.get('userName'));        
        String theme = String.valueOf(data.get('theme'));
        String description =String.valueOf(data.get('description'));
        String phoneNumber = String.valueOf(data.get('userNumber')); 
        String email = String.valueOf(data.get('email')); 
        
        String userId = UserInfo.getUserId();
        String idContactUser = [SELECT Contactid FROM User WHERE Id =: userId LIMIT 1].contactid;
        String accId = [SELECT id, AccountId FROM Contact WHERE id =: idContactUser LIMIT 1].AccountId;
        String segment = [SELECT id, MarketSegment__c FROM Account WHERE id =:accId].MarketSegment__c;
        String managerId = [SELECT Id, ManagerId, AssignedBOS__r.id FROM User WHERE id =:userId].ManagerId;
        String assignedBOId = [SELECT Id, ManagerId, AssignedBOS__r.id FROM User WHERE id =:userId].AssignedBOS__r.id;

        system.debug('!!!!!!!!!' + managerId);
        system.debug('!!!!!!!!!' + assignedBOId);


        Case newCase = new Case();
        if(segment == '00001'){
            newCase.OwnerId = managerId;     
        }else {
            newCase.OwnerId = assignedBOId;     
        }
        newCase.AccountId = accId;
        newCase.ContactId = idContactUser;

        newCase.Description = description;
        newCase.Subject = theme;     
        newCase.Origin = 'Customer Support';
        insert newCase;
        String returnedId = newCase.id;
        
        system.debug(files);
        List<Object> filesSf = (List<Object>) JSON.deserializeUntyped(files);
        system.debug(filesSf);
        for(Object file : filesSf){
            Map<String,Object> getFile = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(file));
            system.debug(getFile.get('name'));
            system.debug(String.valueof(getFile.get('base64')));
            
            String fileName = String.valueof(getFile.get('name'));
            String base64Data = String.valueof(getFile.get('base64'));
            
            
            system.debug('FileUploaderTest');
            //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.FirstPublishLocationId = returnedId;
            cv.Origin = 'H';
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            Insert cv;
            
        }                	
        return 'File upload successfully!';
    }
    
    @AuraEnabled(cacheable=true)
    public static User fetchUserData(){
        String userId = UserInfo.getUserId();        
        User currentUser = [SELECT name,manager.profileid,manager.FirstName,manager.LastName,managerid,manager.Email,Phone,email FROM user WHERE id=:userId LIMIT 1];
        return currentUser;
    }
    
    @AuraEnabled
    public static string setUserPhone(String phone){
        try {
            String userId = UserInfo.getUserId();
            update new User (
                Id = userId, Phone = phone
            );
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String uploadFileReclamation(String files, Id recordId) {
        // Decoding the base64Data
        
        List<Object> filesSf = (List<Object>) JSON.deserializeUntyped(files);
        
        for(Object file : filesSf){
            Map<String,Object> getFile = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(file));
            system.debug(getFile);           
            String fileName = String.valueof(getFile.get('name'));
            String base64Data = String.valueof(getFile.get('base64'));  
            system.debug(base64Data);
            
            //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient =fileName;
            cv.FirstPublishLocationId = recordId;
            cv.Origin = 'H';
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            //cv.VersionData = blob.valueof(base64Data);
            cv.IsMajorVersion = true;
            Insert cv;
           /* 
            String jsonStr = '<Base64 String>';
            Attachment attach = new Attachment();
            attach.contentType = 'image/jpeg';
            attach.name = fileName;
            attach.parentId = recordId;
            attach.body = EncodingUtil.base64Decode(base64Data);
            insert attach;
            Attachment attach1 = [SELECT Id, Name, Body, ContentType, ParentId,OwnerId From Attachment WHERE id=:attach.id LIMIT 1];
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = attach1.name;//File name with extention
            cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = attach1.OwnerId;//Owner of the file
            cVersion.Title = attach1.Name;//Name of the file
            cVersion.VersionData = attach1.Body;//File content
            cVersion.FirstPublishLocationId = recordId;
            Insert cVersion;
            */
        }                	
        return 'File upload successfully!';
    }
    
    @AuraEnabled
	public static String deleteRelatedFile(String docId) {
        String response;
		try {		
            system.debug(docId);
            List<ContentDocument> listToDelete = new List<ContentDocument>();
            List<ContentDocument> cdList = [SELECT Id FROM ContentDocument where Id = :docId];              
            Database.delete(cdList,false);
            response = 'Success';
			System.debug('file has been deleted');
		} catch(DMLException e) {
            response = 'error';
			System.debug('DMLException: ' + e.getMessage());
			
		}
        return response;
	} 
        
}