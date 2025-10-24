@isTest
public class PreviewPdfControllerTestFactory {
    public static PaymentTerms__c createPaymentTerms () {
        PaymentTerms__c pt = new PaymentTerms__c(Name='pt_name_1');
        return pt;
    }
    
    public static DeliveryTerms__c createDeliveryTerms () {
        DeliveryTerms__c dt = new DeliveryTerms__c(Name='dt_name_1', Incoterms__c='FOB');
        return dt;
    }
    
    public static Quote createQuote (Id opp_id, Id pt_id, Id dt_id) {
        Quote qt = new Quote(Name='qt_name_1', Status='Draft', ExpirationDate=Date.today(), OpportunityId=opp_id, PaymentTerms__c=pt_id, DeliveryTerms__c=dt_id);
        return qt;
    }
    
    public static Opportunity createOpportunity () {
        Account acc = new Account(Name='acc_name_1');
        acc.ID_ERP__c = '123457';
        insert acc;
        
        Opportunity opp = new Opportunity(Name='opp_name_1', Type='Ordinary Selling', StageName='Qualification', CloseDate=Date.today() + 30, AccountId=acc.Id, CurrencyIsoCode='EUR');
        return opp;
    }
    
    public static List<QuoteLineItem> creqteQuoteLineItems(OpportunityLineItem oli, Id QuoteId,Integer amount){
        List<QuoteLineItem> createdItems = new List<QuoteLineItem>();
        for(Integer i = 0; i< amount; i++){
            QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = QuoteId, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id);
            createdItems.add(qli);
        }
        return createdItems;
    }
    
    public static List<QuoteLineItem> creqteQuoteLineItemsWithTrueShowInPDF(OpportunityLineItem oli, Id QuoteId,Integer amount){
        List<QuoteLineItem> createdItems = new List<QuoteLineItem>();
        for(Integer i = 0; i< amount; i++){
            QuoteLineItem qli = new QuoteLineItem(OpportunityLineItemId = oli.Id, QuoteId = QuoteId, PriceBookEntryId = oli.PriceBookEntryId,
                                              Quantity=oli.Quantity, UnitPrice=oli.UnitPrice, InquiryQuantity__c=oli.InquiryQuantity__c, 
                                              InquiryUnitPrice__c=oli.InquiryUnitPrice__c, Product2Id = oli.Product2Id,showInPDF__c=true);
            createdItems.add(qli);
        }
        return createdItems;
    }
}