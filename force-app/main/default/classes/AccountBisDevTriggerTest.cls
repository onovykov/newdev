@IsTest
public class AccountBisDevTriggerTest {
    public static String PROFILE_NAME_ADMINISTRATOR = 'System Administrator';
    
    @IsTest
    static void testAfterInsert() {
        User testUserAdmin = CustomNewEnquiryControllerTestFactory.createTestUserAdministrator(PROFILE_NAME_ADMINISTRATOR);
        insert testUserAdmin;

        System.runAs(testUserAdmin) {
            Account account = new Account(Name = 'Test Account');

            Test.startTest();
            insert account;
            Test.stopTest();
        }
                    
        List<AccountSalesSegmentation__c> assList = [SELECT Id, MarketSegment__c, Manager__c FROM AccountSalesSegmentation__c];
        Assert.areEqual(1, assList.size(), 'Account Sales Segmentation must be created');
        Assert.areEqual(testUserAdmin.SalesDivision__c, assList.get(0).MarketSegment__c);
        Assert.areEqual(testUserAdmin.Id, assList.get(0).Manager__c, 'Account Owner should be specified as Manager');
    }
}