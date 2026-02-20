public with sharing class FieldAuditLogOutboundHandler {
    public static void handle(List<Field_Audit_Log__c> logs) {

        List<Field_Audit_Log__c> toSend = new List<Field_Audit_Log__c>();

        for (Field_Audit_Log__c log : logs) {

            if (log.ObjectApiName__c != 'Opportunity') continue;
            if (log.FieldApiName__c != 'BidGuarantees__c') continue;

            // якщо ChangedBy__c = null → технічна помилка, не шлемо
            if (log.ChangedBy__c == null) continue;

            // перевірка ERP-юзера буде в сервісі
            toSend.add(log);
        }

        if (!toSend.isEmpty()) {
            ERPBidGuaranteeOutboundService.sendAsync(toSend);
        }
    }
}