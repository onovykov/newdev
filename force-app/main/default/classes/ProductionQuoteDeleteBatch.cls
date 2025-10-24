global class ProductionQuoteDeleteBatch implements Database.Batchable<SObject>  {
	
    global Set<Id> sbrIdsSet = new Set<Id>();
    global List<Date> listDateCheck = new List<Date>();
   
    
    global ProductionQuoteDeleteBatch(Set<Id> idsSalesBudgetRecords){
        sbrIdsSet = idsSalesBudgetRecords;
        system.debug('start delete production quote records');
        
        List<Deleted_Period__c> dlper = new List<Deleted_Period__c>();
        //AggregateResult[] groupedResults= [SELECT Period__c  FROM SalesBudgetRecord__c where id in :idsSalesBudgetRecords group by Period__c ];
        AggregateResult[] groupedResults= [SELECT Period__c  FROM SalesBudgetRecord__c where SalesBudget__c in :idsSalesBudgetRecords group by Period__c ];
        
        Map<String,Deleted_Period__c> records = Deleted_Period__c.getAll();
        
        for(AggregateResult ar:groupedResults){
    
        if(records.get(String.valueOf(ar.get('Period__c')))==null){
                listDateCheck.add(Date.valueOf(ar.get('Period__c')));
                system.debug(ar.get('Period__c'));
                Deleted_Period__c newRecord = new Deleted_Period__c();
                newRecord.Name = String.valueOf(ar.get('Period__c'));
                newRecord.Deleted__c = Date.valueOf(ar.get('Period__c'));
                dlper.add(newRecord);
            }       
        }
        if(dlper.size()>0){
            insert dlper;
        }
        //SalesPlanFactDeleteBatch deleteSalesPlanFactBatch = new SalesPlanFactDeleteBatch(idsSalesBudgetRecords);
        //Id deleteSalesPlanFactBatchId = Database.executeBatch(deleteSalesPlanFactBatch);
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {	
        return Database.getQueryLocator('SELECT id FROM Production_Quota__c WHERE Period__c in :listDateCheck' );
	}
    
    global void execute(Database.BatchableContext context, List<Production_Quota__c> scope) {
        
        delete scope;
	}
    
    global void finish(Database.BatchableContext context) {
        system.debug('finish delete production quote records');
        ProductionQuoteCreateBatch createBatchProdQuote = new ProductionQuoteCreateBatch(sbrIdsSet);
		//Id createBatchProdQuoteId = Database.executeBatch(createBatchProdQuote);
        System.scheduleBatch( createBatchProdQuote, 'createBatchProdQuote', 2);
	}
}