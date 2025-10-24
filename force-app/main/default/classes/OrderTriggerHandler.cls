public class OrderTriggerHandler extends TriggerHandler implements ITrigger {
    
    public OrderTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
        super(oldMap, newMap, oldList, newList);
    }

    public void bulkBefore() {
        System.debug('bulkBefore OrderItem');

        if (Trigger.isDelete) {
            // Удалим все связанные записи из таблиц SalesPlanFact__c и ProductionJournalRecord__c:
            deleteRelatedRecords();
        }
    }

    
    
    public void bulkAfter() {
        System.debug('bulkAfter OrderItem');
    }

    public void beforeInsert(SObject so) {
        System.debug('beforeInsert OrderItem');
        changeOrderName((Order)so);
    }
    
    public void beforeUpdate(SObject oldSo, SObject so) {
        System.debug('beforeUpdate OrderItem');
		changeOrderName((Order)so);
    }

    public void beforeDelete(SObject so) {
        System.debug('beforeDelete OrderItem');
    }

    public void afterInsert(SObject so) {
        System.debug('afterInsert OrderItem');
    }

    
    public void afterUpdate(SObject oldSo, SObject so) {
        System.debug('afterUpdate OrderItem');
    }


    public void afterDelete(SObject so) {
        System.debug('AfterDelete OrderItem');
    }

    public void postProcessing() {
        System.debug('PostProcessing OrderItem');
    }

    

    public void deleteRelatedRecords() {
        
        Set<String> ordIdSet = ApexUtil.getIds(oldList);
        
        // Удалим старые связанные записи из таблицы SalesPlanFact__c
        List<SalesPlanFact__c> spfToDelete = 
            [   SELECT  Id
                FROM    SalesPlanFact__c
                WHERE   InitialRecordId__c in :ordIdSet
            ];
        
        System.debug('--->> SPF records to delete: ' + spfToDelete);
        delete spfToDelete;

        // Удалим старые связанные записи из таблицы ProductionJournalRecords__c
        List<ProductionJournalRecord__c> pjrToDelete = new List<ProductionJournalRecord__c>(
            [   SELECT  Id
                FROM    ProductionJournalRecord__c
                WHERE   Order__c in :ordIdSet
            ]);
        
        System.debug('--->> PJR records to delete: ' + pjrToDelete);
        delete pjrToDelete;
    }

    private void changeOrderName(Order orderRec) {
        orderRec.Name = orderRec.ITENumber__c;
    }    

}