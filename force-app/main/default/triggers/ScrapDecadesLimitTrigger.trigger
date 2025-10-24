trigger ScrapDecadesLimitTrigger on ScrapDecadesLimit__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ScrapDecadesLimitTriggerHandler handler = new ScrapDecadesLimitTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.old, Trigger.new);

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.old, Trigger.new);
        }
        handler.beforePostProcessing();
    }
    handler.postProcessing();

}