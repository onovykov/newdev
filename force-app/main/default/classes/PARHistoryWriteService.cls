public with sharing class PARHistoryWriteService {

    public static void addFromERPResponse(
        Id parId,
        PARApprovalERPAdapter.ERPResponse response
    ) {

        if (response == null ||
            response.SourceQuoteApprovalMessage == null) {
            return;
        }

        PARApprovalHistory__c history =
            new PARApprovalHistory__c();

        history.PriceApprovalRequestId__c = parId;

        history.StageBefore__c =
            response.SourceQuoteApprovalMessage.StageInfo.Id;

        history.StageAfter__c =
            response.PAMRequestInfo.Stage;

        history.ApprovalDate__c = System.now();

        history.ApproverName__c =
            response.SourceQuoteApprovalMessage
                    .Approver_UserId.Name;

        history.Comment__c =
            response.SourceQuoteApprovalMessage.Comment;

        insert history;
    }
}