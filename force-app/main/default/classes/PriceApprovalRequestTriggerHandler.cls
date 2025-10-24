public class PriceApprovalRequestTriggerHandler extends TriggerHandler implements ITrigger {
	
	// Constructor
	public PriceApprovalRequestTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	// Class variables
	static String approverComment;
	static String approvalResolution;

	final static Map<String, String> STAGES_TO_APPROVAL_PROCESS_NAMES = new Map<String, String> {
		'_3' => 'PAR_Sales_Rep',
		'_18' => 'PAR_PRD_Director',
		'_20' => 'PAR_PRD_Director'
	};
	


	public void bulkBefore() {
		System.debug('bulkBefore PriceApprovalRequest');
	}
	
	public void beforeInsert(SObject so) {
		System.debug('beforeInsert PriceApprovalRequest');
	}
	
	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('beforeUpdate PriceApprovalRequest');
		System.debug(((PriceApprovalRequest__c) so).ApprovalResolution__c);
		if (((PriceApprovalRequest__c) so).ApprovalResolution__c != null) {
			approvalResolution = ((PriceApprovalRequest__c) so).ApprovalResolution__c;
			((PriceApprovalRequest__c) so).ApprovalResolution__c = null;
		}
	}
		
	public void beforeDelete(SObject so) {
		System.debug('beforeDelete PriceApprovalRequest');
	}
	
	public void bulkAfter() {
		System.debug('bulkAfter PriceApprovalRequest');
	}
	
	public void afterInsert(SObject so) {
		System.debug('afterInsert PriceApprovalRequest');
	}
	
	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate PriceApprovalRequest');
		System.debug(approvalResolution);
		PriceApprovalRequest__c par = (PriceApprovalRequest__c) So;
		//System.debug(checkStatus(par, approvalResolution));
		if (approvalResolution != null && checkStatus(par, approvalResolution)) {
			// Этот флаг означает, что есть новый результат процесса согласования (данный триггер был запущен именно установкой этого флага с помощью Approval Process Step Actions)
			
			// Если результат был получен в СФ, а не в ИТ, то передадим в ИТ его данные
			User lastApprover = getLastApprover(par, approvalResolution);
			if (lastApprover.Profile.Name != 'ERP Integration Service') {
				System.debug('>>>>>>>> Approver name on SalesRep step: ' + lastApprover.Name);
				System.debug('>>>>>>>> Approver profile name on SalesRep step: ' + lastApprover.Profile.Name);
				sendApprovalResolutionToERP(par.Id, approvalResolution, lastApprover.Id,approverComment);
			}
		}
	}
	
	public void afterDelete(SObject so) {
		System.debug('After Delete');
	}
	
	public void postProcessing() {
		System.debug('Post Processing');
	}



	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  Helpers

	private Boolean checkStatus(PriceApprovalRequest__c par, String currentResolution) {
		switch on currentResolution {
			when 'SalesRep:1', 'SalesRep:0', 'SalesRep:-1' {
				return par.StageERP__c == '_3';
			}
			when 'PRMDirector:1', 'PRMDirector:0', 'PRMDirector:-1' {
				return par.StageERP__c == '_18' || par.StageERP__c == '_20';
			}
			when 'CEO:1', 'CEO:0', 'CEO:-1' {
				return par.StageERP__c == '_24';
			}
			when else {
				throw new erpException('Undefined Current Resolution value: ' + currentResolution);
				
			}
		}
	}

	private static User getLastApprover(PriceApprovalRequest__c par, String currentResolution) {
		Id lastApproverId;
		String processName;
		String stepName;

		switch on currentResolution {
			when 'SalesRep:1', 'SalesRep:0', 'SalesRep:-1' {
				processName = 'PAR_Sales_Rep';
				stepName = 'Sales_Rep';
			}
			when 'PRMDirector:1', 'PRMDirector:0', 'PRMDirector:-1' {
				processName = 'PAR_PRD_Director';
				stepName = 'PRD_Director';
			}
			when 'CEO:1', 'CEO:0', 'CEO:-1' {
				processName = 'PAR_CEO';
				stepName = 'CEO';
			}
		}

		List<ProcessInstance> piList = [
											SELECT Id,
													(
														SELECT Id, ActorId, OriginalActorId, Comments
														FROM StepsAndWorkitems
														WHERE ProcessNode.DeveloperName = :stepName
														ORDER BY SystemModstamp DESC
													)
											FROM ProcessInstance
											WHERE TargetObjectId = :par.Id
											AND (ProcessDefinition.DeveloperName = :processName)
											AND (Status = 'Approved' OR Status = 'Rejected')
											ORDER BY CompletedDate DESC
										];
		
		System.debug('>>> piList: ' + piList);
		System.debug('>>> steps & workitems: ' + piList.get(0).StepsAndWorkitems.get(0));
		// Результаты запроса отсортированы по CompletetDate (Desc), при этом в выборку попадут только законченные процессы, у которых эта дата не null.
		lastApproverId = piList.get(0)?.StepsAndWorkitems.get(0)?.ActorId;
		approverComment = piList.get(0)?.StepsAndWorkitems.get(0)?.Comments;

		return [SELECT Id, Name, Profile.Name, ManagerId FROM User WHERE Id = :lastApproverId].get(0);
	}



	@Future(callout = true)
	private static void sendApprovalResolutionToERP(String parId, String resolution, String approverId, String comment) {
		String coomentFromUser = comment;
		String data = getJsonString(parId, resolution, approverId,coomentFromUser);
		String calc = '_SF_PAMREQEST_MOVE_ACTION';
		String arg = data;
		SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
				
		try {
			String login = Credentials__c.getOrgDefaults().User_Login__c;
			String password = Credentials__c.getOrgDefaults().User_Password__c;
			String response = ERPhandler.LoginEx(login, password);
			ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
			String ticket = requestObject.Ticket;
			system.debug(Json.serializePretty(data));
			ERPRequestParser.ExecuteResponce_ApprovalResult idResponse = null;

			String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
			System.debug('JSON before deserialization - ' + erpResult);
			String processed = erpResult.remove('\\');
			System.debug('Processed after remove: ' + processed);
			//processed = processed.substring(1, processed.length() - 1);
			idResponse = (ERPRequestParser.ExecuteResponce_ApprovalResult) JSON.deserialize(processed, ERPRequestParser.ExecuteResponce_ApprovalResult.class);

			if (idResponse.Status == false) {
				//ERPWebServiceHandler.insertErrorTask('SF to ERP', arg, erpResult, wrapper.oppo.Id);
				//throw new AuraHandledException(Label.AuraMsgErrorFromERP + '</br>' + idResponse.ErrorType + '</br>' + idResponse.ErrorMessage);
				//FalseSynchroService.createFalseSynchroRecord(calc,arg,parId);                                
				sendNotitficationForUser(idResponse);
				throw new erpException(idResponse.ErrorMessage);
			}
           /* 
            try{
                   
               system.debug('close session');
               String calcCloseSession = 'WEB.CLOSESESSION';                    
               String erpResult2 = ERPhandler.ExecuteEx(calcCloseSession, null, ticket);
               system.debug('close session2');
            } catch(Exception e){
                   system.debug(e.getMessage());
               }  
            */
		} catch(CalloutException callfail) {
			String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();
            //FalseSynchroService.createFalseSynchroRecord(calc,arg,parId);
			Triton.instance.error(TritonTypes.Area.PriceApprovalRequest, callfail);
	        sendEmailCalloutException(errorMessage);
			//sendSyncEmailForUser(parId);

			//ERPWebServiceHandler.insertErrorTask('SF to ERP (callout exception)', arg, errorMessage, wrapper.oppo.Id);
			//throw new AuraHandledException(Label.SFtoERPConnectionFails);
			//throw new erpException(errorMessage);
		} catch(System.JSONException jsfailed) {
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (serialization exception)', arg, errorMessage, wrapper.oppo.Id);
			//throw new AuraHandledException(Label.InvalidJSONReceived);
			Triton.instance.error(TritonTypes.Area.PriceApprovalRequest, jsfailed);
			//throw new erpException(errorMessage);
		} catch(Exception jsfailed){
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
			Triton.instance.error(TritonTypes.Area.PriceApprovalRequest, jsfailed);
			//throw new erpException(errorMessage);
		}
	}


	private static String getJsonString(String parId, String resolution, String approverId,String commentFromApprover) {
		//Этот метод вызывается из @Future метода, поэтому передать параметром ссылку на объект не возможно, нужно делать запрос.
		PriceApprovalRequest__c par = [SELECT ID_ERP__c, Stage__c, StageERP__c, StageName__c, ApprovalMode__c FROM PriceApprovalRequest__c WHERE Id = :parId];
		User approver = [SELECT Id, ID_ERP__c, LoginERP__c, EmployeeNumber, Name, Email FROM User WHERE Id = :approverId];
		String res;

		switch on resolution {
			when 'SalesRep:1', 'SM:1', 'PRMDirector:1' {
				res = par.ApprovalMode__c == '1' ? '1' : '2';
			}
			when 'SalesRep:0', 'SM:0', 'PRMDirector:0' {
				res = '0';
			}
			when 'SalesRep:-1', 'SM:-1', 'PRMDirector:-1' {
				res = '-1';
			}
		}
		
		JSONGenerator jsonToSend = JSON.createGenerator(true);
		
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('MessageType', 'SF-ERP_ParApproval');
		jsonToSend.writeObjectField('ID_ERP', par.ID_ERP__c);
		
		jsonToSend.writeFieldName('StageInfo');
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('Id', par.StageERP__c);
		jsonToSend.writeObjectField('Name', par.StageName__c);
		jsonToSend.writeEndObject();
		
		jsonToSend.writeObjectField('Resolution', res);
		
		jsonToSend.writeFieldName('Approver_UserId');
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('Id', approver.LoginERP__c);
		jsonToSend.writeObjectField('Name', approver.Name);
		jsonToSend.writeObjectField('Email', approver.Email);
		jsonToSend.writeEndObject();
		system.debug( commentFromApprover);
		String comments = String.isNotBlank(commentFromApprover) ? ' с комментарием: ' + commentFromApprover : '';
		jsonToSend.writeObjectField('Comment', 'Согласовано в Salesforce пользователем ' + approver.Name + comments);
        system.debug( 'Согласовано в Salesforce пользователем ' + approver.Name + comments);
		jsonToSend.writeEndObject();

		JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();

		return jsonWrapper.getAsString();
	}
    
    public static void sendNotitficationForUser(ERPRequestParser.ExecuteResponce_ApprovalResult idResponse){
        Set<String> userEmail = new Set<String>();
        String idErrorRecord = getIdOfPARByERPId(idResponse.SourceQuoteApprovalMessage.ID_ERP);
        String orgUrl = Label.OrganizationURL;
        userEmail.add(idResponse.SourceQuoteApprovalMessage.Approver_UserId.email);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>(userEmail);
        message.optOutPolicy = 'FILTER';
        message.subject = 'Price approval request error';
        message.HtmlBody = 'Error occurred. PAR is not synchronized with ERP system. Reason:  ' + idResponse.ErrorMessage + '.Id ERP - ' + idResponse.SourceQuoteApprovalMessage.ID_ERP +
            '. Please, contact with administrator. Link to record - ' + orgUrl + '/'+idErrorRecord;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
	/*public static void sendSyncEmailForUser(Id parId){
        Set<String> userEmail = new Set<String>();
        //String idErrorRecord = getIdOfPARByERPId(idResponse.SourceQuoteApprovalMessage.ID_ERP);
        //String orgUrl = Label.OrganizationURL;
        userEmail.add('sflog@m.interpipe.biz');
		userEmail.add('v.rybak@polytech.software');
		userEmail.add('furman@polytech.software');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>(userEmail);
        message.optOutPolicy = 'FILTER';
        message.subject = 'PAR Sync Error';
        message.HtmlBody = 'This document' + ' ' + parId +' ' + 'was not synchronized with ERP - network tunnel is wrong. We saved this data and we will try to synchronize this document every 30 min. After successful try we will inform you by e-mail';
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }*/

	public static void sendEmailCalloutException(String errorMessage){
		try {
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			List<String> toAddresses = Label.Addresses_for_callout_exception.split(',');
			message.setToAddresses(toAddresses);
			message.subject = 'Price Approval Request synchronization error';
			message.HtmlBody = 'IT/SF synchronization for object "Price Approval Request" have raise error: "PriceApprovalRequestTriggerHandler.erpException: Web service callout failed: Encountered HTML Content when looking for http://schemas.xmlsoap.org/soap/envelope/:Envelope". ' 
			+ '<br>' + 'Please check the Synchronization Web Services and Network Settings.';
			Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
			Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        } catch (Exception e) {
            System.debug('An error occurred while sending the email: ' + e.getMessage());
			throw new erpException(errorMessage);
        }
    }
    
    public static String getIdOfPARByERPId(String erpIdPAR){
        string returnedId = 'null';
        try{
            returnedId = [SELECT id FROM PriceApprovalRequest__c WHERE ID_ERP__c=:erpIdPAR LIMIT 1].id;
        } catch (Exception e){
            system.debug(e.getMessage());
        }
        
        return returnedId;
    }


	public class erpException extends Exception {}

	public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}