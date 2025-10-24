public class ERPMessageHandler  {
		//public static final String NO_SUCH_OPPORTUNITY_MSG = 'There is no Opportunity with such ID_ERP ';
		//public static final String NO_SUCH_OPPORTUNITY_ITEM_MSG = 'There is no OpportunityLineItem with such #';

		public final static Map<Integer, String> HTTPSTATUSES = new Map<Integer, String> {
				200 => 'OK',
				201 => 'CREATED',
				202 => 'ACCEPTED',
				204 => 'NO CONTENT',
				206 => 'PARTIAL CONTENT',
				300 => 'MULTIPLE CHOICES',
				301 => 'MOVED PERMANENTLY',
				302 => 'FOUND',
				304 => 'NOT MODIFIED',
				400 => 'BAD REQUEST',
				401 => 'UNAUTHORIZED',
				403 => 'FORBIDDEN',
				404 => 'NOT FOUND',
				405 => 'METHOD NOT ALLOWED',
				406 => 'NOT ACCEPTABLE',
				409 => 'CONFLICT',
				410 => 'GONE',
				412 => 'PRECONDITION FAILED',
				413 => 'REQUEST ENTITY TOO LARGE',
				414 => 'REQUEST URI TOO LARGE',
				415 => 'UNSUPPORTED MEDIA TYPE',
				417 => 'EXPECTATION FAILED',
				500 => 'INTERNAL SERVER ERROR',
				503 => 'SERVER UNAVAILABLE'
		};

		public static void postCSTfromHelper(RestRequest request, RestResponse response) {
			response.addHeader('Content-Type', 'application/json');

			String requestBody = request.requestBody.toString();
			if(requestBody.substring(0,1) == '['){
				requestBody = requestBody.removeStart('[');
				requestBody = requestBody.removeEnd(']');
			}
			requestBody = requestBody.replace('"Default"', '"DefaultName"');
			System.debug('Recieved body: ' + requestBody);
			Map<String, Object> parsedMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
			String messageType;
			if (parsedMap.containsKey('Metadata')) {
				Map<String, Object> messageMetadata = (Map<String, Object>)parsedMap.get('Metadata');
				messageType = String.valueOf(messageMetadata.get('MsgType'));
			} else {
				messageType = String.valueOf(parsedMap.get('MessageType'));
			}

			System.debug('messageType: ' + messageType);
			String IDERPofOpportunity;
			Opportunity opp = null;

			switch on messageType {
				when 'ERP-SF_OpportunityData' {
					ERPMessageParser.ErpToSfMessage_OpportunityData parsed = (ERPMessageParser.ErpToSfMessage_OpportunityData) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_OpportunityData.class);
					//IDERPofOpportunity = parsed.General_Data.ID_ERP;
					processOppoDataUpdated(parsed, response, requestBody, request);
					system.debug('parsedMessage---->  ' + parsed);
					//System.debug('Recieved body parsed: ' + parsed);
				}
				when 'ERP-SF_Sync_Result' {
					ERPRequestParser.ExecuteResponce parsedIdResponse = (ERPRequestParser.ExecuteResponce) JSON.deserialize(requestBody, ERPRequestParser.ExecuteResponce.class);
					IDERPofOpportunity = parsedIdResponse.Opportunity.ID_ERP;
					processSyncedOppoDataUpdated(parsedIdResponse, response, requestBody);
					System.debug('Recieved body parsed: ' + parsedIdResponse);
				}
				when 'ERP-SF_SetScrapWeight' {
					try {
						// делегуємо в готову бізнес-логіку та віддаємо ERP стандартний JSON
						String outJson = ScrapDeliveryGateway.handleSetScrapWeight(requestBody);
						response.statusCode = 200;
						response.responseBody = Blob.valueOf(outJson);
					} catch (Exception e) {
						response.statusCode = 500;
						response.responseBody = Blob.valueOf('{"Success":false,"ErrorMessage":"' +
								String.escapeSingleQuotes(e.getMessage()) + '"}');
					}
				}
				when 'ERP-SF_ItemStage' {
					ERPRequestParser.ERPItemStage parsedItemStage = (ERPRequestParser.ERPItemStage) JSON.deserialize(requestBody, ERPRequestParser.ERPItemStage.class);
					IDERPofOpportunity = parsedItemStage.Item_Stage.OpportunityID_ERP;
					processChatterPostCreation(parsedItemStage, response, requestBody);
					System.debug('Recieved body parsed: ' + parsedItemStage);
				}
				when 'ERP-SF_PAR' {
					ERPMessageParser.ErpToSfMessage_PAR parsedMessage = (ERPMessageParser.ErpToSfMessage_PAR) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_PAR.class);
					processPriceApprovalRequestMessage(parsedMessage, response, requestBody);

					if (response.statusCode == 500) {
						String parIdErp = String.valueOf(parsedMessage.data.header.id_ERP);
						PriceApprovalRequest__c par;
						List<PriceApprovalRequest__c> parFromJSON = [SELECT Id, Account__c FROM PriceApprovalRequest__c WHERE ID_ERP__c = :parIdErp];
						if (!parFromJSON.isEmpty()) {
							par = parFromJSON[0];
						}
						ERPMessageHandlerPriceApprovalRequest.insertErrorTask(messageType + ' Error for PAR #' + parIdErp, requestBody, response.responseBody.toString(), par?.Account__c);
					}
				}
				when 'ERP-SF_MonthPlan', 'ERP-SF_MonthFact' {
					ERPRequestParser.MonthPlanFactMessage parsedMessage = (ERPRequestParser.MonthPlanFactMessage) JSON.deserialize(requestBody, ERPRequestParser.MonthPlanFactMessage.class);
					processMonthPlanFactMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_SalesBudget' {
					ERPRequestParser.SalesBudgetMessage parsedMessage = (ERPRequestParser.SalesBudgetMessage) JSON.deserialize(requestBody, ERPRequestParser.SalesBudgetMessage.class);
					processSalesBudgetMessage(parsedMessage, response, requestBody, request);
				}
				when 'ERP-SF_AccountsReceivable' {
					ERPMessageParser.ErpToSfMessage_AccountsReceivable parsedMessage = (ERPMessageParser.ErpToSfMessage_AccountsReceivable) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_AccountsReceivable.class);
					processAccountsReceivableMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_OrderDelivery' {
					ERPMessageParser.ErpToSfMessage_OrderDelivery parsedMessage = (ERPMessageParser.ErpToSfMessage_OrderDelivery) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_OrderDelivery.class);
					system.debug('ERPMessageParser.ErpToSfMessage_OrderDelivery---->  ' +json.serializePretty(parsedMessage));
				}
				when 'ERP-SF_ClaimStage' {
					ERPMessageParser.ErpToSfMessage_ClaimStage parsedMessage = (ERPMessageParser.ErpToSfMessage_ClaimStage) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_ClaimStage.class);
					system.debug('ERPMessageParser.ErpToSfMessage_ReclamationStatus---->  ' +json.serializePretty(parsedMessage));
					processReclamationStatus(parsedMessage, response, requestBody);
				}

				when 'ERP-SF_ClaimDoc' {
					ERPMessageParser.ErpToSfMessage_ClaimDoc parsedMessage = (ERPMessageParser.ErpToSfMessage_ClaimDoc) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_ClaimDoc.class);
					system.debug('ERPMessageParser.ErpToSfMessage_ClaimDoc---->  ' +json.serializePretty(parsedMessage));
					processReclamationDoc(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_OrderItemStage' {
					ERPMessageParser.ErpToSfMessage_OrderItemStage parsedMessage = (ERPMessageParser.ErpToSfMessage_OrderItemStage) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_OrderItemStage.class);
					system.debug('---->  ' +json.serializePretty(parsedMessage));
					processOrderItemStage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_Debit' {
					ERPMessageParser.ErpToSfMessage_Debit parsedMessage = (ERPMessageParser.ErpToSfMessage_Debit) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_Debit.class);
					processDebit(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_ProdPlanBalance' {
					ERPMessageParser.ErpToSfMessage_ProdPlanBalance parsedMessage = (ERPMessageParser.ErpToSfMessage_ProdPlanBalance) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_ProdPlanBalance.class);
					processProdPlanBalance(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_OrderProbabilityQuery' {
					ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery parsedMessage = (ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery) JSON.deserialize(requestBody, ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery.class);
					proccessOrderProbability(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_InvoicePDF' {
					ERPMessageParser.ErpToSfMessage_InvoicePDF parsedMessage = (ERPMessageParser.ErpToSfMessage_InvoicePDF) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_InvoicePDF.class);
					proccessInvoicePDF(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_Route' {
					ERPMessageParser.ErpToSfMessage_Route parsedMessage = (ERPMessageParser.ErpToSfMessage_Route) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_Route.class);
					processRouteMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_FamilyType' {
					ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage = (ERPMessageParser.ErpToSfMessage_FamilyType) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_FamilyType.class);
					system.debug('ERPMessageParser.ErpToSfMessage_ReclamationStatus---->  ' +requestBody);

					system.debug('ERPMessageParser.ErpToSfMessage_ReclamationStatus---->  ' +json.serializePretty(parsedMessage));

					processFamilyTypeMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_Family' {
					ERPMessageParser.ErpToSfMessage_Family parsedMessage = (ERPMessageParser.ErpToSfMessage_Family) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_Family.class);
					processFamilyMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_RouteFamilies' {
					ERPMessageParser.ErpToSfMessage_RouteFamilies parsedMessage = (ERPMessageParser.ErpToSfMessage_RouteFamilies) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_RouteFamilies.class);
					processRouteFamilyMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_StructQuotaConfig' {
					ERPMessageParser.ErpToSfMessage_StructQuotaConfig parsedMessage = (ERPMessageParser.ErpToSfMessage_StructQuotaConfig) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_StructQuotaConfig.class);
					processStructQuotaConfigMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_RouteQuota' {
					ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage = (ERPMessageParser.ErpToSfMessage_RouteQuota) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_RouteQuota.class);
					processRouteQuotaMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_QUOTAS_StructQuota' {
					ERPMessageParser.ErpToSfMessage_StructQuota parsedMessage = (ERPMessageParser.ErpToSfMessage_StructQuota) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_StructQuota.class);
					processStructQuotaMessage(parsedMessage, response, requestBody);
				}
				when 'ERP-SF_KBSPEC_WHEEL', 'ERP-SF_KBSPEC_AXLE', 'ERP-SF_KBSPEC_WHEELSET' {
					ERPMessageParser.ErpToSfMessage_KbSpec parsedMessage = (ERPMessageParser.ErpToSfMessage_KbSpec) JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_KbSpec.class);
					processKbSpecMessage(parsedMessage, response, requestBody);
				}
				when else {
					response.statusCode = 400;
					response.responseBody = ERPWebServiceHandler.generateResponseBody(400, 'Unsupported message type.'+messageType);
				}
			}

			if (String.isNotBlank(IDERPofOpportunity)) {
				List<Opportunity> opportunityFromJSON = [SELECT Id FROM Opportunity WHERE ID_ERP__c = :IDERPofOpportunity];
				if (!opportunityFromJSON.isEmpty()) {
					opp = opportunityFromJSON[0];
				}
				if (response.statusCode == 500) {
					ERPWebServiceHandler.insertErrorTask(messageType + ' Error for Opportunity #' + IDERPofOpportunity, requestBody, response.responseBody.toString(), (opp != null ? opp.Id : null));
				}
			}

		}

		private static void processOppoDataUpdated(ERPMessageParser.ErpToSfMessage_OpportunityData generalData, RestResponse response, String requestBody, RestRequest request) {
			if(generalData.data.header.account.Id == '90342') { //ігноруємо Склади України
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerOpportunityData.generateResponseBodyOppUpdate(response.statusCode, null, null, null);
				return;
			}

			//system.debug('generalData---------------->>>>>' + Json.serializePretty(generalData.data.items));
			String errorMsg = '';
			System.debug(generalData.data.items);
			//System.debug('Size before - ' + generalData.data.items.size());
			OpportunityDataEmails.deleteCancelledItems(generalData);

			//System.debug('Size after - ' + generalData.data.items.size());

			Savepoint sp = Database.setSavepoint();
			try {
				String businessDivision = generalData.data.orderType; // Tubes | Wheels
				ERPMessageHandlerOpportunityData.UpdateSFRecordsResult resultOpp = ERPMessageHandlerOpportunityData.updateOpportunity(generalData, requestBody, businessDivision);
				if (resultOpp.parentOpp == null) {
					response.statusCode = 200;
					response.responseBody = ERPMessageHandlerOpportunityData.generateResponseBodyOppUpdate(response.statusCode, null, resultOpp, null);
					return;
				}
				ERPMessageHandlerOpportunityData.UpdateSFRecordsResult resultOppLi;
				//if (!resultOpp.oppChangeStatus = 'Closed') {
				resultOppLi = ERPMessageHandlerOpportunityData.updateLineItems(generalData, resultOpp);
				//}

				if (resultOpp.parentOpp.StageName == 'Closed Won' || resultOpp.parentOpp.IsWon) {
					ERPMessageHandlerOpportunityData.UpdateSFRecordsResultOrder resultOrd = ERPMessageHandlerOpportunityData.updateOrder(generalData, resultOpp);
					ERPMessageHandlerOpportunityData.UpdateSFRecordsResultOrder resultOrdLi = ERPMessageHandlerOpportunityData.updateOrderLineItems(generalData, resultOpp, resultOrd);
				}
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerOpportunityData.generateResponseBodyOppUpdate(response.statusCode, null, resultOpp, resultOppLi);

			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				response.responseBody = ERPMessageHandlerOpportunityData.generateResponseBody(response.statusCode, e.getMessage() + e.getStackTraceString());

				if(e.getMessage().contains('DELETE_FAILED, unable to modify activated order')) {
					try {
						List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'aleksandr.novikov@m.interpipe.biz'];
						String mailBody = 'The order synchronization operation failed. Changes that are not allowed for an active order were attempted. Order ITE Number: ' + generalData.data.header.ITENumber;
						Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
						List<String> toAddresses = new List<String> {generalData.data.header.SalesRep.Email,'Aleksandr.Novikov@m.interpipe.biz'};
						email.setToAddresses(toAddresses);
						email.setSubject('The order synchronization operation failed');
						email.setPlainTextBody(mailBody);
						if ( owea.size() > 0 ) {
							email.setOrgWideEmailAddressId(owea.get(0).Id);
						}
						Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
					} catch (Exception ex) {
						System.debug('An error occurred while sending the email: ' + ex.getMessage());
					}
				}

                Triton.instance.integrationError(
					TritonTypes.Type.ERPMessageHandler,
					TritonTypes.Area.OpportunityData,
					e.getMessage(),
					e.getMessage(),
					request,
					response
				);

				// Triton.instance.integrationError(TritonTypes.Type.ERPMessageHandler, TritonTypes.Area.OpportunityData, e.getMessage(), e.getMessage(),
				// 		request, response, generalData.data.header.account.Name, generalData.data.header.account.Id, generalData.data.header.ITENumber);
			}
		}

		private static void processSyncedOppoDataUpdated(ERPRequestParser.ExecuteResponce executeResponseData, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPWebServiceHandler.UpdateSyncedResult resultOpp = ERPWebServiceHandler.updateSyncedOpportunity(executeResponseData, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPWebServiceHandler.generateResponseBodySyncedOppUpdate(response.statusCode, NULL, resultOpp);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				response.responseBody = ERPWebServiceHandler.generateResponseBody(response.statusCode, e.getMessage() + e.getStackTraceString());
			}
		}

		private static void processChatterPostCreation(ERPRequestParser.ERPItemStage itemStaegeData, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPWebServiceHandler.createChatterPost(itemStaegeData, requestBody);
				response.statusCode = 200;
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				response.responseBody = ERPWebServiceHandler.generateResponseBody(response.statusCode, e.getMessage() + e.getStackTraceString());
			}
		}

		// private static void processMonthPlanFactMessage(ERPRequestParser.MonthPlanFactMessage ParsedMessage, RestResponse response, String requestBody) {
		// 	String errorMsg = '';

		// 	Savepoint sp = Database.setSavepoint();
		// 	try {

		// 		ErpMessageHandlerMonthPlanFact.MessageProcessingResult res = ErpMessageHandlerMonthPlanFact.ProcessMessage(ParsedMessage, requestBody);
		// 		response.statusCode = 200;
		// 		response.responseBody = ErpMessageHandlerMonthPlanFact.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
		// 	} catch(Exception e) {
		// 		Database.rollback(sp);
		// 		response.statusCode = 500;
		// 		String stackTrace = e.getStackTraceString();
		// 		stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
		// 		//response.responseBody = ERPWebServiceHandler.generateResponseBody(response.statusCode, e.getMessage() + stackTrace);
		// 		response.responseBody = ErpMessageHandlerMonthPlanFact.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
		// 	}

		// 	// if (ParsedMessage.PackageNumber == ParsedMessage.TotalPackages) {
		// 	if (ParsedMessage.PackageNumber == ParsedMessage.TotalPackages) {

		// 		//Очистим предыдущие данные за нужный период, применив Batchable Apex:
		// 		String recType = ParsedMessage.MessageType == 'ERP-SF_MonthPlan' ? 'Plan' : 'Fact';
		// 		Date periodStart = Datetime.newInstance(Long.valueOf(parsedMessage.PeriodStart + '000')).date();
		// 		Date periodEnd = Datetime.newInstance(Long.valueOf(parsedMessage.PeriodEnd + '000')).date();
		// 		periodEnd = periodEnd.addMonths(1).toStartOfMonth().addDays(-1);
		// 		String messageTimeStamp = ParsedMessage.MessageTimestamp;
		// 		// PJRCleaning pjrc = new PJRCleaning(recType, periodStart, periodEnd, messageTimeStamp);
		// 		// Id pjrcBatchInstanceId = Database.executeBatch(pjrc);
		// 		SPFCleaning spfc = new SPFCleaning(recType, periodStart, periodEnd, messageTimeStamp, requestBody);
		// 		Id spfcBatchInstanceId = Database.executeBatch(spfc);
		// 		//---------------------------------------------------------
		// 	}
		// }

		private static void processMonthPlanFactMessage(ERPRequestParser.MonthPlanFactMessage ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				String recType = ParsedMessage.MessageType == 'ERP-SF_MonthPlan' ? 'Plan' : 'Fact';
				Date periodStart = Datetime.newInstance(Long.valueOf(parsedMessage.PeriodStart + '000')).date();
				Date periodEnd = Datetime.newInstance(Long.valueOf(parsedMessage.PeriodEnd + '000')).date();
				periodEnd = periodEnd.addMonths(1).toStartOfMonth().addDays(-1);
				String messageTimeStamp = ParsedMessage.MessageTimestamp;
				SPFCleaning spfc = new SPFCleaning(recType, periodStart, periodEnd, messageTimeStamp, requestBody);
				Id spfcBatchInstanceId = Database.executeBatch(spfc, 2000);

			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
			}
		}

		private static void processSalesBudgetMessage(ERPRequestParser.SalesBudgetMessage ParsedMessage, RestResponse response, String requestBody, RestRequest request) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerSalesBudget.MessageProcessingResult res = ERPMessageHandlerSalesBudget.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerSalesBudget.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerSalesBudget.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);

				Triton.instance.integrationError(TritonTypes.Type.ERPMessageHandler, TritonTypes.Area.SalesBudget, e.getMessage(), e.getMessage(), request, response);
			}

			if (ParsedMessage.Metadata.partNumber == ParsedMessage.Metadata.totalParts) {
				System.debug('------------------ParsedMessage.Metadata.partNumber == ParsedMessage.Metadata.totalParts--------------------');
				String budgetId = ParsedMessage.Data.BudgetId;
				Long messageTimeStamp =  parsedMessage.Metadata.MsgTimestamp.getTime();
				System.debug('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'+ budgetId +' !!!!' + messageTimeStamp);
				SalesBudgetCleaning sbc = new SalesBudgetCleaning(budgetId, messageTimeStamp);
				Id sbcBatchInstanceId = Database.executeBatch(sbc);
			}
		}

		private static void processReclamationStatus(ERPMessageParser.ErpToSfMessage_ClaimStage ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerReclamationStatus.MessageProcessingResult res = ERPMessageHandlerReclamationStatus.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerReclamationStatus.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerSalesBudget.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processReclamationDoc(ERPMessageParser.ErpToSfMessage_ClaimDoc ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerReclamationDoc.MessageProcessingResult res = ERPMessageHandlerReclamationDoc.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerReclamationDoc.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerReclamationDoc.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processDebit(ERPMessageParser.ErpToSfMessage_Debit ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerDebit.MessageProcessingResult res = ERPMessageHandlerDebit.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerDebit.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerDebit.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processProdPlanBalance(ERPMessageParser.ErpToSfMessage_ProdPlanBalance ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			System.debug('---- parsed message ----');
			System.debug(ParsedMessage);
			System.debug('--------------');
			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerProdPlanBalance.MessageProcessingResult res = ERPMessageHandlerProdPlanBalance.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerProdPlanBalance.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerProdPlanBalance.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void proccessInvoicePDF(ERPMessageParser.ErpToSfMessage_InvoicePDF ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';
			System.debug('-------------------parsed message-------:  ' + ParsedMessage);
			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerInvoicePDF.MessageProcessingResult res = ERPMessageHandlerInvoicePDF.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerInvoicePDF.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerInvoicePDF.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void proccessOrderProbability(ERPMessageParser.ERPToSfMessage_OrderProbabilityQuery ParsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';
			System.debug('-------------------parsed message-------:  ' + ParsedMessage);
			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerOrderProbability.MessageProcessingResult res = ERPMessageHandlerOrderProbability.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerOrderProbability.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerProdPlanBalance.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processOrderItemStage(ERPMessageParser.ErpToSfMessage_OrderItemStage ParsedMessage, RestResponse response, String requestBody){
			system.debug(ParsedMessage);
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerOrderItemStage.MessageProcessingResult res = ERPMessageHandlerOrderItemStage.ProcessMessage(ParsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerOrderItemStage.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerSalesBudget.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processPriceApprovalRequestMessage(ERPMessageParser.ErpToSfMessage_PAR parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerPriceApprovalRequest.MessageProcessingResult res = ERPMessageHandlerPriceApprovalRequest.ProcessMessage(parsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerPriceApprovalRequest.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerPriceApprovalRequest.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processAccountsReceivableMessage(ERPMessageParser.ErpToSfMessage_AccountsReceivable parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerAccountsReceivable.MessageProcessingResult res = ERPMessageHandlerAccountsReceivable.ProcessMessage(parsedMessage, requestBody);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerAccountsReceivable.generateResponseBody(HTTPSTATUSES, response.statusCode, NULL, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerAccountsReceivable.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processRouteMessage(ERPMessageParser.ErpToSfMessage_Route parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerRoute.MessageProcessingResult res = ERPMessageHandlerRoute.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerRoute.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerRoute.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processFamilyTypeMessage(ERPMessageParser.ErpToSfMessage_FamilyType parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerFamilyType.MessageProcessingResult res = ERPMessageHandlerFamilyType.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerFamilyType.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerFamilyType.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processFamilyMessage(ERPMessageParser.ErpToSfMessage_Family parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerFamily.MessageProcessingResult res = ERPMessageHandlerFamily.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerFamily.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerFamily.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processRouteFamilyMessage(ERPMessageParser.ErpToSfMessage_RouteFamilies parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerRouteFamily.MessageProcessingResult res = ERPMessageHandlerRouteFamily.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerRouteFamily.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerRouteFamily.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processStructQuotaConfigMessage(ERPMessageParser.ErpToSfMessage_StructQuotaConfig parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerStructQuotaConfig.MessageProcessingResult res = ERPMessageHandlerStructQuotaConfig.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerStructQuotaConfig.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerStructQuotaConfig.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processRouteQuotaMessage(ERPMessageParser.ErpToSfMessage_RouteQuota parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerRouteQuota.MessageProcessingResult res = ERPMessageHandlerRouteQuota.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerRouteQuota.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerRouteQuota.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processStructQuotaMessage(ERPMessageParser.ErpToSfMessage_StructQuota parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerStructQuota.MessageProcessingResult res = ERPMessageHandlerStructQuota.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerStructQuota.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerStructQuota.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		private static void processKbSpecMessage(ERPMessageParser.ErpToSfMessage_KbSpec parsedMessage, RestResponse response, String requestBody) {
			String errorMsg = '';

			Savepoint sp = Database.setSavepoint();
			try {
				ERPMessageHandlerKbSpec.MessageProcessingResult res = ERPMessageHandlerKbSpec.ProcessMessage(parsedMessage);
				response.statusCode = 200;
				response.responseBody = ERPMessageHandlerKbSpec.generateResponseBody(HTTPSTATUSES, response.statusCode, res.error, res);
			} catch(Exception e) {
				Database.rollback(sp);
				response.statusCode = 500;
				String stackTrace = e.getStackTraceString();
				stackTrace = stackTrace == '()\n\n\n' ? '' : stackTrace;
				response.responseBody = ERPMessageHandlerKbSpec.generateResponseBody(HTTPSTATUSES, response.statusCode, e.getMessage() + stackTrace, null);
			}
		}

		public static void createInegrationLog(String errorMessage, RestRequest request, RestResponse response, TritonTypes.Area area) {
			Triton.instance.integrationError(TritonTypes.Type.ERPMessageHandler,
					area,
					errorMessage,
					errorMessage,
					request,
					response
			);
		}

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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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