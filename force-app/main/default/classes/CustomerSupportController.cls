public without sharing class CustomerSupportController {
	@AuraEnabled
    public static  List<Map<String,String>> fetchContactNames(){
        
        List<Map<String,String>> managersMapInfo = new List<Map<String,String>>();
		Map<String,String> managerInfo1 = new Map<String,String>();
        
        String userId = UserInfo.getUserId();
        Set<String> managerNames = new Set<String>();
        User currentUser = [SELECT name,manager.profileid,manager.FirstName,manager.LastName,managerid,manager.Email FROM user WHERE id=:userId LIMIT 1];
        String managerNameCurrent = currentUser.manager.FirstName + ' ' + currentUser.manager.LastName;
        String managerId = currentUser.manager.profileid;
        List<User> managers =  [SELECT id,FirstName,LastName FROM USER WHERE Profileid = :managerId];
                               
        managerNames.add(managerNameCurrent);
        
        managerInfo1.put('fullName',managerNameCurrent);
        managerInfo1.put('id',currentUser.managerId);
        managerInfo1.put('email',currentUser.manager.Email);
        managersMapInfo.add(managerInfo1);
        
        for(User u : managers){
            Map<String,String> managerInfo2 = new Map<String,String>();
            //system.debug(u.Name);
            String fullName = u.FirstName + ' '+ u.lastName;
            if(fullName == managerNameCurrent){
                continue;
            } else {
                managerNames.add(fullName);
                managerInfo2.put('fullName',fullName);
                managerInfo2.put('id',u.id);
                managersMapInfo.add(managerInfo2);
            }
            
        }
        system.debug(managers);
        system.debug(currentUser);
        List<String> managersName = new List<String>(managerNames);
        return managersMapInfo;
    }
    
    @AuraEnabled
    public static String createCase(String data){
        //system.debug('woooork');
        String returnedId;
        system.debug(data);
        String userId = UserInfo.getUserId();
        String idContactUser = [SELECT Contactid FROM User WHERE Id=:userId LIMIT 1].contactid;
        Map<String, Object> test = (Map<String, Object>) JSON.deserializeUntyped(data);
        String idManager = String.valueOf(test.get('idManager'));
        String firstName = String.valueOf(test.get('fisrtName'));
        String lastName = String.valueOf(test.get('lastName'));
        String subject = String.valueOf(test.get('subject'));
        String description =String.valueOf(test.get('description'));
        //system.debug(String.valueOf(test.get('fisrtName')));
        //system.debug(String.valueOf(test.get('subject')));
        //system.debug(String.valueOf(test.get('description')));
        //system.debug(test.get('files'));
        List<Object> filesIds = (List<Object>) JSON.deserializeUntyped(JSON.serialize(test.get('files')));
        system.debug(filesIds);
        For(Object c : filesIds){
            System.debug(String.valueOf(c));
        }
        Case newCase = new Case();
        newCase.Description = description;
        newCase.Subject = subject;
        newCase.OwnerId = idManager;
        newCase.ContactId = idContactUser;
        newCase.Origin = 'Customer Support';
        insert newCase;
        returnedId = newCase.id;
        
        List<ContentDocumentLink> linksFile = new List<ContentDocumentLink>();
        For(Object c : filesIds){
            ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Opportunity(Parent) record
                cdl.LinkedEntityId = newCase.id; // Opportunity ID
                cdl.ContentDocumentId = String.valueOf(c); //Content Dcoument ID
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                linksFile.add(cdl);
           // System.debug();
        }
        insert linksFile;
        /*
        		ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Opportunity(Parent) record
                cdl.LinkedEntityId = newCase.id; // Opportunity ID
                cdl.ContentDocumentId = '0690E000001waZ0QAI'; //Content Dcoument ID
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
      */  
        return returnedId;
    }
    
    @AuraEnabled
    public static List<WrapperTableInfo> fetchTableInfo(){
        List<WrapperTableInfo> tabInfo = new List<WrapperTableInfo>();
        String userId = UserInfo.getUserId();
        
        Site site = [SELECT Id FROM Site WHERE UrlPathPrefix = 'CustomerRoom' LIMIT 1];
		String communityUrl = [SELECT SecureURL FROM SiteDetail WHERE DurableId =: site.Id].SecureUrl;
		System.debug('Community url: ' + communityUrl);
                       
        system.debug(userId);
        String idContactUser = [SELECT Contactid FROM User WHERE Id=:userId LIMIT 1].contactid;
        system.debug(idContactUser);
        List<Case> userCases = [SELECT Id,Subject,Status,CreatedDate,Status_Date__c,Owner.Email FROM Case WHERE ContactId=:idContactUser ORDER BY CreatedDate DESC];
        
        for(Case c: userCases){
            String ulrSubject = communityUrl + '/s/detail/' + c.id;
            WrapperTableInfo info = new WrapperTableInfo();
            info.id = c.id;
            info.supportContact =c.Owner.Email;
            info.subjectUrl = ulrSubject;                        
            info.subject = c.Subject;
            info.creationDate = date.newinstance(c.CreatedDate.year(),c.CreatedDate.month(),c.CreatedDate.day());
            info.status = c.Status;
            info.statusDate = c.Status_Date__c;
            tabInfo.add(info);
        }
        return tabInfo;
        
    }
    
    public class WrapperTableInfo {
        
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String supportContact;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public Date creationDate;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Date statusDate;
        @AuraEnabled
        public String subjectUrl;
       
    }
}