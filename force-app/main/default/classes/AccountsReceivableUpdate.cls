global class AccountsReceivableUpdate implements Database.Batchable<SObject> {
	
	global Long messageTimeStamp;
	global Set<String> accIdErpSet = new Set<String>();
	global Map<String, ERPMessageParser.AccountsReceivableItem> accErpId_To_Ari_Map = new Map<String, ERPMessageParser.AccountsReceivableItem>();
	
	
	global AccountsReceivableUpdate(String requestBody) {
		
		ERPMessageParser.ErpToSfMessage_AccountsReceivable parsedMessage = (ERPMessageParser.ErpToSfMessage_AccountsReceivable) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_AccountsReceivable.class);
		
		//messageTimeStamp = Long.valueOf(parsedMessage.metadata.messageTimestamp);
		messageTimeStamp = parsedMessage.metadata.msgTimestamp.getTime();
		//String serializedMsgData = JSON.serialize(parsedMessage.data);
		//System.debug('>>>>>>>> Serialized MsgData: ' + serializedMsgData);
		//ERPMessageParser.AccountsReceivableMessageData messageData = (ERPMessageParser.AccountsReceivableMessageData) JSON.deserialize(serializedMsgData, ERPMessageParser.AccountsReceivableMessageData.class);
		ERPMessageParser.AccountsReceivableMessageData messageData = parsedMessage.data;
		for(ERPMessageParser.AccountsReceivableItem ari : messageData.items) {
			accIdErpSet.add(ari.account.id.trim());
			accErpId_To_Ari_Map.put(ari.Account.Id, ari);
		}
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator('SELECT Id, ID_ERP__c, Name FROM Account WHERE Id_ERP__c in :accIdErpSet');
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<Account> scope) {
		
		List<Account> accListToUpdate = new List<Account>();
		for (Account acc : scope) {
			ERPMessageParser.AccountsReceivableItem ari = accErpId_To_Ari_Map.get(acc.ID_ERP__c);
			
			/*
			acc.AccountsReceivableExchangeTimestamp__c = messageTimeStamp;
			acc.AccountsReceivableLastSync__c = Datetime.newInstance(MessageTimeStamp * 1000);
			acc.DealingStatus__c = ari.Status;
			acc.Balance__c = String.isNotBlank(ari.Balance) ? Decimal.valueOf(ari.Balance) : null;
			acc.PastDueDebt__c = String.isNotBlank(ari.PastDueDebt) ? Decimal.valueOf(ari.PastDueDebt) : null;
			acc.PastDueDebt15More__c = String.isNotBlank(ari.PastDueDebt15More) ? Decimal.valueOf(ari.PastDueDebt15More) : null;
			acc.GroupPastDueDebt__c = String.isNotBlank(ari.GroupPastDueDebt) ? Decimal.valueOf(ari.GroupPastDueDebt) : null;
			acc.GroupPastDueDebt15More__c = String.isNotBlank(ari.GroupPastDueDebt15More) ? Decimal.valueOf(ari.GroupPastDueDebt15More) : null;
			Long blockDateTimestamp = String.isNotBlank(ari.DueDate) ? Long.valueOf(ari.DueDate + '000') : null;
			acc.BlockDate__c = blockDateTimestamp != null && blockDateTimestamp > 0 ? DateTime.newInstance(blockDateTimestamp).date() : null;
			acc.CurrentMonthReceipts__c = String.isNotBlank(ari.Receipts) ? Decimal.valueOf(ari.Receipts) : null;
			acc.StopListRisk__c = String.isNotBlank(ari.ToBlock) ? (ari.ToBlock == '1' ? true : false) : null;
			Long permissionDateTimestamp = String.isNotBlank(ari.PermissionDate) ? Long.valueOf(ari.PermissionDate + '000') : null;
			acc.PermissionDate__c = permissionDateTimestamp != null && permissionDateTimestamp > 0 ? DateTime.newInstance(permissionDateTimestamp).date() : null;
			//acc.PermittedById__c = 
			acc.PermittedProductionAmount__c =  String.isNotBlank(ari.PermittedProductionAmount) ? Decimal.valueOf(ari.PermittedProductionAmount) : null;
			acc.PermittedShipmentAmount__c =  String.isNotBlank(ari.PermittedShipmentAmount) ? Decimal.valueOf(ari.PermittedShipmentAmount) : null;
			acc.PermissionComment__c = ari.PermissionComment;
			*/

			acc.AccountsReceivableExchangeTimestamp__c = messageTimeStamp;
			acc.AccountsReceivableLastSync__c = Datetime.newInstance(messageTimeStamp);
			//acc.DealingStatus__c = String.valueOf(ari.status);
			acc.Balance__c = ari.balance;
			acc.PastDueDebt__c = ari.pastDueDebt;
			acc.PastDueDebt15More__c = ari.pastDueDebt15More;
			acc.GroupPastDueDebt__c = ari.groupPastDueDebt;
			acc.GroupPastDueDebt15More__c = ari.groupPastDueDebt15More;
			acc.BlockDate__c = ari.dueDate?.date();
			acc.CurrentMonthReceipts__c = ari.receipts;
			acc.StopListRisk__c = ari.toBlock;
			acc.PermissionDate__c = ari.permissionDate?.date();
			//acc.PermittedById__c = 
			acc.PermittedProductionAmount__c =  ari.permittedProductionAmount;
			acc.PermittedShipmentAmount__c =  ari.permittedShipmentAmount;
			acc.PermissionComment__c = ari.permissionComment;
            
            if(ari.toBlock){
               acc.DealingStatus__c = '40'; 
            }else{
               acc.DealingStatus__c = String.valueOf(ari.status); 
            }
			
			accListToUpdate.add(acc);
		}

		System.debug('---------> accListToUpdate size: ' + accListToUpdate.size());
		update accListToUpdate;

	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
       
		AccountsBlockedUpdate abu = new AccountsBlockedUpdate(accIdErpSet);
        Id abuId = Database.executeBatch(abu);
    }
	
}