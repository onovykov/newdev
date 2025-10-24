public class QuoteLineItemGroupEditController {
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems (Id recordId){
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        quoteLineItems = [SELECT Id, Product2.Name, Description, InquiryUnit__c, Quantity, InquiryQuantity__c, UnitPrice, Quote.Opportunity.CurrencyIsoCode,
                          InquiryUnitPrice__c, Discount, ProductStandard__c, ProductStandard__r.Name, ProductSpecLevel__c, ProductSpecLevel__r.Name, 
                          SteelGrade__c, SteelGrade__r.Name, TubeOD__c, TubeOD__r.Name,
                          TubeWT__c, TubeWT__r.Name, TubeEnds__c, TubeEnds__r.Name, TubeLengthSize__c, TubeLengthSize__r.Name, Weight_kpm__c, Weight_ppf__c, Shop__c, ShippingPoint__c,
                          Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c,Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,Product2.Is_Accessory__c,
                          TubeLengthSize__r.MinLength__c,TubeLengthSize__r.MaxLength__c
                          FROM QuoteLineItem
                          WHERE QuoteId =: recordId];
        
        // Strip fields that are not readable
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            quoteLineItems);
		
        return quoteLineItems;
    }

    @AuraEnabled
    public static String updateQuoteLineItems( Object data ) {
        List < QuoteLineItem > qlisForUpdate = ( List < QuoteLineItem > ) JSON.deserialize(
            JSON.serialize( data ),
            List < QuoteLineItem >.class
        );

        System.debug(data);
        System.debug(JSON.serialize( data ));
        System.debug(qlisForUpdate);

        try {
            update qlisForUpdate;
            return 'Success: QuoteLineItem(s) updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }
}