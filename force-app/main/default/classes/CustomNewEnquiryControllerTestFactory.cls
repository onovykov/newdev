@isTest
public with sharing class CustomNewEnquiryControllerTestFactory {
    public static Integer RANDOM_INT = Integer.valueOf(Math.rint(math.random()*1000000));
    
    public static Country__c createUserContactCountry(String countryName, String countryA2Code, String countryA3Code, String countryNumCode){
        
        Country__c userContactCountry = new Country__c(Name=countryName, A2Code__c=countryA2Code, A3Code__c=countryA3Code, NumCode__c=countryNumCode);
        return userContactCountry;
    }
    
    public static Account createUserAccount() {
        
        Account userAccount = new Account(Name = 'TestUserAccount' + String.valueOf(RANDOM_INT));
        insert userAccount;
        
        Account userAccountQueried = [SELECT Id, OwnerId FROM Account WHERE Id =: userAccount.Id LIMIT 1];
        return userAccountQueried;
    }
    
    public static Contact createUserContact(Id userAccountId, String userContactCountry) {
        
        Contact userContact = new Contact(AccountId=userAccountId, LastName='Test', MailingCountry=userContactCountry);
        return userContact;
    }    
	
    public static User createTestUser(String profileName, Id userContactId) {
        
        String testUserName = 'CustomNewEnquiryControllerTest' + String.valueOf(RANDOM_INT) + '@test.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName];
        
        User testUser = New User(Alias='testAli', ContactId=userContactId, IsActive = true,  
                                 Email='testEmail@test.com', EmailEncodingKey='ISO-8859-1',
                                 LastName='testLastName', LanguageLocaleKey='en_US', LocaleSidKey='en_US', BusinesDivision__c = 'Pipes',
                                 ProfileId=p.Id, TimeZoneSidKey='America/New_York', Username=testUserName, SalesDivision__c = '00004');
		
        return testUser;
	}
    
    public static User createTestUserAdministrator(String profileName) {
        
        String testUserName = 'CustomNewEnquiryControllerTest' + String.valueOf(RANDOM_INT+1) + '@test.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName];
        UserRole role = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
        
        User testUser = New User(Alias='testAli', IsActive = true,  
                                 Email='testEmail@test.com', EmailEncodingKey='ISO-8859-1', UserRoleId = role.Id,
                                 LastName='testLastName', LanguageLocaleKey='en_US', LocaleSidKey='en_US', BusinesDivision__c = 'Pipes',
                                 ProfileId=p.Id, TimeZoneSidKey='America/New_York', Username=testUserName, SalesDivision__c = '00004',ID_ERP__c = 'TESTBO',                                
                                 EmployeeNumber = 'TESTBO',
                                 LoginERP__c = 'TESTBO');
		
        return testUser;
	}
}