public class AllPricesDatatableController {
    @AuraEnabled (cacheable=true)
    public static List<PriceWrapper> getPrices() {
        List<PriceWrapper> priceWrappers = new List<PriceWrapper>();

        List<Price__c> prices = [SELECT Id, OD_mm__r.OD_mm__c, OD_inch__c, WT_mm__r.WT_mm__c, WT_inch__c, Weight_ppf__c, Additional_Information__c, 
                                        Incoterms__c, ShippingPoint__r.Name, Price__c, Margin__c, MarginBG__c, Product_Type__c, Country__r.Name,
                                        Shop__r.Name, Product__r.Name, SteelGradeGroup__r.Name, CurrencyIsoCode, OD_mm_max__r.OD_mm__c, WT_mm_max__r.WT_mm__c,
                                        OD_inch_max__c, WT_inch_max__c
                                 FROM Price__c
                                 WHERE Archived__c = false
                                 ORDER BY Country__r.Name, OD_mm__r.OD_mm__c ASC
                                 LIMIT 100];

        for (Price__c price : prices) {            
            PriceWrapper priceWrapper = new PriceWrapper(price);
            priceWrappers.add(priceWrapper);
        }

        return priceWrappers;
    }

    @AuraEnabled (cacheable=true)
    public static List<PriceWrapper> getFilteredPrices(Map<String, String> filters, Map<String, String> fieldsTypes, Map<String, String> fieldsMax) {
        String query = 'SELECT Id, OD_mm__r.OD_mm__c, OD_inch__c, WT_mm__r.WT_mm__c, WT_inch__c, Weight_ppf__c, Additional_Information__c, ' +
                    'Incoterms__c, ShippingPoint__r.Name, Price__c, Margin__c, MarginBG__c, Product_Type__c, Country__r.Name, SteelGradeGroup__r.Name, ' +
                    'Shop__r.Name, Product__r.Name, CurrencyIsoCode, OD_mm_max__r.OD_mm__c, WT_mm_max__r.WT_mm__c, OD_inch_max__c, WT_inch_max__c ' +
                    'FROM Price__c WHERE Id != null';

        for (String key : filters.keySet()) {
            String value = filters.get(key);
            String type = fieldsTypes.get(key);
            String maxField = fieldsMax.get(key);
            if (!String.isEmpty(value)) {
                if(type == 'number') {
                    if(maxField != null) {
                        if (value.startsWith('>=')) {
                            query += ' AND ((' + key + ' >= ' + value.substring(2).trim() + ' AND ' + maxField + ' = null) OR (' + key + ' <= ' 
                                    + value.substring(2).trim() + ' AND ' + maxField + ' >= ' + value.substring(2).trim() + '))';
                        } else if (value.startsWith('<=')) {
                            query += ' AND ((' + key + ' <= ' + value.substring(2).trim() + ' AND ' + maxField + ' = null) OR (' + key + ' <= ' 
                                    + value.substring(2).trim() + ' AND ' + maxField + ' >= ' + value.substring(2).trim() + '))';
                        } else if (value.startsWith('>')) {
                            query += ' AND ((' + key + ' > ' + value.substring(1).trim() + ' AND ' + maxField + ' = null) OR (' + key + ' <= ' 
                                    + value.substring(1).trim() + ' AND ' + maxField + ' >= ' + value.substring(1).trim() + '))';
                        } else if (value.startsWith('<')) {
                            query += ' AND ((' + key + ' < ' + value.substring(1).trim() + ' AND ' + maxField + ' = null) OR (' + key + ' <= ' 
                                    + value.substring(1).trim() + ' AND ' + maxField + ' >= ' + value.substring(1).trim() + '))';
                        } else if (value.startsWith('=')) {
                            query += ' AND ((' + key + ' = ' + value.substring(1).trim() + ' AND ' + maxField + ' = null) OR (' + key + ' <= ' 
                                    + value.substring(1).trim() + ' AND ' + maxField + ' >= ' + value.substring(1).trim() + ')))';
                        } else if (!value.contains(',') && !value.contains('.')) {
                            query += ' AND ((' + key + ' >= ' + value + ' AND ' + key + ' <= ' + value + '.9999) OR (' + maxField + ' >= ' + value 
                                    + ' AND ' + maxField + ' <= ' + value + '.9999) OR (' + key + ' <= ' + value + ' AND ' + maxField + ' >= ' + value + '))';
                        } else {
                            query += ' AND ((' + key + ' >= ' + value + ' AND ' + key + ' <= ' + value + '9999) OR (' + maxField + ' >= ' + value 
                                    + ' AND ' + maxField + ' <= ' + value + '9999) OR (' + key + ' <= ' + value + ' AND ' + maxField + ' >= ' + value + '))';
                        }
                    } else {
                        if (value.startsWith('>=')) {
                            query += ' AND ' + key + ' >= ' + value.substring(2).trim();
                        } else if (value.startsWith('<=')) {
                            query += ' AND ' + key + ' <= ' + value.substring(2).trim();
                        } else if (value.startsWith('>')) {
                            query += ' AND ' + key + ' > ' + value.substring(1).trim();
                        } else if (value.startsWith('<')) {
                            query += ' AND ' + key + ' < ' + value.substring(1).trim();
                        } else if (value.startsWith('=')) {
                            query += ' AND ' + key + ' = ' + value.substring(1).trim();
                        } else if (!value.contains(',') && !value.contains('.')) {
                            query += ' AND ' + key + ' >= ' + value + ' AND ' + key + ' <= ' + value + '.9999';
                        } else {
                            query += ' AND ' + key + ' >= ' + value + ' AND ' + key + ' <= ' + value + '9999';
                        }
                    }
                } else {
                    query += ' AND ' + key + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
                }
            }
        }

        System.debug('query : ' + JSON.serialize(query));

        query += ' ORDER BY Country__r.Name, OD_mm__r.OD_mm__c ASC LIMIT 100';

        List<Price__c> prices = Database.query(query);
        List<PriceWrapper> priceWrappers = new List<PriceWrapper>();

        for (Price__c price : prices) {
            PriceWrapper priceWrapper = new PriceWrapper(price);
            priceWrappers.add(priceWrapper);
        }

        return priceWrappers;
    }

