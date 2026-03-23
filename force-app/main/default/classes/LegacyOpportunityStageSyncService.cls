/*
    Legacy Service
    Тут живе стара SOAP / JSON / Triton / email логіка, але вже без @future.
    Тут навмино використовується старий SFtoERPOpportunityStage як helper-компонент для payload, логування і email,
    щоб зараз не ламати старий обмін.
    У старому класі вже є придатні для цього методи:
    - getJSONData
    - sendExecutionStatusEmail
    - sendEmailCalloutException
    - formatException.
    Коли буде перехід на новий Integration Framework - це відкоригуємо
    Наразі най так буде
*/
public without sharing class LegacyOpportunityStageSyncService {
    public class SyncResult {
        public Id opportunityId;
        public Boolean success;
        public String message;

        public SyncResult(Id opportunityId, Boolean success, String message) {
            this.opportunityId = opportunityId;
            this.success = success;
            this.message = message;
        }
    }

    public static SyncResult send(Opportunity opp) {
        if (opp == null || opp.Id == null) {
            return new SyncResult(null, false, 'Opportunity is null');
        }

        try {
            String payload = SFtoERPOpportunityStage.getJSONData(opp);

            // Запит
            Triton.instance.debug(
                TritonTypes.Type.RequestDebug,
                TritonTypes.Area.SFtoERPOpportunityStage,
                'SF to ERP Opportunity Stage - Request body',
                payload
            );

            Credentials__c cs = Credentials__c.getOrgDefaults();
            if (cs == null || String.isBlank(cs.User_Login__c) || String.isBlank(cs.User_Password__c)) {
                Triton.instance.debug(
                    TritonTypes.Type.RequestDebug,
                    TritonTypes.Area.SFtoERPOpportunityStage,
                    'ERROR: Credentials__c Org Defaults are missing or incomplete',
                    null
                );
                SFtoERPOpportunityStage.sendExecutionStatusEmail(
                    false,
                    'Missing ERP credentials (Credentials__c Org Defaults).'
                );
                return new SyncResult(opp.Id, false, 'Missing ERP credentials');
            }

            SFToERP.WebServiceSoap soap = new SFToERP.WebServiceSoap();

            String loginResp;
            ERPRequestParser.LoginResponse loginObj;
            try {
                loginResp = soap.LoginEx(cs.User_Login__c, cs.User_Password__c);
                loginObj = (ERPRequestParser.LoginResponse)JSON.deserialize(
                    loginResp,
                    ERPRequestParser.LoginResponse.class
                );
            } catch (Exception e) {
                ErrorService.handle('ERR_INT_OPPSTAGE_SYNC', null, e);
                SFtoERPOpportunityStage.sendEmailCalloutException(
                    e.getMessage() + '\n' + e.getStackTraceString()
                );
                return new SyncResult(opp.Id, false, 'ERP LoginEx failed: ' + e.getMessage());
            }

            if (loginObj == null || String.isBlank(loginObj.Ticket)) {
                Triton.instance.debug(
                    TritonTypes.Type.RequestDebug,
                    TritonTypes.Area.SFtoERPOpportunityStage,
                    'ERROR: ERP LoginEx returned empty ticket',
                    null
                );
                SFtoERPOpportunityStage.sendExecutionStatusEmail(
                    false,
                    'ERP login failed (empty ticket).'
                );
                return new SyncResult(opp.Id, false, 'ERP login failed (empty ticket)');
            }

            String calc = '_SF_UPDATE_OPPORTUNITY_INFO';
            String erpResult;
            try {
                erpResult = soap.ExecuteEx(calc, payload, loginObj.Ticket);
            } catch (CalloutException ce) {
                ErrorService.handle('ERR_INT_OPPSTAGE_SYNC', null, ce);
                SFtoERPOpportunityStage.sendEmailCalloutException(
                    ce.getMessage() + '\n' + ce.getStackTraceString()
                );
                return new SyncResult(opp.Id, false, 'ExecuteEx callout failed: ' + ce.getMessage());
            }

            String processed = (erpResult == null) ? null : erpResult.remove('\\');

            ERPRequestParser.ExecuteResponceOppStage execObj;
            try {
                execObj = (ERPRequestParser.ExecuteResponceOppStage)JSON.deserialize(
                    processed,
                    ERPRequestParser.ExecuteResponceOppStage.class
                );
            } catch (System.JSONException je) {
                ErrorService.handle('ERR_INT_OPPSTAGE_SYNC', null, je);
                return new SyncResult(opp.Id, false, 'ERP response JSON parsing failed: ' + je.getMessage());
            }

            // Відповідь
            Triton.instance.debug(
                TritonTypes.Type.RequestDebug,
                TritonTypes.Area.SFtoERPOpportunityStage,
                'SF to ERP Opportunity Stage - Response body',
                processed
            );

            if (execObj != null && execObj.Success == true) {
                return new SyncResult(opp.Id, true, null);
            }

            String comment = (execObj == null) ? 'Empty ERP response' : execObj.Comments;
            SFtoERPOpportunityStage.sendExecutionStatusEmail(false, comment);
            return new SyncResult(opp.Id, false, comment);

        } catch (Exception e) {
            ErrorService.handle('ERR_INT_OPPSTAGE_SYNC', null, e);
            SFtoERPOpportunityStage.sendEmailCalloutException(
                e.getMessage() + '\n' + e.getStackTraceString()
            );
            return new SyncResult(opp.Id, false, e.getMessage());
        }
    }
}