@isTest
public class AccountsBatchTest extends BaseTest {
	
     @testSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        
        // insert accounts
        for (Integer i=0;i<1000;i++) {
            
            Account newAcc = new Account();
            newAcc.Name = 'Account'+i;
            newAcc.ID_ERP__c = 'test'+i;
            if(i==100 || i==200 || i==300 || i==400 || i==500 || i==600 || i==700 || i==800 || i==900){
                newAcc.DealingStatus__c = '10';
            }else{
                newAcc.DealingStatus__c = '0';
            }
            
           accounts.add(newAcc);
        }
        insert accounts;
            
    }
    
    @isTest static void AccountsReceivableUpdateTest() {
                        
       String jsonbody = getJSONBody(200);
        system.debug(jsonbody);
       System.assertEquals(9, [select id from account where DealingStatus__c = '10'].size()); 
        t.start();       
               AccountsReceivableUpdate aru = new AccountsReceivableUpdate(jsonbody);
               Id aruId = Database.executeBatch(aru);
        t.stop();
        
        System.assertEquals(200, [select id from account where DealingStatus__c = '10'].size());
        
    }
    
     @isTest static void AccountsReceivableUpdateWithBlockedTest() {
        
       Integer toBeBlockedAccs = 5; 
       Integer accsToUpdate = 200;  
       String jsonbody = getJSONBodyWithBlocked(accsToUpdate,toBeBlockedAccs);
        system.debug(jsonbody);
        t.start();       
               AccountsReceivableUpdate aru = new AccountsReceivableUpdate(jsonbody);
               Id aruId = Database.executeBatch(aru);
        t.stop();
       
        integer expectedblockedAccs = accsToUpdate - toBeBlockedAccs;
        System.assertEquals(toBeBlockedAccs, [select id from account where DealingStatus__c = '40'].size());
        System.assertEquals(expectedblockedAccs, [select id from account where DealingStatus__c = '10'].size()); 
       
    }
    
    public static String getJSONBody(integer quantity){
        String jsonbody = '{"MessageType": "ERP-SF_AccountsReceivable",' +
         '"metadata":{' +
            '"msgType":"asdfsadfffffaa",' +
            '"msgTypeVersion":2.3,'+
            '"msgTimestamp":"1995-12-17T03:24:00",'+
            '"partNumber":"1",'+
            '"totalParts":"1"'+
            '},'+
            '"data": {'+
            '"items": [';
            for(Integer i = 0;i<quantity;i++){
            jsonbody +=  '{'+
            '"Account": {'+
            ' "Name": "Abb",'+
                ' "Id": "test' +i+'"},'+
            ' "Status": 10,'+
            '"Balance": 3330,'+
            '"PastDueDebt": 2.3,'+
            '"PastDueDebt15More": 2.3,'+
            '"GroupName": "",'+
            '"GroupPastDueDebt": "0.00",'+
            '"GroupPastDueDebt15More": "0.00",'+
            '"DueDate": null,'+
            '"Receipts": "2584282.85",'+
            '"ToBlock": false,'+
            '"PermissionDate": null,'+
            '"Approver": {'+
            '"Name": "",'+
            '"UserId": "",'+
            '"Email": "",'+
            '"Id": ""'+
            '},'+
            '"PermittedProductionAmount": "0.00",'+
            '"PermittedShipmentAmount": "0.00",'+
            '"PermissionComment": ""';
                if(i ==quantity-1){
                   jsonbody += '}';
                } else{
                    jsonbody += '},';
                }
        }
           jsonbody += ']}}';
        
        return jsonbody;
    }
    
    public static String getJSONBodyWithBlocked(integer quantity,integer blockedQuantity){
        Integer forBlockedAccounts = 0;
        String jsonbody = '{"MessageType": "ERP-SF_AccountsReceivable",' +
         '"metadata":{' +
            '"msgType":"asdfsadfffffaa",' +
            '"msgTypeVersion":2.3,'+
            '"msgTimestamp":"1995-12-17T03:24:00",'+
            '"partNumber":"1",'+
            '"totalParts":"1"'+
            '},'+
            '"data": {'+
            '"items": [';
            for(Integer i = 0;i<quantity;i++){
            jsonbody +=  '{'+
            '"Account": {'+
            ' "Name": "Abb",'+
                ' "Id": "test' +i+'"},'+
            ' "Status": 10,'+
            '"Balance": 3330,'+
            '"PastDueDebt": 2.3,'+
            '"PastDueDebt15More": 2.3,'+
            '"GroupName": "",'+
            '"GroupPastDueDebt": "0.00",'+
            '"GroupPastDueDebt15More": "0.00",'+
            '"DueDate": null,'+
            '"Receipts": "2584282.85",';
                if(forBlockedAccounts<blockedQuantity){
                    jsonbody += '"ToBlock": true,';
                    forBlockedAccounts++;
                } else {
                    jsonbody += '"ToBlock": false,';                    
                }            
            jsonbody += '"PermissionDate": null,'+
            '"Approver": {'+
            '"Name": "",'+
            '"UserId": "",'+
            '"Email": "",'+
            '"Id": ""'+
            '},'+
            '"PermittedProductionAmount": "0.00",'+
            '"PermittedShipmentAmount": "0.00",'+
            '"PermissionComment": ""';
                if(i ==quantity-1){
                   jsonbody += '}';
                } else{
                    jsonbody += '},';
                }
        }
           jsonbody += ']}}';
        
        return jsonbody;
    }
    
   static { BaseTest.t = new AccountsBatchTest(); }
   static BaseTest t { get { return BaseTest.t; } } 
}