public with sharing class PARStageSyncService {

    public static void syncStage(
        PriceApprovalRequest__c par,
        ERPMessageParser.PARStage stageInfo
    ) {

        if (stageInfo == null || String.isBlank(stageInfo.milestone)) {
            return;
        }

        String erpMilestone = stageInfo.milestone.trim();

        String sfStage =
            PARStageMappingProvider.resolveSfStage(erpMilestone);

        if (sfStage == null) {
            System.debug('PAR Stage Mapping not found for milestone: ' + erpMilestone);
            return;
        }

        par.Stage__c = sfStage;
    }
}