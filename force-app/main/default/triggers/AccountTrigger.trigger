trigger AccountTrigger on Account(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    AccountTriggerHandler handler = new AccountTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.old, Trigger.new);

    if (Trigger.isBefore) {
        handler.bulkBefore();
        if (Trigger.isDelete) {
            for (SObject so : Trigger.old) {
                handler.beforeDelete(so);
            }
        } else if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
                //handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
                handler.beforeUpdate(Trigger.old, Trigger.new);
        }
        handler.beforePostProcessing();
    } else {
        handler.bulkAfter();
        if (Trigger.isDelete) {
            for (Account so : Trigger.old) {
                handler.afterDelete(so);
            }
        } else if (Trigger.isInsert) {
            //for (SObject so : Trigger.new) {
                handler.afterInsert(Trigger.new);
            //}
        } else if (Trigger.isUpdate) {
            //for (SObject so : Trigger.old) {
                handler.afterUpdate(Trigger.new, Trigger.oldMap);
            //}
        }
        handler.postProcessing();
    }
    
}