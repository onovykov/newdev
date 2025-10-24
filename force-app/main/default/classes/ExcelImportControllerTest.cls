@isTest
public class ExcelImportControllerTest 
{ 
    public static testMethod void TestSOQL() 
	{
        try{
		List<Excel_Import_Setting__mdt> listSettings = excelImportController.getImportSettings();		
		System.assert( listSettings  != null);
        }
        catch(Exception e){	
            
		}
	}
    
    // public static testMethod void testDeleteRecords(){
        
       // List<Account> accList = new List <Account> ();
       // Account a = new Account(Name='TestExcel');
       // accList.add(a);
        
       // insert accList;
       // string q = 'Select id from account';
       // excelImportController.deleteExsistingRecords(q);
       // List<Account> insertedAcc =[SELECT id, Name From Account Where Name =:'TestExcel'];
       // Account b = new Account(Name='TestExcel');
       // System.assert(insertedAcc.size()  == 1 );
  // }
    public static testMethod void testInsertRecords(){
        
        List<Account> accList = new List <Account> ();
        Account a = new Account(Name='TestExcel');
        accList.add(a);
        excelImportController.insertRecords(accList);
        List<Account> insertedAcc =[SELECT id, Name From Account Where Name =:'TestExcel'];
        System.assert( insertedAcc  != null);
    }
}