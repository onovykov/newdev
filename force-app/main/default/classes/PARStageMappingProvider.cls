/* Provider для PAR Stage Mapping */
public with sharing class PARStageMappingProvider {

    private static Map<String, String> stageMap;

    private static void load() {
        if (stageMap != null) return;

        stageMap = new Map<String, String>();

        for (PARStageMapping__mdt rec :
            [SELECT ERPStageCode__c, SFStage__c
             FROM PARStageMapping__mdt
             WHERE IsActive__c = true]) {

            stageMap.put(rec.ERPStageCode__c, rec.SFStage__c);
        }
    }

    public static String resolveSfStage(String erpStageCode) {
        load();
        return stageMap.get(erpStageCode);
    }
}