public with sharing class TubesData extends OppEnvelope.DataBase {

    // Helper types (outer-level, single nesting only)
    public class Dim { public Decimal OD_mm {get;set;} public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Wt  { public Decimal Wt_mm {get;set;} public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Length { public Integer MinLength {get;set;} public Integer MaxLength {get;set;} public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Facet { public String Name {get;set;} public String FacetCode {get;set;} public String Id {get;set;} }
    public class Std { public String Name {get;set;} public String Id {get;set;} }
    public class NameForDoc { public String Id {get;set;} public Map<String,String> Name {get;set;} }

    public class ProductCharacteristic {
        public Dim Diameter { get; set; }
        public Wt Thickness { get; set; }
        public Length LengthSize { get; set; }
        public Facet Ends { get; set; }
        public Facet Coating { get; set; }
        public Std Standard { get; set; }
        public Facet SteelGrade { get; set; }
        public NameForDoc NameForDoc { get; set; }
    }

    public class TubesItem extends ItemBase {
        public ProductCharacteristic ProductCharacteristic { get; set; }
    }

    public List<TubesItem> Items { get; set; }
}