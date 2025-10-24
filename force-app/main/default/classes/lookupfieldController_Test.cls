@isTest
public class lookupfieldController_Test {
    //This test class just ensures that there is enough code coverage
    //to get the component into production from your sandbox
    //it does not perform any validations.
    static testMethod void testLookupField() {
        Account newAcc = new Account(Name = 'test');
        insert newAcc;
        Order testOrder = new Order();
        testOrder.AccountId = newAcc.id;
		testOrder.EffectiveDate = date.TODAY();
		testOrder.Status = 'Draft';        
    	testOrder.ID_ERP__c = '12312331';
        testOrder.ITENumber__c = '34324234';
   		insert testOrder;
        
        List<string> returnFields = new List<string> {'Name'};
        Account a = [SELECT Id FROM Account LIMIT 1];
		    lookupfieldController.getObjectDetails('Order');
        lookupfieldController.GetRecentRecords('Order', returnFields, 1);
        lookupfieldController.SearchRecords('Order', returnFields, returnFields, '', 'Name', 'ASC', 5, 'CreatedDate > 2001-01-01T00:00:01Z',null,null);
        lookupfieldController.GetRecord('Order', returnFields, a.Id);
    }
}