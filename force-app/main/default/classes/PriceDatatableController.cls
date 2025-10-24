public without sharing class PriceDatatableController {

    @AuraEnabled(cacheable=true)
    public static List<PriceWrapper> getPrices(Id priceListHierarchyId) {
        List<PriceWrapper> priceWrappers = new List<PriceWrapper>();

        List<Price__c> prices = [SELECT Id, OD_mm__r.OD_mm__c, OD_inch__c, WT_mm__r.WT_mm__c, WT_inch__c, Weight_ppf__c, Additional_Information__c, 
                                        Incoterms__c, ShippingPoint__r.Name, Price__c, Margin__c, MarginBG__c, Product_Type__c
                                 FROM Price__c 
                                 WHERE PriceListH__c = :priceListHierarchyId AND Archived__c = false
                                 ORDER BY OD_mm__r.OD_mm__c ASC];

        for (Price__c price : prices) {            
            PriceWrapper priceWrapper = new PriceWrapper(
                price.Id, 
                price.OD_mm__r.OD_mm__c,
                price.WT_mm__r.WT_mm__c, 
                price.OD_inch__c, 
                price.WT_inch__c,
                price.Weight_ppf__c,
                price.Incoterms__c,
                price.ShippingPoint__r.Name,
                price.Price__c,
                price.Margin__c,
                price.MarginBG__c,
                price.Product_Type__c,
                price.Additional_Information__c
            );
            priceWrappers.add(priceWrapper);
            
        }

        return priceWrappers;
    }

    public class PriceWrapper {
        @AuraEnabled public Id priceId {get; set;}
        @AuraEnabled public Decimal odmm {get; set;}
        @AuraEnabled public Decimal wtmm {get; set;}
        @AuraEnabled public Decimal odin {get; set;}
        @AuraEnabled public Decimal wtin {get; set;}
        @AuraEnabled public Decimal ppf {get; set;}
        @AuraEnabled public String incoterms {get; set;}
        @AuraEnabled public String shippingPoint {get; set;}
        @AuraEnabled public Decimal price {get; set;}
        @AuraEnabled public Decimal margin {get; set;}
        @AuraEnabled public Decimal budgetMargin {get; set;}
        @AuraEnabled public String prodType {get; set;}
        @AuraEnabled public String additionalInformation {get; set;}

        public PriceWrapper(Id priceId, Decimal odmm, Decimal wtmm, Decimal odin, Decimal wtin, Decimal ppf, String incoterms,
                            String shippingPoint, Decimal price, Decimal margin, Decimal budgetMargin, String prodType, String additionalInformation) {
            
            this.priceId = priceId;
            this.odmm = odmm;
            this.wtmm = wtmm;
            this.odin = odin;
            this.wtin = wtin;
            this.ppf = ppf;
            this.incoterms = incoterms;
            this.shippingPoint = shippingPoint;
            this.price = price;
            this.margin = margin;
            this.budgetMargin = budgetMargin;
            this.prodType = prodType;
            this.additionalInformation = additionalInformation;
        }
    }
}