public class ERPMessageHandlerReclamationDoc {
    
        
    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_ClaimDoc parsedMessage, String requestBody) {


        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;
        system.debug(parsedMessage);
		try{
			Account acc = [SELECT id, ID_ERP__c, IsCustomerPortal FROM Account WHERE ID_ERP__C =:parsedMessage.data.ORG LIMIT 1];
			system.debug(acc.id);
			system.debug('IsCustomerPortal ' );

			Reclamation__c reclamationForInsert = new Reclamation__c();

			reclamationForInsert.Status__c = '_1';
			reclamationForInsert.Account__c = acc.Id;
			reclamationForInsert.ERPSyncDate__c = date.today();
			reclamationForInsert.ID_in_ERP__c = parsedMessage.data.ID;
			reclamationForInsert.ERP_Number__c = parsedMessage.data.NUMB;
			reclamationForInsert.ReclSum__c = parsedMessage.data.DES_AMNT;
			reclamationForInsert.BackOffice_Description__c = parsedMessage.data.DESCR;
			reclamationForInsert.No_Refund__c = parsedMessage.data.NO_DES;
			reclamationForInsert.CurrencyIsoCode = String.valueOf(parsedMessage.data.KVAL);
			reclamationForInsert.CreationDate__c = Date.newinstance(parsedMessage.data.DT.year(), parsedMessage.data.DT.month(),parsedMessage.data.DT.day());
			if(parsedMessage.data.K_CL_T != '0' && acc.IsCustomerPortal ==true){
				insert reclamationForInsert; 
				res.NumberOfInsertedRecords = 1;
			}
        } catch (Exception e){
            system.debug(e.getMessage());
        }
                
        return res;
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', statusCodesMap.get(statusCode));
		if (error == NULL) {
			gen.writeStringField('Processed message type', mpRes.MessageType);
			gen.writeStringField('Number of inserted reclamations', String.valueOf(mpRes.NumberOfInsertedRecords));
			
		} else {
			gen.writeStringField('Error Message', error);
		}

		gen.writeEndObject();
		
		String res = gen.getAsString();
		System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}

    public class MessageProcessingResult {
		public String MessageType;		
		public Integer NumberOfInsertedRecords = 0;		
	}
}