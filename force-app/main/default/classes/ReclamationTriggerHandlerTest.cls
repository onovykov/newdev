@isTest
public class ReclamationTriggerHandlerTest extends BaseTest {

    @isTest static void deleteReclamationTest(){
       
        Reclamation__c newReclamation = new Reclamation__c();
        insert newReclamation;
         t.start();            
 		delete newReclamation;	
		t.stop();
                        
    }      
    static { BaseTest.t = new ReclamationTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}