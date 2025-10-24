public class FlowTriggerProductionQuoteCreate {
	@InvocableMethod(label='Create Production Quotes' description='Returns the list of account')
     public static void getContact(List<ID> ids) {
       system.debug(ids);  
       Set<id> salesbudgetId = new set<id>();
	   //testList.add('a0P0E000005K33jUAC');
       salesbudgetId.add(ids[0]);
       ProductionQuoteDeleteBatch deleteBatchProdQuote = new ProductionQuoteDeleteBatch(salesbudgetId);
       Id groupBatchProdQuoteId = Database.executeBatch(deleteBatchProdQuote);
         
       //SalesPlanFactDeleteBatch deleteSalesPlanFactBatch = new SalesPlanFactDeleteBatch(salesbudgetId);
       //Id deleteSalesPlanFactBatchId = Database.executeBatch(deleteSalesPlanFactBatch);  
       //System.scheduleBatch(deleteSalesPlanFactBatch,'deleteSalesPlanFactBatch',1);
    }
}