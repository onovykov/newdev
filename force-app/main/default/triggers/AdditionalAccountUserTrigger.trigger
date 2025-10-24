trigger AdditionalAccountUserTrigger on Additional_Account_User__c (before insert,before delete,after delete) {
	AdditionalAccountUserHandler handler = new AdditionalAccountUserHandler(Trigger.oldMap, Trigger.newMap, Trigger.old, Trigger.new);

    if (Trigger.isBefore) {
        handler.bulkBefore();
        if (Trigger.isDelete) {
            System.debug('deleteBefore');
            for (SObject so : Trigger.old) {
                handler.beforeDelete(so);
            }
        } else if (Trigger.isInsert) {
            for (SObject so : Trigger.new) {
                handler.beforeInsert(so);
            }
        } else if (Trigger.isUpdate) {
            for (SObject so : Trigger.old) {
                handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
            }
        }
      
    } else {
        handler.bulkAfter();
        if (Trigger.isDelete) {
            System.debug('deleteAfter');
            for (SObject so : Trigger.old) {
                handler.afterDelete(so);
            }
        } else if (Trigger.isInsert) {
            for (SObject so : Trigger.new) {
                handler.afterInsert(so);
            }
        } else if (Trigger.isUpdate) {
            for (SObject so : Trigger.old) {
                handler.afterUpdate(so, Trigger.newMap.get(so.Id));
            }
        }
        //handler.postProcessing();
    }
    if(Trigger.isDelete){
        System.debug('deleteAfter');
    }
}