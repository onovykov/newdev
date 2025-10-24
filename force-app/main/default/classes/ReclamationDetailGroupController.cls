public class ReclamationDetailGroupController {

    @AuraEnabled(cacheable=true)
    public static List<Reclamation_Detail__c> getReclamationDetail (Id recordId){
        
        List<Reclamation_Detail__c> reclamationDetailList = new List<Reclamation_Detail__c>();
        reclamationDetailList = [SELECT ITENumber__c, OrderItemID__r.Product2.Name,ClaimSum__c,ClaimQty__c,  OrderItemID__r.Name__c,CurrencyIsoCode,OrderID__r.AdditionalNumber__c,
                                 OrderQty__c,toLabel(Mistmatch_Type__c),toLabel(Mistmatch_SubType__c),PO_Number__c,Order_Additional_Number__c FROM Reclamation_Detail__c WHERE ReclID__c =: recordId];
        
        // Strip fields that are not readable      
		
        return reclamationDetailList;
    }
}