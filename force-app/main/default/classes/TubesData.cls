public with sharing class TubesData extends OppEnvelope.DataBase {

    public List<Item> Items;

    public class Item {
        public Long Undoc;
        public Integer Npp;
        public String IteNumber;
        public String KMAT;

        public OppEnvelope.NamedRef ProductGroup;
        public QuotaType QuotaType;
        public Shop Shop;

        public Decimal InqQuantity;
        public String InqUnit;

        public Decimal Quantity_Mt;
        public Decimal Quantity_m;
        public Decimal Quantity_ft;
        public Decimal Quantity_pcs;

        public Decimal LinearWeight_ppf;
        public Decimal LinearWeight_kpm;

        public Decimal Price;
        public Decimal Price_t;
        public Decimal Margin_t;
        public Decimal TotalPrice;

        public ShippingPoint ShippingPoint;

        public Integer IsTypical;
        public Integer TechExp;

        public Datetime CriticalDispatchDate;
        public Datetime RecommendedCDD;
        public Datetime RequestedDeliveryDate;
        public Datetime ConfirmedDeliveryDate;

        public String FinStatus;
        public Integer FinApproval;
        public String Stage;

        public Decimal Produced;
        public Decimal Dispatched;
        public Decimal Shipped;

        public List<Lot> Lots;
        public List<Object> Quotas;

        public Decimal FinDataShipped;
        public Decimal FinDataMargin;

        public ProductCharacteristic ProductCharacteristic;

        public String CoatingSpec;
        public OppEnvelope.NamedRef SpecLevel;

        public String NPS;
        public String SCH;
        public String Mark1;

        public Boolean Print_Inch;
        public Boolean Print_NPS;
        public Boolean Print_Mark;

        public Decimal WeightMainUnit_kg;
    }

    public class Lot {
        public Datetime LotDate;
        public Decimal Produced;
        public Decimal Dispatched;
        public Decimal Shipped;
    }

    public class FacetRef {
        public String Code;
        public String Id;
    }

    public class NameRef {
        public String Id;
        public String Name;
    }

    public class ProductCharacteristic {
        public Diameter Diameter;
        public Thickness Thickness;
        public LengthSize LengthSize;
        public ProductOption Ends;
        public ProductOption Coating;
        public Standard Standard;
        public SteelGrade SteelGrade;
        public NameForDoc NameForDoc;
    }

    public class Diameter {
        public Decimal OD_mm;
        public String Name;
        public FacetRef Facet;

        // legacy support
        public String FacetCode;
        public String Id;
    }

    public class Thickness {
        public Decimal Wt_mm;
        public String Name;
        public FacetRef Facet;

        // legacy support
        public String FacetCode;
        public String Id;
    }

    public class LengthSize {
        public Decimal MinLength;
        public Decimal MaxLength;
        public String Name;
        public FacetRef Facet;

        // legacy support
        public String FacetCode;
        public String Id;
    }

    public class ProductOption {
        public String Name;
        public FacetRef Facet;

        // legacy support
        public String FacetCode;
        public String Id;
    }

    public class Standard {
        public FacetRef Facet;
        public NameRef StdNameRef;

        // tolerant / mixed-json support
        public String Id;
        public String Name;
        public String FacetCode;
        public String FacetId;
    }

    public class SteelGrade {
        public String Name;
        public FacetRef Facet;

        // legacy support
        public String FacetCode;
        public String Id;
    }

    public class NameForDoc {
        public String Id;
        public LocalizedName Name;
    }

    public class LocalizedName {
        public String defaultLng;
        public String En;
        public String Uk;
    }

    public class ShippingPoint {
        public String spType;
        public String Id;
        public String Name;
    }

    public class QuotaType {
        public OppEnvelope.NamedRef Shop;
        public String Name;
        public String Id;
    }

    public class Shop {
        public OppEnvelope.NamedRef Mill;
        public String Name;
        public String Id;
    }
}