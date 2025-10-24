trigger ScrapSupplierLimitTrigger on ScrapSupplierLimit__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ScrapSupplierLimitTriggerHandler handler = new ScrapSupplierLimitTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.old, Trigger.new);

    if (Trigger.isBefore) {
        //handler.bulkBefore();
        if (Trigger.isDelete) {
            //for (SObject so : Trigger.old) {
            //    handler.beforeDelete(so);
            //}
        } else if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.old, Trigger.new);
        }
        handler.beforePostProcessing();
    } else {
        //handler.bulkAfter();
        if (Trigger.isDelete) {
            //for (ScrapSupplierLimit so : Trigger.old) {
            //    handler.afterDelete(so);
            //}
        } else if (Trigger.isInsert) {
            //handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            //handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        handler.postProcessing();
    }
}