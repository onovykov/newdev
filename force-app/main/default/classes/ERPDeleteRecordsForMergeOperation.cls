public class ERPDeleteRecordsForMergeOperation {
    
    public static void checkAndDeleteRecords(ERPMessageParser.MessageMetadata parsedMetadata, String quotaObject, Date dateBegin, Date dateEnd) {
        String msgTimestampStr = parsedMetadata.msgTimestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        List<Current_Quotas_Transactions__c> currentTransactions = [SELECT Number_of_Parts_Processed__c 
                                                                   FROM Current_Quotas_Transactions__c 
                                                                   WHERE Transaction_Id__c = :msgTimestampStr LIMIT 1];

        if(parsedMetadata.totalParts == 1) {
            deleteRecords(msgTimestampStr, quotaObject, dateBegin, dateEnd);
        } else {
            if(currentTransactions.size() > 0) {
                Current_Quotas_Transactions__c currentTransaction = currentTransactions.get(0);
                if(currentTransaction.Number_of_Parts_Processed__c + 1 == parsedMetadata.totalParts) {
                    deleteRecords(msgTimestampStr, quotaObject, dateBegin, dateEnd);
                    delete currentTransaction;
                    if(!Test.isRunningTest()) {
                        ID jobID = System.enqueueJob(new RouteQuotesHierarchyQueueable(true));
                    }
                } else {
                    currentTransaction.Number_of_Parts_Processed__c += 1;
                    update currentTransaction;
                }
            } else {
                Current_Quotas_Transactions__c newCurrentTransaction = new Current_Quotas_Transactions__c();
                newCurrentTransaction.Transaction_Id__c = msgTimestampStr;
                newCurrentTransaction.Number_of_Parts_Processed__c = 1;
                newCurrentTransaction.Name = 'Transaction - ' + msgTimestampStr;
    
                insert newCurrentTransaction;
            }
        }
    }
    
    private static void deleteRecords(String msgTimestampStr, String quotaObject, Date dateBegin, Date dateEnd) {
        String query = 'SELECT Id, Transaction_Id__c FROM ' + quotaObject + ' WHERE Transaction_Id__c != \'' + msgTimestampStr + '\'';
        if(dateBegin != null) {
            String dateBeginStr = dateBegin.year() + '-' + String.valueOf(dateBegin.month()).leftPad(2, '0') + '-' + 
                                  String.valueOf(dateBegin.day()).leftPad(2, '0');
            String dateEndStr = dateEnd.year() + '-' + String.valueOf(dateEnd.month()).leftPad(2, '0') + '-' + 
                                String.valueOf(dateEnd.day()).leftPad(2, '0');
            query += ' AND DateBegin__c >= ' + dateBeginStr + ' AND DateEnd__c <= ' + dateEndStr;
        }
    
        List<sObject> sobjList = Database.query(query);
        delete sobjList;
    }
}