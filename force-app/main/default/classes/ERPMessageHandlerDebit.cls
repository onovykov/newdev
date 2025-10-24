public with sharing class ERPMessageHandlerDebit {
    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_Debit parsedMessage, String requestBody) {

        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;
        system.debug(parsedMessage);
		try{
			ERPMessageParser.InvoiceOrderDebtMessageData[] invoiceItems = parsedMessage.data;

			// List<InvoiceOrderDebt__c> invoicesToUpsert = new List<InvoiceOrderDebt__c>();
			// system.debug('invoiceItems ----> '  + invoiceItems);
			
			// Map<String, Id> accidErpToId = new Map<String,Id> ();
			// Map<String, Id> ordidErpToId = new Map<String,Id> ();
			
			// for (Account a : [SELECT id, ID_ERP__c FROM Account]) {
			// 	accidErpToId.put(a.ID_ERP__c, a.id);
			// }
			// for (Order o : [SELECT id, ID_ERP__c FROM Order]) {
			// 	ordidErpToId.put(o.ID_ERP__c, o.id);
			// }


			// for(ERPMessageParser.InvoiceOrderDebtMessageData invoice : invoiceItems){

			// 	InvoiceOrderDebt__c inv = new InvoiceOrderDebt__c();
			// 	inv.Name = invoice.NDM_INVOCE;
			// 	inv.ITENumber__c = invoice.NDM_INVOCE;

			// 	If(accidErpToId.keySet().contains(invoice.ORG) == true){
			// 		inv.Account__c = accidErpToId.get(invoice.ORG);
			// 	}else {
			// 		continue;
			// 	}

			// 	If(accidErpToId.keySet().contains(invoice.ORG_K) == true){
			// 		inv.InternalAccount__c = accidErpToId.get(invoice.ORG_K);
			// 	}else {
			// 		Account newInternalAcc = new Account();
			// 		newInternalAcc.Name = invoice.ORG_K_NAME;
			// 		newInternalAcc.ID_ERP__C = invoice.ORG_K;
			// 		insert newInternalAcc;
			// 		system.debug('newInternalAcc' + newInternalAcc);
			// 		accidErpToId.put(invoice.ORG_K, newInternalAcc.id);
			// 		inv.InternalAccount__c = newInternalAcc.id;
			// 	}
			// 	if(ordidErpToId.keySet().contains(invoice.UNDOC_ORDER) == true){
			// 		inv.Order__c = ordidErpToId.get(invoice.UNDOC_ORDER);
			// 	}
			// 	inv.OutstandingDebt__c = invoice.DT_OUT;
			// 	inv.VATAmount__c = invoice.VAT_AMNT;
			// 	inv.NetAmount__c = invoice.NET_AMNT;
			// 	inv.DaysOverdue__c = invoice.DAYS;
			// 	if(invoice.DUE_DATE != '0001-01-01T00:00:00'){
			// 		inv.DueDate__c = Date.valueOf(invoice.DUE_DATE);
			// 	}
			// 	if(invoice.DDM != '0001-01-01T00:00:00'){
			// 		inv.InvoiceDate__c = Date.valueOf(invoice.DDM);
			// 	}
			// 	inv.CurrencyIsoCode = invoice.VAL;
			// 	invoicesToUpsert.add(inv);
			// 	// system.debug('!!!!' + inv);

			// }
			InvoiceOrderDebtCleaning batch = new InvoiceOrderDebtCleaning(invoiceItems);
			String batchJobId = Database.executeBatch(batch, 200);
			// Query the batch job result
			AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, CreatedDate, CompletedDate FROM AsyncApexJob WHERE Id = :batchJobId];
			res.jobStatus = 'Batch job ' + jobInfo.Id + ' started with status ' + jobInfo.Status + '.     ' + 'Start time: ' + jobInfo.CreatedDate +'. ' +'If there are any errors, we will notify the administrators by email';

        } catch (Exception e){
            system.debug(e.getMessage());
			res.error = e.getMessage();
        }
                
        return res;
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
		system.debug('!!!!' + error);
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();

		gen.writeStringField('Status', statusCodesMap.get(statusCode));

		if (error == NULL) {
			gen.writeStringField('Processed message type', mpRes.MessageType);
			gen.writeStringField('',  mpRes.jobStatus);

		} else {
			gen.writeStringField('Error Message', error);
		}

		gen.writeEndObject();
		
		String res = gen.getAsString();
		//System.debug('Response body text generated: ' + res);
		return Blob.valueOf(res);
	}

    public class MessageProcessingResult {
		public String MessageType;		
		public String error;		
		public String jobStatus;		

	}
}