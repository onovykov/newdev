@isTest
public class CustomNewEnquiryControllerTest {
    
    public static String PROFILE_NAME = 'Customer Community User (Custom)';
    public static String PROFILE_NAME_ADMINISTRATOR = 'System Administrator';
    public static String COUNTRY_NAME = 'Andorra';
    public static String COUNTRY_A2CODE = 'AD';
    public static String COUNTRY_A3CODE = 'AND';
    public static String COUNTRY_NUMCODE = '20';
    
    @isTest
    static void testGetCustomerEnquiryRecTypes() {
        
        Test.startTest();
        List<CustomNewEnquiryController.RecordTypesWrapper> testRecTypesInfo = CustomNewEnquiryController.getCustomerEnquiryRecTypes();
        Test.stopTest();
        
        System.assert(testRecTypesInfo != null, 'Record Types List is NULL!');
        System.assert(!testRecTypesInfo.isEmpty(), 'Record Types List is EMPTY!');
    }
    
    @isTest
    static void testGetContactMailingCountry() {
                        
        User testUserAdmin = CustomNewEnquiryControllerTestFactory.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
        insert testUserAdmin;
        
        System.runAs(testUserAdmin) {
            Country__c userContactCountry = CustomNewEnquiryControllerTestFactory.createUserContactCountry(COUNTRY_NAME, COUNTRY_A2CODE, COUNTRY_A3CODE, COUNTRY_NUMCODE);
            insert userContactCountry;
            
            Account userAccountQueried = CustomNewEnquiryControllerTestFactory.createUserAccount();
            
            Contact userContact = CustomNewEnquiryControllerTestFactory.createUserContact(userAccountQueried.Id, COUNTRY_NAME);
            insert userContact;
                               
        
            User testUser = CustomNewEnquiryControllerTestFactory.createTestUser(PROFILE_NAME, userContact.Id);
            testUser.ManagerId = testUserAdmin.id;
            insert testUser;
        
            Test.startTest();
            CustomNewEnquiryController.PrepolutateWrapper testPrepolutatedFieldValues = CustomNewEnquiryController.getContactMailingCountry(testUser.id);
            Test.stopTest();
            
            System.assertEquals(userContactCountry.Id, testPrepolutatedFieldValues.mailingCountryId, 'Incorrect Mailing Country ID');
            System.assertEquals(userAccountQueried.OwnerId, testPrepolutatedFieldValues.managerId, 'Incorrect Manager ID');
        }  
    }

    @isTest
    static void testGetBusinessDivision() {
                        
        User testUserAdmin = CustomNewEnquiryControllerTestFactory.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
        insert testUserAdmin;
        
        System.runAs(testUserAdmin) {
            Country__c userContactCountry = CustomNewEnquiryControllerTestFactory.createUserContactCountry(COUNTRY_NAME, COUNTRY_A2CODE, COUNTRY_A3CODE, COUNTRY_NUMCODE);
            insert userContactCountry;
            
            Account userAccountQueried = CustomNewEnquiryControllerTestFactory.createUserAccount();
            
            Contact userContact = CustomNewEnquiryControllerTestFactory.createUserContact(userAccountQueried.Id, COUNTRY_NAME);
            insert userContact;

            AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :userAccountQueried.Id AND ContactId = :userContact.Id];
            acr.BusinessDivision__c = 'Pipes';
            update acr;
                               
            User testUser = CustomNewEnquiryControllerTestFactory.createTestUser(PROFILE_NAME, userContact.Id);
            testUser.ManagerId = testUserAdmin.id;
            insert testUser;
        
            Test.startTest();
            CustomNewEnquiryController.BusinessDivisionWrapper testBusinessDivisionWrapper = CustomNewEnquiryController.getBusinessDivision(testUser.id);
            Test.stopTest();
            
            System.assertEquals('Pipes', testBusinessDivisionWrapper.businessDivision, 'Incorrect Business Division');
            System.assertEquals(false, testBusinessDivisionWrapper.allDivisions, 'Incorrect All Divisions');
        }  
    }
    
}