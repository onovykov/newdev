/**
 * Created by volodymyr on 31.07.21.
 */

public with sharing class excelImportController {
    @AuraEnabled(cacheable=true)
    public static List<Excel_Import_Setting__mdt> getImportSettings() {
       return [SELECT Object_Name__c,Sheet_Columns__c,Sheet_Name__c , Required_Fields__c FROM Excel_Import_Setting__mdt];
        }
    // @AuraEnabled
    // public static string deleteExsistingRecords(String q){
    //         DeleteImportDataBatch deleteRecords = new DeleteImportDataBatch(q);
	// 		database.executeBatch(deleteRecords, 200);
    //         return 'Success';
    // }
    @AuraEnabled 
    public static String insertRecords(List<sObject> records) {        	
            ExcelImportBatch db = new ExcelImportBatch(records);
			database.executeBatch(db, 2000);

       		return 'Success';
    }
}