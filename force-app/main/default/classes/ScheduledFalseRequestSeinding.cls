global class ScheduledFalseRequestSeinding implements Schedulable {
   global void execute(SchedulableContext SC) {
       for(False_Synchronization__c fs : [SELECT Method_name__c,Json_Text__c FROM False_Synchronization__c WHERE Resended__c=false]){
           sendToERP(fs.Json_Text__c,fs.Method_name__c,'False_Synchronization__c',fs.id);
       }
   }
    
    @Future(callout = true)
	private static void sendToERP(String jsonText, String methodName, String recordType, String recordId) {
		
		SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
				
		try {
			String login = Credentials__c.getOrgDefaults().User_Login__c;
			String password = Credentials__c.getOrgDefaults().User_Password__c;
			String response = ERPhandler.LoginEx(login, password);
			ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
			
			String calc = methodName;
			String ticket = requestObject.Ticket;
			String arg = jsonText;
			ERPRequestParser.ExecuteResponce_ApprovalResult idResponse = null;

			String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
			System.debug('JSON before deserialization - ' + erpResult);
			String processed = erpResult.remove('\\');
			System.debug('Processed after remove: ' + processed);
			//processed = processed.substring(1, processed.length() - 1);
			idResponse = (ERPRequestParser.ExecuteResponce_ApprovalResult) JSON.deserialize(processed, ERPRequestParser.ExecuteResponce_ApprovalResult.class);

			if (idResponse.Status == false) {			
			}else if(idResponse.Status == true){
				system.debug('Success');
				sendNotitficationForUser();
			}
           
		} catch(CalloutException callfail) {
			String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (callout exception)', arg, errorMessage, wrapper.oppo.Id);
			//throw new AuraHandledException(Label.SFtoERPConnectionFails);
			throw new erpException(errorMessage);
		} catch(System.JSONException jsfailed) {
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
			//ERPWebServiceHandler.insertErrorTask('SF to ERP (serialization exception)', arg, errorMessage, wrapper.oppo.Id);
			//throw new AuraHandledException(Label.InvalidJSONReceived);
			throw new erpException(errorMessage);
		} catch(Exception jsfailed){
			String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
			throw new erpException(errorMessage);
		}
	}
	public static void sendNotitficationForUser(){
        Set<String> userEmail = new Set<String>();
        //String orgUrl = Label.OrganizationURL;
        userEmail.add('sflog@m.interpipe.biz');
		userEmail.add('v.rybak@polytech.software');


        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>(userEmail);
        message.optOutPolicy = 'FILTER';
        message.subject = 'Sync Error';
        message.HtmlBody = 'The documet was synchronized with ERP';
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
    public class erpException extends Exception {}
}