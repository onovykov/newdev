@IsTest
public class ProductionQuoteDeleteDuplicationTest {

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
        Id batchJobId = Database.executeBatch(new ProductionQuoteDeleteDuplicationBatch(), 200);
        Test.stopTest();
    }
}