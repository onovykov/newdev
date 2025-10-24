@IsTest
private class ScrapSupplierLimitTrigger_Test {

    // --- Константи рівнів ієрархії Decade__c
    private static final Integer LVL_YEAR  = 1;
    private static final Integer LVL_MONTH = 2;
    // Далі (декада/день) зараз не потрібні

    // ===== ХЕЛПЕРИ =========================================================

    // Будь-який активний RecordType для ScrapSupplierLimit__c (або null)
    private static Id anyRT() {
        List<RecordType> rts = [
                SELECT Id
                FROM RecordType
                WHERE SobjectType = 'ScrapSupplierLimit__c' AND IsActive = true
                LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    // Повертає перше валідне значення пікліста поля (як текст)
    private static String firstPickVal(Schema.SObjectType soType, String fieldApi) {
        Schema.DescribeFieldResult d =
                soType.getDescribe().fields.getMap().get(fieldApi).getDescribe();
        for (Schema.PicklistEntry p : d.getPicklistValues()) {
            if (p.isActive()) return p.getValue();
        }
        // fallback (наразі не очікується)
        return d.getPicklistValues().isEmpty() ? null : d.getPicklistValues()[0].getValue();
    }

    // Забезпечує наявність річного вузла; повертає його Id
    // Забезпечує наявність річного вузла; повертає його Id
    private static Id ensureYearNode(Integer year) {
        List<Decade__c> ys = [
                SELECT Id
                FROM Decade__c
                WHERE Level__c = :LVL_YEAR AND Year__c = :year
                LIMIT 1
        ];
        Decade__c y = ys.isEmpty() ? null : ys[0];

        if (y == null) {
            y = new Decade__c(Name = 'Y-' + year, Level__c = LVL_YEAR, Year__c = year);
            insert y;
        }
        return y.Id;
    }


    // Забезпечує наявність місячного вузла для року; повертає Id місяця
    private static Id ensureMonthNode(Integer year, Integer monthInt) {
        Id yearId = ensureYearNode(year);
        String monthStr = String.valueOf(monthInt);

        List<Decade__c> months = [
                SELECT Id, Level__c, Parent__c, Year__c
                FROM Decade__c
                WHERE Parent__c = :yearId AND Month__c = :monthStr
                LIMIT 1
        ];
        Decade__c m = months.isEmpty() ? null : months[0];

        if (m == null) {
            m = new Decade__c(
                    Name      = 'M-' + monthStr,
                    Level__c  = LVL_MONTH,  // 2
                    Month__c  = monthStr,
                    Year__c   = year,       // <-- обов’язково!
                    Parent__c = yearId
            );
            insert m;
        } else {
            Boolean needUpdate = false;
            if (m.Level__c != LVL_MONTH) { m.Level__c = LVL_MONTH; needUpdate = true; }
            if (m.Year__c == null)       { m.Year__c  = year;      needUpdate = true; }
            if (needUpdate) update m;
        }
        return m.Id;
    }

    // Створює постачальника
    private static Account makeSupplier() {
        Account a = new Account(Name = 'ТОВ Метал Плюс', IsSupplier__c = true);
        insert a;
        return a;
    }

    // Створює валідний чернетковий запис ліміту без дублів
    private static ScrapSupplierLimit__c makeLimit(Id supplierId, String yearPick, String monthPick, Id rtId) {
        ScrapSupplierLimit__c rec = new ScrapSupplierLimit__c();
        rec.Supplier__c  = supplierId;
        rec.YearPick__c  = yearPick;     // пікліст (текст!)
        rec.Month__c     = monthPick;    // пікліст (текст!)
        if (rtId != null) rec.RecordTypeId = rtId;
        // Name обов’язкове, але його перезапише тригер у before insert;
        // все ж задамо заглушку, щоб не залежати від зовнішніх VR.
        rec.Name = 'tmp';
        return rec;
    }

    // ===== SETUP ДЛЯ ВСІХ ТЕСТІВ ===========================================

    @TestSetup
    static void setup() {
        // Візьмемо валідні пікліст-значення з самої схеми
        String yearVal  = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'YearPick__c'); // напр. '2025'
        String monthVal = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'Month__c');    // '1'..'12'
        System.assertNotEquals(null, yearVal,  'Expected YearPick__c picklist to have at least 1 value');
        System.assertNotEquals(null, monthVal, 'Expected Month__c picklist to have at least 1 value');

        Integer y = Integer.valueOf(yearVal);
        Integer m = Integer.valueOf(monthVal);

        // Підготуємо вузли року/місяця (щоб ScrapUtils.getMonthId мав що знайти)
        ensureMonthNode(y, m);

        // Мінімально — ще один інший місяць для update-кейсу
        Integer nextM = (m == 12) ? 1 : m + 1;
        ensureMonthNode(y, nextM);

        // Створимо 1 постачальника (використаємо в тестах)
        makeSupplier();
    }

