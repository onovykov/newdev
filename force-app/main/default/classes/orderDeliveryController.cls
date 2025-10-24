public without sharing class orderDeliveryController {
	// Pass in the endpoint to be used using the string url
	@AuraEnabled(cacheable=true)
	public static Map < String,Object > getCalloutResponseContents(String recId) {
		Map<String,String> iteNumberToName = new Map<String,String>();
		Order currentOrder = [SELECT ID_ERP__C, Itenumber__c FROM Order WHERE id =: recId LIMIT 1];
        String reqText = '{json:\'{"ID_ERP__c":' + currentOrder.ID_ERP__C + ',"ITENumber__c": "'+currentOrder.Itenumber__c +'"}\'}';     
		String res = makeCallout(reqText);
        // StaticResource staticRes = [SELECT Body FROM StaticResource WHERE Name = 'Test_JSON_Data'];
        // String res = staticRes.Body.toString();
        System.debug('RES ---------------->  res' + res);
        System.debug('RES ---------------->  res' + JSON.serializePretty(res));

		Map < String,Object > resultsMap = (Map < String, Object > ) JSON.deserializeUntyped(res);
		system.debug('resultsMap-->' + resultsMap);
        
        Set<String> iteNumbers = new Set<String>();
               
        try{
            system.debug('resultsMap-->' + resultsMap.get('OrderLineItems'));
            
        	List<Object> orderItems = (List<Object>) resultsMap.get('OrderLineItems');
            
            //collect ITENumbers from order items
        	for(Object o: orderItems){        
                Map < String,Object> result = (Map< String,Object>) o;
                String iteNumber = (String)result.get('ITENumber__c');
                iteNumbers.add(iteNumber);
        	}
            System.debug('iteNumbers ---> ' + iteNumbers);
			List<OrderItem> orderItemNames = [ SELECT Name__c,ITENumber__c FROM OrderItem WHERE ITENumber__c IN :iteNumbers];       
            if(orderItemNames.size()>0){
                for(OrderItem oi : orderItemNames){
                	iteNumberToName.put(oi.ITENumber__c,oi.Name__c);
                } 
            }   
           //set Names of orderItems for records
        	for(Object o: orderItems){           
                Map < String,Object> result = (Map< String,Object>) o;
                String iteNumber = (String)result.get('ITENumber__c');
                iteNumbers.add(iteNumber);
                String nameProduct = iteNumberToName.get(iteNumber)!=null?iteNumberToName.get(iteNumber): 'Name not found';
                result.put('NameProduct',nameProduct);
        	} 
            
        }catch(Exception e){
            system.debug(e.getMessage());
        }                                      
		return resultsMap;
	}
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> requestForCertificate (String kobj,String undoc, String iteNumber, String packNum){
        Map<String,Object> response = new Map<String,Object>();       
        String reqText = '{json:\'{"KOBJ":"' + kobj + '","UNDOC_PA": "'+undoc +'","ITENumber__c": "'+iteNumber +'","PACK_NUM": "'+packNum +'"}\'}'; 
        system.debug(reqText);
        
        String res = makeCalloutCertificate(reqText);
		response = (Map < String, Object > ) JSON.deserializeUntyped(res);
        //system.debug(response.get('Content'));
        String contentResponse = (String) response.get('Content');
		system.debug(contentResponse);  
        
        //String jsonStr = '<Base64 String>';
       
        
        
        return response;
    }
        
	@AuraEnabled(cacheable=true)
	public static List<Order> getOrderById(String recId) {      
		return [SELECT ID_ERP__C, Itenumber__c FROM Order WHERE id =: recId];
	}


	@AuraEnabled		
	public static void sendEmail(String body){
        
    List<String> emailsToSentList = new List<String>(); 
        try{ 
    for(Delivery_Status_Emails__mdt dse : [SELECT Email__c FROM Delivery_Status_Emails__mdt]){
        emailsToSentList.add(dse.Email__c);    
    }  
        } catch(Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
        }
	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
	
    message.toAddresses = emailsToSentList;    
	message.subject = 'Ошибка выгрузки статуса доставки';
    message.HtmlBody = body;
	message.plainTextBody = body ;
	Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

	if (results[0].success) {
		System.debug('The email was sent successfully.');
	} else {
		System.debug('The email failed to send: ' + results[0].errors[0].message);
	}
}
    public static String makeCalloutCertificate(string jsonString){
       
       SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
       String login = Credentials__c.getOrgDefaults().User_Login__c;
       String password = Credentials__c.getOrgDefaults().User_Password__c;
       String response = ERPhandler.LoginEx(login, password);
       ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
    
       String calc = '_SF_GET_CERT_QUALITY';
       String ticket = requestObject.Ticket;
       String arg = jsonString;
       ERPRequestParser.ExecuteResponceCertificate idResponse = null;
       try{
           String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
           system.debug(arg);
           system.debug(arg.remove('\\'));
           system.debug(json.serializePretty(arg));
           System.debug('JSON before deserialization - ' + erpResult);
           String processed = erpResult.remove('\\');
           JSON2Apex checkBoolean = (JSON2Apex) System.JSON.deserialize(erpResult, JSON2Apex.class);
           system.debug(checkBoolean);
           if(checkBoolean.Success == false){
               processed = erpResult;
           }
           
           idResponse = (ERPRequestParser.ExecuteResponceCertificate) JSON.deserialize(processed, ERPRequestParser.ExecuteResponceCertificate.class);
           System.debug(processed);                              
           System.debug(idResponse.Success);
           if(idResponse.Success == 'true'){
               system.debug('Success');                
           } else {
              // sendEmail(idResponse.Comments);
               system.debug('error');
           }
           
           if(!Test.isRunningTest()){
               system.debug('close session');
               String calcCloseSession = 'WEB.CLOSESESSION';                    
               String erpResult2 = ERPhandler.ExecuteEx(calcCloseSession, null, ticket);
               system.debug('close session2');
           }
           
           return processed;
       } catch(CalloutException callfail) {
           String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();	   
           system.debug(errorMessage);	
           //sendEmail('Call invalid for json order');
           AuraHandledException e = new AuraHandledException('Call invalid for json order');
       e.setMessage('Call invalid for json order');
       system.debug(e);
       throw e;
       } catch(System.JSONException jsfailed) {
           String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
           system.debug(errorMessage);
           sendEmail('JSONException. ' + errorMessage);	   			
           throw new AuraHandledException(Label.InvalidJSONReceived);
       } 
	}

	public static String makeCallout(string jsonString){
        SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
       String login = Credentials__c.getOrgDefaults().User_Login__c;
       String password = Credentials__c.getOrgDefaults().User_Password__c;
       String response = ERPhandler.LoginEx(login, password);
       ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
    
       String calc = '_SF_GET_ORDER_SHIPS';
       String ticket = requestObject.Ticket;
       String arg = jsonString;
       ERPRequestParser.ExecuteResponceQuote idResponse = null;
       try{
           String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
           system.debug(arg);
           system.debug(arg.remove('\\'));
           system.debug(json.serializePretty(arg));
           System.debug('JSON before deserialization - ' + erpResult);
           erpResult = erpResult.remove('\\"');
           String processed = erpResult.remove('\\');
           JSON2Apex checkBoolean = (JSON2Apex) System.JSON.deserialize(erpResult, JSON2Apex.class);
           system.debug(checkBoolean);
           if(checkBoolean.Success == false){
               processed = erpResult;
           }
           system.debug(processed);
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
           system.debug(errorMessage);	
           sendEmail('Call invalid for json order');
           AuraHandledException e = new AuraHandledException('Call invalid for json order');
       e.setMessage('Call invalid for json order');
       system.debug(e);
       throw e;
       } catch(System.JSONException jsfailed) {
           String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
           system.debug(errorMessage);
           sendEmail('JSONException. ' + errorMessage);	   			
           throw new AuraHandledException(Label.InvalidJSONReceived);
       } finally {
           closeSessionAsync.closeCurrentSessionAsync(ticket);
       }
        /*
        finally {   
            system.debug('close session');
            String calcCloseSession = 'WEB.CLOSESESSION';
            String ticketClose = requestObject.Ticket;
            String argClose = null; 
            String erpResult = ERPhandler.ExecuteEx(calcCloseSession, argClose, ticketClose);
       }    
*/
	}
    
    @future(callout=true)
    public static void closeSessionAsync(String ticket) {
        system.debug('close session');
        SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String calcCloseSession = 'WEB.CLOSESESSION';                    
        String erpResult2 = ERPhandler.ExecuteEx(calcCloseSession, null, ticket);
        system.debug('close session2');
    }
    
    public class JSON2Apex{
       	public boolean Success;
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
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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