public with sharing class OppEnvelope {

    public Metadata Metadata;
    public DataBase Data;

    public class Metadata {
        public String MsgType;
        public String MsgTypeVersion;

        // raw value from ERP, useful for logging/debug
        public String MsgTimestampRaw;

        // normalized value, populated in OppDtoFactory
        public Datetime MsgTimestamp;

        public Integer PartNumber;
        public Integer TotalParts;
    }

    // Common part of Data. Concrete subclasses: TubesData, WheelsData
    public abstract class DataBase {
        public String OrderType;
        public String OrderCurrency;
        public Header Header;
    }

    public class Header {
        public Long Undoc;

        public String IteNumber;
        public String AltNumber;
        public String PONumber;
        public String ID_SF;

        public Datetime CreatedDate;
        public Datetime OrderDate;

        public AccountRef Account;

        // ALL ERP codes / IDs are Strings
        public String BusinessSegmentId;
        public String RegionId;
        public String CountryId;

        public NamedRef PaymentTerms;
        public DeliveryTermsRef DeliveryTerms;

        public UserRef SalesRep;
        public UserRef BoSpecialist;

        public String CrossMarket_BusinessSegment;
        public UserRef CrossMarket_SalesRep;

        // business value, not code
        public Decimal CrossMarket_Percent;
    }

    public class AccountRef {
        public String Name;

        // ERP code -> String
        public String CountryId;

        public String Address;

        // ERP id -> String
        public String Id;
    }

    public class NamedRef {
        public String Name;
        public String Id;
    }

    public class DeliveryTermsRef {
        public String Name;
        public String Incoterms;
        public String Id;
    }

    public class UserRef {
        public String Name;

        // ERP identifiers/codes -> String
        public String UId;
        public String UserId;
        public String Email;
        public String Id;
    }
}