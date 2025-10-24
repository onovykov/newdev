public class AccountRepository {

    private static Map<Id, Account> allAccountsById;
    private static Map<String, Account> allAccountsByErp;
    // Мапа для індексації по полях фонетичних індексів
    private static Map<String, Map<String, List<Account>>> indexedAccountsByField;

    private static Boolean isLoaded = false;
    private static Boolean isLoadedChanges = false;

    // Кеш для lightClearName
    private static Map<String, String> changeMap;

    // Список полів, які індексуються
    private static final List<String> INDEXED_FIELDS = new List<String>{
        'PhoneticCode__c', 'MetaphonePrimary__c', 'MetaphoneAlternate__c',
        'NYSIISFirstCode__c', 'NYSIIS__c', 'NormalizedName__c',
        'SoundexFirst3Letters__c', 'SoundexFirstWord__c', 'SoundexAllWords__c'
    };

    public static void loadAllAccounts() {
    if (isLoaded) return;

    // Re-init core maps
    allAccountsById   = new Map<Id, Account>();
    allAccountsByErp  = new Map<String, Account>();

    // Re-init field indexes
    indexedAccountsByField = new Map<String, Map<String, List<Account>>>();
    for (String field : INDEXED_FIELDS) {
        indexedAccountsByField.put(field, new Map<String, List<Account>>());
    }

    // Single SOQL + index population
    for (Account acc : [
        SELECT
            Id, Name, ID_ERP__c,
            MarketSegment__c, Country__c, BillingCountryCode, BillingCity, Activity_Type__c,
            Under_sanctions__c, OwnerId, CreatedDate, CreatedById, OppsCount__c, ClosedWonOpps__c,
            OrdersCount__c, HoldingGroup__c, ParentId, NormalizedName__c,
            PhoneticCode__c, MetaphonePrimary__c, MetaphoneAlternate__c,
            NYSIISFirstCode__c, NYSIIS__c,
            SoundexFirst3Letters__c, SoundexFirstWord__c, SoundexAllWords__c,
            SoundexGroup__c
        FROM Account
    ]) {
        // 1) Index by Id
        allAccountsById.put(acc.Id, acc);

        // 2) Index by ERP
        if (!String.isBlank(acc.ID_ERP__c)) {
            allAccountsByErp.put(acc.ID_ERP__c, acc);
        }

        // 3) Generic field indexing
        for (String field : INDEXED_FIELDS) {
            Object raw = acc.get(field);
            if (raw == null) continue;
            String val = String.valueOf(raw).trim();
            if (String.isBlank(val)) continue;

            Map<String, List<Account>> fieldMap = indexedAccountsByField.get(field);
            List<Account> bucket = fieldMap.get(val);
            if (bucket == null) {
                bucket = new List<Account>();
                fieldMap.put(val, bucket);
            }
            bucket.add(acc);
        }
    }

    isLoaded = true;
    }


    //--- Метод для доступу до індексів
    public static List<Account> getByFieldValue(String fieldName, String fieldValue) {
        loadAllAccounts();
        if (String.isBlank(fieldName) || String.isBlank(fieldValue)) return new List<Account>();
        if (!indexedAccountsByField.containsKey(fieldName)) return new List<Account>();

        Map<String, List<Account>> fieldMap = indexedAccountsByField.get(fieldName);
        return fieldMap.containsKey(fieldValue)
            ? fieldMap.get(fieldValue)
            : new List<Account>();
    }

    //--- Повертаємо акаунт по Id
    public static Account getById(Id id) {
        loadAllAccounts();
        return allAccountsById.get(id);
    }

    //--- Повертаємо акаунт по ID_ERP__c
    public static Account getByErp(String erpCode) {
        loadAllAccounts();
        return allAccountsByErp.get(erpCode);
    }

    //--- Вибираємо всі акаунти
    public static List<Account> getAllAccounts() {
        loadAllAccounts();
        return new List<Account>(allAccountsById.values());
    }

    //--- Чистимо кеш
    public static void clearCache() {
        isLoaded = false;
        isLoadedChanges = false;
        allAccountsById = null;
        allAccountsByErp = null;
        indexedAccountsByField = null;
        changeMap = null;
    }

    public static void refresh() {
        clearCache();
        loadAllAccounts();
    }
}