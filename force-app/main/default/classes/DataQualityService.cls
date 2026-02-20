public with sharing class DataQualityService {

    /* ==========================
       Public API
       ========================== */

    public static Boolean isInvalid(
        String objectNameParam,
        String fieldNameParam,
        SObject record
    ) {
        Mapping m = resolveMapping(objectNameParam, fieldNameParam);
        if (m == null) {
            return false; // unknown field → do not block
        }

        Object raw = record.get(m.fieldApiName);
        if (raw == null) {
            return false;
        }

        return isInvalidValue(
            m.objectApiName,
            m.fieldApiName,
            String.valueOf(raw)
        );
    }

    public static Boolean isInvalidValue(
        String objectApiName,
        String fieldApiName,
        String value
    ) {
        if (String.isBlank(value)) {
            return false;
        }

        String fieldType = getFieldType(objectApiName, fieldApiName);

        if (fieldType == 'Email') {
            return isInvalidEmail(value);
        }
        if (fieldType == 'Phone') {
            return isInvalidPhone(value);
        }
        if (fieldType == 'Url') {
            return isInvalidWebsite(value);
        }

        return false;
    }

    /* ==========================
       Email validation
       ========================== */
/*
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$',
        Pattern.CASE_INSENSITIVE
    );
*/
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        '(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$'
    );

    private static Boolean isInvalidEmail(String email) {
        if (String.isBlank(email)) return false;

        String e = email.trim();

        // exactly one @
        if (e.countMatches('@') != 1) return true;

        List<String> parts = e.split('@');
        if (parts.size() != 2) return true;

        String local = parts[0];
        String domain = parts[1];

        // basic sanity
        if (local.length() < 1) return true;
        if (domain.length() < 3) return true;

        // must contain dot in domain
        if (!domain.contains('.')) return true;

        // no spaces
        if (e.contains(' ')) return true;

        // TLD length
        String tld = domain.substringAfterLast('.');
        if (tld.length() < 2 || tld.length() > 24) return true;

        // only ASCII basic chars
        if (!Pattern.matches('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$', e)) {
            return true;
        }

        return false;
    }

    /* ==========================
       Phone / Mobile validation
       ========================== */

    private static Boolean isInvalidPhone(String phone) {
        String p = phone
            .replace('+','')
            .replace(' ','')
            .replace('-','')
            .replace('(','')
            .replace(')','')
            .replace('.','');

        if (!Pattern.matches('^[0-9]+$', p)) {
            return true;
        }

        return p.length() < 7 || p.length() > 20;
    }

    /* ==========================
       Website validation
       ========================== */

    private static Boolean isInvalidWebsite(String url) {
        String u = url.trim().toLowerCase();

        if (u.contains(' ')
            || u.contains('..')
            || !u.contains('.')
        ) {
            return true;
        }

        if (!u.startsWith('http://') && !u.startsWith('https://')) {
            u = 'https://' + u;
        }

        return !Pattern.matches(
            '^https?://[a-z0-9.-]+\\.[a-z]{2,}(/.*)?$',
            u
        );
    }

    /* ==========================
       CMDT resolution
       ========================== */

    private class Mapping {
        String objectApiName;
        String fieldApiName;
    }

    private static Map<String, Mapping> mappingCache;

    private static Mapping resolveMapping(
        String objectNameParam,
        String fieldNameParam
    ) {
        if (mappingCache == null) {
            mappingCache = new Map<String, Mapping>();

            for (InvalidPhoneEmail__mdt mdt :
                InvalidPhoneEmail__mdt.getAll().values()
            ) {
                Mapping m = new Mapping();
                m.objectApiName = mdt.ObjectAPI__c;
                m.fieldApiName  = mdt.FieldAPI__c;

                String key =
                    mdt.ObjectNameParam__c + '.' +
                    mdt.FieldNameParam__c;

                mappingCache.put(key.toLowerCase(), m);
            }
        }

        return mappingCache.get(
            (objectNameParam + '.' + fieldNameParam).toLowerCase()
        );
    }

    //--- Резет кеша
    public static void resetMappingCache() {
        mappingCache = null;
    }
    
    private static String getFieldType(
        String objectApi,
        String fieldApi
    ) {
        Schema.SObjectType t =
            Schema.getGlobalDescribe().get(objectApi);

        if (t == null) {
            return null;
        }

        Schema.DescribeFieldResult d =
            t.getDescribe()
             .fields.getMap()
             .get(fieldApi)
             .getDescribe();

        return String.valueOf(d.getType());
    }

    public static Boolean isSuspiciousEmail(String email) {
        if (String.isBlank(email)) return false;

        String e = email.toLowerCase().trim();

        // invalid — не тут
        if (isInvalidEmail(e)) return false;

        // ----------------------------
        // Parse email
        // ----------------------------
        List<String> parts = e.split('@');
        if (parts.size() != 2) return false;

        String local = parts[0];
        String domain = parts[1];

        List<String> domainLabels = domain.split('\\.');
        String firstLabel = domainLabels.isEmpty() ? '' : domainLabels[0];

        // ----------------------------
        // SAFE LOCAL whitelist
        // ----------------------------
        Set<String> safeLocals = new Set<String>();
        for (EmailSafeLocal__mdt s : [
            SELECT LocalValue__c
            FROM EmailSafeLocal__mdt
            WHERE IsActive__c = true
        ]) {
            if (!String.isBlank(s.LocalValue__c)) {
                safeLocals.add(s.LocalValue__c.toLowerCase());
            }
        }

        if (safeLocals.contains(local)) return false;

        // ----------------------------
        // Suspicious rules
        // ----------------------------
        for (EmailSuspiciousRule__mdt r : [
            SELECT RuleType__c, Pattern__c
            FROM EmailSuspiciousRule__mdt
            WHERE IsActive__c = true
        ]) {
            String type = r.RuleType__c;
            String rulePattern = r.Pattern__c;

            // 1️. SHORT_LOCAL
            if (type == 'SHORT_LOCAL') {
                Integer maxLen;
                try {
                    maxLen = Integer.valueOf(rulePattern);
                } catch (Exception ex) {
                    continue;
                }
                if (local.length() <= maxLen) return true;
            }

            // 2️. LOCAL_EQUALS_DOMAIN
            else if (type == 'LOCAL_EQUALS_DOMAIN') {
                if (local == firstLabel) return true;
            }

            // 3️. NUMERIC_ONLY
            else if (type == 'NUMERIC_ONLY') {
                if (!String.isBlank(rulePattern) &&
                    System.Pattern.matches(rulePattern, local + '@' + domain)
                ) {
                    return true;
                }
            }

            // 4️. PLACEHOLDER
            else if (type == 'PLACEHOLDER') {
                if (!String.isBlank(rulePattern) &&
                    System.Pattern.matches(rulePattern, local + '@')
                ) {
                    return true;
                }
            }

            // 5️. REPEAT_PATTERN
            else if (type == 'REPEAT_PATTERN') {
                if (!String.isBlank(rulePattern) &&
                    System.Pattern.matches('.*' + rulePattern + '.*', local)
                ) {
                    return true;
                }
            }
        }

        return false;
}

    public static Boolean isSuspiciousPhone(String phone) {
        if (String.isBlank(phone)) {
            return false;
        }

        // якщо технічно invalid — не просто suspicious
        if (isInvalidPhone(phone)) {
            return false;
        }

        String p = phone
            .replace('+','')
            .replace(' ','')
            .replace('-','')
            .replace('(','')
            .replace(')','')
            .replace('.','');

        Integer len = p.length();

        // 1️. всі цифри однакові (довгі)
        if (p.replace(p.substring(0,1), '').length() == 0) {
            return true;
        }

        // 2️. повторюваний хвіст після коду країни
        // +994111111111, +998111111111
        Integer ccLen = Math.min(3, len); // умовно
        String tail = p.substring(ccLen);

        if (tail.length() >= 6 &&
            tail.replace(tail.substring(0,1), '').length() == 0
        ) {
            return true;
        }

        // 2️b: довгий хвіст з нулів або одиниць після початку
        // +993110000000, +994550000000
        for (Integer i = 4; i <= 6 && i < p.length(); i++) {
            String t = p.substring(i);
            if (t.length() >= 6 &&
                t.replace(t.substring(0,1), '').length() == 0
            ) {
                return true;
            }
        }

        // 3️. монотонні послідовності
        Boolean inc = true;
        Boolean dec = true;

        for (Integer i = 1; i < p.length(); i++) {
            Integer prev = Integer.valueOf(p.substring(i-1, i));
            Integer curr = Integer.valueOf(p.substring(i, i+1));

            if (curr != prev + 1) inc = false;
            if (curr != prev - 1) dec = false;
        }

        if (inc || dec) {
            return true;
        }

        // 4️. дуже низька ентропія (≤ 2 різних цифр)
        Set<String> uniq = new Set<String>();
        for (Integer i = 0; i < p.length(); i++) {
            uniq.add(p.substring(i, i+1));
        }

        if (uniq.size() <= 2) {
            return true;
        }

        return false;
    }
    
}