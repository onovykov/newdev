// RecordTypeCache.cls
public without sharing class RecordTypeCache {

    // Кастомне виключення для зручності
    public class NotFoundException extends Exception {}

    // Кеши: активні та "всі" (включно з неактивними)
    private static Map<String, Map<String, Id>> ACTIVE = null;
    private static Map<String, Map<String, Id>> ALL    = null;

    /* ======================= ПУБЛІЧНЕ API ======================= */

    // Отримати Id за API-іменем об'єкта та DeveloperName рекорд-тайпу (активні)
    public static Id getId(String sObjectApiName, String developerName) {
        return getId(sObjectApiName, developerName, false);
    }

    // Перевантаження: з токеном типу (безпечніше від опечаток у назві об’єкта)
    public static Id getId(Schema.SObjectType sObjType, String developerName) {
        return getId(sObjType.getDescribe().getName(), developerName, false);
    }

    // Те саме, але з опцією включати неактивні рекорд-тайпи
    public static Id getId(String sObjectApiName, String developerName, Boolean includeInactive) {
        ensureBuilt(includeInactive);
        Map<String, Id> perObject = (includeInactive ? ALL : ACTIVE).get(sObjectApiName);
        return perObject == null ? null : perObject.get(developerName);
    }

    // Варіант, що кине помилку, якщо не знайдено
    public static Id getOrThrow(String sObjectApiName, String developerName, Boolean includeInactive) {
        Id rtId = getId(sObjectApiName, developerName, includeInactive);
        if (rtId == null) {
            throw new NotFoundException(
                'RecordType NOT found: ' + sObjectApiName + '.' + developerName +
                ' (includeInactive=' + String.valueOf(includeInactive) + ')'
            );
        }
        return rtId;
    }

    // Отримати мапу рекорд-тайпів для конкретного об’єкта (активні).
    public static Map<String, Id> getMapFor(String sObjectApiName) {
        ensureBuilt(false);
        Map<String, Id> m = ACTIVE.get(sObjectApiName);
        return m == null ? new Map<String, Id>() : new Map<String, Id>(m);
    }

    // Отримати всю мапу (активні) як копію (щоб зовнішній код не зіпсував кеш)
    public static Map<String, Map<String, Id>> getAllAsMap() {
        ensureBuilt(false);
        return deepClone(ACTIVE);
    }

    // Попередньо прогріти весь кеш (активні / всі)
    public static void primeAll(Boolean includeInactive) {
        build(includeInactive, null, true);
    }

    // Прогріти тільки для підмножини об’єктів (імена API) — економія лімітів
    public static void primeFor(Set<String> sObjectApiNames, Boolean includeInactive) {
        if (sObjectApiNames == null || sObjectApiNames.isEmpty()) return;
        build(includeInactive, sObjectApiNames, false);
    }

    // Скинути кеш (напр., після деплою/створення нових RT)
    public static void flush() {
        ACTIVE = null;
        ALL    = null;
    }

    /* ======================= ВНУТРІШНЄ ======================= */

    private static void ensureBuilt(Boolean includeInactive) {
        if (includeInactive) {
            if (ALL == null) build(true, null, true);
        } else {
            if (ACTIVE == null) build(false, null, true);
        }
    }

    // Основний білдер: 1 SOQL по RecordType
    private static void build(Boolean includeInactive, Set<String> onlyThese, Boolean replaceWhole) {
        String soql =
            'SELECT Id, SObjectType, DeveloperName, IsActive ' +
            'FROM RecordType ' +
            'WHERE SObjectType != null';

        if (onlyThese != null && !onlyThese.isEmpty()) {
            soql += ' AND SObjectType IN :onlyThese';
        }
        if (!includeInactive) {
            soql += ' AND IsActive = true';
        }
        soql += ' ORDER BY SObjectType, DeveloperName';

        List<RecordType> rows = Database.query(soql);

        Map<String, Map<String, Id>> built = new Map<String, Map<String, Id>>();
        for (RecordType rt : rows) {
            Map<String, Id> innerMap = built.get(rt.SObjectType);
            if (innerMap == null) {
                innerMap = new Map<String, Id>();
                built.put(rt.SObjectType, innerMap);
            }
            // Ключ другого рівня — DeveloperName (системне ім’я), значення — Id
            innerMap.put(rt.DeveloperName, rt.Id);
        }

        if (includeInactive) {
            if (replaceWhole || ALL == null) ALL = built;
            else mergeInto(ALL, built);
        } else {
            if (replaceWhole || ACTIVE == null) ACTIVE = built;
            else mergeInto(ACTIVE, built);
        }
    }

    private static void mergeInto(Map<String, Map<String, Id>> base, Map<String, Map<String, Id>> inc) {
        for (String sobj : inc.keySet()) {
            Map<String, Id> baseInner = base.get(sobj);
            if (baseInner == null) {
                base.put(sobj, new Map<String, Id>(inc.get(sobj)));
            } else {
                baseInner.putAll(inc.get(sobj));
            }
        }
    }

    private static Map<String, Map<String, Id>> deepClone(Map<String, Map<String, Id>> src) {
        Map<String, Map<String, Id>> copy = new Map<String, Map<String, Id>>();
        for (String sobj : src.keySet()) {
            copy.put(sobj, new Map<String, Id>(src.get(sobj)));
        }
        return copy;
    }

    /* ======================= TEST HELPERS ======================= */
    @TestVisible
    private static void test_inject(Map<String, Map<String, Id>> activeMap,
                                    Map<String, Map<String, Id>> allMap) {
        // Глибокі копії, щоб унеможливити зовнішні мутації
        ACTIVE = (activeMap == null) ? null : deepClone(activeMap);
        ALL    = (allMap    == null) ? null : deepClone(allMap);
    }

    @TestVisible
    private static void test_injectObject(String sObjectApiName,
                                          Map<String, Id> developerToId,
                                          Boolean intoAll) {
        if (String.isBlank(sObjectApiName) || developerToId == null) return;
        Map<String, Map<String, Id>> target = (intoAll == true) ? ALL : ACTIVE;
        if (target == null) target = new Map<String, Map<String, Id>>();
        Map<String, Id> innerMap = target.get(sObjectApiName);
        if (innerMap == null) innerMap = new Map<String, Id>();
        innerMap.putAll(developerToId);
        target.put(sObjectApiName, innerMap);
        if (intoAll == true) ALL = target; else ACTIVE = target;
    }

    @TestVisible
    private static void test_mergeExpose(Map<String, Map<String, Id>> base,
                                         Map<String, Map<String, Id>> inc,
                                         Boolean toAll) {
        // Ініціалізуємо ціль і викликаємо mergeInto, щоб покрити for-loop усередині.
        if (toAll == true) {
            ALL = (base == null) ? new Map<String, Map<String, Id>>() : deepClone(base);
            mergeInto(ALL, inc == null ? new Map<String, Map<String, Id>>() : deepClone(inc));
        } else {
            ACTIVE = (base == null) ? new Map<String, Map<String, Id>>() : deepClone(base);
            mergeInto(ACTIVE, inc == null ? new Map<String, Map<String, Id>>() : deepClone(inc));
        }
    }

    @TestVisible
    private static Map<String, Map<String, Id>> test_peekActive() {
        return (ACTIVE == null) ? null : deepClone(ACTIVE);
    }

    @TestVisible
    private static Map<String, Map<String, Id>> test_peekAll() {
        return (ALL == null) ? null : deepClone(ALL);
    }
}
/*
// 1) Раз прогріти (опційно; інакше прогріється ліниво на першому зверненні)
RecordTypeCache.primeAll(false); // лише активні

// 2) Витягнути конкретний RecordTypeId
Id rtId = RecordTypeCache.getId('Opportunity', 'New_Client_Enquiry');
// або безпечно через токен:
Id rtId2 = RecordTypeCache.getId(Opportunity.SObjectType, 'New_Client_Enquiry');

// 3) Взяти всю мапу для об’єкта
Map<String, Id> oppRtMap = RecordTypeCache.getMapFor('Opportunity'); // developerName -> Id

// 4) Скинути кеш (напр., після деплою/створення нових RT)
RecordTypeCache.flush();

*/