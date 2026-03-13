public with sharing class PARStageUpdateService {

    public static void applyERPStage(
        PriceApprovalRequest__c par,
        String erpStageCode
    ) {

        if (String.isBlank(erpStageCode)) {
            return;
        }

        PARStageMapping__mdt mapping =
            PARStageMapping__mdt.getInstance(erpStageCode);

        if (mapping == null) {
            throw new AuraHandledException(
                'No stage mapping found for ERP stage: ' + erpStageCode
            );
        }

        par.StageERP__c = erpStageCode;
        par.Stage__c = mapping.SFStage__c;
        par.StageName__c = mapping.SFStage__c;

        update par;
    }
}