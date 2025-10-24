@IsTest
private class ScrapSlotReserveTriggerHandler_Test {

    // *** ПІДГОНКА ПІД ОРГ (онови при потребі) ***
    private static final Integer LVL_YEAR   = 1;
    private static final Integer LVL_MONTH  = 2;
    private static final Integer LVL_DECADE = 3;
    private static final Integer LVL_DAY    = 4;

    private class Hier {
        Id yearId;
        Id monthId;
        Id decadeId;
        Id dayId;
    }

    // Створює/повертає ланцюжок Decade__c для конкретної дати d
    private static Hier ensureHierarchy(Date d) {
        Hier h = new Hier();

        // 1) Day
        Decade__c day = [
                SELECT Id, Parent__c,
                        Parent__r.Id, Parent__r.Level__c,
                        Parent__r.Parent__c, Parent__r.Parent__r.Id, Parent__r.Parent__r.Level__c,
                        Parent__r.Parent__r.Parent__c, Parent__r.Parent__r.Parent__r.Id, Parent__r.Parent__r.Parent__r.Level__c
                FROM Decade__c
                WHERE Date__c = :d
                LIMIT 1
        ];
        h.dayId = day.Id;

        // 2) Decade (parent of Day) або створюємо
        Decade__c dec = [SELECT Id, Level__c, Parent__c FROM Decade__c WHERE Id = :day.Parent__c LIMIT 1];
        if (dec.Level__c == null || dec.Level__c != LVL_DECADE) {
            dec.Level__c = LVL_DECADE;
            update dec;
        }
        h.decadeId = dec.Id;

        // 3) Month (parent of Decade)
        Decade__c mon = [SELECT Id, Level__c, Parent__c FROM Decade__c WHERE Id = :dec.Parent__c LIMIT 1];
        if (mon.Level__c == null || mon.Level__c != LVL_MONTH) {
            mon.Level__c = LVL_MONTH;
            update mon;
        }
        h.monthId = mon.Id;

        // 4) Year (parent of Month)
        Decade__c year = [SELECT Id, Level__c FROM Decade__c WHERE Id = :mon.Parent__c LIMIT 1];
        if (year.Level__c == null || year.Level__c != LVL_YEAR) {
            year.Level__c = LVL_YEAR;
            update year;
        }
        h.yearId = year.Id;

        // 5) Підправляємо рівень Day за потреби (фільтр DateLookup: Level = 4)
        Decade__c dayUpd = new Decade__c(Id = h.dayId, Level__c = LVL_DAY);
        update dayUpd;

        return h;
    }

    @TestSetup
    static void setupData() {
        // Створимо мінімальну ієрархію під конкретну дату d.
        // Ланцюжок: Year -> Month -> Decade -> Day
        Date d = Date.newInstance(2025, 8, 18);

        // Year
        Decade__c year = new Decade__c(
                Name = 'Y-' + d.year(),
                Level__c = LVL_YEAR,
                Year__c = d.year()
        );
        insert year;

        // Month
        Decade__c month = new Decade__c(
                Name = 'M-' + String.valueOf(d.month()),
                Level__c = LVL_MONTH,
                Month__c = String.valueOf(d.month()),
                Parent__c = year.Id
        );
        insert month;

        // Decade
        Integer dom = d.day();
        String decPick = dom <= 10 ? '1' : (dom <= 20 ? '2' : '3');
        Decade__c dec = new Decade__c(
                Name = 'D-' + decPick,
                Level__c = LVL_DECADE,
                Decade__c = decPick,
                Parent__c = month.Id
        );
        insert dec;

        // Day
        Decade__c day = new Decade__c(
                Name = 'DAY-' + d.format(),
                Level__c = LVL_DAY,
                Date__c = d,
                Parent__c = dec.Id
        );
        insert day;
    }

