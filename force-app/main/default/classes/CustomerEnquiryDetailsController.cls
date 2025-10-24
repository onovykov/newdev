public class CustomerEnquiryDetailsController {
	@AuraEnabled
    public static  List<WrapperProducts> takeInitialInfo(String recordId){
        
        List<WrapperProducts> wrapingProducts = new List<WrapperProducts>();
        //String dataForOpp;
              
        String oppId = [SELECT OpportunityId__c FROM CustomerEnquiry__c WHERE id=:recordId LIMIT 1].OpportunityId__c;
        system.debug(oppId);
        List<OpportunityLineItem> oppLiItem = [SELECT id,Name,Product2.Name,toLabel(InquiryUnit__c),InquiryQuantity__c,Quantity,ITENumber__c FROM OpportunityLineItem WHERE OpportunityId=:oppId];
        //dataForOpp = [SELECT Name FROM Opportunity WHERE id=:oppId LIMIT 1].Name;
        system.debug(oppLiItem);
        for(OpportunityLineItem oppli : oppLiItem){
            
            WrapperProducts wp = new WrapperProducts();                            
            wp.id = oppli.id;
            wp.product = oppli.Name;
            wp.productName = oppli.Product2.Name;
            wp.measurementUnit = oppli.InquiryUnit__c;
            wp.quantity = oppli.InquiryQuantity__c;
            wp.quantityT = oppli.Quantity;
            wp.iteNumber = oppli.ITENumber__c;
            system.debug(wp);
            wrapingProducts.add(wp);
                        
        }
                
        system.debug(wrapingProducts);
        return wrapingProducts;
    }
    
    public class WrapperProducts {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String product;
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public String measurementUnit;
        @AuraEnabled
        public Decimal quantity;
        @AuraEnabled
        public Decimal quantityT;
        @AuraEnabled
        public String iteNumber;
    }
}