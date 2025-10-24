global class UpdateInquiryOnQuoteItemsBatch implements Database.Batchable<SObject> {
	
    global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator('SELECT Id,InquiryQuantity__c, InquiryUnit__c,Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,Quantity,Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c,InquiryUnitPrice__c,UnitPrice FROM QuoteLineItem' );
	}
    
    global void execute(Database.BatchableContext context, List<QuoteLineItem> scope) {
		
        List<QuoteLineItem> qliListToUpdate = new List<QuoteLineItem>();
        for (QuoteLineItem q : scope) {
            
            //t
            if(q.InquiryUnit__c == '34'){
                q.Quantity = q.Quantity==null? q.InquiryQuantity__c : q.Quantity;
                             
            }
            
            //m
            if(q.InquiryUnit__c == '20'){
                q.Quantity_m__c = q.Quantity_m__c==null? q.InquiryQuantity__c : q.Quantity_m__c ;
                q.Sales_Price_m__c = q.Sales_Price_m__c==null? q.InquiryUnitPrice__c:q.Sales_Price_m__c;
            }
            
            //ft
            if(q.InquiryUnit__c == '74'){
                q.Quantity_ft__c = q.Quantity_ft__c==null? q.InquiryQuantity__c : q.Quantity_ft__c;
                q.Sales_Price_ft__c = q.Sales_Price_ft__c==null? q.InquiryUnitPrice__c : q.Sales_Price_ft__c;
            }
            
            //pcs
            if(q.InquiryUnit__c == '43'){
                q.Quantity_pcs__c = q.Quantity_pcs__c==null ? q.InquiryQuantity__c : q.Quantity_pcs__c;
                q.Sales_Price_pcs__c = q.Sales_Price_pcs__c==null? q.InquiryUnitPrice__c : q.Sales_Price_pcs__c;
            }
            qliListToUpdate.add(q);
        }
        update qliListToUpdate;

	}
    
    global void finish(Database.BatchableContext context) {
		
	}
    
}