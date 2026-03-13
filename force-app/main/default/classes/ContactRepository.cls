public with sharing class ContactRepository {
    private static Map<Id, Contact> byId = new Map<Id, Contact>();
    private static Map<String, List<Contact>> byAccountType = new Map<String, List<Contact>>();
    private static Map<String, Contact> byEmail = new Map<String, Contact>();
    private static Map<String, List<Contact>> byType = new Map<String, List<Contact>>();

    public static Contact getById(Id contactId) {
        if (contactId == null) return null;
        if (!byId.containsKey(contactId)) {
            if (SettingsService.allowSoqlFallback()) {
                Contact c = [SELECT Id, AccountId, Email, HasOptedOutOfEmail, Type__c FROM Contact WHERE Id = :contactId LIMIT 1];
                put(c);
            } else { byId.put(contactId, null); }
        }
        return byId.get(contactId);
    }

    public static List<Contact> getByAccountAndType(Id accountId, String typeValue) {
        if (accountId == null || String.isBlank(typeValue)) return new List<Contact>();
        String key = keyAccType(accountId, typeValue);
        if (!byAccountType.containsKey(key)) {
            if (SettingsService.allowSoqlFallback()) {
                List<Contact> rows = [
                    SELECT Id, AccountId, Email, HasOptedOutOfEmail, Type__c
                    FROM Contact
                    WHERE AccountId = :accountId
                      AND Type__c = :typeValue
                      AND Email != null
                      AND (HasOptedOutOfEmail = false OR HasOptedOutOfEmail = null)
                ];
                prime(rows); byAccountType.put(key, rows);
            } else { byAccountType.put(key, new List<Contact>()); }
        }
        return byAccountType.get(key);
    }

    public static List<Contact> getByType(String typeValue) {
        System.debug('typeValue: ' + typeValue);
        if (String.isBlank(typeValue)) return new List<Contact>();
        String key = typeValue.trim();
        if (!byType.containsKey(key)) {
            if (SettingsService.allowSoqlFallback()) {
                System.debug('Before SOQL');
                List<Contact> rows = [
                    SELECT Id, AccountId, Email, HasOptedOutOfEmail, Type__c
                    FROM Contact
                    WHERE Type__c = :typeValue
                      AND Email != null
                      AND (HasOptedOutOfEmail = false OR HasOptedOutOfEmail = null)
                ];
                System.debug('rows: ' + rows);
                prime(rows); byType.put(key, rows);
            } else { byType.put(key, new List<Contact>()); }
        }
        return byType.get(key);
    }

    public static Contact getByEmail(String email) {
        if (String.isBlank(email)) return null;
        String key = email.trim().toLowerCase();
        if (!byEmail.containsKey(key)) {
            if (SettingsService.allowSoqlFallback()) {
                List<Contact> rows = [
                    SELECT Id, AccountId, Email, HasOptedOutOfEmail, Type__c
                    FROM Contact
                    WHERE Email = :email
                      AND (HasOptedOutOfEmail = false OR HasOptedOutOfEmail = null)
                    LIMIT 1
                ];
                if (!rows.isEmpty()) put(rows[0]); else byEmail.put(key, null);
            } else { byEmail.put(key, null); }
        }
        return byEmail.get(key);
    }

    public static void primeByAccountIds(Set<Id> accountIds, String typeValue) {
        if (accountIds == null || accountIds.isEmpty() || String.isBlank(typeValue)) return;
        if (!SettingsService.allowSoqlFallback()) return;
        List<Contact> rows = [
            SELECT Id, AccountId, Email, HasOptedOutOfEmail, Type__c
            FROM Contact
            WHERE AccountId IN :accountIds
              AND Type__c = :typeValue
              AND Email != null
              AND (HasOptedOutOfEmail = false OR HasOptedOutOfEmail = null)
        ];
        prime(rows);
        Map<Id, List<Contact>> perAcc = new Map<Id, List<Contact>>();
        for (Contact c : rows) {
            List<Contact> l = perAcc.get(c.AccountId); if (l==null) l=new List<Contact>(); l.add(c); perAcc.put(c.AccountId, l);
        }
        for (Id accId : accountIds) {
            String mapKey = keyAccType(accId, typeValue);
            byAccountType.put(mapKey, perAcc.containsKey(accId) ? perAcc.get(accId) : new List<Contact>());
        }
    }

    public static void put(Contact c) {
        if (c == null) return;
        byId.put(c.Id, c);
        if (!String.isBlank(c.Email)) byEmail.put(c.Email.trim().toLowerCase(), c);
        if (c.AccountId != null && String.valueOf(c.get('Type__c')) != null) {
            String key = keyAccType(c.AccountId, String.valueOf(c.get('Type__c')));
            List<Contact> bucket = byAccountType.get(key); if (bucket == null) bucket = new List<Contact>();
            Integer idx = -1; for (Integer i=0;i<bucket.size();i++) if (bucket[i].Id == c.Id) { idx=i; break; }
            if (idx>=0) bucket[idx]=c; else bucket.add(c); byAccountType.put(key, bucket);
        }
        if (String.valueOf(c.get('Type__c')) != null) {
            String typeKey = String.valueOf(c.get('Type__c')).trim();
            List<Contact> typeBucket = byType.get(typeKey); if (typeBucket == null) typeBucket = new List<Contact>();
            Integer typeIdx = -1; for (Integer i=0;i<typeBucket.size();i++) if (typeBucket[i].Id == c.Id) { typeIdx=i; break; }
            if (typeIdx>=0) typeBucket[typeIdx]=c; else typeBucket.add(c); byType.put(typeKey, typeBucket);
        }
    }

    public static void prime(List<Contact> contacts) { if (contacts == null) return; for (Contact c : contacts) put(c); }
    private static String keyAccType(Id accId, String typeVal) { return String.valueOf(accId) + '|' + typeVal.trim(); }
}