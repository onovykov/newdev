global class SalesPlanFactDeleteBatch implements Database.Batchable<SObject>  {
	
    global Id sbrIdsSet;
    global List<Date> listDateCheck = new List<Date>();
    global dateTime lastUpdateBudget;
    //global String selectedType = 'Actual Budget';
    global String typeActualBudget = 'Actual Budget';
    global String typeCorrectedBudget = 'Corrected Budget';
    
    global SalesPlanFactDeleteBatch(Id idsSalesBudgetRecords){
    sbrIdsSet = idsSalesBudgetRecords;
    // AggregateResult[] groupedResults= [SELECT Period__c  FROM SalesBudgetRecord__c where SalesBudget__c =:idsSalesBudgetRecords group by Period__c ];
    lastUpdateBudget = [ SELECT LastModifiedDate FROM SalesBudget__c WHERE id =:idsSalesBudgetRecords LIMIT 1].LastModifiedDate.addMinutes(-10);   
        
        List<Deleted_Period__c> dlper = new List<Deleted_Period__c>();
        //check periods to delete'
        List<SalesBudget__c> budget = [SELECT id, PeriodBeginning__c, PeriodEnd__c FROM SalesBudget__c WHERE id =:idsSalesBudgetRecords LIMIT 1];
       
        Map<String,Deleted_Period__c> records = Deleted_Period__c.getAll();
        
        Date startDate = budget[0].PeriodBeginning__c;
        Date endDate = budget[0].PeriodEnd__c;
        
        // Increment the start date until it reaches the end date
        while (startDate < endDate) {
            listDateCheck.add(startDate);
            startDate = startDate.addMonths(1);
        }

        // for(AggregateResult ar:groupedResults){  
        // 	if(records.get(String.valueOf(ar.get('Period__c')))==null){
        //         listDateCheck.add(Date.valueOf(ar.get('Period__c')));               
        //     }       
        // }
        system.debug(listDateCheck);
        system.debug(lastUpdateBudget);
        Triton.instance.debug(TritonTypes.Type.Backend, 
							  TritonTypes.Area.SalesPlanFact,   
							  'Sales Plan Fact Delete debug',
							  'Period : ' + listDateCheck + '; Last Update Budget : ' + lastUpdateBudget);
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {	    
        
        return Database.getQueryLocator('SELECT id FROM SalesPlanFact__c WHERE Period__c in :listDateCheck AND (Type__c =:typeActualBudget OR Type__c =:typeCorrectedBudget) AND CreatedDate<:lastUpdateBudget' );//
        //return Database.getQueryLocator('SELECT id FROM SalesPlanFact__c WHERE Period__c in :listDateCheck AND Type__c =:selectedType AND CreatedDate<:lastUpdateBudget' );
	}
    
    global void execute(Database.BatchableContext context, List<SalesPlanFact__c> scope) {
        
        delete scope;
	}
    
    global void finish(Database.BatchableContext context) {
        
	}
}