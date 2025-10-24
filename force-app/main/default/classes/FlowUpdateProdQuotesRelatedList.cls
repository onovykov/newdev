public class FlowUpdateProdQuotesRelatedList {
	@InvocableMethod(label='Update related items' description='updating')
     public static void getContact() {
       
       ProductionQuoteDeleteShopItemBatch deleteRelatedShopItemToProdQuote = new ProductionQuoteDeleteShopItemBatch();
       Id deleteRelatedShopItemToProdQuoteId = Database.executeBatch(deleteRelatedShopItemToProdQuote);
         
       ProductionQuoteDeleteOppItemsBatch deleteRelatedOppItemToProdQuote = new ProductionQuoteDeleteOppItemsBatch();
       Id deleteRelatedOppItemToProdQuoteId = Database.executeBatch(deleteRelatedOppItemToProdQuote);  
         
       ProductionQuoteOnUpdateBatch createProdQuoteRelatedItems = new ProductionQuoteOnUpdateBatch();
		//Id createBatchProdQuoteId = Database.executeBatch(createBatchProdQuote,30);
       System.scheduleBatch( createProdQuoteRelatedItems, 'ShopQuoteRelated', 4,10);  
         
       ProductionQuoteDeleteDuplicationBatch deleteDuplitcations = new ProductionQuoteDeleteDuplicationBatch();
		//Id createBatchProdQuoteId = Database.executeBatch(createBatchProdQuote,30);
       System.scheduleBatch( deleteDuplitcations, 'deleteDuplitcations', 7,50);    
    }
}