/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//===  1. База (загальні утиліти CmdtDeploy, CmdtImportLogger тощо)
//     1.3. Утиліти для читання наявних CMDT (для валідації/деактивації)
public with sharing class CmdtReadUtil {
    public static Set<String> existingDevNames_OD(){
        return new Map<String, Tube_OD__mdt>([SELECT DeveloperName FROM Tube_OD__mdt]).keySet();
    }
    public static Set<String> existingDevNames_WT(){
        return new Map<String, Tube_WT__mdt>([SELECT DeveloperName FROM Tube_WT__mdt]).keySet();
    }
    public static Set<String> existingDevNames_SCH(){
        return new Map<String, SCH_OD_WT__mdt>([SELECT DeveloperName FROM SCH_OD_WT__mdt]).keySet();
    }
    /*   
        Можна буде роширити, додавши будь-які інші потрібні CMDT 
        Наприклад - решту CMDT параметрів, ShipmentStatus, ShipmentTypes тощо
    */
}