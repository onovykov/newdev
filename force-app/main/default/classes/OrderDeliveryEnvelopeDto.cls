public class OrderDeliveryEnvelopeDto {

    public MetadataDto Metadata;
    public OrderDeliveryDto Data;

    public class MetadataDto {
        public String MsgType;
        public Decimal MsgTypeVersion;
        public Datetime MsgTimestamp;
        public Integer PartNumber;
        public Integer TotalParts;
    }
}