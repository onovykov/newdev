public class OrderInboundDTO {

    public String externalOrderNumber;
    public Date requestedDeliveryDate;
    public List<Item> items = new List<Item>();

    public class Item {
        public String externalItemKey; // ITENumber__c
        public String sapItemNumber;   // POSEX
        public String materialNumber;
        public Decimal quantity;
    }
}