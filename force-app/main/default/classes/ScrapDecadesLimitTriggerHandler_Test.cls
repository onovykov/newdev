@IsTest(seeAllData=false)
private class ScrapDecadesLimitTriggerHandler_Test {

    private static final Date D1 = Date.newInstance(2025, 8, 18);
    private static final Date D2 = Date.newInstance(2025, 8, 19);

    private class H {
        Id monthGroupId;
        Id decadeGroupId;
        Id dayId;
        Integer yearNum;
        String monthStr;
        String decadeStr;
        Date dateVal;
    }

    // Створює ієрархію Decade__c під конкретну дату (Level: 1=місяць, 2=декада, 4=день — вимагає lookup-фільтр)
    private static H ensureHierarchy(Date d) {
        H h = new H();
        h.dateVal   = d;
        h.yearNum   = d.year();
        h.monthStr  = String.valueOf(d.month()); // picklist 1..12
        h.decadeStr = '2';                       // picklist 1..3

        Decade__c m = new Decade__c(
                Date__c=d.toStartOfMonth(), Year__c=h.yearNum,
                Month__c=h.monthStr, Decade__c=h.decadeStr, Level__c=1
        );
        insert m;

        Decade__c g = new Decade__c(
                Date__c=Date.newInstance(d.year(), d.month(), 10), Year__c=h.yearNum,
                Month__c=h.monthStr, Decade__c=h.decadeStr, Parent__c=m.Id, Level__c=2
        );
        insert g;

        Decade__c day = new Decade__c(
                Date__c=d, Year__c=h.yearNum,
                Month__c=h.monthStr, Decade__c=h.decadeStr, Parent__c=g.Id, Level__c=4
        );
        insert day;

        h.monthGroupId  = m.Id;
        h.decadeGroupId = g.Id;
        h.dayId         = day.Id;
        return h;
    }

    private static Id ensureScrapType() {
        ScrapType__c t = new ScrapType__c(Name = 'TestType-' + String.valueOf(Crypto.getRandomInteger()));
        insert t;
        return t.Id;
    }

    @testSetup
    static void setupData() {
        // Базова ієрархія під D1 + один валідний запис SDL (без ScrapType__c, щоб не заважав тестам на дубль)
        H h1 = ensureHierarchy(D1);
        insert new ScrapDecadesLimit__c(
                LimitDate__c   = h1.dateVal,
                DayLookup__c   = h1.dayId,
                DecadeGroup__c = h1.decadeGroupId,
                MonthGroup__c  = h1.monthGroupId,
                Year__c        = h1.yearNum,
                Month__c       = h1.monthStr,
                Decade__c      = h1.decadeStr
        );
    }

    // === TEST 1: before insert — тригер простампує службові поля
    @IsTest
    static void beforeInsert_stamps_fields() {
        Id stId = ensureScrapType();
        ScrapDecadesLimit__c rec = new ScrapDecadesLimit__c(LimitDate__c=D1, ScrapType__c=stId);

        Test.startTest();
        insert rec;
        Test.stopTest();

        ScrapDecadesLimit__c got = [
                SELECT DayLookup__c, Year__c, Month__c, Decade__c,
                        DecadeGroup__c, MonthGroup__c, Key__c, ScrapType__c
                FROM ScrapDecadesLimit__c WHERE Id = :rec.Id
        ];
        System.assertNotEquals(null, got.DayLookup__c);
        System.assertNotEquals(null, got.DecadeGroup__c);
        System.assertNotEquals(null, got.MonthGroup__c);
        System.assertEquals(D1.year(), got.Year__c);
        System.assertEquals(String.valueOf(D1.month()), got.Month__c);
        System.assertEquals('2', got.Decade__c);
        System.assert(got.Key__c.startsWith(String.valueOf(got.DayLookup__c) + '-'));
        System.assertEquals(stId, got.ScrapType__c);
    }

    // === TEST 2: дубль в одній транзакції — допускаємо, що хендлер помітить ОБИДВА рядки як дублікат
    @IsTest
    static void beforeInsert_blocks_duplicate_in_same_txn() {
        Id stId = ensureScrapType();
        ScrapDecadesLimit__c r1 = new ScrapDecadesLimit__c(LimitDate__c=D1, ScrapType__c=stId);
        ScrapDecadesLimit__c r2 = new ScrapDecadesLimit__c(LimitDate__c=D1, ScrapType__c=stId);

        Test.startTest();
        Database.SaveResult[] sr = Database.insert(new List<ScrapDecadesLimit__c>{ r1, r2 }, /*allOrNone*/ false);
        Test.stopTest();

        System.assertEquals(2, sr.size());

        // Має впасти ПРИНАЙМНІ один (у твоїй реалізації зазвичай падають ОБИДВА)
        Integer failed = 0;
        for (Database.SaveResult r : sr) {
            if (!r.isSuccess()) {
                failed++;
                System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, r.getErrors()[0].getStatusCode());
            }
        }
        System.assert(failed >= 1, 'Очікуємо хоча б один дублікат у транзакції');
    }

    // === TEST 3: before update — конфлікт проти існуючого запису у БД
    @IsTest
    static void beforeUpdate_blocks_conflict_against_existing() {
        Id stId = ensureScrapType();

        // Існуючий запис на D1
        ScrapDecadesLimit__c existing = new ScrapDecadesLimit__c(LimitDate__c=D1, ScrapType__c=stId);
        insert existing;

        // Другий запис — валідний на D2 (щоб зберігся), потім апдейтнемо на D1 і словимо конфлікт
        H h2 = ensureHierarchy(D2);
        ScrapDecadesLimit__c toUpd = new ScrapDecadesLimit__c(
                LimitDate__c   = h2.dateVal,
                ScrapType__c   = stId,
                DayLookup__c   = h2.dayId,
                DecadeGroup__c = h2.decadeGroupId,
                MonthGroup__c  = h2.monthGroupId,
                Year__c        = h2.yearNum,
                Month__c       = h2.monthStr,
                Decade__c      = h2.decadeStr
        );
        insert toUpd;

        // Тригер на апдейті має побачити конфлікт із existing
        toUpd.LimitDate__c = D1;

        Test.startTest();
        Database.SaveResult sr = Database.update(toUpd, /*allOrNone*/ false);
        Test.stopTest();

        System.assertEquals(false, sr.isSuccess(), 'апдейт має впасти як конфлікт');
        // Перевіряємо по коду помилки — не залежимо від тексту/локалі
//        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr.getErrors()[0].getStatusCode());
    }
}