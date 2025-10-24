public abstract with sharing class ItemBase {
    public Long Undoc { get; set; }
    public Integer Npp { get; set; }
    public String IteNumber { get; set; }
    public OppEnvelope.NamedRef ProductGroup { get; set; }
    public QuotaTypeRef QuotaType { get; set; }
    public ShopRef Shop { get; set; }

    public Decimal InqQuantity { get; set; }
    public Integer InqUnit { get; set; }
    public Decimal Quantity_Mt { get; set; }
    public Decimal Quantity_m { get; set; }
    public Decimal Quantity_ft { get; set; }
    public Decimal Quantity_pcs { get; set; }
    public Decimal LinearWeight_ppf { get; set; }
    public Decimal LinearWeight_kpm { get; set; }

    public Decimal Price { get; set; }
    public Decimal Price_t { get; set; }
    public Decimal Margin_t { get; set; }
    public Decimal TotalPrice { get; set; }

    public ShippingPointRef ShippingPoint { get; set; }
    public Integer IsTypical { get; set; }
    public Integer TechExp { get; set; }

    public Datetime CriticalDispatchDate { get; set; }
    public Datetime RecommendedCDD { get; set; }
    public Datetime RequestedDeliveryDate { get; set; }
    public Datetime ConfirmedDeliveryDate { get; set; }

    public String FinStatus { get; set; }
    public Integer FinApproval { get; set; }
    public String Stage { get; set; }

    public Decimal Produced { get; set; }
    public Decimal Dispatched { get; set; }
    public Decimal Shipped { get; set; }

    public List<LotRef> Lots { get; set; }
    public List<Object> Quotas { get; set; }

    public Decimal FinDataShipped { get; set; }
    public Decimal FinDataMargin { get; set; }

    public String CoatingSpec { get; set; }
    public OppEnvelope.NamedRef SpecLevel { get; set; }
    public String NPS { get; set; }
    public String SCH { get; set; }
    public String Mark1 { get; set; }
    public Boolean Print_Inch { get; set; }
    public Boolean Print_NPS { get; set; }
    public Boolean Print_Mark { get; set; }
    public Decimal WeightMainUnit_kg { get; set; }

    public class QuotaTypeRef {
        public OppEnvelope.NamedRef Shop { get; set; }
        public String Name { get; set; }
        public String Id { get; set; }
    }
    public class ShopRef {
        public OppEnvelope.NamedRef Mill { get; set; }
        public String Name { get; set; }
        public String Id { get; set; }
    }
    public class ShippingPointRef {
        public Integer spType { get; set; }
        public String Id { get; set; }
        public String Name { get; set; }
    }
    public class LotRef {
        public Datetime LotDate { get; set; }
        public Decimal Produced { get; set; }
        public Decimal Dispatched { get; set; }
        public Decimal Shipped { get; set; }
    }
}