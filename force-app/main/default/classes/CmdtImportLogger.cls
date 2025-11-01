/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//===  1. База (загальні утиліти CmdtDeploy, CmdtImportLogger тощо)
//     1.2. Логування помилок/попереджень
//      Тимчасово (на період перших проб і тестів) писатимемо логи до об'єкту CmdtImportLog__c
//      Струкрура:
//          Type__c (Text), RecordKey__c (Text), Message__c (Long Text), 
//          Details__c (Long Text), Level__c (Picklist: ERROR, WARN, INFO)
//      Надалі прикрутимо Pharos (навмисне структуру подібною тут зробив)
//----------------------------------------------------------------------------------
public with sharing class CmdtImportLogger {
    public static void log(String type, String key, String message, String level, Boolean toObj/*, Boolean toEvt*/){
        //if (toObj) {
            CmdtImportLog__c row = new CmdtImportLog__c(
                Type__c = type, RecordKey__c = key, Message__c = message, Level__c = level
            );
            try { insert row; } catch (Exception e) {}
        //}
        /*
        if (toEvt) {
            try {
                CmdtImportIssue__e evt = new CmdtImportIssue__e(
                    Type__c = type, RecordKey__c = key, Message__c = message, Level__c = level
                );
                Database.SaveResult r = EventBus.publish(evt);
            } catch (Exception e) {}
        }
        */
        System.debug((level=='ERROR'?LoggingLevel.ERROR:LoggingLevel.WARN), type+'['+key+']: '+message);
    }
}