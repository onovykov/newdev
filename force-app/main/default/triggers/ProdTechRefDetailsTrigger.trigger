trigger ProdTechRefDetailsTrigger on ProdTechRefDetails__c (
    before insert,
    before update
) {
    ProdTechRefDetailsTriggerHandler.handleBefore(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}
