@isTest
public class AdditionalAccountUserHandlerTest extends BaseTest {

    @isTest
    public static void addAdditionalUserToAccount() {
		String userId = [SELECT id FROM USER WHERE LastName ='last' LIMIT 1].id;
        String accountId = [SELECT id FROM Account LIMIT 1].id;
        t.start(); 
			Additional_Account_User__c newAAU = new Additional_Account_User__c();
	        newAAU.Account__c =accountId;
        	newAAU.User__c = userId;
        	insert newAAU;      
        t.stop();
        
    }
    
    @isTest
    public static void deleteAdditionalUserToAccount() {
		String userId = [SELECT id FROM USER WHERE LastName ='last' LIMIT 1].id;
        String accountId = [SELECT id FROM Account LIMIT 1].id;
        Additional_Account_User__c newAAU = new Additional_Account_User__c();
	    newAAU.Account__c =accountId;
        newAAU.User__c = userId;
        insert newAAU;
        t.start(); 
			 delete newAAU;    
        t.stop();
        
    }
    
    
    @testSetup static void testSetup() {
        User user1 = AdditionalAccountUserHandlerTest.createUser('System Administrator','test1');
        insert user1;
        
        Account newAcc = new Account();
        newAcc.Name = 'Account'+1;
        newAcc.ID_ERP__c = 'test'+1;
        newAcc.DealingStatus__c = '10';
        insert newAcc;
    }
    
    public static User createUser(String profileName, String username){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        User createdUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Id = :profileId LIMIT 1].Id,
            LastName = 'last',
            Email = username+ 'user@sf.com' + System.currentTimeMillis(),
            Username = username+ 'user@sf.com' + System.currentTimeMillis(),
            CompanyName = 'Vertamedia',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            SalesDivision__c = '00001',
            ID_ERP__c  =username,
            EmployeeNumber = username
        );
        return createdUser;
    }
    
    
    
    static { BaseTest.t = new AdditionalAccountUserHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}