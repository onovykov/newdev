public class EDI_ORDERS05_DTO {

    public String documentNumber;
    public Date requestedDeliveryDate;

    public List<Item> items = new List<Item>();

    public class Item {
        public String sapItemNumber;
        public String extKey;
        public String materialNumber;
        public Decimal quantity;
    }
}