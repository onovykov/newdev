global without sharing class SendPostFromFlowRestoreProd {
	
    @InvocableMethod
   public static void sendPost(List<String> idCancelledProduct) {
    system.debug(idCancelledProduct);
    CancelledOpportunityLineItem__c assignedBOCancelledProduct =  [SELECT Owner__r.AssignedBOS__r.Id FROM CancelledOpportunityLineItem__c  where id=:idCancelledProduct[0] LIMIT 1] ;
    String userIdBO = assignedBOCancelledProduct.Owner__r.AssignedBOS__r.Id;   
    String currentUserId = UserInfo.getUserId();
    User getUserInfo = [SELECT contact.account.ownerid, AssignedBOS__c FROM User WHERE id =:currentUserId LIMIT 1];  
    String ownerAccoutId = getUserInfo.contact.account.ownerid; 
    String assignedBosId = userIdBO;
    String urlProduction = system.label.OrganizationURL;
    system.debug(userIdBO);   
    //FeedItem post = new FeedItem();
    //post.ParentId = ownerAccoutId;
    //post.Body = 'Request for cancell opportunity product. Link: '+ urlProduction + '/'+idCancelledProduct[0]; 
       
    FeedItem post2 = new FeedItem();
    post2.ParentId = assignedBosId;
    post2.Body = 'Restore for restore opportunity product. Link: '+ urlProduction + '/'+idCancelledProduct[0];  
       
       if(assignedBosId!=null){
           insert post2; 
       }
       
      // if(ownerAccoutId!=null){
       //    insert post; 
       //}
  Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    
    message.optOutPolicy = 'FILTER';
    message.subject = 'Restore opportunity product';
    message.htmlbody = 'Request for restore opportunity product. Link: '+ urlProduction+ '/'+idCancelledProduct[0]; 
       try{
           User ownerEmail  = [SELECT email FROM user WHERE id =:ownerAccoutId limit 1];   
           User assignedBosEmail  = [SELECT Email FROM USER WHERE id=:assignedBosId limit 1]; 
           message.toAddresses = new String[] { assignedBosEmail.Email};   
           Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
           Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
       } catch (exception e){
           system.debug(e.getMessage());
       }
      
   }

}