public class ContentDocumentLink_TriggerHandler {
    public  void OnAfterInsert(){
        Set<ID> contentDocIds = new Set<ID>();
        for(ContentDocumentLink cdl: (List<ContentDocumentLink>) Trigger.new){
            contentDocIds.add(cdl.ContentDocumentId);
        }
        
        Set<Id> CustomerEnquiryIds = new Set<Id>();
        Map<String,String> CustomerEnquiryMap = new Map<String,String>();
        
        for(ContentDocumentLink cdlObj: (List<ContentDocumentLink>) Trigger.new)
        {
                CustomerEnquiryIds.add(cdlObj.LinkedEntityId);            
        }
        for(CustomerEnquiry__c e:[select id, OpportunityId__c from CustomerEnquiry__c where Id IN:CustomerEnquiryIds]){
            CustomerEnquiryMap.put(e.Id, e.OpportunityId__c);
        }
        Map<String,String> parentRecMap = new Map<String,String>();
        for(ContentDocumentLink cdl: (List<ContentDocumentLink>) Trigger.new){
         
                    parentRecMap.put(cdl.ContentDocumentId, CustomerEnquiryMap.get(cdl.LinkedEntityId));
           
        }
        List<ContentDocumentLink> cdl_List = new List<ContentDocumentLink>();
        if(ContentDocumentLink_TriggerHelper.Flag == true){
            ContentDocumentLink_TriggerHelper.Flag = false;
            for(String str: parentRecMap.keySet()){
                ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Opportunity(Parent) record
                cdl.LinkedEntityId = parentRecMap.get(str); // Opportunity ID
                cdl.ContentDocumentId = str; //Content Dcoument ID
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                cdl_List.add(cdl);
                
            }
        }
        system.debug('Size : '+ cdl_List);
        if(cdl_List.size()>0)
            ContentDocumentLink_TriggerHelper.shareFile(cdl_List);// Insert Content Document Link to share the file with Opportunity 
        
    }
}