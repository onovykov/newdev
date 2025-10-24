public class QuoteJSONGenerator {
    
	@InvocableMethod(label='generate JSON')
    public static void createJsonData(List<String> idQuote){
        system.debug('------------------------------------');
        Quote curQuote = [SELECT Id,QuoteNumber,OpportunityId, Opportunity.Probability,ExpirationDate FROM Quote WHERE ID=:idQuote[0] LIMIT 1];
        List<OpportunityLineItem> oppLineItems = [SELECT ID_ERP__c,Name__c,ITENumber__c,Product2Id 
                                                  FROM OpportunityLineItem WHERE OpportunityId=:curQuote.OpportunityId];
        List<QuoteLineItem> quoLineItems = [SELECT QuoteId, Name__c,ID_ERP__c, OpportunityLineItemITENumber__c, InquiryUnit__c,Quantity,InquiryQuantity__c,UnitPrice,InquiryUnitPrice__c,LastModifiedDate,Product2Id,OpportunityLineItemId,
                                            Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c
                                            FROM QuoteLineItem WHERE QuoteId=:curQuote.id];
        
        system.debug(curQuote);
        system.debug(oppLineItems);
        system.debug(quoLineItems);
        
        JSONGenerator jsonToSend = JSON.createGenerator(true);
		jsonToSend.writeStartObject();
        system.debug(curQuote.id);
        jsonToSend.writeObjectField('QuoteId',curQuote.id);
        system.debug(curQuote.QuoteNumber);
        jsonToSend.writeObjectField('QuoteNumber',curQuote.QuoteNumber);
        jsonToSend.writeObjectField('ExpirationDate',curQuote.ExpirationDate);
        jsonToSend.writeObjectField('Probability',curQuote.Opportunity.Probability);
        jsonToSend.writeFieldName('QuoteLineItems');
        jsonToSend.writeStartArray();
        
        for(QuoteLineItem quoteItem: quoLineItems){
           jsonToSend.writeStartObject();
            if(quoteItem.ID_ERP__c != null){
                jsonToSend.writeObjectField('ID_ERP__c',quoteItem.ID_ERP__c);
            }else {
                jsonToSend.writeObjectField('ID_ERP__c',searchERP(quoteItem,oppLineItems));
            }
            // system.debug(searchITE(quoteItem,oppLineItems));
            if(quoteItem.OpportunityLineItemITENumber__c != null){
                jsonToSend.writeObjectField('OpportunityLineItemITENumber__c', quoteItem.OpportunityLineItemITENumber__c); 
            }else{
                jsonToSend.writeObjectField('OpportunityLineItemITENumber__c',searchITE(quoteItem,oppLineItems)); 
            }
           jsonToSend.writeObjectField('LastModifiedDate',quoteItem.LastModifiedDate);
           jsonToSend.writeObjectField('InquiryUnit__c',quoteItem.InquiryUnit__c);
           jsonToSend.writeObjectField('Quantity',quoteItem.Quantity==null?0:quoteItem.Quantity); 
           jsonToSend.writeObjectField('InquiryQuantity__c',quoteItem.InquiryQuantity__c==null?0:quoteItem.InquiryQuantity__c); 
           jsonToSend.writeObjectField('UnitPrice',quoteItem.UnitPrice==null?0:quoteItem.UnitPrice); 
           jsonToSend.writeObjectField('InquiryUnitPrice__c',quoteItem.InquiryUnitPrice__c==null?0:quoteItem.InquiryUnitPrice__c);
                                   
			jsonToSend.writeEndObject();           
        }
        
        jsonToSend.writeEndArray();       
        jsonToSend.writeEndObject();
        
        JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();
        
        //---------callout
        callout(jsonWrapper.getAsString());
       
       //---------callout
       //
        system.debug(jsonToSend.getAsString());
        system.debug(jsonToSend);
        
    }
    
    public static String searchERP(QuoteLineItem qlt, List<OpportunityLineItem> oppItems){
        String erp = '';
        for(OpportunityLineItem o: oppItems){
            if(qlt.OpportunityLineItemid == o.id){
                erp = o.ID_ERP__c;
            }
        }
        
        if(erp==null){
            erp = 'null';
        }
        
        return erp;
    }
    
    public static String searchITE(QuoteLineItem qlt, List<OpportunityLineItem> oppItems){
        String ite = '';
        for(OpportunityLineItem o: oppItems){
            if(qlt.OpportunityLineItemid == o.id){
                ite = o.ITENumber__c;
            }
        }       
        if(ite==null){
            ite = 'null';
        }
        
        return ite;
    }
        
    public static void updatedQuoteItemJSON(List<Id> tst){
        List<QuoteLineItem> quoLineItems = [SELECT QuoteId, Name__c, ID_ERP__c, OpportunityLineItemITENumber__c,InquiryUnit__c,Quantity,InquiryQuantity__c,UnitPrice,InquiryUnitPrice__c,LastModifiedDate,Product2Id,
                                            Quantity_ft__c,Quantity_lb__c,Quantity_m__c,Quantity_pcs__c,Sales_Price_ft__c,Sales_Price_lb__c,Sales_Price_m__c,Sales_Price_pcs__c,OpportunityLineItemid
                                            FROM QuoteLineItem WHERE Id=:tst];
        Quote curQuote = [SELECT Id,QuoteNumber,OpportunityId,Opportunity.Probability, ExpirationDate  FROM Quote WHERE ID=:quoLineItems[0].QuoteId LIMIT 1];
        List<OpportunityLineItem> oppLineItems = [SELECT ID_ERP__c,Name__c,ITENumber__c,Product2Id,id 
                                                  FROM OpportunityLineItem WHERE OpportunityId=:curQuote.OpportunityId];
        generateAndSendJSON(curQuote, quoLineItems,oppLineItems);
       
    }    
    
    @future(callout = true)
	 public static void callout(string jsonString){    
     makeCallout(jsonString);
}   
    
    public static String generateAndSendJSON(Quote curQuote, List<QuoteLineItem> quoLineItems,List<OpportunityLineItem> oppLineItems){
         JSONGenerator jsonToSend = JSON.createGenerator(true);
		jsonToSend.writeStartObject();
        jsonToSend.writeObjectField('QuoteId',curQuote.id);
        jsonToSend.writeObjectField('QuoteNumber',curQuote.QuoteNumber);
        // jsonToSend.writeObjectField('ExpirationDate',curQuote.ExpirationDate);
        jsonToSend.writeObjectField('Probability',curQuote.Opportunity.Probability);
        jsonToSend.writeFieldName('QuoteLineItems');
        jsonToSend.writeStartArray();
        
        for(QuoteLineItem quoteItem: quoLineItems){
           jsonToSend.writeStartObject();
           
                if(quoteItem.ID_ERP__c != null){
                    jsonToSend.writeObjectField('ID_ERP__c',quoteItem.ID_ERP__c);
                }else {
                    jsonToSend.writeObjectField('ID_ERP__c',searchERP(quoteItem,oppLineItems));
                }
                if(quoteItem.OpportunityLineItemITENumber__c != null){
                    jsonToSend.writeObjectField('OpportunityLineItemITENumber__c', quoteItem.OpportunityLineItemITENumber__c); 
                }else{
                    jsonToSend.writeObjectField('OpportunityLineItemITENumber__c',searchITE(quoteItem,oppLineItems)); 
                }
               jsonToSend.writeObjectField('LastModifiedDate',quoteItem.LastModifiedDate);
               jsonToSend.writeObjectField('InquiryUnit__c',quoteItem.InquiryUnit__c);
               jsonToSend.writeObjectField('Quantity',quoteItem.Quantity==null?0:quoteItem.Quantity); 
               jsonToSend.writeObjectField('InquiryQuantity__c',quoteItem.InquiryQuantity__c==null?0:quoteItem.InquiryQuantity__c.setScale(2)); 
               jsonToSend.writeObjectField('UnitPrice',quoteItem.UnitPrice==null?0:quoteItem.UnitPrice); 
               jsonToSend.writeObjectField('InquiryUnitPrice__c',quoteItem.InquiryUnitPrice__c==null?0:quoteItem.InquiryUnitPrice__c);                                 
		   jsonToSend.writeEndObject();           
        }
        
        jsonToSend.writeEndArray();       
        jsonToSend.writeEndObject();
        
         JSONGenerator jsonWrapper = JSON.createGenerator(true);
		jsonWrapper.writeStartObject();
		jsonWrapper.writeStringField('JSON', jsonToSend.getAsString());
		jsonWrapper.writeEndObject();
        
        String reqText = '{JSON:\''+jsonToSend.getAsString()+'\'}';
        //---------callout
        callout(string.valueof(reqText));
       
       //---------callout
       //
        system.debug(string.valueof(reqText));
        system.debug(reqText);
       	system.debug(jsonWrapper);
        
        return jsonToSend.getAsString();
    }
    
    private static void sendEmail(String comment) {
        String toAddr = System.Label.email_name_for_send_error;
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { toAddr };
        message.optOutPolicy = 'FILTER';
        message.subject = 'JSON Quote Error';
        message.plainTextBody = comment;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
	}
   
     public static String makeCallout(string jsonString){
         SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String login = Credentials__c.getOrgDefaults().User_Login__c;
		String password = Credentials__c.getOrgDefaults().User_Password__c;
		String response = ERPhandler.LoginEx(login, password);
        ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);

		String calc = '_SF_UPDATEQUOTAS';
		String ticket = requestObject.Ticket;
		String arg = jsonString;
		ERPRequestParser.ExecuteResponceQuote idResponse = null;
        try{
			String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
			system.debug(arg);
            system.debug(arg.remove('\\'));
            system.debug(json.serializePretty(arg));
            System.debug('JSON before deserialization - ' + erpResult);
			String processed = erpResult.remove('\\');
			idResponse = (ERPRequestParser.ExecuteResponceQuote) JSON.deserialize(processed, ERPRequestParser.ExecuteResponceQuote.class);
            System.debug(processed);
            System.debug(idResponse.Success);
            if(idResponse.Success == 'true'){
                system.debug('Success');                
            } else {
                sendEmail(idResponse.Comments);
                system.debug('error');
            }
                                                     
            return processed;
        } catch(CalloutException callfail) {
			String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (callout exception)', arg, errorMessage, wrapper.oppo.Id);	
			system.debug(errorMessage);	
            sendEmail('Call invalid for json quote item');
			AuraHandledException e = new AuraHandledException('Call invalid for json quote item');
        e.setMessage('Call invalid for json quote item');
        system.debug(e);
        throw e;
		} catch(System.JSONException jsfailed) {
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
            system.debug(errorMessage);
            sendEmail('JSONException. ' + errorMessage);
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (serialization exception)', arg, errorMessage, wrapper.oppo.Id);			
			throw new AuraHandledException(Label.InvalidJSONReceived);
        } catch(Exception e){
            system.debug(e.getMessage());
            AuraHandledException e1 = new AuraHandledException(e.getMessage());
        	e1.setMessage(e1.getMessage());
        	system.debug(e1);
            throw e1;
        }
    }
                 
}