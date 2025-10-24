public without sharing class OpportunityInfoController {
	@AuraEnabled
	public Opportunity oppo { get; set; }
	@AuraEnabled
	public Account acc { get; set; }
	@AuraEnabled
	public List<OpportunityLineItem> products { get; set; }
	@AuraEnabled
	public User bo_user { get; set; }
    @AuraEnabled
	public User additionalbo_user { get; set; }    
	@AuraEnabled
	public List<OpportunitySenderMail> emails { get; set; }
	@AuraEnabled
	public List<OpportunitySenderAttachment> attachements { get; set; }

	private static User BOSpecialist;
    private static User AdditionalBOSpecialist;
	private static final String NO_ERP_VALUE = 'There is no value in the LoginERP__c field';


	@AuraEnabled
	public static String getJSONData(Opportunity opp, Account acc, List<OpportunityLineItem> opportunityProducts) {
		//Picklist fields maps
		Map<String, String> priceUnitValues = ApexUtil.getPicklistFieldMap('OpportunityLineItem', 'InquiryUnit__c');
		Map<String, String> salesDivisionApinames = ApexUtil.getPicklistFieldMap('User', 'SalesDivision__c');

		String epochFromDate = String.valueOf(Datetime.now().getTime()).substring(0, String.valueOf(Datetime.now().getTime()).length() - 3);

		JSONGenerator jsonToSend = JSON.createGenerator(true);
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('MessageType', 'SF-ERP_OpportunityData');
		jsonToSend.writeObjectField('SyncDateTime', String.valueOf(epochFromDate));
		jsonToSend.writeFieldName('General_Data');
		jsonToSend.writeStartObject();
		jsonToSend.writeObjectField('ID_SF', opp.Id);
		jsonToSend.writeObjectField('ID_ERP', (opp.ID_ERP__c == null) ? '' : opp.ID_ERP__c);
		if (acc.ID_ERP__c != null) {
			jsonToSend.writeObjectField('Account', acc.ID_ERP__c);
		}
		jsonToSend.writeObjectField('AccountName', acc.Name);
		jsonToSend.writeObjectField('MarketSegment', (opp.MarketSegment__c == null) ? '' : opp.MarketSegment__c);
		jsonToSend.writeObjectField('Country', (opp.Country__r.NumCode__c == null) ? '' : opp.Country__r.NumCode__c);
		jsonToSend.writeObjectField('DeliveryTerms', (opp.DeliveryTerms__c == null) ? '' : opp.DeliveryTerms__r.ID_ERP__c);
		jsonToSend.writeObjectField('PaymentTerms', (opp.PaymentTerms__c == null) ? '' : opp.PaymentTerms__r.ID_ERP__c);
		jsonToSend.writeObjectField('Description', (opp.Description == null) ? '' : opp.Description);
		jsonToSend.writeObjectField('OpportunityCurrency', (opp.CurrencyIsoCode == null) ? '' : String.valueOf(opp.CurrencyIsoCode));
		jsonToSend.writeObjectField('ExpectedDelivDate', (opp.ExpectedDelivDate__c == null) ? '' : String.valueOf(opp.ExpectedDelivDate__c));

		if(opp.Owner.LoginERP__c != null) {
			jsonToSend.writeObjectField('SalesRepId', opp.Owner.LoginERP__c);
		} else {
			createDebugLog(TritonTypes.Type.Backend, NO_ERP_VALUE, 'Opportunity Owner ' + opp.Owner.Name + ' does not have a value in the LoginERP__c field. Opportunity Id - ' + opp.Id, null);
			throw new AuraHandledException('Opportunity Owner ' + opp.Owner.Name + ' does not have a value in the LoginERP__c field.');
		}
		
		if(BOSpecialist != null) {
			if(BOSpecialist.LoginERP__c != null) {
				jsonToSend.writeObjectField('BOSpecialistId', BOSpecialist.LoginERP__c);
			} else {
				createDebugLog(TritonTypes.Type.Backend, NO_ERP_VALUE, 'BOSpecialist ' + BOSpecialist.Name + ' does not have a value in the LoginERP__c field. Opportunity Id - ' + opp.Id, null);
				throw new AuraHandledException('BOSpecialist ' + BOSpecialist.Name + ' does not have a value in the LoginERP__c field.');
			}
		} else {
			jsonToSend.writeObjectField('BOSpecialistId', '');
		}
		
		if(AdditionalBOSpecialist != null) {
			if(AdditionalBOSpecialist.LoginERP__c != null) {
				jsonToSend.writeObjectField('AdditionalBOSpecialistId', AdditionalBOSpecialist.LoginERP__c);
			} else {
				createDebugLog(TritonTypes.Type.Backend, NO_ERP_VALUE, 'Additional BO Specialist ' + AdditionalBOSpecialist.Name + ' does not have a value in the LoginERP__c field. Opportunity Id - ' + opp.Id, null);
				throw new AuraHandledException('Additional BO Specialist ' + AdditionalBOSpecialist.Name + ' does not have a value in the LoginERP__c field.');
			}
		} else {
			jsonToSend.writeObjectField('AdditionalBOSpecialistId', '');
		}

		jsonToSend.writeFieldName('Item_Data');
		jsonToSend.writeStartArray();
		
		for (OpportunityLineItem oppProduct : opportunityProducts) {
			jsonToSend.writeStartObject();

			jsonToSend.writeObjectField('Modified', (oppProduct.LastModifiedDate > opp.LastSyncERP__c) ? ((oppProduct.ID_ERP__c == '' || oppProduct.ID_ERP__c == null) ? '0' : '1') : '0');

			jsonToSend.writeObjectField('ID_SF', (oppProduct.Id == null) ? '' : oppProduct.Id);
			jsonToSend.writeObjectField('ID_ERP', (oppProduct.NPP_ERP__c == null) ? '' : String.valueOf(oppProduct.NPP_ERP__c));
			jsonToSend.writeObjectField('ProductGroup', (oppProduct.Product2.ID_ERP__c == null) ? '' : oppProduct.Product2.ID_ERP__c);
			jsonToSend.writeObjectField('QuotaType', (oppProduct.QuotaType__r.ID_ERP__c == null) ? '' : oppProduct.QuotaType__r.ID_ERP__c);
			jsonToSend.writeObjectField('Standard', (oppProduct.ProductStandard__r.ID_ERP__c == null ? '' : oppProduct.ProductStandard__r.ID_ERP__c));
			jsonToSend.writeObjectField('SpecLevel', (oppProduct.ProductSpecLevel__r.ID_ERP__c == null ? '' : oppProduct.ProductSpecLevel__r.ID_ERP__c));
			jsonToSend.writeObjectField('SteelGrade', (oppProduct.SteelGrade__r.ID_ERP__c == null) ? '' : oppProduct.SteelGrade__r.ID_ERP__c);
			jsonToSend.writeObjectField('OD', (oppProduct.TubeOD__r.ID_ERP__c == null) ? '' : oppProduct.TubeOD__r.ID_ERP__c);
			jsonToSend.writeObjectField('WT', (oppProduct.TubeWT__r.ID_ERP__c == null) ? '' : oppProduct.TubeWT__r.ID_ERP__c);
			jsonToSend.writeObjectField('InqQuantity', (oppProduct.InquiryQuantity__c == null) ? '' : String.valueOf(oppProduct.InquiryQuantity__c));
			jsonToSend.writeObjectField('Quantity_Mt', (oppProduct.Quantity == null) ? '0' : String.valueOf(oppProduct.Quantity));
			jsonToSend.writeObjectField('Quantity_m', (oppProduct.Quantity_m__c == null) ? '0' : String.valueOf(oppProduct.Quantity_m__c));
			jsonToSend.writeObjectField('Quantity_ft', (oppProduct.Quantity_ft__c == null) ? '0' : String.valueOf(oppProduct.Quantity_ft__c));
			jsonToSend.writeObjectField('Quantity_pcs', (oppProduct.Quantity_pcs__c == null) ? '0' : String.valueOf(oppProduct.Quantity_pcs__c));
			jsonToSend.writeObjectField('InqUnit', (oppProduct.InquiryUnit__c == null) ? '' : oppProduct.InquiryUnit__c);
			jsonToSend.writeObjectField('LengthSize', (oppProduct.LengthSize__r.ID_ERP__c == null) ? '' : oppProduct.LengthSize__r.ID_ERP__c);
			jsonToSend.writeObjectField('Ends', (oppProduct.TubeEnds__r.ID_ERP__c == null) ? '' : oppProduct.TubeEnds__r.ID_ERP__c);
			jsonToSend.writeObjectField('Coating', (oppProduct.Coating__r.ID_ERP__c == null) ? '' : oppProduct.Coating__r.ID_ERP__c);
			jsonToSend.writeObjectField('Shop', (oppProduct.Shop__r.ID_ERP__c == null) ? '' : oppProduct.Shop__r.ID_ERP__c);
			jsonToSend.writeObjectField('Price', (oppProduct.UnitPrice == null) ? '0' : String.valueOf(oppProduct.UnitPrice));
			jsonToSend.writeObjectField('TotalPrice', (oppProduct.TotalPrice == null) ? '0' : String.valueOf(oppProduct.TotalPrice));
			jsonToSend.writeObjectField('ShippingPointType', (oppProduct.ShippingPoint__r.ID_ERP__c == null) ? '' : oppProduct.ShippingPoint__r.ID_ERP__c.substringBefore('-'));
			jsonToSend.writeObjectField('ShippingPoint', (oppProduct.ShippingPoint__r.ID_ERP__c == null) ? '' : oppProduct.ShippingPoint__r.ID_ERP__c.substringAfter('-'));
			jsonToSend.writeEndObject();
		}
		jsonToSend.writeEndArray();

		jsonToSend.writeEndObject();

		jsonToSend.writeEndObject();

		System.debug('JSON to send - ' + jsonToSend.getAsString());
		JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();

		System.debug(jsonWrapper.getAsString());
		return jsonWrapper.getAsString();
	}

	@AuraEnabled
	public static void sendJSONData(String jsonedWrapper) {
		OpportunityInfoController wrapper = (OpportunityInfoController) JSON.deserializeStrict(jsonedWrapper, OpportunityInfoController.class);

		List<OpportunityLineItem> items = [
		                                   SELECT Name, ProductCode, LastModifiedDate, Product2.ID_ERP__c, SteelGrade__r.ID_ERP__c, ProductSpecLevel__r.ID_ERP__c, InquiryQuantity__c,
		                                   Quantity, Quantity_m__c, Quantity_ft__c, Shop__r.ID_ERP__c, Description,
		                                   UnitPrice, TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, ShippingPoint__r.ID_ERP__c,
		                                   Quantity_pcs__c, InquiryUnit__c, TubeEnds__r.ID_ERP__c, LengthSize__r.ID_ERP__c, TotalPrice,
		                                   ProductStandard__r.ID_ERP__c, Coating__r.ID_ERP__c, ID_ERP__c, QuotaType__r.ID_ERP__c, NPP_ERP__c
		                                   FROM OpportunityLineItem WHERE OpportunityId = :wrapper.oppo.Id
		                                   ORDER BY Product2.ID_ERP__c];

		Id boUserId = wrapper.oppo.AssignedBOS__c == null ? wrapper.bo_user.Id : wrapper.oppo.AssignedBOS__c;
		BOSpecialist = [SELECT Id, Name, FirstName, Email, ID_ERP__c, LoginERP__c, EmployeeNumber FROM User WHERE Id = :BOuserId LIMIT 1];
       
        
        Id AdditionalBOUserId = wrapper.oppo.AdditionalBOS__c;
        if(string.isNotBlank(AdditionalBOUserId)){
        AdditionalBOSpecialist = [SELECT Id, Name, FirstName, Email, ID_ERP__c, LoginERP__c, EmployeeNumber FROM User WHERE Id = :AdditionalBOUserId LIMIT 1];
        }
        
		Triton.instance.startTransaction();
		String data = getJSONData(wrapper.oppo, wrapper.acc, items);
		createDebugLog(TritonTypes.Type.RequestDebug, 'Send to Backoffice Request body', data, null);
		SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();

		String login = Credentials__c.getOrgDefaults().User_Login__c;
		String password = Credentials__c.getOrgDefaults().User_Password__c;
		String response = ERPhandler.LoginEx(login, password);
		ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);

		String calc = '_SL_NEW_OPPORTUNITY';
		String ticket = requestObject.Ticket;
		String arg = data;
		ERPRequestParser.ExecuteResponce idResponse = null;
		try {	
			String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
			String processed = erpResult.remove('\\');
			processed = processed.substring(1, processed.length() - 1);
			idResponse = (ERPRequestParser.ExecuteResponce) JSON.deserialize(processed, ERPRequestParser.ExecuteResponce.class);
			Datetime dateTimeOfSyncedOpp;
			String iteNumber = idResponse?.Opportunity?.ITENumber;
			
			createDebugLog(TritonTypes.Type.RequestDebug, 'Send to Backoffice Response body', String.valueOf(idResponse), iteNumber);
            
                                  
			if (idResponse.ErrorType == null && idResponse.ErrorMessage == null && idResponse.Opportunity != null && String.isNotBlank(idResponse.Opportunity.ID_ERP)) {

				if (idResponse.SyncResult == '1') {

					List<ERPRequestParser.ERPOpportunityLineItemId> oppLiResultList = idResponse.Opportunity.Item;
					List<OpportunityLineItem> oppLiToUpdate = new List<OpportunityLineItem> ();

					if (oppLiResultList != null) {
						for (ERPRequestParser.ERPOpportunityLineItemId oppLi : oppLiResultList) {
							if (String.isNotBlank(oppLi.ID_SF)) {
								oppLiToUpdate.add(new OpportunityLineItem(
								                                          Id = oppLi.ID_SF,
								                                          NPP_ERP__c = oppLi.ID_ERP
								));
							}
						}
						if (!oppLiToUpdate.isEmpty()) {
							update oppLiToUpdate;
						}
					}

					Opportunity opp = new Opportunity(
					                                  Id = wrapper.oppo.Id,
					                                  ID_ERP__c = idResponse.Opportunity.ID_ERP,
													  ITENumber__c = idResponse.Opportunity.ITENumber,
					                                  AssignedBOS__c = BOSpecialist.Id                        							
                        							  
					);
					
					if (idResponse.SyncDateTime != null) {
						dateTimeOfSyncedOpp = DateTime.newInstance(Long.valueOf(idResponse.SyncDateTime + '000'));
						opp.LastSyncERP__c = dateTimeOfSyncedOpp;
					}

					update opp;

					if (BOSpecialist != null) {

						String textForEmailBody = formEmailBody(wrapper, idResponse, true);
						sendEmail(idResponse.Opportunity.ID_ERP, textForEmailBody, BOSpecialist.Email,  wrapper.getCheckedAttachments(), wrapper.getCheckedEmails());
					}
                    if (AdditionalBOSpecialist != null) {

						String textForEmailBody = formEmailBody(wrapper, idResponse, true);
						sendEmail(idResponse.Opportunity.ID_ERP, textForEmailBody, AdditionalBOSpecialist.Email,  wrapper.getCheckedAttachments(), wrapper.getCheckedEmails());
                    }
				}

				if (idResponse.SyncResult == '0') {
					
					if (idResponse.SyncDateTime != null) {
						dateTimeOfSyncedOpp = DateTime.newInstance(Long.valueOf(idResponse.SyncDateTime + '000'));
					}

					if (BOSpecialist != null) {

						String textForEmailBody = formEmailBody(wrapper, idResponse, false);
						sendEmail(idResponse.Opportunity.ID_ERP, textForEmailBody, BOSpecialist.Email, wrapper.getCheckedAttachments(), wrapper.getCheckedEmails());			
					}
                    if (AdditionalBOSpecialist != null) {

						String textForEmailBody = formEmailBody(wrapper, idResponse, false);
						sendEmail(idResponse.Opportunity.ID_ERP, textForEmailBody, AdditionalBOSpecialist.Email, wrapper.getCheckedAttachments(), wrapper.getCheckedEmails());			
                    }
				}

			} else {
				ERPWebServiceHandler.insertErrorTask('SF to ERP', arg, erpResult, wrapper.oppo.Id);
				Triton.instance.error(TritonTypes.Type.Backend, 
							  		  TritonTypes.Area.SendToBackoffice,   
									  Label.AuraMsgErrorFromERP,
									  idResponse.ErrorType + ' ' + idResponse.ErrorMessage + '; Opportunity Id - ' + wrapper.oppo.Id);
				throw new AuraHandledException(Label.AuraMsgErrorFromERP + '</br>' + idResponse.ErrorType + '</br>' + idResponse.ErrorMessage);
			}
		} catch(CalloutException callfail) {
			String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();
//			FalseSynchroService.createFalseSynchroRecord(calc,arg,wrapper.oppo.Id);
			sendSyncEmailForUser(wrapper.oppo.Id);
			ERPWebServiceHandler.insertErrorTask('SF to ERP (callout exception)', arg, errorMessage, wrapper.oppo.Id);
			Triton.instance.error(TritonTypes.Area.SendToBackoffice, callfail);
			throw new AuraHandledException(Label.SFtoERPConnectionFails);
		} catch(System.JSONException jsfailed) {
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
			ERPWebServiceHandler.insertErrorTask('SF to ERP (serialization exception)', arg, errorMessage, wrapper.oppo.Id);
			Triton.instance.error(TritonTypes.Area.SendToBackoffice, jsfailed);
			throw new AuraHandledException(Label.InvalidJSONReceived);
		}

		Triton.instance.stopTransaction();
	}

	private static void createDebugLog(TritonTypes.Type type, String summary, String details, String iteNumber) {
		Triton.instance.debug(type, TritonTypes.Area.SendToBackoffice, summary, details, iteNumber);
	}

	public static void sendSyncEmailForUser(Id oppId){
        Set<String> userEmail = new Set<String>();
        userEmail.add('sflog@m.interpipe.biz');
		userEmail.add('o.motoziuk@polytech.software');
		userEmail.add('Aleksandr.Novikov@m.interpipe.biz');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>(userEmail);
        message.optOutPolicy = 'FILTER';
        message.subject = 'Opportunity Sync Error';
        message.HtmlBody = 'This document'+' ' + oppid + ' ' + 'was not synchronized with ERP - network tunnel is wrong. We saved this data and we will try to synchronize this document every 30 min. After successful try we will inform you by e-mail';
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }

	private static String formEmailBody(OpportunityInfoController wrapper, ERPRequestParser.ExecuteResponce idResponse, Boolean isNew) {

		User sm = [SELECT Id, Name FROM User WHERE Id = :wrapper.oppo.OwnerId].get(0);
		
		String body = 'Hello ' + '\n\n';

		if (isNew) {
			body += UserInfo.getName() + ' sent a new customer inquiry for processing in It-Enterprise:\n';
		} else {
			body += UserInfo.getName() + ' made changes to existing order. Please, review and accept or refuse these changes.\n';
		}

		body += '\nOrder number: ' + idResponse.Opportunity.ITENumber + '.\n';
		body += 'Order ID (Undoc): ' + idResponse.Opportunity.ID_ERP + '.\n';
		body += 'Sales manager: ' + sm.Name + '.\n';
		body += 'Order name: ' + wrapper.oppo.Name + '.\n';
		body += 'Customer: ' + wrapper.acc.Name + '.\n';
        body += 'Opportunity Stage: ' + wrapper.oppo.StageName + '.\n';
		if (wrapper.oppo.CommentToBackoffice__c != null) {
			body += 'Description: ' + wrapper.oppo.CommentToBackoffice__c + '.\n';
		}
		body += '\nYou can open the order in the web version of IT-Enterprise by navigating to:\n';
		body += idResponse.Opportunity.ITEOrderUrl;
		return body;

	}

	private static void sendEmail(String subject, String body, String toAddress, Set<String> attachIds, List<EmailMessage> mails) {
		List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage> ();
	
		if (attachIds.isEmpty()) {
			emailsToSend.add(createSingleEmail(toAddress, subject, body, null));
		} else {
			emailsToSend.add(createSingleEmail(toAddress, subject, body, new List<String> (attachIds)));
		}

		for (EmailMessage msg : mails) {
			emailsToSend.add(createSingleEmail(toAddress, msg.Subject, msg.TextBody, null));
		}
		if (!emailsToSend.isEmpty()) {
			Messaging.sendEmail(emailsToSend);
		}
	}

	private static Messaging.SingleEmailMessage createSingleEmail(String toAddress, String subject, String body, List<String> attachIds) {
		System.debug(attachIds);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new List<String> { toAddress });
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		if (attachIds != null) {
			mail.setEntityAttachments(attachIds);
		}
		return mail;
	}

	@AuraEnabled
	public static OpportunityInfoController getOpportunity(Id oppId) {
		return new OpportunityInfoController(oppId);
	}

	public OpportunityInfoController(Id oppId) {
		oppo = [SELECT Id, Name, ID_ERP__c, LastSyncERP__c, Country__c, Country__r.NumCode__c, Country__r.Name, Description, CommentToBackoffice__c, CurrencyIsoCode, AccountId,
				OwnerId, Owner.ID_ERP__c, Owner.LoginERP__c, Owner.Name, Owner.SalesDivision__c,
				AssignedBOS__c, AssignedBOS__r.ID_ERP__c, AssignedBOS__r.LoginERP__c, AssignedBOS__r.Name, AssignedBOS__r.Email,
                AdditionalBOS__c,AdditionalBOS__r.ID_ERP__c, AdditionalBOS__r.LoginERP__c, AdditionalBOS__r.Name, AdditionalBOS__r.Email,
                PaymentTerms__c, PaymentTerms__r.ID_ERP__c, DeliveryTerms__c, DeliveryTerms__r.ID_ERP__c, DeliveryTerms__r.Name, ExpectedDelivDate__c, MarketSegment__c,StageName
		        FROM Opportunity
		        WHERE Id = :oppId LIMIT 1];

		acc = [SELECT Name, Type, Website, Phone, BillingCity, BillingCountry, BillingState, BillingStreet, BillingPostalCode,
		       ShippingCity, ShippingCountry, ShippingState, ShippingStreet, ShippingPostalCode, Description,
		       ID_ERP__c
		       FROM Account
		       WHERE Id = :oppo.AccountId];

		products = [SELECT Name, ProductCode, LastModifiedDate, Product2.ID_ERP__c, Product2.Name, SteelGrade__r.ID_ERP__c, ProductSpecLevel__r.ID_ERP__c, InquiryQuantity__c,
		            Quantity, Quantity_m__c, Quantity_ft__c, Shop__r.ID_ERP__c, Description,
		            UnitPrice, TubeOD__r.ID_ERP__c, TubeWT__r.ID_ERP__c, ShippingPoint__r.ID_ERP__c,
		            Quantity_pcs__c, InquiryUnit__c, TubeEnds__r.ID_ERP__c, LengthSize__r.ID_ERP__c, TotalPrice,
		            ProductStandard__r.ID_ERP__c, Coating__r.ID_ERP__c, ID_ERP__c, QuotaType__r.ID_ERP__c, NPP_ERP__c
		            FROM OpportunityLineItem WHERE OpportunityId = :oppId]; 

		emails = new List<OpportunitySenderMail> ();
		attachements = new List<OpportunitySenderAttachment> ();
		Set<Id> emailMessageIds = new Set<Id> ();
		for (EmailMessage messag :[SELECT Id, Subject, TextBody FROM EmailMessage WHERE RelatedToId = :oppId]) {
			emails.add(new OpportunitySenderMail(messag, false));
			emailMessageIds.add(messag.Id);
		}
		for (Attachment at :[SELECT Id, Name FROM Attachment WHERE ParentId IN :emailMessageIds]) {
			attachements.add(new OpportunitySenderAttachment(at.id, at.name, false, 'Email'));
		}
		for (Attachment attch :[SELECT Id, Name FROM Attachment WHERE ParentId = :oppId]) {
			attachements.add(new OpportunitySenderAttachment(attch.id, attch.name, false, 'Opportunity'));
		}
		List<String> documentsList = new List<String> ();
		for (ContentDocumentLink cdl :[SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :oppId]) {
			documentsList.add(cdl.ContentDocumentId);
		}
		for (ContentVersion cv :[SELECT ID, Title FROM ContentVersion WHERE IsLatest = true AND ContentDocumentId IN :documentsList]) {
			attachements.add(new OpportunitySenderAttachment(cv.id, cv.Title, false, 'Opportunity'));
		}
		System.debug(emails);
		System.debug(attachements);
	}

	public List<EmailMessage> getCheckedEmails() {
		List<EmailMessage> result = new List<EmailMessage> ();
		for (OpportunitySenderMail mail : emails) {
			if (mail.checkbox) {
				result.add(mail.mailMessage);
			}
		}
		return result;
	}

	public Set<String> getCheckedAttachments() {
		Set<String> result = new Set<String> ();
		for (OpportunitySenderAttachment attach : attachements) {
			if (attach.checkbox) {
				result.add(attach.recordId);
			}
		}
		return result;
	}

	public class OpportunitySenderMail {

		@AuraEnabled
		public Boolean checkbox { get; set; }

		@AuraEnabled
		public EmailMessage mailMessage { get; set; }

		public OpportunitySenderMail(EmailMessage mailMessag, Boolean isChecked) {
			this.checkbox = isChecked;
			this.mailMessage = mailMessag;
		}
	}

	public class OpportunitySenderAttachment {

		@AuraEnabled
		public Boolean checkbox { get; set; }
		@AuraEnabled
		public String recordId { get; set; }
		@AuraEnabled
		public String Name { get; set; }
		@AuraEnabled
		public String source { get; set; }

		public OpportunitySenderAttachment(String Id, String name, Boolean isChecked, String source) {
			this.checkbox = isChecked;
			this.name = name;
			this.recordId = Id;
			this.source = source;
		}
	}
}