public class ERPBidGuaranteeOutboundDTO {

    public String idErp;
    public String iteNumber;

    public String bidGuarantees;
    public Datetime changedAt;
    public ERPUserDTO changedBy;

    public class ERPUserDTO {
        public String login;
    }
}