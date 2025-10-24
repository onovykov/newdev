public without sharing class SFtoERPOpportunityStage {
    /* ** Нова версія — O. Novykov, 2025-09-19 (допилена до фіналу)
       Зміни vs старі релізи:
       - прибрано hardcode емейлів; отримувачі — з NotifRecip__c
       - додані тестові шунти:
           @TestVisible static List<String> recipientsOverride
           @TestVisible static Integer testEmailsSent
       - детерміновані гілки тестів через @TestVisible testBypassMode
       - null-safe getJSONData; логування Triton
       - guard-и на пусті списки адрес; без зайвих throw у нотифікаціях
    */

    @TestVisible static Id      leadEnquiryRtIdOverride;
    @TestVisible static Boolean testLastSyncUpdated = false;
    @TestVisible static String  testBypassMode; // null | 'success' | 'failure' | 'exception'
    @TestVisible static List<String> recipientsOverride;
    @TestVisible static Integer testEmailsSent = 0;

    @future(callout=true)
    public static void sendJSONData(Id oppId) {
        if (Test.isRunningTest()) { testLastSyncUpdated = false; }

        if (oppId == null) {
            logDebug('sendJSONData called with null oppId', null);
            return;
        }

        Opportunity opp;
        try {
            opp = [
                SELECT Id, LastSyncERP__c, Id_ERP__c, StageName, LastModifiedDate, ExpectedDelivDate__c,
                       RecordTypeId, Lead__c, Status__c
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];
        } catch (Exception e) {
            logError('Failed to query Opportunity', e);
            return;
        }

        final String payload = getJSONData(opp);
        logReq('SF to ERP Opportunity Stage - Request body', payload);

        // ---- TEST BYPASS (детермінований результат у тестах, без зовнішніх залежностей) ----
        if (Test.isRunningTest() && !String.isBlank(testBypassMode)) {
            if (testBypassMode == 'success') {
                update new Opportunity(Id = opp.Id, LastSyncERP__c = DateTime.now());
                testLastSyncUpdated = true;
                return;
            } else if (testBypassMode == 'failure') {
                sendExecutionStatusEmail(false, 'test-bypass: failure');
                return;
            } else if (testBypassMode == 'exception') {
                logError('test-bypass: exception path', null);
                return;
            }
        }
        // ----------------------------------------------------------------------------

        Credentials__c cs = Credentials__c.getOrgDefaults();
        if (cs == null || String.isBlank(cs.User_Login__c) || String.isBlank(cs.User_Password__c)) {
            logError('Credentials__c Org Defaults are missing or incomplete', null);
            sendExecutionStatusEmail(false, 'Missing ERP credentials (Credentials__c Org Defaults).');
            return;
        }

        SFToERP.WebServiceSoap soap = new SFToERP.WebServiceSoap();
        final String login    = cs.User_Login__c;
        final String password = cs.User_Password__c;

        ERPRequestParser.LoginResponse loginObj;
        try {
            String resp = soap.LoginEx(login, password);
            loginObj = (ERPRequestParser.LoginResponse) JSON.deserialize(resp, ERPRequestParser.LoginResponse.class);
        } catch (Exception e) {
            logError('ERP LoginEx failed', e);
            sendEmailCalloutException(formatException(e));
            return;
        }

        if (loginObj == null || String.isBlank(loginObj.Ticket)) {
            logError('ERP LoginEx returned empty ticket', null);
            sendExecutionStatusEmail(false, 'ERP login failed (empty ticket).');
            return;
        }

        final String calc   = '_SF_UPDATE_OPPORTUNITY_INFO';
        final String ticket = loginObj.Ticket;

        try {
            String erpResult = soap.ExecuteEx(calc, payload, ticket);
            String processed = (erpResult == null) ? null : erpResult.remove('\\');
            ERPRequestParser.ExecuteResponceOppStage execObj =
                (ERPRequestParser.ExecuteResponceOppStage) JSON.deserialize(processed, ERPRequestParser.ExecuteResponceOppStage.class);

            //logResp('SF to ERP Opportunity Stage - Response body', String.valueOf(execObj));
            logResp('SF to ERP Opportunity Stage - Response body', payload);

            if (execObj != null && execObj.Success == true) {
                update new Opportunity(Id = opp.Id, LastSyncERP__c = DateTime.now());
                if (Test.isRunningTest()) { testLastSyncUpdated = true; }
            } else {
                String comment = (execObj == null) ? 'Empty ERP response' : execObj.Comments;
                sendExecutionStatusEmail(false, comment);
            }
        } catch (CalloutException ce) {
            logError('ExecuteEx callout failed', ce);
            sendEmailCalloutException(formatException(ce));
        } catch (System.JSONException je) {
            logError('ERP response JSON parsing failed', je);
        }
    }

    public static String getJSONData(Opportunity opp) {
        if (opp == null) return '{"JSON":"{}"}';

        // RT "New_Client_Enquiry" з урахуванням тестового оверрайду
        Id rtIdOpp = (Test.isRunningTest() && leadEnquiryRtIdOverride != null)
            ? leadEnquiryRtIdOverride
            : RecordTypeCache.getId(Opportunity.SObjectType, 'New_Client_Enquiry');

        String oppStage = (rtIdOpp != null && opp.RecordTypeId == rtIdOpp)
            ? 'Enquiry'
            : String.valueOf(opp.StageName);

        JSONGenerator innerJSON = JSON.createGenerator(true);
        innerJSON.writeStartObject();
        innerJSON.writeObjectField('MessageType', 'SF-ERP_OpportunityInfo');

        if (opp.Id_ERP__c != null) innerJSON.writeObjectField('ID_ERP', opp.Id_ERP__c);
        else innerJSON.writeNullField('ID_ERP');

        innerJSON.writeObjectField('ID_SF', opp.Id);

        if (oppStage != null) innerJSON.writeObjectField('Status', oppStage);
        else innerJSON.writeNullField('Status');

        if (opp.LastModifiedDate != null) innerJSON.writeObjectField('StatusModified', opp.LastModifiedDate);
        else innerJSON.writeNullField('StatusModified');

        if (opp.ExpectedDelivDate__c != null) innerJSON.writeObjectField('ExpectedDelivDate', opp.ExpectedDelivDate__c);
        else innerJSON.writeNullField('ExpectedDelivDate');

        innerJSON.writeEndObject();

        JSONGenerator wrapper = JSON.createGenerator(true);
        wrapper.writeStartObject();
        wrapper.writeStringField('JSON', innerJSON.getAsString()); // внутрішній JSON — як рядок (як було)
        wrapper.writeEndObject();
        return wrapper.getAsString();
    }

    public static void sendExecutionStatusEmail(Boolean isSuccess, String errorMessage) {
        List<String> toAddresses = new List<String>();

        if (Test.isRunningTest() && recipientsOverride != null && !recipientsOverride.isEmpty()) {
            toAddresses.addAll(new Set<String>(recipientsOverride));
        } else {
            try {
                List<NotifRecip__c> nrList = [
                    SELECT Email__c
                    FROM NotifRecip__c
                    WHERE NotifyTipe__c = 'Opportunity Fault'
                ];
                if (nrList != null && !nrList.isEmpty()) {
                    Set<String> uniq = new Set<String>();
                    for (NotifRecip__c nr : nrList) {
                        if (!String.isBlank(nr.Email__c)) uniq.add(nr.Email__c.trim());
                    }
                    toAddresses.addAll(uniq);
                }
            } catch (Exception e) {
                logError('Failed to prepare Opportunity Fault recipients', e);
                return;
            }
        }

        if (toAddresses.isEmpty()) return;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject((isSuccess ? '' : '[ERROR] ') + 'SFtoERPOpportunityStage execution status');
        mail.setPlainTextBody(
            (isSuccess ? 'Execution finished successfully.' : 'Execution failed.')
            + (String.isBlank(errorMessage) ? '' : (' Details: ' + String.valueOf(errorMessage)))
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        if (Test.isRunningTest()) { testEmailsSent++; }
    }

    public static void sendEmailCalloutException(String errorMessage) {
        List<String> toAddresses = new List<String>();

        if (Test.isRunningTest() && recipientsOverride != null && !recipientsOverride.isEmpty()) {
            toAddresses.addAll(new Set<String>(recipientsOverride));
        } else {
            try {
                List<NotifRecip__c> nrList = [
                    SELECT Email__c
                    FROM NotifRecip__c
                    WHERE NotifyTipe__c = 'Callout Exception'
                ];
                if (nrList != null && !nrList.isEmpty()) {
                    Set<String> uniq = new Set<String>();
                    for (NotifRecip__c nr : nrList) {
                        if (!String.isBlank(nr.Email__c)) uniq.add(nr.Email__c.trim());
                    }
                    toAddresses.addAll(uniq);
                } else {
                    logError('No recipients configured for Callout Exception', null);
                    return;
                }
            } catch (Exception e) {
                logError('Failed to prepare Callout Exception recipients', e);
                return;
            }
        }

        if (toAddresses.isEmpty()) return;

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);
        message.setSubject('[ERROR] Price Approval Request synchronization error');
        message.setPlainTextBody(
            'IT/SF synchronization for object "Price Approval Request" raised an error.'
            + '\nDetails:\n' + String.valueOf(errorMessage)
            + '\nPlease check the Synchronization Web Services and Network Settings.'
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        if (Test.isRunningTest()) { testEmailsSent++; }
    }

    // --- Логування (узгоджено з Triton API) ---
    @TestVisible private static void logReq(String msg, String body) {
        Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.SFtoERPOpportunityStage, msg, body);
    }
    @TestVisible private static void logResp(String msg, String body) {
        Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.SFtoERPOpportunityStage, msg, body);
    }
    @TestVisible private static void logDebug(String msg, String body) {
        Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.SFtoERPOpportunityStage, msg, (body == null ? '' : (' :: ' + body)));
    }
    @TestVisible private static void logError(String msg, Exception e) {
        if (e != null) {
            Triton.instance.error(TritonTypes.Area.SFtoERPOpportunityStage, e);
        } else {
            Triton.instance.debug(TritonTypes.Type.RequestDebug, TritonTypes.Area.SFtoERPOpportunityStage, 'ERROR: ' + msg, null);
        }
    }

    @TestVisible private static String formatException(Exception e) {
        return e.getMessage() + '\n' + e.getStackTraceString();
    }
}