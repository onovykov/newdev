public class UserRepository {

    private static Map<Id, User> allUsersById;
    private static Map<String, User> allUsersByErp;
    private static Map<String, User> allUsersByUID;
    private static Map<String, User> allUsersByLoginErp;
    private static Map<String, User> allUsersByAlias;
    private static Map<Id, User> IdToOwnerMap;

    // Мапа для індексації по полях індексів
    private static Map<String, Map<String, List<User>>> indexedUsersByField;
    // Флаг - чи відпрацював метод loadAllUsers
    private static Boolean isLoaded = false;

    // Список полів, які індексуються
    private static final List<String> INDEXED_FIELDS = new List<String>{
        'UID_ERP__c', 'ID_ERP__c', 'LoginERP__c', 'Alias'
    };

    public static void loadAllUsers() {
        if (isLoaded) return;

        // Re-init core maps
        allUsersById   = new Map<Id, User>();
        IdToOwnerMap  = new Map<Id, User>();
        allUsersByErp = new Map<String, User>();
        allUsersByUID = new Map<String, User>();
        allUsersByLoginErp = new Map<String, User>();
        allUsersByAlias = new Map<String, User>();

        // Re-init field indexes
        indexedUsersByField = new Map<String, Map<String, List<User>>>();
        for (String field : INDEXED_FIELDS) {
            indexedUsersByField.put(field, new Map<String, List<User>>());
        }

        // Single SOQL + index population
        for (User usr : [
            SELECT
                Id, Name, Alias, ID_ERP__c, UID_ERP__c, LoginERP__c,
                BusinesDivision__c, SalesDivision__c,
                UserRoleId, UserRole.Name, UserRole.DeveloperName,
                ProfileId, Profile.Name, Profile.UserLicense.Name,
                LanguageLocaleKey, LocaleSidKey, AssignedBOS__c,
                ManagerId, Manager.Name
            FROM User
            WHERE IsActive=true
        ]) {
            // 1) Index by Id
            allUsersById.put(usr.Id, usr);

            // 2) Index by ID_ERP
            if (!String.isBlank(usr.ID_ERP__c)) {
                allUsersByErp.put(usr.ID_ERP__c, usr);
            }

            // 3) Index by UID_ERP
            if (!String.isBlank(usr.UID_ERP__c)) {
                allUsersByUID.put(usr.UID_ERP__c, usr);
            }

            // 4) Index by UID_ERP
            if (!String.isBlank(usr.LoginERP__c)) {
                allUsersByLoginErp.put(usr.LoginERP__c, usr);
            }

            // 5) Index by Alias
            if (!String.isBlank(usr.Alias)) {
                allUsersByAlias.put(usr.Alias, usr);
            }

            // 5) Будуємо мапу IdToOwnerMap - бізнес-сегменти юзерів
            if (
                !String.isBlank(usr.BusinesDivision__c) &&
                usr.BusinesDivision__c != 'DVM' &&
                usr.BusinesDivision__c != 'Marketing' &&
                usr.BusinesDivision__c != 'PRD' &&
                usr.BusinesDivision__c != 'TOP' &&
                usr.Profile.UserLicense.Name == 'Salesforce'
                )
            {
                IdToOwnerMap.put(usr.Id, usr);
            }

            // 6) Generic field indexing
            for (String field : INDEXED_FIELDS) {
                Object raw = usr.get(field);
                if (raw == null) continue;
                String val = String.valueOf(raw).trim();
                if (String.isBlank(val)) continue;

                Map<String, List<User>> fieldMap = indexedUsersByField.get(field);
                List<User> bucket = fieldMap.get(val);
                if (bucket == null) {
                    bucket = new List<User>();
                    fieldMap.put(val, bucket);
                }
                bucket.add(usr);
            }
        }
        isLoaded = true;
    }

    //--- Метод для доступу до індексів
    public static List<User> getByFieldValue(String fieldName, String fieldValue) {
        loadAllUsers();
        if (String.isBlank(fieldName) || String.isBlank(fieldValue)) return new List<User>();
        if (!indexedUsersByField.containsKey(fieldName)) return new List<User>();

        Map<String, List<User>> fieldMap = indexedUsersByField.get(fieldName);
        return fieldMap.containsKey(fieldValue)
            ? fieldMap.get(fieldValue)
            : new List<User>();
    }

    //--- Повертаємо юзера по Id
    public static User getById(Id id) {
        loadAllUsers();
        return allUsersById.get(id);
    }

    //--- Повертаємо юзера по ID_ERP__c
    public static User getByErp(String erpCode) {
        loadAllUsers();
        return allUsersByErp.get(erpCode);
    }

    //--- Повертаємо юзера по UID_ERP__c
    public static User getByUID(String UIDCode) {
        loadAllUsers();
        return allUsersByUID.get(UIDCode);
    }

    //--- Повертаємо юзера по LoginERP__c
    public static User getByLoginERP(String LoginCode) {
        loadAllUsers();
        return allUsersByLoginErp.get(LoginCode);
    }

    //--- Повертаємо юзера по Alias
    public static User getByAlias(String userAlias) {
        loadAllUsers();
        return allUsersByAlias.get(userAlias);
    }

    //--- Повертаємо мапу IdToOwnerMap - бізнес-дивізіони юзерів
    public static Map<Id, User> getUsersBisDev() {
        loadAllUsers();
        return IdToOwnerMap;
    }

    //--- Вибираємо всіх юзерів
    public static List<User> getAllUsers() {
        loadAllUsers();
        return new List<User>(allUsersById.values());
    }

    //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        allUsersById = null;
        allUsersByErp = null;
        IdToOwnerMap = null;
        allUsersByLoginErp = null;
        indexedUsersByField = null;
        allUsersByAlias = null;
    }

    public static void refresh() {
        clearCache();
        loadAllUsers();
    }
}