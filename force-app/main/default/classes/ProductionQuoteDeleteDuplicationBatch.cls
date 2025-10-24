global class ProductionQuoteDeleteDuplicationBatch implements Database.Batchable<SObject>,Database.Stateful{
    //global String productGuName = 'LP';
    global static Set<ProdQuoteToOppProduct__c> idsToDelete = new Set<ProdQuoteToOppProduct__c>();
	global Database.QueryLocator start(Database.BatchableContext context) {		              
        return Database.getQueryLocator('SELECT id, ITE_Number__c,Production_Quota__r.Product__c,Product__c FROM ProdQuoteToOppProduct__c' );
	}
    
    global void execute(Database.BatchableContext context, List<ProdQuoteToOppProduct__c> scope) {
        Set<String> pqtopITEnumberSet = new Set<String>();
        for(ProdQuoteToOppProduct__c record : scope) {
            pqtopITEnumberSet.add(record.ITE_Number__c);
        }

        List<ProdQuoteToOppProduct__c> searchingProducts = [SELECT id, ITE_Number__c,Production_Quota__r.Product__c,Product__c FROM ProdQuoteToOppProduct__c WHERE ITE_Number__c IN :pqtopITEnumberSet];
        Map<String, List<ProdQuoteToOppProduct__c>> iteNumberToPqtopListMap = new Map<String, List<ProdQuoteToOppProduct__c>>();

        for(ProdQuoteToOppProduct__c record : searchingProducts) {
            if(iteNumberToPqtopListMap.get(record.ITE_Number__c) == null) {
                iteNumberToPqtopListMap.put(record.ITE_Number__c, new List<ProdQuoteToOppProduct__c>{record});
            } else {
                iteNumberToPqtopListMap.get(record.ITE_Number__c).add(record);
            }
        }

        for(List<ProdQuoteToOppProduct__c> pqtopList : iteNumberToPqtopListMap.values()) {
            if(pqtopList.size()>1) {
                for(ProdQuoteToOppProduct__c record : pqtopList) {
                    if(record.Product__c != record.Production_Quota__r.Product__c) {
                        idsToDelete.add(record);
                    }
                }
            }
        }

        
        // for(ProdQuoteToOppProduct__c record : scope){            
        //     List<ProdQuoteToOppProduct__c> searchingProducts = [SELECT id, ITE_Number__c,Production_Quota__r.Product__c,Product__c FROM ProdQuoteToOppProduct__c WHERE ITE_Number__c=:record.ITE_Number__c];                  		
        //     if(searchingProducts.size()>1){
        //         for(ProdQuoteToOppProduct__c record2 : searchingProducts){
        //             if(record2.Product__c != record2.Production_Quota__r.Product__c){
        //                 idsToDelete.add(record2);
                        
        //             }
        //         }
        //     }
        // }

        List<ProdQuoteToOppProduct__c> lStrings = new List<ProdQuoteToOppProduct__c>(idsToDelete);
        Database.delete(lStrings,false);
       
	}
    
    global void finish(Database.BatchableContext context) {        
		List<ProdQuoteToOppProduct__c> lStrings = new List<ProdQuoteToOppProduct__c>(idsToDelete);
        delete lStrings;
	}
}