    public class PriceWrapper {
        @AuraEnabled public Id priceId {get; set;}
        @AuraEnabled public String odmm {get; set;}
        @AuraEnabled public String wtmm {get; set;}
        @AuraEnabled public String odin {get; set;}
        @AuraEnabled public String wtin {get; set;}
        @AuraEnabled public Decimal ppf {get; set;}
        @AuraEnabled public String incoterms {get; set;}
        @AuraEnabled public String shippingPoint {get; set;}
        @AuraEnabled public Decimal price {get; set;}
        @AuraEnabled public Decimal margin {get; set;}
        @AuraEnabled public Decimal budgetMargin {get; set;}
        @AuraEnabled public String prodType {get; set;}
        @AuraEnabled public String additionalInformation {get; set;}
        @AuraEnabled public String country {get; set;}
        @AuraEnabled public String shop {get; set;}
        @AuraEnabled public String product {get; set;}
        @AuraEnabled public String steelGrade {get; set;}
        @AuraEnabled public String priceCurrency {get; set;}

        public PriceWrapper(Price__c price) {
            this.priceId = price.Id;
            this.odmm = price.OD_mm_max__r == null ? price.OD_mm__r == null ? null :
                        String.valueOf(price.OD_mm__r?.OD_mm__c.setScale(2)) : 
                        String.valueOf(price.OD_mm__r.OD_mm__c.setScale(2)) + ' - ' + String.valueOf(price.OD_mm_max__r.OD_mm__c.setScale(2));
            this.wtmm = price.WT_mm_max__r == null ? price.WT_mm__r == null ? null :
                        String.valueOf(price.WT_mm__r?.WT_mm__c.setScale(2)) : 
                        String.valueOf(price.WT_mm__r.WT_mm__c.setScale(2)) + ' - ' + String.valueOf(price.WT_mm_max__r.WT_mm__c.setScale(2));
            this.odin = price.OD_mm_max__r == null ? price.OD_inch__c == null ? null :
                        String.valueOf(price.OD_inch__c?.setScale(2)) :
                        String.valueOf(price.OD_inch__c.setScale(2)) + ' - ' + String.valueOf(price.OD_inch_max__c.setScale(2));
            this.wtin = price.WT_mm_max__r == null ? price.WT_inch__c == null ? null :
                        String.valueOf(price.WT_inch__c) : 
                        String.valueOf(price.WT_inch__c) + ' - ' + String.valueOf(price.WT_inch_max__c);
            this.ppf = price.Weight_ppf__c;
            this.incoterms = price.Incoterms__c;
            this.shippingPoint = price.ShippingPoint__r.Name;
            this.price = price.Price__c;
            this.margin = price.Margin__c;
            this.budgetMargin = price.MarginBG__c;
            this.prodType = price.Product_Type__c;
            this.additionalInformation = price.Additional_Information__c;
            this.country = price.Country__r.Name;
            this.shop = price.Shop__r.Name;
            this.product = price.Product__r.Name;
            this.steelGrade = price.SteelGradeGroup__r.Name;
            this.priceCurrency = price.CurrencyIsoCode;
        }
    }
}