    // ===== ТЕСТИ ===========================================================

    @IsTest
    static void beforeInsert_stamps_fields() {
        Id rt = anyRT(); // може бути null — ок
        Account sup = [SELECT Id, Name FROM Account  WHERE IsSupplier__c = TRUE LIMIT 1];

        String yearVal  = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'YearPick__c');
        String monthVal = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'Month__c');

        ScrapSupplierLimit__c rec = makeLimit(sup.Id, yearVal, monthVal, rt);

        Test.startTest();
        insert rec;
        Test.stopTest();

        rec = [
                SELECT Id, MonthLookup__c, Key__c, Name, Supplier__c, RecordTypeId
                FROM ScrapSupplierLimit__c
                WHERE Id = :rec.Id
        ];
        System.assertNotEquals(null, rec.MonthLookup__c,  'MonthLookup__c must be stamped in before insert');
        System.assertNotEquals(null, rec.Key__c,          'Key__c must be built in before insert');
        System.assertNotEquals(null, rec.Name,            'Name must be composed in before insert');
        System.assertEquals(sup.Id, rec.Supplier__c);
        // RecordTypeId може бути null, якщо на орзі лише Master — це нормально
    }

    @IsTest
    static void afterInsert_blocks_duplicate_in_same_period() {
        Id rt = anyRT();
        Account sup = [SELECT Id FROM Account WHERE IsSupplier__c = TRUE LIMIT 1];

        String yearVal  = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'YearPick__c');
        String monthVal = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'Month__c');

        ScrapSupplierLimit__c a = makeLimit(sup.Id, yearVal, monthVal, rt);
        insert a;

        // Другий з тим самим ключем → очікуємо addError у тригері (DmlException)
        ScrapSupplierLimit__c b = makeLimit(sup.Id, yearVal, monthVal, rt);

        Test.startTest();
        try {
            insert b;
            System.assert(false, 'Expected duplicate to be blocked by trigger addError');
        } catch (DmlException e) {
            // В after-тригерах зазвичай статус CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
            // головне — щоб повідомлення з addError прилетіло
            System.assert(e.getMessage().contains('ПОМИЛКА'), 'Should contain addError message, got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void beforeUpdate_recomputes_month_and_key() {
        Id rt = anyRT();
        Account sup = [SELECT Id FROM Account WHERE IsSupplier__c = TRUE  LIMIT 1];

        // Візьмемо поточний і "наступний" місяць із пікліста
        List<String> months = new List<String>();
        for (Schema.PicklistEntry p : ScrapSupplierLimit__c.Month__c.getDescribe().getPicklistValues()) {
            if (p.isActive()) months.add(p.getValue());
        }
        System.assert(months.size() > 0);
        String m1 = months[0];
        String m2 = (months.size() > 1 ? months[1] : months[0]); // якщо лише один — оновимо тим самим

        String yearVal = firstPickVal(ScrapSupplierLimit__c.SObjectType, 'YearPick__c');
        Integer y = Integer.valueOf(yearVal);
        ensureMonthNode(y, Integer.valueOf(m1));
        ensureMonthNode(y, Integer.valueOf(m2));

        ScrapSupplierLimit__c rec = makeLimit(sup.Id, yearVal, m1, rt);
        insert rec;

        // Змінимо місяць — тригер має перерахувати MonthLookup__c та Key__c
        rec = [
                SELECT Id, Month__c, MonthLookup__c, Key__c
                FROM ScrapSupplierLimit__c
                WHERE Id = :rec.Id
        ];
        Id oldMonthId = rec.MonthLookup__c;
        String oldKey = rec.Key__c;

        rec.Month__c = m2;

        Test.startTest();
        update rec;
        Test.stopTest();

        rec = [
                SELECT Id, Month__c, MonthLookup__c, Key__c
                FROM ScrapSupplierLimit__c
                WHERE Id = :rec.Id
        ];
        System.assertNotEquals(oldMonthId, rec.MonthLookup__c, 'MonthLookup__c must change after month switch');
        System.assertNotEquals(oldKey,     rec.Key__c,         'Key__c must change after month switch');
    }
}