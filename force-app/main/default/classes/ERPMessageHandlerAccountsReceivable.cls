public class ERPMessageHandlerAccountsReceivable  {
	
	public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_AccountsReceivable parsedMessage, String requestBody) {
		
		MessageProcessingResult res = new MessageProcessingResult();
		res.messageType = parsedMessage.metadata.msgType;

		AccountsReceivableUpdate aru = new AccountsReceivableUpdate(requestBody);
		Id aruId = Database.executeBatch(aru);

		return res;
	}



	public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeNumberField('Status Code', statusCode);
		gen.writeStringField('Status', statusCodesMap.get(statusCode));
		if (error == NULL) {
			gen.writeStringField('Processed message type', mpRes.MessageType);
			if (String.isNotBlank(mpRes.resultComment)){
				gen.writeStringField('Result comment', mpRes.resultComment);
			}
		} else {
			gen.writeStringField('Error Message', error);
		}

		gen.writeEndObject();
		
		String res = gen.getAsString();
		System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}


	
	public class MessageProcessingResult {
		public String messageType;
		public Boolean isNewPriceApprovalRequestCreated = false;
		public String resultComment;
	}
	
	

	public class erpException extends Exception {}
}