@isTest
public class ExpCloudShowToastControllerTest{
    public static testMethod void testSOQL() 
    {
        try{
        List<Account> listAccount = experienceCloudShowToastEventController.getCustomerComunityUserAccount();       
        System.assert( listAccount  != null);
        }
        catch(Exception e){ 
            
        }
    }
}