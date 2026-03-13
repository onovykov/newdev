public with sharing class PARApprovalOutboundService {

    public static void sendApproval(
        PriceApprovalRequest__c par,
        String resolution,
        String comment
    ) {

        par.ApprovalStatus__c = 'Processing';
        par.RetryCount__c = 0;
        par.LastErrorMessage__c = null;
        par.LastAttemptDate__c = null;
        par.CorrelationId__c = generateCorrelationId();

        update par;

        System.enqueueJob(
            new PARApprovalQueueable(par.Id, resolution, comment)
        );
    }

    private static String generateCorrelationId() {

        String raw =
            UserInfo.getOrganizationId() +
            UserInfo.getUserId() +
            String.valueOf(System.now().getTime()) +
            String.valueOf(Math.random());

        Blob hash = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(raw)
        );

        return EncodingUtil.convertToHex(hash);
    }
}