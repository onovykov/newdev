@IsTest
public class UpdateOrderItemsBatchTest {
    
    @IsTest
    static void testLastActivityDate() {
        Account account = new Account(Name = 'Test');
        insert account;
        Product2 product = new Product2(Name = 'Product');
        insert product;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100);
        insert priceBookEntry;
        Order order = new Order(AccountId = account.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = pricebookId);
        insert order;

        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Integer i = 0; i < 50; i++) {
            OrderItem orderItem = new OrderItem(OrderId = order.Id, UnitPrice = 100, Quantity = 10, Product2Id = product.Id, PriceBookEntryId = priceBookEntry.Id);
            orderItemList.add(orderItem);
        }
        insert orderItemList;

        Test.startTest();
        Id batchJobId = Database.executeBatch(new UpdateOrderItemsBatch(), 50);
        Test.stopTest();
    }
}