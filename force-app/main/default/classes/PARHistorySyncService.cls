public with sharing class PARHistorySyncService {

    public static void syncHistory(
        Id parId,
        List<ERPMessageParser.PARApprovalHistory> erpHistory
    ) {

        if (parId == null || erpHistory == null || erpHistory.isEmpty()) {
            return;
        }

        List<PARApprovalHistory__c> recordsToUpsert =
            new List<PARApprovalHistory__c>();

        for (ERPMessageParser.PARApprovalHistory hist : erpHistory) {

            String historyHash = buildHistoryHash(parId, hist);

            PARApprovalHistory__c rec =
                new PARApprovalHistory__c();

            rec.HistoryHash__c = historyHash;
            rec.PriceApprovalRequestId__c = parId;
            rec.StageBefore__c = hist.stageBefore != null ? hist.stageBefore.id : null;
            rec.StageAfter__c  = hist.stageAfter  != null ? hist.stageAfter.id  : null;
            rec.ApprovalDate__c = hist.approvalDate;
            rec.ApproverName__c =
                hist.approver != null ? hist.approver.name : null;
            rec.Comment__c = hist.comment;

            recordsToUpsert.add(rec);
        }

        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert HistoryHash__c;
        }
    }

    private static String buildHistoryHash(
        Id parId,
        ERPMessageParser.PARApprovalHistory hist
    ) {

        List<String> keyParts = new List<String>{
            String.valueOf(parId),
            hist.approvalDate != null
                ? String.valueOf(hist.approvalDate.getTime())
                : '',
            hist.stageBefore != null ? hist.stageBefore.id : '',
            hist.stageAfter  != null ? hist.stageAfter.id  : '',
            hist.approver    != null ? hist.approver.userId : ''
        };

        return SysUtils.buildERPHash(keyParts);
    }
}