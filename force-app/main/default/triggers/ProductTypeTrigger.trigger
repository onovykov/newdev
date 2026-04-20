trigger ProductTypeTrigger on ProductType__c (
    before insert,
    before update
) {
    ProductTypeTriggerHandler.handleBefore(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}