trigger FieldAuditEventTrigger
on Field_Audit_Event__e (after insert) {
    FieldAuditEventTriggerHelper.handle(Trigger.new);
}