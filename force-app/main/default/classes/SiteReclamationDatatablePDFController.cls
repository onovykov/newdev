public without sharing class SiteReclamationDatatablePDFController {
    public List<Reclamation__c> reclamationsList{get;set;}

    public SiteReclamationDatatablePDFController() {
        system.debug(ApexPages.currentPage().getUrl());
        System.debug(ApexPages.currentPage().getParameters());
        String reclamationIds = ApexPages.currentPage().getParameters().get('Ids');
        System.debug(reclamationIds);
        List<Id> ids =(List<id>)  JSON.deserialize(reclamationIds, List<id>.class);
        System.debug(ids);
        this.reclamationsList = [SELECT id, ERP_Number__c, CreatedDate, toLabel(Status__c), Comment__c, Owner.Name, No_Refund__c FROM Reclamation__c
                                WHERE id in: ids];       
        System.debug(this.reclamationsList);                              
    }

    
}