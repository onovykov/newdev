public with sharing class SyncUsersService {

    /**
     * Викликається з Scheduler-а.
     * Читає CMDT SyncUserSettings__mdt, і якщо IsEnabled__c = true —
     * запускає SyncUsers.syncUsersToERP().
     */
    public static void runSync() {
        SyncUserSettings__mdt cfg = loadSettings();
        if (cfg == null) {
            System.debug('SyncUsersService.runSync: No CMDT settings found');
            return;
        }

        if (cfg.IsEnabled__c == false) {
            System.debug('SyncUsersService.runSync: Disabled via CMDT');
            return;
        }

        // Основний запуск інтеграції
        SyncUsers.syncUsersToERP();

        // ❗ Важливо:
        // CMDT — read-only. lastRun не оновлюємо.
        // Для health-check згодом можна зробити окремий Custom Object.
    }

    // ======================================================================
    // 🟦 ГОЛОВНИЙ БІЗНЕС-МЕТОД: ДЕАКТИВАЦІЯ ЮЗЕРІВ
    // ======================================================================
    public static void deactivateUsersByLogin(List<String> loginErpList) {
        if (loginErpList == null || loginErpList.isEmpty()) return;

        // 1) Витягуємо всіх користувачів
        List<User> users = [
            SELECT Id, Name, IsActive, User_Type__c, ManagerId,
                   AssignedBOS__c, AdditionalBOS__c, LoginERP__c
            FROM User
            WHERE LoginERP__c IN :loginErpList
        ];

        if (users.isEmpty()) {
            System.debug('SyncUsersService: No users found for ERP logins');
            return;
        }

        // Розділяємо Sales і Back Office
        List<User> salesManagers   = new List<User>();
        List<User> backOfficeUsers = new List<User>();

        for (User u : users) {
            if (u.User_Type__c == 'SALES MANAGERS') {
                salesManagers.add(u);
            } else if (u.User_Type__c == 'BACK OFFICE') {
                backOfficeUsers.add(u);
            }
        }

        // ======================================================================
        // 🟦 A. Менеджери → очищаємо ManagerId у їхніх беків
        // ======================================================================
        List<User> beksManagerFix = new List<User>();

        if (!salesManagers.isEmpty()) {
            Set<Id> managerIds = new Set<Id>();
            for (User m : salesManagers) managerIds.add(m.Id);

            List<User> beks = [
                SELECT Id, ManagerId
                FROM User
                WHERE ManagerId IN :managerIds
            ];

            for (User bek : beks) {
                bek.ManagerId = null;
                beksManagerFix.add(bek);
            }
        }

        // ======================================================================
        // 🟦 B. Back Office → чистимо поля в менеджерів + AccountBOS
        // ======================================================================
        Map<Id, User> managersBOSFixMap = new Map<Id, User>();
        List<AccountBOS__c> accountBosFix = new List<AccountBOS__c>();

        if (!backOfficeUsers.isEmpty()) {

            Set<Id> bekIds = new Set<Id>();
            for (User b : backOfficeUsers) bekIds.add(b.Id);

            // AssignedBOS__c
            List<User> managersAssigned = [
                SELECT Id, AssignedBOS__c
                FROM User
                WHERE AssignedBOS__c IN :bekIds
            ];
            for (User m : managersAssigned) {
                User mgr = managersBOSFixMap.containsKey(m.Id) ? managersBOSFixMap.get(m.Id) : m;
                mgr.AssignedBOS__c = null;
                managersBOSFixMap.put(mgr.Id, mgr);
            }

            // AdditionalBOS__c
            List<User> managersAdditional = [
                SELECT Id, AdditionalBOS__c
                FROM User
                WHERE AdditionalBOS__c IN :bekIds
            ];
            for (User m : managersAdditional) {
                User mgr = managersBOSFixMap.containsKey(m.Id) ? managersBOSFixMap.get(m.Id) : m;
                mgr.AdditionalBOS__c = null;
                managersBOSFixMap.put(mgr.Id, mgr);
            }

            // AccountBOS__c → IsActive__c = false
            List<AccountBOS__c> bosRecords = [
                SELECT Id, User__c, IsActive__c
                FROM AccountBOS__c
                WHERE User__c IN :bekIds
                  AND IsActive__c = true
            ];
            for (AccountBOS__c rec : bosRecords) {
                rec.IsActive__c = false;
                accountBosFix.add(rec);
            }
        }

        // ======================================================================
        // 🟦 C. Деактивуємо всіх юзерів
        // ======================================================================
        List<User> usersToUpdate = new List<User>();
        for (User u : users) {
            if (u.IsActive) {
                u.IsActive = false;
                usersToUpdate.add(u);
            }
        }

        // ======================================================================
        // 🟦 D. DML (bulk-safe)
        // ======================================================================
        if (!beksManagerFix.isEmpty()) {
            Database.update(beksManagerFix, false);
        }
        if (!managersBOSFixMap.isEmpty()) {
            Database.update(managersBOSFixMap.values(), false);
        }
        if (!accountBosFix.isEmpty()) {
            Database.update(accountBosFix, false);
        }
        if (!usersToUpdate.isEmpty()) {
            Database.update(usersToUpdate, false);
        }

        // ======================================================================
        // 🟦 E. Нотифікації
        // ======================================================================
        sendDeactivationNotifications(usersToUpdate);
    }

    // ======================================================================
    // 📧 EMAIL NOTIFICATIONS
    // ======================================================================
    private static void sendDeactivationNotifications(List<User> deactivated) {
        if (deactivated == null || deactivated.isEmpty()) return;

        SyncUserSettings__mdt st = loadSettings();
        if (st != null && st.AllowNotifications__c == false) {
            System.debug('SyncUsersService: Notifications disabled via CMDT');
            return;
        }

        List<String> adminEmails = getAdminEmails();
        if (adminEmails.isEmpty()) {
            System.debug('SyncUsersService: No AdminsForEmail members found');
            return;
        }

        String body = 'The following users have been deactivated in Salesforce:\n\n';
        for (User u : deactivated) {
            body += '- ' + u.Name + ' (LoginERP__c: ' + u.LoginERP__c + ')\n';
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(adminEmails);
        mail.setSubject('User Deactivation Notification (ERP Sync)');
        mail.setPlainTextBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('SyncUsersService: Email error: ' + e.getMessage());
        }
    }

    private static List<String> getAdminEmails() {
        List<User> admins = [
            SELECT Email
            FROM User
            WHERE Id IN (
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE Group.DeveloperName = 'AdminsForEmail'
            )
            AND Email != null
        ];

        List<String> emails = new List<String>();
        for (User u : admins) emails.add(u.Email);
        return emails;
    }

    // ======================================================================
    // CMDT loader
    // ======================================================================
    private static SyncUserSettings__mdt loadSettings() {
        List<SyncUserSettings__mdt> listSt = [
            SELECT DeveloperName, IsEnabled__c, AllowNotifications__c, ScheduleCron__c
            FROM SyncUserSettings__mdt
            WHERE DeveloperName = 'OrgDefaults'
            LIMIT 1
        ];
        return listSt.isEmpty() ? null : listSt[0];
    }
}