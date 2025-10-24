trigger ClientLeadTrigger on ClientLead__c (before insert, after insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        ClientLeadTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        ClientLeadTriggerHandler.handleAfterInsert(Trigger.new);
    }
}