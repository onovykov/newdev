public with sharing class SiteEnquiryDatatablePDFController {
    public List<CustomerEnquiry__c> enquiriesList{get;set;}

    public SiteEnquiryDatatablePDFController() {
        system.debug(ApexPages.currentPage().getUrl());
        System.debug(ApexPages.currentPage().getParameters());
        String enquiriesIds = ApexPages.currentPage().getParameters().get('Ids');
        List<Id> ids =(List<id>)  JSON.deserialize(enquiriesIds, List<id>.class);
        this.enquiriesList = [SELECT Name, AccountId__c, CreatedDate, Status__c, SalesRepId__c, SalesRepId__r.Name, CreatedBy.Name ,OrderId__r.ITENumber__c,OpportunityId__r.StageName
                            FROM CustomerEnquiry__c
                            WHERE id in: ids LIMIT 100];             
    }

}