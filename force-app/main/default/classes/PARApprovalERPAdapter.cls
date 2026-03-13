public with sharing class PARApprovalERPAdapter {

    public class ERPResponse {
        public Boolean Status;
        public String ErrorMessage;
        public PAMRequestInfo PAMRequestInfo;
        public SourceQuoteApprovalMessage SourceQuoteApprovalMessage;
    }

    public class PAMRequestInfo {
        public Integer Status;
        public String Stage;
        public String StageName;
    }

    public class SourceQuoteApprovalMessage {
        public Integer ID_ERP;
        public Integer Resolution;
        public StageInfo StageInfo;
        public Approver Approver_UserId;
        public String Comment;
    }

    public class StageInfo {
        public String Id;
        public String Name;
    }

    public class Approver {
        public String Id;
        public String Name;
        public String Email;
    }

    public static ERPResponse sendApproval(
        String erpId,
        String resolution,
        String comment
    ) {

        SFToERP.WebServiceSoap client =
            new SFToERP.WebServiceSoap();

        String payload = buildPayload(
            erpId,
            resolution,
            comment
        );

        String calcId = 'SF-ERP_ParApproval';

        String rawResponse =
            client.ExecuteEx(
                calcId,
                payload,
                null
            );

        return (ERPResponse)
            JSON.deserialize(rawResponse, ERPResponse.class);
    }

    private static String buildPayload(
        String erpId,
        String resolution,
        String comment
    ) {
        Map<String, Object> body = new Map<String, Object>{
            'ID_ERP' => erpId,
            'Resolution' => resolution,
            'Comment' => comment
        };

        return JSON.serialize(body);
    }
}