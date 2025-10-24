trigger ShopQuotaTrigger on Shop_Quota__c (after insert, after update) {
    if(Trigger.isAfter) {
        if (Trigger.isInsert) {
        	ShopQuotaTriggerHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            system.debug('TRIGGER NEW ---->>> ' + trigger.new);
        	
        }
    }
}