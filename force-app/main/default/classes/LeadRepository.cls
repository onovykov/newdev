public class LeadRepository {

    // === Кеші ===
    private static Map<Id, ClientLead__c> byId;
    private static Map<String, Map<String, List<ClientLead__c>>> indexByField;
    private static Boolean isLoaded = false;

    // === Поля для індексації (дзеркало вашого списку) ===
    private static final List<String> INDEXED_FIELDS = new List<String>{
        'PhoneticCode__c', 'MetaphonePrimary__c', 'MetaphoneAlternate__c',
        'NYSIISFirstCode__c', 'NYSIIS__c', 'NormalizedName__c',
        'SoundexFirst3Letters__c', 'SoundexFirstWord__c', 'SoundexAllWords__c'
    };

    // === Публічні API ===

    /** Повертає лід за Id (з кеша). */
    public static ClientLead__c getById(Id id) {
        ensureLoaded();
        return byId.get(id);
    }

    /** Пошук у побудованому індексі: fieldName=значення → список лідов. Повертає КОПІЮ списку. */
    public static List<ClientLead__c> getByFieldValue(String fieldName, String fieldValue) {
        ensureLoaded();
        if (String.isBlank(fieldName) || String.isBlank(fieldValue)) return new List<ClientLead__c>();

        Map<String, List<ClientLead__c>> fieldMap = indexByField.get(fieldName);
        if (fieldMap == null) return new List<ClientLead__c>();

        List<ClientLead__c> bucket = fieldMap.get(fieldValue);
        if (bucket == null || bucket.isEmpty()) return new List<ClientLead__c>();

        // ВАЖЛИВО: віддаємо копію, щоб зовнішній код не міняв внутрішній індекс
        List<ClientLead__c> copy = new List<ClientLead__c>();
        copy.addAll(bucket);
        return copy;
    }

    /** Всі ліди (копія значень кешу). */
    public static List<ClientLead__c> getAllLeads() {
        ensureLoaded();
        return new List<ClientLead__c>(byId.values());
    }

    /** Сумісність із попереднім ім’ям. */
    public static List<ClientLead__c> getloadAllLeads() {
        return getAllLeads();
    }

    /** Скидання кешів. Наступний виклик ensureLoaded() збудує все наново. */
    public static void clearCache() {
        isLoaded = false;
        byId = null;
        indexByField = null;
    }

    // === Внутрішня реалізація ===

    /** Гарантує, що кеши завантажені (ліниве ініціалізування). */
    private static void ensureLoaded() {
        if (isLoaded) return;
        rebuild();
        isLoaded = true;
    }

    /** Будує кеші ОДНИМ SOQL і однією ітерацією. Атомарно підміняє посилання після побудови. */
    @TestVisible
    private static void rebuild() {
        // Локальні тимчасові структури — будуємо повністю, потім одним присвоєнням замінюємо глобальні
        Map<Id, ClientLead__c> byIdTmp = new Map<Id, ClientLead__c>();
        Map<String, Map<String, List<ClientLead__c>>> idxTmp =
            new Map<String, Map<String, List<ClientLead__c>>>();

        // Підготовка порожніх мап для кожного індексованого поля
        for (String f : INDEXED_FIELDS) {
            idxTmp.put(f, new Map<String, List<ClientLead__c>>());
        }

        // ЄДИНИЙ запит
        List<ClientLead__c> rows = [
            SELECT Id, Name, MarketSegment__c, Country__c, CityName__c, LeadStage__c, Account__c,
                   OwnerId, CreatedDate, CreatedById, Holding__c, ParentAccount__c, ChildAccount__c,
                   NormalizedName__c, PhoneticCode__c, MetaphonePrimary__c, MetaphoneAlternate__c,
                   NYSIISFirstCode__c, NYSIIS__c, SoundexFirst3Letters__c, SoundexFirstWord__c,
                   SoundexAllWords__c, Phone__c, Mobile__c, Email__c, Web__c
            FROM ClientLead__c
        ];

        // ЄДИНА ітерація: наповнюємо byId та індекси
        for (ClientLead__c rec : rows) {
            byIdTmp.put(rec.Id, rec);

            // Загальна логіка індексації
            for (String f : INDEXED_FIELDS) {
                Object raw = rec.get(f);
                if (raw == null) continue;

                String val = String.valueOf(raw).trim();
                if (String.isBlank(val)) continue;

                Map<String, List<ClientLead__c>> fieldMap = idxTmp.get(f);
                List<ClientLead__c> bucket = fieldMap.get(val);
                if (bucket == null) {
                    bucket = new List<ClientLead__c>();
                    fieldMap.put(val, bucket);
                }
                bucket.add(rec);
            }
        }

        // АТОМАРНО підміняємо посилання (без частково-побудованих станів)
        byId = byIdTmp;
        indexByField = idxTmp;
    }

     // === ТІЛЬКИ ДЛЯ ТЕСТІВ ===
    /**
     * Інжектор тестових даних без DML. Дає можливість покрити
     * позитивні гілки індексації та getById/getByFieldValue.
     */
    @TestVisible
    private static void injectForTest(List<ClientLead__c> rows) {
        Map<Id, ClientLead__c> byIdTmp = new Map<Id, ClientLead__c>();
        Map<String, Map<String, List<ClientLead__c>>> idxTmp =
            new Map<String, Map<String, List<ClientLead__c>>>();

        for (String f : INDEXED_FIELDS) {
            idxTmp.put(f, new Map<String, List<ClientLead__c>>());
        }

        for (ClientLead__c rec : rows) {
            // Заувага: Id може бути підставлений у тесті вручну (15/18-симв. рядок)
            byIdTmp.put(rec.Id, rec);

            for (String f : INDEXED_FIELDS) {
                Object raw = rec.get(f);
                if (raw == null) continue;

                String val = String.valueOf(raw).trim();
                if (String.isBlank(val)) continue;

                Map<String, List<ClientLead__c>> fieldMap = idxTmp.get(f);
                List<ClientLead__c> bucket = fieldMap.get(val);
                if (bucket == null) {
                    bucket = new List<ClientLead__c>();
                    fieldMap.put(val, bucket);
                }
                bucket.add(rec);
            }
        }

        byId = byIdTmp;
        indexByField = idxTmp;
        isLoaded = true;
    }
   
}