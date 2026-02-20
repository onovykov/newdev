trigger FieldAuditLogTrigger on Field_Audit_Log__c (after insert) {
    FieldAuditLogOutboundHandler.handle(Trigger.new);
}