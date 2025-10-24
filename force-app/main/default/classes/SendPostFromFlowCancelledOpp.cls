public class SendPostFromFlowCancelledOpp {
	
    @InvocableMethod
   public static void sendPost(List<String> idCancelledProduct) {
    system.debug(idCancelledProduct);
    Opportunity assignedBOCancelledOpportunity =  [SELECT AssignedBOS__c,Cancel_reason__c,id, MarketSegment__c FROM Opportunity WHERE id=:idCancelledProduct[0] LIMIT 1] ;
    String userIdBO = assignedBOCancelledOpportunity.AssignedBOS__c;
    List<String> toAddressesList = new List<String>();

    if(assignedBOCancelledOpportunity.MarketSegment__c == '00004') {
        toAddressesList = Label.Emails_for_Cancelled_Opportunity.split(';');
    }
    
    String assignedBosId = userIdBO;
    String urlProduction = system.label.OrganizationURL;
    system.debug(userIdBO);  
    
    
    String createMessage =  createMessageEmail(assignedBOCancelledOpportunity,urlProduction,idCancelledProduct[0]);  
    FeedItem post2 = new FeedItem();
    post2.ParentId = assignedBosId;
    post2.Body = createMessage;  
       
       if(assignedBosId!=null){
           insert post2; 
       }
         
  	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();    
    message.optOutPolicy = 'FILTER';
    message.subject = 'Cancelled opportunity';
    message.htmlbody = createMessage; 
       try{                  
           User assignedBosEmail  = [SELECT Email FROM USER WHERE id=:assignedBosId limit 1];
           toAddressesList.add(assignedBosEmail.Email);            
           message.toAddresses = toAddressesList;   
           Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
           Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
       } catch (exception e){
           system.debug(e.getMessage());
       }
   }
    
    public static String createMessageEmail(Opportunity oppToCancel, String urlProduction, String idCancelledProduct){
        String createdMessage;        
        createdMessage = 'Request for cancell opportunity. Reason - ' +oppToCancel.Cancel_reason__c +'. Link: '+ urlProduction+ '/'+idCancelledProduct;
        return createdMessage;
    }
}