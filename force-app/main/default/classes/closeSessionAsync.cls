public class closeSessionAsync {
	
    @future(callout=true)
    public static void closeCurrentSessionAsync(String ticket) {
        system.debug('close session');
        SFToERP.WebServiceSoap ERPhandler = new SFToERP.WebServiceSoap();
        String calcCloseSession = 'WEB.CLOSESESSION';                    
        String erpResult2 = ERPhandler.ExecuteEx(calcCloseSession, null, ticket);
        system.debug('close session2');
    }
    
}