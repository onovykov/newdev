public class ERPBidGuaranteeInboundDTO {

    public String idErp;              // ID_ERP__c
    public String iteNumber;           // ITENumber__c (fallback)
    public String bidGuarantees;       // New value
    public Datetime changedAt;         // When change happened in ERP
    public ERPUserDTO changedBy;       // ERP user

    public class ERPUserDTO {
        public String login;           // LoginERP__c
    }
}