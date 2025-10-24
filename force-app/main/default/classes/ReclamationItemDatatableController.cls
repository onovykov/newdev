public without sharing class ReclamationItemDatatableController {
	@AuraEnabled(cacheable=false)
    public static Reclamation__c getReclamationDetail(String ReclamationId){
        return [SELECT id,Name,CreationDate__c,Account__r.Name,ID_in_ERP__c,ContractNum__c,ContractDate__c,CurrencyIsoCode,toLabel(Status__c),No_Refund__c,Comment__c,Owner.firstName,Owner.LastName,
                (SELECT PO_Number__c,OrderItemID__r.Product2.Name,OrderItemID__r.Name__c,OrderQty__c,MeasurementUnit__c,ClaimQty__c,ClaimSum__c,Currency__c,CurrencyIsoCode,tolabel(Mistmatch_Type__c),tolabel(Mistmatch_SubType__c) FROM Reclamation_Details__r)
                FROM Reclamation__c
				WHERE id = :ReclamationId ];
    }
    
    @AuraEnabled
    public static void deleteReclamation(String ReclamationId){
        delete [SELECT id
                FROM Reclamation__c
				WHERE id = :ReclamationId ];
    }
    
    @AuraEnabled
    public static void deleteReclamationItem(String idRecord){
        delete [SELECT id FROM Reclamation_Detail__c WHERE id=:idRecord];
    }
    
    public static Set<Id> orderIds = new Set<id>();
    public Id currentReclamationId;
    
	@AuraEnabled
    public static List<List<String>> confirmReclamationIt(String reclamationId){       
        Set<Id> orderIdsFromReclamation = new Set<id>();
        List<List<String>> resultList = new List<List<String>>();
        List<String> innerResultList = new List<String>();
        String idERPAssignedBo;
        Reclamation__c reclamation = [SELECT Id,Name ,CreationDate__c, OwnerId, MarketSegment__c, ContractNum__c, ContractDate__c,ReclSum__c,
                                      AssignedBO_ID__c,CurrencyIsoCode,Comment__c,Account__r.ID_ERP__c FROM Reclamation__c WHERE Id=:reclamationId limit 1];
        List<Reclamation_Detail__c> reclamationDetails = [SELECT ID_in_ERP__c,Mistmatch_Type__c, MismatchDate__c,Mistmatch_SubType__c,ClaimQty__c,OrderID__c,
                                                          ClaimSum__c,CurrencyIsoCode,ClaimReason__c,OrderItemID__r.Quantity,iteNumber__c FROM Reclamation_Detail__c WHERE ReclID__c=:reclamationId];
        
        if(!Test.isRunningTest()){
            User assignedBO = [SELECT ID_ERP__c,LoginERP__c	 FROM User WHERE Id = :reclamation.AssignedBO_ID__c LIMIT 1];
        	idERPAssignedBo = assignedBO.LoginERP__c;
        } else {
            idERPAssignedBo = 'test123';
        }
        
        
        system.debug(reclamationDetails);
        Map<String,OpportunityLineItem> relatedOppLineItemMap = getRelatedOppLineItem(reclamationDetails);
        system.debug(relatedOppLineItemMap);
        try{
        JSONGenerator jsonToSend = JSON.createGenerator(true);
        string currentTime = string.valueof(DateTime.now());
		jsonToSend.writeStartObject();
            jsonToSend.writeFieldName('header');
            jsonToSend.writeStartObject();
           
                jsonToSend.writeObjectField('DT','2021-02-12T00:00:00');
            	jsonToSend.writeObjectField('DT_IN',currentTime);
            	//jsonToSend.writeObjectField('K_CL_T',' ');
            	jsonToSend.writeObjectField('KSEC',reclamation.MarketSegment__c==null?'0':reclamation.MarketSegment__c);
            	jsonToSend.writeObjectField('ORG',reclamation.Account__r.ID_ERP__c==null?' ':reclamation.Account__r.ID_ERP__c);
            	
            	jsonToSend.writeObjectField('DES_AMNT',reclamation.ReclSum__c==null?0:reclamation.ReclSum__c);
           		jsonToSend.writeObjectField('OVAL',reclamation.CurrencyIsoCode);
            	jsonToSend.writeObjectField('DESCR',reclamation.Comment__c==null?'none':reclamation.Comment__c);
            	jsonToSend.writeObjectField('UID_RESP',idERPAssignedBo);
                                              
        	jsonToSend.writeEndObject();
        	jsonToSend.writeFieldName('lines');
        	jsonToSend.writeStartArray();
       
        for(Reclamation_Detail__c reclItem: reclamationDetails){
            system.debug(reclItem);
            system.debug(reclItem.ITENumber__c);
            system.debug(relatedOppLineItemMap.get(reclItem.ITENumber__c));
            jsonToSend.writeStartObject();
            jsonToSend.writeObjectField('KZAJNPP',reclItem.iteNumber__c==null?'0':reclItem.iteNumber__c);
            jsonToSend.writeObjectField('K_MISTM',reclItem.Mistmatch_SubType__c==null?null:reclItem.Mistmatch_SubType__c);
            jsonToSend.writeObjectField('DT_MISTM',reclItem.MismatchDate__c==null?null:reclItem.MismatchDate__c);
            jsonToSend.writeObjectField('DESCR',reclItem.ClaimReason__c==null?'0':reclItem.ClaimReason__c);
           
            
            jsonToSend.writeObjectField('TONS',relatedOppLineItemMap.get(reclItem.ITENumber__c).quantity==null?0:relatedOppLineItemMap.get(reclItem.ITENumber__c).quantity);
            jsonToSend.writeObjectField('METERS',relatedOppLineItemMap.get(reclItem.ITENumber__c).Quantity_m__c==null?0:relatedOppLineItemMap.get(reclItem.ITENumber__c).Quantity_m__c);
            jsonToSend.writeObjectField('PCS',relatedOppLineItemMap.get(reclItem.ITENumber__c).Quantity_pcs__c==null?0:relatedOppLineItemMap.get(reclItem.ITENumber__c).Quantity_pcs__c.setScale(0));
           
            
            jsonToSend.writeEndObject();
            orderIdsFromReclamation.add(reclItem.OrderID__c);
        }
        
        jsonToSend.writeEndArray();       
        jsonToSend.writeEndObject();
        
        system.debug(jsonToSend.getAsString());
        makeCallout(jsonToSend.getAsString(), reclamation,orderIdsFromReclamation,reclamation.id);
         
        //searchAndSendNotificationForOrderOwners(orderIdsFromReclamation,reclamation.id);    
        } catch(Exception e ){
            system.debug(e.getMessage());
            innerResultList.add('Error occur. \n Notification mail was sent for administrator');
            system.debug(innerResultList);
            resultList.add(innerResultList);
            searchAndSendNotificationForAdministrator('Error occur: \n Problem with Formalize JSON' + e.getMessage(),reclamation.id);
            return resultList;
        }
        innerResultList.add('Reclamation was created');
        resultList.add(innerResultList);
        return resultList;
        
    }
    
    public static String makeCallout(string jsonString,Reclamation__c currentReclamation,Set<id> orderIds, Id reclamationId){
         SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String login = Credentials__c.getOrgDefaults().User_Login__c;
		String password = Credentials__c.getOrgDefaults().User_Password__c;
		String response = ERPhandler.LoginEx(login, password);
        ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);

		String calc = '_ADD_CLAIM_FROM_SF';
		String ticket = requestObject.Ticket;
		String arg = jsonString;
		ERPRequestParser.ExecuteResponceReclamation idResponse = null;
        try{
			String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
			system.debug(arg);
            system.debug(arg.remove('\\'));
            system.debug(json.serializePretty(arg));
            System.debug('JSON before deserialization - ' + erpResult);
			String processed = erpResult.remove('\\');
			idResponse = (ERPRequestParser.ExecuteResponceReclamation) JSON.deserialize(processed, ERPRequestParser.ExecuteResponceReclamation.class);
            Map<String, Object> mappingResponse = (Map<String, Object>) JSON.deserializeUntyped(processed);
            
        
            if(mappingResponse.get('ERROR') == null){
                system.debug('Success');  
                searchAndSendNotificationForOrderOwners(orderIds,reclamationId);
                //currentReclamation.Comment__c = idResponse.id;
                currentReclamation.ID_in_ERP__c = String.valueOf(mappingResponse.get('ID'));
                currentReclamation.ERPSyncDate__c =  Date.today();
                currentReclamation.ERP_Number__c =String.valueOf(mappingResponse.get('NUMBER'));
                currentReclamation.Status__c = '_1';
                update currentReclamation;
            } else {
                //sendEmail(idResponse.Comments);
                system.debug('error');
                CalloutException e = new CalloutException();
                e.setMessage(String.valueof(mappingResponse.get('ERROR')));
                throw e;
            }
                       
            return processed;
        } catch(CalloutException callfail) {
			String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (callout exception)', arg, errorMessage, wrapper.oppo.Id);	
			system.debug(errorMessage);	
           // sendEmail('Call invalid for json quote item');
			AuraHandledException e = new AuraHandledException('Call invalid for json reclamation');
            e.setMessage(errorMessage);
            system.debug(e);
        throw e;
		} catch(System.JSONException jsfailed) {
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
            system.debug(errorMessage);
           // sendEmail('JSONException. ' + errorMessage);
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (serialization exception)', arg, errorMessage, wrapper.oppo.Id);			
			throw new AuraHandledException(Label.InvalidJSONReceived);
		} finally {
           //closeSessionAsync.closeCurrentSessionAsync(ticket);
       } 
    }
    
    public static List<String> takeLinksToAttachedFiles(id reclamationId){
        List<ContentDocumentLink> contentDocumentLinkList = [SELECT ContentDocumentId, ContentDocument.title FROM ContentDocumentLink WHERE  LinkedEntityId =:reclamationId];
        List<id> contentDocumentIds = new List<id>();
        List<id> contentVersionIds = new List<id>();
        List<String> documentLinks = new List<String>();
        List<ContentDistribution> contentDistributionsToInsert = new List<ContentDistribution>();
        system.debug('136');
        for(ContentDocumentLink cdl:contentDocumentLinkList){
            contentDocumentIds.add(cdl.ContentDocumentId);
        }        
        for(ContentVersion cv : [SELECT Id, IsLatest, title FROM ContentVersion WHERE ContentDocumentId in :contentDocumentIds]){
            contentVersionIds.add(cv.id);
            ContentDistribution cd = new ContentDistribution();
            cd.Name = cv.Title;
            cd.ContentVersionId = cv.Id;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = false;
            cd.PreferencesAllowOriginalDownload = true;
            	contentDistributionsToInsert.add(cd);
        }
        system.debug('152');
        insert contentDistributionsToInsert;
        system.debug('154');
        for(ContentDistribution cd:[SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE ContentVersionId in:contentVersionIds]){
            documentLinks.add(cd.ContentDownloadUrl);
        }
        system.debug(documentLinks);
        return documentLinks;
    }
    
    public static Map<String,OpportunityLineItem> getRelatedOppLineItem(List<Reclamation_Detail__c> reclamationDetails){
       Map<String,OpportunityLineItem> resultMap = new Map<String,OpportunityLineItem>();
       List<String> iteNumberList = new  List<String>();
       for(Reclamation_Detail__c rd:reclamationDetails){
            iteNumberList.add(rd.iteNumber__c);
       }
       system.debug(iteNumberList);        
       List<OpportunityLineItem> fetchedOppLineItem = [SELECT ITENumber__c,Quantity,Quantity_m__c,Quantity_pcs__c FROM OpportunityLineItem WHERE ITENumber__c in:iteNumberList];
       system.debug(fetchedOppLineItem);
        for(OpportunityLineItem oli:fetchedOppLineItem){
            resultMap.put(oli.ITENumber__c,oli);
       }
       return resultMap;
    }
    
    public static void searchAndSendNotificationForOrderOwners(Set<id> orderIds, Id reclamationId){
        List<String> orderBoOwnerEmails = new List<String>();
        Set<String> ownerOppIds = new Set<String>();
        String orgUrl = Label.OrganizationURL;
        String mailBody = 'Reclamation was registered. Link: '+ orgUrl+ '/'+reclamationId;
        
        try{
            for(Order orderSearch:[SELECT Owner.Email,OwnerId FROM ORDER WHERE Id in:orderIds] ){
                //orderOwnerEmails.add(orderSearch.Owner.Email);
                ownerOppIds.add(orderSearch.OwnerId);
            }
        }catch(Exception e){          
            system.debug(e.getMessage());
        }
        
        try{
            for(User boUser:[SELECT AssignedBOS__r.Email,AssignedBOS__c FROM User WHERE Id in:ownerOppIds] ){
                orderBoOwnerEmails.add(boUser.AssignedBOS__r.Email);                      
            }
        }catch(Exception e){          
            system.debug(e.getMessage());
        }    
        
        try{
            //orderBoOwnerEmails.add('Olga.Napkhanko@m.interpipe.biz');
            //orderBoOwnerEmails.add('onaphanko@m.interpipe.biz');
        }catch(Exception e){          
            system.debug(e.getMessage());
        }     
        
        try{
            for(User boUser:[SELECT Manager.Email FROM User WHERE Id in:ownerOppIds] ){
            	orderBoOwnerEmails.add(boUser.Manager.Email);                  
        	}
        }catch(Exception e){          
            system.debug(e.getMessage());
        }
        
        if(orderBoOwnerEmails.size()>0){
           Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = orderBoOwnerEmails;
            message.optOutPolicy = 'FILTER';
            message.subject = 'Registrered Reclamation';
            message.htmlbody = mailBody;
        }                           
    }
    
    public static void searchAndSendNotificationForAdministrator(String errorText, Id reclamationId){
        List<String> administratorEmails = new List<String>();
        
        String mailBody = errorText +' \n Reclamation id: '+ reclamationId;
        String administratorEmail =  Label.email_name_for_send_error;        
        administratorEmails.add(administratorEmail);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = administratorEmails;
        message.optOutPolicy = 'FILTER';
        message.subject = 'Error Reclamation';
        message.htmlbody = mailBody;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);             
    }
    
    @AuraEnabled
    public static void editReclamationItem(Object reclamationItem){
        Map<String, Integer> mistmatchTypeMap = getMapTypes();
        String jsonString = Json.serialize(reclamationItem);
        Reclamation_Detail__c itemToUpdate = (Reclamation_Detail__c) Json.deserialize(jsonString , Reclamation_Detail__c.class);
		//Reclamation_Detail__c itemToUpdate = (Reclamation_Detail__c) reclamationItem;
        update new Reclamation_Detail__c(id = itemToUpdate.id,
                                         ClaimQty__c = itemToUpdate.ClaimQty__c,
                                        Mistmatch_Type__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(itemToUpdate.Mistmatch_Type__c))),
           								Mistmatch_SubType__c =String.valueOf(mistmatchTypeMap.get(String.valueOf(itemToUpdate.Mistmatch_SubType__c))));
    }
    
    public static Map<String,Integer> getMapTypes(){
        //Map<String, Integer> MistmatchType = new Map<String, Integer>();
    	
        Map<String,Integer> valueSubTypeMap= new Map<String,Integer>();
		
		Schema.DescribeFieldResult fieldResult = Reclamation_Detail__c.Mistmatch_SubType__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){			
            valueSubTypeMap.put(pickListVal.getLabel(),Integer.valueOf(pickListVal.getValue()));
		} 
        
        Schema.DescribeFieldResult fieldResult2 = Reclamation_Detail__c.Mistmatch_Type__c.getDescribe();
		List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple2){			
            valueSubTypeMap.put(pickListVal.getLabel(),Integer.valueOf(pickListVal.getValue()));
		}
                                                       
        return valueSubTypeMap;
    }
}