public without sharing class SiteOrderDatatablePDFController {
    public List<Order> ordersList{get;set;}

    public SiteOrderDatatablePDFController() {
        system.debug(ApexPages.currentPage().getUrl());
        System.debug(ApexPages.currentPage().getParameters());
        String orderIds = ApexPages.currentPage().getParameters().get('Ids');
        List<Id> ids =(List<id>)  JSON.deserialize(orderIds, List<id>.class);
        this.ordersList = [SELECT AdditionalNumber__c, OrderNumber, EffectiveDate, Status, TotalOrderQuantity__c, ProducedQuantity__c, DispatchedQuantity__c,  ShippedQuantity__c 
                            FROM Order 
                            WHERE id in: ids LIMIT 100];   
    }

    
}