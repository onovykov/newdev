@IsTest
private class DTUtilsTest {
    @IsTest
    static void testGetDateAsString() {
        Date d = Date.newInstance(2025, 8, 1);
        Datetime dt = Datetime.newInstance(2025, 8, 1, 12, 0, 0);
        System.assertEquals('01.08.2025', DTUtils.getDateAsString(d));
        System.assertEquals('01.08.2025', DTUtils.getDateAsString(dt));
    }

    @IsTest
    static void testMonthDecades() {
        Map<Integer, List<Date>> m = DTUtils.getMonthDecades(2025, 8);
        System.assertEquals(3, m.size());
        System.assertEquals(Date.newInstance(2025, 8, 1), m.get(1)[0]);
        System.assertEquals(Date.newInstance(2025, 8, 10), m.get(1)[1]);
    }

    @IsTest
    static void testCurrentDecade() {
        Date d = Date.newInstance(2025, 8, 14); // друга декада
        Integer dec = DTUtils.getCurrentDecade(d);
        System.assertEquals(2, dec);
    }

    @IsTest
    static void testYearMonthDecadeByDate() {
        List<Integer> res = DTUtils.getYearMonthDecadeByDate(Date.newInstance(2025, 8, 25));
        System.assertEquals(3, res.size());
        System.assertEquals(2025, res[0]);
        System.assertEquals(8, res[1]);
        System.assertEquals(3, res[2]);
    }

    @IsTest
    static void testFormatDate() {
        Date d = Date.newInstance(2025, 8, 5);
        System.assertEquals('05.08.2025', DTUtils.formatDate(d, 'dd.MM.yyyy'));
        System.assertEquals('2025-08-05', DTUtils.formatDate(d, 'yyyy-MM-dd'));
    }

    @IsTest
    static void testParseDotNetDate() {
        // Тестова дата: 2025-08-01 00:00:00 UTC = 1754006400000 мс
        String dotNet = '/Date(1754006400000)/';
        String result = DTUtils.parseDotNetDate(dotNet);
        System.assert(result != null && result != '----');

        // До 2015 року
        String oldDate = '/Date(1262304000000)/'; // 2010-01-01 UTC
        System.assertEquals('----', DTUtils.parseDotNetDate(oldDate));

        System.assertEquals('-', DTUtils.parseDotNetDate('/Date()/')); // поганий рядок
    }

    @isTest
    static void testGetDatesByPWeek() {
        // створюємо тестовий ProdWeeksH__c
        ProdWeeksH__c week = new ProdWeeksH__c(
                WeekNum__c = 33,
                DateFrom__c = Date.newInstance(2025, 8, 12),
                DateTo__c   = Date.newInstance(2025, 8, 18),
                Year__c     = 2025,
                Month__c    = '8'
        );
        insert week;

        // виклик
        Map<Integer, List<Date>> result = DTUtils.getDatesByPWeek(week.Id);

        System.assertEquals(1, result.size());
        System.assert(result.containsKey(33));
        System.assertEquals(week.DateFrom__c, result.get(33)[0]);
        System.assertEquals(week.DateTo__c, result.get(33)[1]);

        // перевірка на null
        System.assertEquals(0, DTUtils.getDatesByPWeek(null).size());
    }

    @IsTest
    static void testGetPWeekByDate() {
        Date d = Date.newInstance(2025, 8, 15);

        ProdWeeksH__c week = new ProdWeeksH__c(
                WeekNum__c = 34,
                DateFrom__c = Date.newInstance(2025, 8, 10),
                DateTo__c   = Date.newInstance(2025, 8, 20),
                Year__c     = 2025,
                Month__c    = '8'
        );
        insert week;

        ProdWeeksH__c res = DTUtils.getPWeekByDate(d);
        System.assertEquals(week.Id, res.Id);

        // null date → очікується пустий об'єкт
        System.assertEquals(null, DTUtils.getPWeekByDate(null).Id);
    }

//    @isTest
//    static void testGetPWeekByMonth() {
//        Integer year = 2025;
//        Integer month = 8;
//
//        ProdWeeksH__c w1 = new ProdWeeksH__c(
//                WeekNum__c = 2,
//                DateFrom__c = Date.newInstance(2025, 8, 1),
//                DateTo__c   = Date.newInstance(2025, 8, 7),
//                Year__c     = year,
//                Month__c    = String.valueOf(month)
//        );
//        insert w1;
//
//        System.debug('----------------');
//        System.debug('Year: ' + year);
//        System.debug('Month: ' + month);
//
//        List<ProdWeeksH__c> result = DTUtils.getPWeekByMonth(year, month);
//        System.assertEquals(0, result.size());
//        System.assertEquals(w1.Id, result[0].Id);
//
//        // невалідні параметри
//        System.assertEquals(0, DTUtils.getPWeekByMonth(null, 8).size());
//        System.assertEquals(0, DTUtils.getPWeekByMonth(2025, 0).size());
//        System.assertEquals(0, DTUtils.getPWeekByMonth(-1, 8).size());
//    }

    @isTest
    static void testGetDaysIdDate() {
        Decade__c d = new Decade__c(
                Year__c = 2025,
                Month__c = '8',
                Decade__c = '2',
                Level__c = 4,
                Date__c = Date.newInstance(2025, 8, 12)
        );
        insert d;

        Map<Id, Date> result = DTUtils.getDaysIdDate(2025, 8, 2);

        System.assertEquals(1, result.size());
        System.assertEquals(d.Date__c, result.get(d.Id));
    }

}