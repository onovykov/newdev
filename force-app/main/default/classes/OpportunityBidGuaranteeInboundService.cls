public with sharing class OpportunityBidGuaranteeInboundService {

    private static final String OBJECT_API = 'Opportunity';
    private static final String FIELD_API  = 'BidGuarantees__c';

    public static ERPBidGuaranteeInboundResponseDTO handle(
        ERPBidGuaranteeInboundDTO dto
    ) {
        // =========================
        // 1. Find Opportunity
        // =========================
        Opportunity opp =
            OpportunityRepository.findByErpId(dto.idErp);

        if (opp == null && !String.isBlank(dto.iteNumber)) {
            opp = OpportunityRepository.findByIteNumber(dto.iteNumber);
        }

        if (opp == null) {
            return ERPBidGuaranteeInboundResponseDTO.rejected(
                'OPPORTUNITY_NOT_FOUND',
                null
                /*
                Тут додати лог у Pharos + Notify (визначити на кого)
                */
            );
        }

        // =========================
        // 2. Resolve ERP user
        // =========================
        User erpUser =
            UserRepository.getByLoginERP(dto.changedBy.login);

        if (erpUser == null) {
            return ERPBidGuaranteeInboundResponseDTO.rejected(
                'ERP_USER_NOT_FOUND',
                null
                /*
                Тут додати лог у Pharos + Notify (визначити на кого)
                */               
            );
        }

        // =========================
        // 3. Get last audit log
        // =========================
        Field_Audit_Log__c lastAudit =
            getLastAudit(opp.Id);

        // =========================
        // 4. Arbitration by ChangedAt
        // =========================
        if (lastAudit != null &&
            lastAudit.ChangedAt__c != null &&
            dto.changedAt != null &&
            lastAudit.ChangedAt__c.getTime() >=
            dto.changedAt.getTime()
        ) {
            return ERPBidGuaranteeInboundResponseDTO.rejected(
                'STALE_ERP_DATA',
                lastAudit
            );
        }

        // =========================
        // 5. Apply change from ERP
        // =========================
        opp.BidGuarantees__c = dto.bidGuarantees;

        // оновлення відбувається як юзер інтеграції,
        // але аудит буде зберігати користувача ERP явно
        update opp;

        // =========================
        // 6. Success
        // =========================
        return ERPBidGuaranteeInboundResponseDTO.applied();
    }

    // ============================================================
    // Helper: get last audit record
    // ============================================================
    private static Field_Audit_Log__c getLastAudit(Id oppId) {
        List<Field_Audit_Log__c> logs = [
            SELECT Id,
                   ChangedAt__c,
                   OldValue__c,
                   NewValue__c,
                   ChangedBy__r.LoginERP__c
            FROM Field_Audit_Log__c
            WHERE ObjectApiName__c = :OBJECT_API
              AND RecordId__c     = :oppId
              AND FieldApiName__c = :FIELD_API
            ORDER BY ChangedAt__c DESC
            LIMIT 1
        ];
        return logs.isEmpty() ? null : logs[0];
    }
}