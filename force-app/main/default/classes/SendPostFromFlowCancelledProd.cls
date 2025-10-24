global without sharing class SendPostFromFlowCancelledProd {
	
    @InvocableMethod
   public static void sendPost(List<String> idCancelledProduct) {
    system.debug(idCancelledProduct);
    opportunitylineitem assignedBOCancelledProduct =  [SELECT Opportunity.Owner__r.AssignedBOS__r.Id,Is_Placed__c FROM opportunitylineitem  where id=:idCancelledProduct[0] LIMIT 1] ;
    String userIdBO = assignedBOCancelledProduct.Opportunity.Owner__r.AssignedBOS__r.Id;   
    String currentUserId = UserInfo.getUserId();
    User getUserInfo = [SELECT contact.account.ownerid, AssignedBOS__c FROM User WHERE id =:currentUserId LIMIT 1];  
    String ownerAccoutId = getUserInfo.contact.account.ownerid; 
    String assignedBosId = userIdBO;
    String urlProduction = system.label.OrganizationURL;
    system.debug(userIdBO);  
    system.debug(getUserInfo); 
       system.debug(getUserInfo.id); 
    //FeedItem post = new FeedItem();
    //post.ParentId = ownerAccoutId;
    //post.Body = 'Request for cancell opportunity product. Link: '+ urlProduction + '/'+idCancelledProduct[0]; 
    String createMessage =  createMessageEmail(assignedBOCancelledProduct,urlProduction,idCancelledProduct[0]);  
    FeedItem post2 = new FeedItem();
    post2.ParentId = assignedBosId;
    post2.Body = createMessage;  
       
       if(assignedBosId!=null){
           insert post2; 
       }
       
      // if(ownerAccoutId!=null){
       //    insert post; 
       //}
  	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();    
    message.optOutPolicy = 'FILTER';
    message.subject = 'Cancell opportunity product';
    message.htmlbody = createMessage; 
       try{
           system.debug('before owner email');  
           User ownerEmail  = [SELECT email FROM user WHERE id =:ownerAccoutId limit 1]; 
           system.debug('before BO email');
           User assignedBosEmail  = [SELECT Email FROM USER WHERE id=:assignedBosId limit 1]; 
           system.debug('after all');
           message.toAddresses = new String[] { assignedBosEmail.Email};   
           Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
           Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
       } catch (exception e){
           system.debug(e.getMessage());
       }
      
   }
    
    public static String createMessageEmail(OpportunityLineItem oppProductToCancel, String urlProduction, String idCancelledProduct){
        String createdMessage;
        if(oppProductToCancel.Is_Placed__c){
            createdMessage = 'Request for cancell opportunity product.This product already placed - to confirm cancel, contact with Chief Sales Officer. Link product: '+ urlProduction+ '/'+idCancelledProduct;
        }else{
            createdMessage = 'Request for cancell opportunity product. Link: '+ urlProduction+ '/'+idCancelledProduct;
        }
        return createdMessage;
        
    }
}