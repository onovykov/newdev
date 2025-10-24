public class CreateReclamationTestUtility {
	
    public static Integer RANDOM_INT = Integer.valueOf(Math.rint(math.random()*1000000));
    
    public static User createUser(String roleId, String profId, String firstName, String lastName){
        User tempUser = prepareUser(roleId, profId, firstName, lastName);
        return tempUser;
    }

    private static User prepareUser(String roleId, String profId, String firstName, String lastName) {  

        String orgId = UserInfo.getOrganizationId();  
        String dateString =   
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        User tempUser = new User(  
            FirstName = firstName,  
            LastName = lastName,  
            email = uniqueName + '@sfdc' + orgId + '.org',  
            Username = uniqueName + '@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profId
        );    
        if( String.isBlank(roleId) == false ){
            tempUser.UserRoleId = roleId;
        }
        return tempUser;  
    }

    public static User createCommunityUser(String contactId, String profId, String firstName, String lastName) {
        User tempUser = prepareUser('', profId, firstName, lastName);
        tempUser.ContactId = contactId;
        return tempUser;
    }

    public static Account createAccount(String Name){
        Account portalAccount = new Account(name = Name,
                                            MarketSegment__c = '00002');
        return portalAccount;
    }
    public static Contact createContact(String firstName, String lastName, String email, String accountId){
        Contact portalContact = new contact(
            FirstName = firstName, 
            LastName = lastName, 
            Email = email, 
            AccountId = accountId
        );
        return portalContact;
    }
    
    public static User createTestUserAdministrator(String profileName) {
        
        String testUserName = 'CustomNewEnquiryControllerTest' + String.valueOf(RANDOM_INT+1) + '@test.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName];
        
        User testUser = New User(Alias='testAli', IsActive = true,  
                                 Email='testEmail@test.com', EmailEncodingKey='ISO-8859-1', 
                                 LastName='testLastName', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
                                 ProfileId=p.Id, TimeZoneSidKey='America/New_York', Username=testUserName);
		
        return testUser;
	}
}