public with sharing class OppEnvelope {
    public Metadata Metadata { get; set; }
    public DataBase Data { get; set; }

    public class Metadata {
        public String MsgType { get; set; }
        public Decimal MsgTypeVersion { get; set; }
        public Datetime MsgTimestamp { get; set; }
        public Integer PartNumber { get; set; }
        public Integer TotalParts { get; set; }
    }

    // Common part of Data. Concrete subclasses: TubesData, WheelsData
    public abstract class DataBase {
        public String OrderType { get; set; }      // "Tubes" | "Wheels" | ...
        public String OrderCurrency { get; set; }
        public Header Header { get; set; }
    }

    public class Header {
        public Long Undoc { get; set; }
        public String IteNumber { get; set; }
        public String AltNumber { get; set; }
        public String PONumber { get; set; }
        public String ID_SF { get; set; }
        public Datetime CreatedDate { get; set; }
        public Datetime OrderDate { get; set; }
        public AccountRef Account { get; set; }
        public String BusinessSegmentId { get; set; }
        public Integer RegionId { get; set; }
        public Integer CountryId { get; set; }
        public NamedRef PaymentTerms { get; set; }   // {Name, Id}
        public DeliveryTermsRef DeliveryTerms { get; set; } // {Name, Incoterms, Id}
        public UserRef SalesRep { get; set; }
        public UserRef BoSpecialist { get; set; }
        public String CrossMarket_BusinessSegment { get; set; }
        public UserRef CrossMarket_SalesRep { get; set; }
        public Decimal CrossMarket_Percent { get; set; }
    }

    public class AccountRef {
        public String Name { get; set; }
        public Integer CountryId { get; set; }
        public String Address { get; set; }
        public String Id { get; set; }
    }
    public class NamedRef {
        public String Name { get; set; }
        public String Id { get; set; }
    }
    public class DeliveryTermsRef {
        public String Name { get; set; }
        public String Incoterms { get; set; }
        public String Id { get; set; }
    }
    public class UserRef {
        public String Name { get; set; }
        public String UserId { get; set; }
        public String Email { get; set; }
        public String Id { get; set; }
    }
}