@isTest
public class OrderTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        Account account = new Account(Name = 'Account Name');
        insert account;

        Order order1 = new Order(Name = 'Test Order 1', ITENumber__c = '24-001', AccountId = account.Id, EffectiveDate = Date.today(), Status = 'Draft');
        insert order1;
        
        Order order2 = new Order(Name = 'Test Order 2', ITENumber__c = '24-002', AccountId = account.Id, EffectiveDate = Date.today(), Status = 'Draft');
        insert order2;

        SalesPlanFact__c spf = new SalesPlanFact__c(InitialRecordId__c = order1.Id);
        insert spf;

        ProductionJournalRecord__c pjr = new ProductionJournalRecord__c(Order__c = order1.Id, Type__c = 'Order');
        insert pjr;
    }

    @isTest
    static void testBulkBeforeDelete() {
        List<Order> ordersToDelete = [SELECT Id FROM Order LIMIT 2];

        Set<Id> ordersToDeleteIds = new Set<Id>();
        for(Order orderToDelete : ordersToDelete) {
            ordersToDeleteIds.add(orderToDelete.Id);
        }

        Test.startTest();
        delete ordersToDelete;
        Test.stopTest();

        Integer spfCount = [SELECT COUNT() FROM SalesPlanFact__c WHERE InitialRecordId__c IN :ordersToDeleteIds];
        Integer pjrCount = [SELECT COUNT() FROM ProductionJournalRecord__c WHERE Order__c IN :ordersToDeleteIds];

        System.assertEquals(0, spfCount, 'Related SalesPlanFact__c records should be deleted');
        System.assertEquals(0, pjrCount, 'Related ProductionJournalRecord__c records should be deleted');
    }

    @isTest
    static void testBeforeInsert() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Order newOrder = new Order(Name = 'Test Order', ITENumber__c = '24-003', AccountId = account.Id, EffectiveDate = Date.today(), Status = 'Draft');

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        newOrder = [SELECT Name FROM Order WHERE Id = :newOrder.Id];
        System.assertEquals('24-003', newOrder.Name, 'Order name should be set to ITENumber__c');
    }

    @isTest
    static void testBeforeUpdate() {
        Order existingOrder = [SELECT Id, Name, ITENumber__c FROM Order LIMIT 1];
        existingOrder.ITENumber__c = '24-999';

        Test.startTest();
        update existingOrder;
        Test.stopTest();

        existingOrder = [SELECT Name FROM Order WHERE Id = :existingOrder.Id];
        System.assertEquals('24-999', existingOrder.Name, 'Order name should be set to ITENumber__c');
    }
}