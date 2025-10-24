@IsTest
public class ProductionQuoteDeleteOppItemsBatchTest {
    @IsTest
    static void testLastActivityDate() {
        Production_Quota__c prodQuota = new Production_Quota__c();
        insert prodQuota;

        List<ProdQuoteToOppProduct__c> prodQuoteToOppProductList = new List<ProdQuoteToOppProduct__c>();
        for(Integer i = 0; i < 200; i++) {
            ProdQuoteToOppProduct__c prodQuoteToOppProduct = new ProdQuoteToOppProduct__c(Production_Quota__c = prodQuota.Id);
            prodQuoteToOppProductList.add(prodQuoteToOppProduct);
        }
        insert prodQuoteToOppProductList;

        Test.startTest();
        Id batchJobId = Database.executeBatch(new ProductionQuoteDeleteOppItemsBatch(), 200);
        Test.stopTest();

        List<ProdQuoteToOppProduct__c> newProdQuoteToOppProductList = [SELECT Id FROM ProdQuoteToOppProduct__c];

        Assert.isTrue(newProdQuoteToOppProductList.size() == 0);
    }
}