public with sharing class ERPBidGuaranteeOutboundService {

    /**
     * Entry point from trigger/handler
     */
    public static void sendAsync(List<Field_Audit_Log__c> logs) {
        if (logs == null || logs.isEmpty()) return;
        /* Check Outbound Enabled
            Перевіряємо, чи дозволено Outbound до ERP
            Переметр задається в полі OutboundActive__c (checkbox, default TRUE)
            в об'єкті Field_Audit_Config__mdt
        */
        if (!FieldAuditConfigProvider.isOutboundEnabled(
                'Opportunity',
                'BidGuarantees__c'
        )
        ) {
            return;
        }
        /*****************************************/
        System.enqueueJob(
                new OutboundQueueable(new List<Id>(
                        new Map<Id, Field_Audit_Log__c>(logs).keySet()
                ))
        );
    }

    /**
     * Queueable — safe for callouts
     */
    public class OutboundQueueable implements Queueable, Database.AllowsCallouts {

        private final List<Id> auditLogIds;

        public OutboundQueueable(List<Id> auditLogIds) {
            this.auditLogIds = auditLogIds;
        }

        public void execute(QueueableContext ctx) {

            // 1. Load audit logs
            List<Field_Audit_Log__c> logs = [
                    SELECT Id,
                            RecordId__c,
                            NewValue__c,
                            ChangedAt__c,
                            ChangedBy__c
                    FROM Field_Audit_Log__c
                    WHERE Id IN :auditLogIds
            ];

            if (logs.isEmpty()) return;

            // 2. Collect User Ids
            Set<Id> userIds = new Set<Id>();
            Set<Id> oppIds  = new Set<Id>();

            for (Field_Audit_Log__c log : logs) {
                if (log.ChangedBy__c != null) {
                    userIds.add(log.ChangedBy__c);
                }
                oppIds.add((Id)log.RecordId__c);
            }

            // 3. Load Users
            Map<Id, User> usersById = new Map<Id, User>(
            [
                    SELECT Id, LoginERP__c
                    FROM User
                    WHERE Id IN :userIds
            ]
            );

            // 4. Load Opportunities
            Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(
            [
                    SELECT Id, ID_ERP__c, ITENumber__c
                    FROM Opportunity
                    WHERE Id IN :oppIds
            ]
            );

            // 5. Prepare payloads
            List<ERPBidGuaranteeOutboundDTO> payload =
                    new List<ERPBidGuaranteeOutboundDTO>();

            for (Field_Audit_Log__c log : logs) {

                Opportunity opp = oppById.get((Id)log.RecordId__c);
                if (opp == null) continue;

                User u = usersById.get(log.ChangedBy__c);

                // KEY RULE:
                // If change was made by ERP user — DO NOT send outbound
                if (u != null && u.LoginERP__c != null) {
                    continue;
                }

                ERPBidGuaranteeOutboundDTO dto =
                        new ERPBidGuaranteeOutboundDTO();

                dto.idErp = opp.ID_ERP__c;
                dto.iteNumber = opp.ITENumber__c;
                dto.bidGuarantees = log.NewValue__c;
                dto.changedAt = log.ChangedAt__c;

                dto.changedBy =
                        new ERPBidGuaranteeOutboundDTO.ERPUserDTO();
                dto.changedBy.login =
                        u != null ? u.LoginERP__c : null;

                payload.add(dto);
            }

            if (payload.isEmpty()) return;

            // 6. Call ERP
            sendToErp(payload);
        }
    }

    /**
     * Actual ERP call (isolated for test mocking)
     */
    @TestVisible
    private static void sendToErp(
            List<ERPBidGuaranteeOutboundDTO> payload
    ) {
        if (Test.isRunningTest()) {
            // mocked in tests
            return;
        }

        Credentials__c creds = Credentials__c.getOrgDefaults();
        if (creds == null) {
            throw new AuraHandledException('Credentials__c missing');
        }

        SFToERP.WebServiceSoap soap = new SFToERP.WebServiceSoap();

        String ticket = soap.LoginEx(
                creds.User_Login__c,
                creds.User_Password__c
        );

        if (String.isBlank(ticket)) {
            throw new AuraHandledException('ERP login failed');
        }

        soap.ExecuteEx(
                '_SF_UPDATE_BID_GUARANTEES',
                JSON.serialize(payload),
                ticket
        );
    }
}