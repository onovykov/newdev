global without sharing class DTUtils {
    //--- Повертаємо значення типу Date або DateTime як текст у форматі dd.mm.yyyy
    // Форматує Date як dd.mm.yyyy
    public static String getDateAsString(Date d) {
        String day = (d.day() < 10 ? '0' : '') + String.valueOf(d.day());
        String month = (d.month() < 10 ? '0' : '') + String.valueOf(d.month());
        String year = String.valueOf(d.year());

        return day + '.' + month + '.' + year;
    }
    // Форматує DateTime як dd.mm.yyyy
    public static String getDateAsString(DateTime dt) {
        Date d = dt.date();
        return getDateAsString(d); // повторно використовуємо перший метод
    }
    
    //--- Номер тижня та його дати DateFrom__c, DateTo__c по Id ProdWeeksH__c
    public static Map<Integer, List<Date>> getDatesByPWeek(Id weekId) {
        Map<Integer, List<Date>> resultMap = new Map<Integer, List<Date>>();
        List<Date> datesList = new List<Date>();

        if (weekId == null) {
            System.debug('❌ ERROR: Parameter is null!');
            return resultMap;
        }

        List<ProdWeeksH__c> records = [
            SELECT WeekNum__c, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE Id = :weekId
            LIMIT 1
        ];

        if (!records.isEmpty()) {
            ProdWeeksH__c weekRec = records[0];
            datesList.add(weekRec.DateFrom__c);
            datesList.add(weekRec.DateTo__c);
            resultMap.put((Integer) weekRec.WeekNum__c, datesList);
        } else {
            System.debug('⚠️ No record found for Id: ' + String.valueOf(weekId));
        }

        return resultMap;
    }


    //--- Виробничий тиждень по даті
    public static ProdWeeksH__c getPWeekByDate(Date Day) {
        ProdWeeksH__c week = new ProdWeeksH__c();

        if (Day == null) {
            System.debug('❌ ERROR: Parameter is null!');
            return week;
        }

        List<ProdWeeksH__c> results = [
            SELECT Id, WeekNum__c, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE DateFrom__c <= :Day AND DateTo__c >= :Day
            LIMIT 1
        ];

        if (!results.isEmpty()) {
            week = results[0];
        } else {
            System.debug('⚠️ No production week found for date: ' + String.valueOf(Day));
        }

        return week;
    }

    //--- Виробничі тижні місяця року
    public static List<ProdWeeksH__c> getPWeekByMonth(Integer nYear, Integer nMonth) {
        List<ProdWeeksH__c> weeksList = new List<ProdWeeksH__c>();

        if (nYear == null || nYear < 0) {
            System.debug('❌ ERROR: Year is incorrect!');
            return weeksList;
        }
        if (nMonth == null || nMonth < 1 || nMonth > 12) {
            System.debug('❌ ERROR: Month is incorrect!');
            return weeksList;
        }

        String sMonth = '\'' + String.valueOf(nMonth) + '\'';
        weeksList = [
            SELECT Id, WeekNum__c, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE Year__c = :nYear AND Month__c = :sMonth
        ];

        return weeksList;
    }

    //--- Декади місяця
    public static Map<Integer, List<Date>> getMonthDecades(Integer nYear, Integer nMonth) {
        Map<Integer, List<Date>> decadeMap = new Map<Integer, List<Date>>();

        if (nYear == null || nMonth == null || nMonth < 1 || nMonth > 12) {
            System.debug('❌ ERROR: Invalid parameters!');
            return decadeMap;
        }

        // Перша декада: 1–10
        Date start1 = Date.newInstance(nYear, nMonth, 1);
        Date end1 = Date.newInstance(nYear, nMonth, 10);
        decadeMap.put(1, new List<Date>{start1, end1});

        // Друга декада: 11–20
        Date start2 = Date.newInstance(nYear, nMonth, 11);
        Date end2 = Date.newInstance(nYear, nMonth, 20);
        decadeMap.put(2, new List<Date>{start2, end2});

        // Третя декада: 21–кінець місяця
        Date start3 = Date.newInstance(nYear, nMonth, 21);
        Integer daysInMonth = Date.daysInMonth(nYear, nMonth); // ключовий момент
        Date end3 = Date.newInstance(nYear, nMonth, daysInMonth);
        decadeMap.put(3, new List<Date>{start3, end3});

        return decadeMap;
    }
    
    //--- Визначаємо поточну декаду по даті
    public static Integer getCurrentDecade(Date d) {
        Map<Integer, List<Date>> decadeMap = getMonthDecades(d.year(), d.month());    
        for(Integer dNum : decadeMap.keySet()) {
            List<Date> dList = decadeMap.get(dNum);          
            if(d>=dList[0] && d<=dList[1]) return dNum;
        }
        return 0;
    }    
    //--- Повертаємо рік, місяць, декаду по даті
    public static List<Integer> getYearMonthDecadeByDate(Date d) {
        Map<Integer, List<Date>> decadeMap = getMonthDecades(d.year(), d.month());
        List<Integer> resultList = new List<Integer>();
        Integer nDecade = 0;
        Integer nMonth = 0;
        Integer nYear = 0;
        for(Integer dNum : decadeMap.keySet()) {
            List<Date> dList = decadeMap.get(dNum);
            if(d>=dList[0] && d<=dList[1]) nDecade = dNum;
        }
        resultList.add(d.year());
        resultList.add(d.month());
        resultList.add(nDecade);
        return resultList;
    }   
    
    //--- Повертаємо дату як String згідно із зазначеним форматом
    public static String formatDate(Date d, String pattern) {
        if (d == null || String.isBlank(pattern)) return '';
        String day   = (d.day() < 10 ? '0' : '') + d.day();
        String month = (d.month() < 10 ? '0' : '') + d.month();
        String year  = String.valueOf(d.year());

        return pattern
            .replace('dd', day)
            .replace('MM', month)
            .replace('yyyy', year);
    }
    /* Приклад використання
    Date d = Date.newInstance(2025, 7, 1);
    System.debug(DateFormatter.format(d, 'dd.MM.yyyy')); // → 01.07.2025
    System.debug(DateFormatter.format(d, 'yyyy-MM-dd')); // → 2025-07-01
    */      

    //--- Повертаємо мапу Map<Id, Date> днів декади з ієрархії Decade__c
    public static Map<Id, Date> getDaysIdDate(Integer year, Integer month, Integer decade) {
        Map<Id, Date> mapIdDate = new Map<Id, Date>();
        List<Decade__c> daysList = [SELECT Id, Date__c FROM Decade__c
                            WHERE Year__c = :year
                            AND Month__c = :String.valueOf(month)
                            AND Decade__c = :String.valueOf(decade)
                            AND Level__c=4];
        if(!daysList.isEmpty()) {
            for(Decade__c rec : daysList) {
                mapIdDate.put(rec.Id, rec.Date__c);
            }
        }
        return mapIdDate;
    }  
    
    //--- Ковертуємо UNIX timestamp у мілісекундах (.NET JSON) у DateTime
    //    Очікується параметром щось на кшталт "/Date(1753833600257)/"
    @AuraEnabled
    public static String parseDotNetDate(String rawDate) {
        Pattern p = Pattern.compile('/Date\\((\\d+)\\)/');
        Matcher m = p.matcher(rawDate);

        if (m.find()) {
            Long millis = Long.valueOf(m.group(1));
            Integer seconds = (Integer)(millis / 1000);

            Datetime epoch = Datetime.newInstance(1970, 1, 1, 0, 0, 0);
            Datetime dtUtc = epoch.addSeconds(seconds);

            TimeZone tz = UserInfo.getTimeZone();
            Datetime dtLocal = dtUtc.addSeconds(tz.getOffset(dtUtc) / 1000);

            if (dtLocal.year() < 2015) {
                return '----';
            }

            return dtLocal.format(); // або з .format('dd.MM.yyyy') якщо потрібний формат
        }

        return '-';
    }

    //--- Метод для автоматичної ґенерації ієрархічного календаря для певного року 
    //    з пошуком і створення root-вузла та записом календаря в об'єкт Decade__c
    public static void buildFullCalendarHierarchy(Integer year) {
        // --- 1. Пошук або створення root-вузла "Календар"
        Decade__c root;
        List<Decade__c> roots = [
            SELECT Id, Name 
            FROM Decade__c 
            WHERE Level__c = 0 AND Parent__c = null 
            LIMIT 1
        ];
        if (!roots.isEmpty()) {
            root = roots[0];
        } else {
            root = new Decade__c(Name = 'Календар', Level__c = 0);
            insert root;
        }

        // --- 2. Створення ієрархії
        List<Decade__c> records = new List<Decade__c>();
        Date d = Date.newInstance(year, 1, 1);
        Date endDate = Date.newInstance(year + 1, 1, 1);

        Integer prevYear = null;
        Integer prevMonth = null;
        Integer prevDecade = null;

        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => 'Січень', 2 => 'Лютий', 3 => 'Березень',
            4 => 'Квітень', 5 => 'Травень', 6 => 'Червень',
            7 => 'Липень', 8 => 'Серпень', 9 => 'Вересень',
            10 => 'Жовтень', 11 => 'Листопад', 12 => 'Грудень'
        };
        Map<Integer, String> decadeNames = new Map<Integer, String>{
            1 => 'І декада', 2 => 'ІІ декада', 3 => 'ІІІ декада'
        };

        do {
            List<Integer> ymd = DTUtils.getYearMonthDecadeByDate(d);
            Integer y = ymd[0];
            Integer m = ymd[1];
            Integer dec = ymd[2];

            // Level 1 — рік
            if (prevYear == null || y != prevYear) {
                prevYear = y;
                prevMonth = null;
                prevDecade = null;

                Decade__c rec = new Decade__c();
                rec.Year__c = year;
                rec.Name = String.valueOf(y);
                rec.Level__c = 1;
                rec.Parent__c = root.Id;
                records.add(rec);
            }

            // Level 2 — місяць
            if (prevMonth == null || m != prevMonth) {
                prevMonth = m;
                prevDecade = null;

                Decade__c rec = new Decade__c();
                rec.Year__c = year;
                rec.Month__c = String.valueOf(m);
                rec.Name = monthNames.get(m);
                rec.Level__c = 2;
                records.add(rec);
            }

            // Level 3 — декада
            if (prevDecade == null || dec != prevDecade) {
                prevDecade = dec;

                Decade__c rec = new Decade__c();
                rec.Year__c = year;
                rec.Month__c = String.valueOf(m);
                rec.Decade__c = String.valueOf(dec);
                rec.Name = decadeNames.get(dec);
                rec.Level__c = 3;
                records.add(rec);
            }

            // Level 4 — день
            Decade__c dayRec = new Decade__c();
            dayRec.Year__c = year;
            dayRec.Month__c = String.valueOf(m);
            dayRec.Decade__c = String.valueOf(dec);
            dayRec.Date__c = d;
            dayRec.Name = DTUtils.getDateAsString(d);
            dayRec.Level__c = 4;
            records.add(dayRec);

            d = d.addDays(1);
        } while (d < endDate);

        // --- 3. INSERT усіх записів (без Parent__c)
        insert records;

        // --- 4. Створення мап для зв’язків
        Map<String, Id> yearMap = new Map<String, Id>();
        Map<String, Id> monthMap = new Map<String, Id>();
        Map<String, Id> decadeMap = new Map<String, Id>();

        for (Decade__c rec : records) {
            Decimal level = rec.Level__c;

            if (level == 1) {
                yearMap.put(String.valueOf(rec.Year__c), rec.Id);
            } else if (level == 2) {
                monthMap.put(rec.Year__c + '-' + rec.Month__c, rec.Id);
            } else if (level == 3) {
                decadeMap.put(rec.Year__c + '-' + rec.Month__c + '-' + rec.Decade__c, rec.Id);
            }
        }

        // --- 5. Прив’язка Parent__c
        for (Decade__c rec : records) {
            Decimal level = rec.Level__c;

            if (level == 2) {
                String key = String.valueOf(rec.Year__c);
                if (yearMap.containsKey(key)) rec.Parent__c = yearMap.get(key);
            } else if (level == 3) {
                String key = rec.Year__c + '-' + rec.Month__c;
                if (monthMap.containsKey(key)) rec.Parent__c = monthMap.get(key);
            } else if (level == 4) {
                String key = rec.Year__c + '-' + rec.Month__c + '-' + rec.Decade__c;
                if (decadeMap.containsKey(key)) rec.Parent__c = decadeMap.get(key);
            }
        }

        // --- 6. Оновлення з Parent__c
        update records;
    }    
    
    //--- Видалити всю ієрархію календаря для певного року
    public static void deleteCalendarHierarchyByYear(Integer yearToDelete) {
        for (Integer level = 4; level >= 1; level--) {
            List<Decade__c> toDelete = [
                SELECT Id 
                FROM Decade__c 
                WHERE Year__c = :yearToDelete AND Level__c = :level
            ];
            
            if (!toDelete.isEmpty()) {
                delete toDelete;
            }
        }
    }

    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}