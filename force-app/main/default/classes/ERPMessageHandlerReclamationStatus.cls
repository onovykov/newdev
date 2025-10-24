public class ERPMessageHandlerReclamationStatus {
    
        
    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_ClaimStage parsedMessage, String requestBody) {
        MessageProcessingResult res = new MessageProcessingResult();
		      
        res.MessageType = parsedMessage.metadata.MsgType;
        system.debug(parsedMessage);
        Reclamation__c reclamationForUpdate = findReclamation(parsedMessage,res);
        
        String statusForUpdate = parsedMessage.data.STAGE;
        String claimDecision = parsedMessage.data.K_DEC;
        Decimal CompensationAmount = parsedMessage.data.PAY_AMNT;
        String ReclamationSummary = parsedMessage.data.DES_AMNT;

        system.debug('statusForUpdate' + statusForUpdate);
        system.debug('claimDecision' + claimDecision);
        system.debug('CompensationAmount' + CompensationAmount);
        system.debug('ReclamationSummary' + ReclamationSummary);

        if(statusForUpdate == '_1'){
            statusForUpdate = '_1';
        }else if(statusForUpdate == '_2' || statusForUpdate == '3' || statusForUpdate == '_4' || statusForUpdate == '_6' || statusForUpdate == '_11' && claimDecision == 'null'){
            statusForUpdate = '_2';
        }else if(statusForUpdate == '_5' && (claimDecision == 'null' || claimDecision == '1' || claimDecision == '2' || claimDecision == '3')){
            statusForUpdate = '_2';
        }else if(statusForUpdate == '_5' && claimDecision == '4'){
            statusForUpdate = 'OnHold';
        }else if(statusForUpdate == '_7' &&  claimDecision == 'null'){
            statusForUpdate = '_2';
        }else if(statusForUpdate == '_9' && claimDecision == '1' && CompensationAmount > 0){
            statusForUpdate = 'Accepted_PendingCompensation';
        }else if(statusForUpdate == '_9' && claimDecision == '1' && CompensationAmount == 0){
            statusForUpdate = '_9';
        }else if(statusForUpdate == '_9' && claimDecision == '2' && CompensationAmount > 0){
            statusForUpdate = 'AcceptedPartially_PendingCompensation';
        }else if(statusForUpdate == '_9' && claimDecision == '2' && CompensationAmount == 0){
            statusForUpdate = 'AcceptedPartially';
        }else if(statusForUpdate == '_9' && claimDecision == '3'){
            statusForUpdate = '_8';
        }else if(statusForUpdate == '_8' && claimDecision == '1'){
            statusForUpdate = '_9';
        }else if(statusForUpdate == '_8' && claimDecision == '2'){
            statusForUpdate = 'AcceptedPartially';
        }else if(statusForUpdate == '_8' && claimDecision == '3'){
            statusForUpdate = '_8';
        }

        // if(statusForUpdate == '_3' || statusForUpdate == '_4' || statusForUpdate == '_5' || statusForUpdate == '_6' || statusForUpdate == '_11' || statusForUpdate == '_7'  ){
            
        // }
        //reclamationForUpdate.ID_in_ERP__c = parsedMessage.ID_in_ERP;
        system.debug(statusForUpdate);
        reclamationForUpdate.Status__c = statusForUpdate;
        reclamationForUpdate.CompensationAmount__c = CompensationAmount;
        reclamationForUpdate.ERPSyncDate__c = date.today();
        try{
           update reclamationForUpdate; 
           res.NumberOfUpdatedRecords = 1;
           sendNotificationEmail(reclamationForUpdate.Owner.Email,reclamationForUpdate.Id); 
        } catch (Exception e){
            system.debug(e.getMessage());
        }
                
        return res;
    }
    
    private static Reclamation__c  findReclamation(ERPMessageParser.ErpToSfMessage_ClaimStage parsedMessage , MessageProcessingResult res){
        
        Reclamation__c reclamation = new Reclamation__c();
        system.debug(parsedMessage.data.NUMBER_RECLAMATION);
        List<Reclamation__c> findedReclamations = [SELECT id,Status__c,ERPSyncDate__c,Owner.Email FROM Reclamation__c WHERE ERP_Number__c=:parsedMessage.data.NUMBER_RECLAMATION];
        if(findedReclamations.size()>0){
            reclamation = findedReclamations[0];
        }
        system.debug(reclamation);
        //res.NumberOfUpdatedRecords = findedReclamations.size();
        return reclamation;
        
    }
    
    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', statusCodesMap.get(statusCode));
		if (error == NULL) {
			gen.writeStringField('Processed message type', mpRes.MessageType);
			gen.writeStringField('Number of updated reclamations', String.valueOf(mpRes.NumberOfUpdatedRecords));
			
		} else {
			gen.writeStringField('Error Message', error);
		}

		gen.writeEndObject();
		
		String res = gen.getAsString();
		System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}
    
    public static void sendNotificationEmail(String email,String reclamationId){
        
        List<String> orderOwnerEmails = new List<String>();
        orderOwnerEmails.add(email);
        String mailBody = 'Reclamation status was updated. Link: '+ URL.getSalesforceBaseUrl().toExternalForm()+ '/'+reclamationId;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = orderOwnerEmails;
        message.optOutPolicy = 'FILTER';
        message.subject = 'Reclamation Status';
        message.htmlbody = mailBody;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
    }
    
    public class MessageProcessingResult {
		public String MessageType;		
		public Integer NumberOfUpdatedRecords = 0;		
	}
}