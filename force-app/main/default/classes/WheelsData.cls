public with sharing class WheelsData extends OppEnvelope.DataBase {

    // Helper types (outer-level, single nesting only)
    public class Dim { public Decimal OD_mm {get;set;} public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Hub { public Decimal Wt_mm {get;set;} public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Facet { public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Std { public String Name {get;set;} public String Id {get;set;} }
    public class NameForDoc { public String Id {get;set;} public Map<String,String> Name {get;set;} }

    public class ProductCharacteristic {
        public Integer Specification { get; set; }
        public Dim Diameter { get; set; }
        public Hub Hub { get; set; }
        public Facet Drawing { get; set; }
        public Std Standard { get; set; }
        public Facet SteelGrade { get; set; }
        public NameForDoc NameForDoc { get; set; }
    }

    public class WheelsItem extends ItemBase {
        public ProductCharacteristic ProductCharacteristic { get; set; }
    }

    public List<WheelsItem> Items { get; set; }
}