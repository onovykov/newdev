public class GetOrderSpecificationsController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> requestForOrderSpecList (String recId){
        Map<String, Object> response = new Map<String, Object>();
        Order currentOrder = [SELECT ID_ERP__C FROM Order WHERE id = :recId LIMIT 1];

        String reqText = '{"ID_ERP":' + currentOrder.ID_ERP__C +'}';
        
        String res = makeCalloutOrderSpecList(reqText, '_SF_GET_ORDER_SPEC_FILES_LIST');
		response = (Map <String, Object> ) JSON.deserializeUntyped(res);
		system.debug(response);  
        
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> requestForOrderSpec (String recId, String fieldId){
        Map<String, Object> response = new Map<String, Object>();
        Order currentOrder = [SELECT ID_ERP__C FROM Order WHERE id = :recId LIMIT 1];

        String reqText = '{"ID_ERP":' + currentOrder.ID_ERP__C  + ',"FileId": ' + fieldId +'}';
        
        String res = makeCalloutOrderSpecList(reqText, '_SF_GET_ORDER_SPEC_FILE_BASE64');
		response = (Map <String, Object> ) JSON.deserializeUntyped(res);
		system.debug(response);  
        
        return response;
    }

    public static String makeCalloutOrderSpecList(String jsonString, String calcString){
        SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String login = Credentials__c.getOrgDefaults().User_Login__c;
        String password = Credentials__c.getOrgDefaults().User_Password__c;
        String response = ERPhandler.LoginEx(login, password);
        ERPRequestParser.LoginResponse requestObject = (ERPRequestParser.LoginResponse) System.JSON.deserialize(response, ERPRequestParser.LoginResponse.class);
     
        String calc = calcString;
        String ticket = requestObject.Ticket;
        String arg = jsonString;
        ERPRequestParser.ExecuteResponceQuote idResponse = null;
        String processed;

        try{
            String erpResult = ERPhandler.ExecuteEx(calc, arg, ticket);
            System.debug('JSON before deserialization - ' + erpResult);
            processed = erpResult.remove('\\');
            JSON2Apex checkBoolean = (JSON2Apex) System.JSON.deserialize(erpResult, JSON2Apex.class);
            if(checkBoolean.Success == false){
                processed = erpResult;
            }
            
        } catch(CalloutException callfail) {
            String errorMessage = callfail.getMessage() + '\n' + callfail.getStackTraceString();	   
            system.debug(errorMessage);
        } catch(System.JSONException jsfailed) {
            String errorMessage = jsfailed.getMessage() + '\n' + jsfailed.getStackTraceString();
            system.debug(errorMessage);
        }

        return processed;
    }

    public class JSON2Apex{
        public boolean Success;
    }
}