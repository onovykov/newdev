@isTest
public class CustomerSupportControllerTest {
	 public static String PROFILE_NAME = 'Customer Community User (Custom)';
        public static String COUNTRY_NAME = 'Andorra';
        public static String COUNTRY_A2CODE = 'AD';
        public static String COUNTRY_A3CODE = 'AND';
        public static String COUNTRY_NUMCODE = '20';
    
    @isTest
    static void takeInitialInfoTest(){
        
        User u = [SELECT id FROM USER WHERE Alias='testAli' LIMIT 1 ];
        system.debug(u);
        system.assertEquals(true, true, 'msg');
        System.runAs(u) {
              // The following code runs as user 'u'
              String userId = UserInfo.getUserId();
              Set<String> managerNames = new Set<String>();
              User currentUser = [SELECT name,manager.profileid,manager.FirstName,manager.LastName,managerid FROM user WHERE id=:userId LIMIT 1];
              String managerNameCurrent = currentUser.manager.FirstName + ' ' + currentUser.manager.LastName;
              String managerId = currentUser.manager.profileid;
              List<User> managers =  [SELECT id,FirstName,LastName FROM USER WHERE Profileid = :managerId];
            
              List<Map<String,String>> testList = CustomerSupportController.fetchContactNames();
           	  system.debug(testList);
              system.assertEquals(managers.size(), testList.size(), 'msg');
          }
    }
    
    @isTest
    static void createCaseTest(){
        
        User u = [SELECT id FROM USER WHERE Alias='testAli' LIMIT 1 ];
        system.debug(u);
        system.assertEquals(true, true, 'msg');
        System.runAs(u) {
              // The following code runs as user 'u'
              String userId = UserInfo.getUserId();
              Set<String> managerNames = new Set<String>();
              User currentUser = [SELECT name,manager.profileid,manager.FirstName,manager.LastName,managerid FROM user WHERE id=:userId LIMIT 1];
              String managerNameCurrent = currentUser.manager.FirstName + ' ' + currentUser.manager.LastName;
              String managerId = currentUser.manager.profileid;
              List<User> managers =  [SELECT id,FirstName,LastName FROM USER WHERE Profileid = :managerId];
              
              List<Map<String,String>> testList = CustomerSupportController.fetchContactNames();
           	  system.debug(testList);
              String managerId2 = testList[0].get('id');
            String data = '{"idManager": "'+managerId2+ '", "firstName": "Artem", "lastName": "Kovtun", "subject": "test","description": "test","files": []}';
              CustomerSupportController.createCase(data);
            List<Case> cases = [SELECT Id FROM Case];
            
              system.assertEquals(1, cases.size(), 'msg');
          }
    }
    
    @isTest
    static void fetchDataTable(){
         User u = [SELECT id FROM USER WHERE Alias='testAli' LIMIT 1 ];
        system.debug(u);
        system.assertEquals(true, true, 'msg');
        System.runAs(u) {
              // The following code runs as user 'u'
              String userId = UserInfo.getUserId();
              Set<String> managerNames = new Set<String>();
              User currentUser = [SELECT name,manager.profileid,manager.FirstName,manager.LastName,managerid FROM user WHERE id=:userId LIMIT 1];
              String managerNameCurrent = currentUser.manager.FirstName + ' ' + currentUser.manager.LastName;
              String managerId = currentUser.manager.profileid;
              List<User> managers =  [SELECT id,FirstName,LastName FROM USER WHERE Profileid = :managerId];
              
              List<Map<String,String>> testList = CustomerSupportController.fetchContactNames();
           	  system.debug(testList);
              String managerId2 = testList[0].get('id');
            String data = '{"idManager": "'+managerId2+ '", "firstName": "Artem", "lastName": "Kovtun", "subject": "test","description": "test","files": []}';
            CustomerSupportController.createCase(data);
                                    
            List<CustomerSupportController.WrapperTableInfo> tableInfo =  CustomerSupportController.fetchTableInfo();
            system.assertEquals(1, tableInfo.size(), 'Not expected number');
            
            //system.assertEquals(1, cases.size(), 'msg');
          }
    }
    
    @testSetup static void testSetup() {
        
        Profile p = [SELECT id, Name FROM Profile where name = 'System Administrator' ].get(0);  
  				User u = new User(firstname= 'Samuel',
  						  lastname='XXXX',
  						  Alias='Samuel',
  						  email = 'samuel@asd.com',
  						  username= 'samuel@asd.com', 
  						  profileId= p.id, 
  						  emailencodingkey='UTF-8',
  						  languagelocalekey='en_US',
  						  localesidkey='en_US',
  						  timezonesidkey='America/Los_Angeles',
                          ID_ERP__c = 'TESTBO',
	  					  SalesDivision__c = '00004',
	  					  EmployeeNumber = 'TESTBO',
	  					  LoginERP__c = 'TESTBO' );
        
  				insert u;	 
        
        Account userAccountQueried = CustomNewEnquiryControllerTestFactory.createUserAccount();
        
        Contact userContact = CustomNewEnquiryControllerTestFactory.createUserContact(userAccountQueried.Id, COUNTRY_NAME);
        insert userContact;
        
        User testUser = CustomNewEnquiryControllerTestFactory.createTestUser(PROFILE_NAME, userContact.Id);     
	    testUser.SalesDivision__c = '00004';	     
        testUser.ManagerId = u.id;
        insert testUser; 
    }
}