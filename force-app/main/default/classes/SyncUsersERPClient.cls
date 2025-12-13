public with sharing class SyncUsersERPClient {

    public static List<String> getLoginsToDeactivate(String jsonPayload) {
        List<String> result = new List<String>();

        SFToERP.WebServiceSoap erp = new SFToERP.WebServiceSoap();

        String login;
        String password;

        // --- читаємо креденшали --------------------------------------------
        try {
            Credentials__c creds = Credentials__c.getOrgDefaults();
            login    = creds.User_Login__c;
            password = creds.User_Password__c;
        } catch (Exception e) {
            System.debug('SyncUsersERPClient: Error reading credentials: ' + e.getMessage());
            return result;
        }

        // --- LoginEx --------------------------------------------------------
        String loginResponse;
        try {
            loginResponse = erp.LoginEx(login, password);
        } catch (Exception e) {
            System.debug('SyncUsersERPClient: LoginEx callout error: ' + e.getMessage());
            return result;
        }

        ERPRequestParser.LoginResponse loginObj;
        try {
            loginObj = (ERPRequestParser.LoginResponse)
                JSON.deserialize(loginResponse, ERPRequestParser.LoginResponse.class);
        } catch (Exception e) {
            System.debug('SyncUsersERPClient: Cannot deserialize LoginResponse: ' + e.getMessage());
            return result;
        }

        if (loginObj == null || String.isBlank(loginObj.Ticket)) {
            System.debug('SyncUsersERPClient: LoginResponse has no ticket, aborting');
            return result;
        }

        String calc   = '_SF_CHECK_DISMISSAL_USERS';
        String ticket = loginObj.Ticket;

        // --- ExecuteEx ------------------------------------------------------
        String erpResultRaw;
        try {
            erpResultRaw = erp.ExecuteEx(calc, jsonPayload, ticket);
            System.debug('SyncUsersERPClient: RAW ERP RESULT = ' + erpResultRaw);
        } catch (Exception e) {
            System.debug('SyncUsersERPClient: ExecuteEx callout error: ' + e.getMessage());
            return result;
        }

        if (String.isBlank(erpResultRaw)) {
            System.debug('SyncUsersERPClient: Empty ERP response from ExecuteEx');
            return result;
        }

        // --- парсимо JSON з ERP --------------------------------------------
        try {
            List<ERPRequestParser.SyncUsers> syncUsersList =
                (List<ERPRequestParser.SyncUsers>) JSON.deserialize(
                    erpResultRaw,
                    List<ERPRequestParser.SyncUsers>.class
                );

            if (syncUsersList != null) {
                for (ERPRequestParser.SyncUsers su : syncUsersList) {
                    if (su != null && String.isNotBlank(su.USERID)) {
                        result.add(su.USERID);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('SyncUsersERPClient: Cannot deserialize ERP ExecuteEx result: ' + e.getMessage());
            return result;
        }

        System.debug('SyncUsersERPClient: ERP returned logins to deactivate = ' + result);
        return result;
    }
}