public class ERPBidGuaranteeInboundResponseDTO {

    public Boolean applied;
    public String reason;

    public AuditSnapshot audit; // only when applied = false

    public class AuditSnapshot {
        public String changedBy;
        public Datetime changedAt;
        public String oldValue;
        public String newValue;
    }

    public static ERPBidGuaranteeInboundResponseDTO applied() {
        ERPBidGuaranteeInboundResponseDTO r =
            new ERPBidGuaranteeInboundResponseDTO();
        r.applied = true;
        return r;
    }

    public static ERPBidGuaranteeInboundResponseDTO rejected(
        String reason,
        Field_Audit_Log__c auditLog
    ) {
        ERPBidGuaranteeInboundResponseDTO r =
            new ERPBidGuaranteeInboundResponseDTO();
        r.applied = false;
        r.reason = reason;

        if (auditLog != null) {
            r.audit = new AuditSnapshot();
            r.audit.changedBy =
                auditLog.ChangedBy__r.LoginERP__c;
            r.audit.changedAt =
                auditLog.ChangedAt__c;
            r.audit.oldValue =
                auditLog.OldValue__c;
            r.audit.newValue =
                auditLog.NewValue__c;
        }
        return r;
    }
}