    @IsTest
    static void beforeInsert_stamps_lookups() {
        // Беремо дату з @TestSetup, під яку вже є ієрархія
        Date d = Date.newInstance(2025, 8, 18);
        Hier h = ensureHierarchy(d);

        // Мінімум обов’язкових полів: IsCancelled, IsOutOfLimit
        ScrapSlotReserve__c s = new ScrapSlotReserve__c(
                ReserveDate__c = d,
                IsCancelled__c = false,
                IsOutOfLimit__c = false
        );

        insert s;

        s = [
                SELECT DateLookup__c, DecadeLookup__c, MonthLookup__c, YearLookup__c
                FROM ScrapSlotReserve__c
                WHERE Id = :s.Id
        ];

        System.assertEquals(h.dayId,   s.DateLookup__c,   'DateLookup__c має вказувати на Day');
        System.assertEquals(h.decadeId, s.DecadeLookup__c, 'DecadeLookup__c має вказувати на Decade');
        System.assertEquals(h.monthId,  s.MonthLookup__c,  'MonthLookup__c має вказувати на Month');
        System.assertEquals(h.yearId,   s.YearLookup__c,   'YearLookup__c має вказувати на Year');
    }

    @IsTest
    static void beforeUpdate_restamps_when_date_changes() {
        // Початкова дата
        Date d1 = Date.newInstance(2025, 8, 18);
        Hier h1 = ensureHierarchy(d1);

        // Друга дата (інший день → інша “Day” нода)
        Date d2 = Date.newInstance(2025, 8, 19);

        // Створимо ланцюжок під d2 (якщо Day вже існує в проді — метод тільки вирівняє рівні)
        // Щоб тест був самодостатнім, створимо всю гілку зі своєю датою:
        // рік/місяць ті ж, може відрізнятись тільки Day і (за потреби) Decade
        // Спробуємо знайти day за датою, якщо немає — створимо всю потрібну підгілку.
        Decade__c day2;
        List<Decade__c> z = [
                SELECT Id, Parent__c,
                        Parent__r.Id, Parent__r.Parent__c,
                        Parent__r.Parent__r.Id
                FROM Decade__c
                WHERE Date__c = :d2
                LIMIT 1
        ];
        if (z.isEmpty()) {
            // Decade для d2
            Integer dom2 = d2.day();
            String decPick2 = dom2 <= 10 ? '1' : (dom2 <= 20 ? '2' : '3');
            // Візьмемо Month і Year з h1 (та сама гілка року/місяця)
            Decade__c dec2 = new Decade__c(
                    Name = 'D-' + decPick2,
                    Level__c = LVL_DECADE,
                    Decade__c = decPick2,
                    Parent__c = h1.monthId
            );
            insert dec2;

            day2 = new Decade__c(
                    Name = 'DAY-' + d2.format(),
                    Level__c = LVL_DAY,
                    Date__c = d2,
                    Parent__c = dec2.Id
            );
            insert day2;
        } else {
            day2 = z[0];
        }

        // Тепер сам запис
        ScrapSlotReserve__c s = new ScrapSlotReserve__c(
                ReserveDate__c = d1,
                IsCancelled__c = false,
                IsOutOfLimit__c = false
        );
        insert s;

        // Міняємо дату → хендлер має перерахувати всі лукапи
        s.ReserveDate__c = d2;
        update s;

        s = [
                SELECT DateLookup__c, DecadeLookup__c, MonthLookup__c, YearLookup__c
                FROM ScrapSlotReserve__c
                WHERE Id = :s.Id
        ];

        // Витягнемо очікуваний ланцюжок під d2 (через ensureHierarchy — вирівняє рівні)
        Hier h2 = ensureHierarchy(d2);
        System.assertEquals(h2.dayId,   s.DateLookup__c,   'DateLookup__c має перелінкуватися на Day(d2)');
        System.assertEquals(h2.decadeId, s.DecadeLookup__c, 'DecadeLookup__c має перелінкуватися на Decade(d2)');
        System.assertEquals(h2.monthId,  s.MonthLookup__c,  'MonthLookup__c має лишитись тим самим місяцем');
        System.assertEquals(h2.yearId,   s.YearLookup__c,   'YearLookup__c має лишитись тим самим роком');
    }
}