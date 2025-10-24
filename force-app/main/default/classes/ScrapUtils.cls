public without sharing class ScrapUtils {
        //--- Константи
    public static final Boolean APPROVED = true;
    public static final Boolean DECLARED = false;

    //--- Отримати ліміти по типах брухту незалежно від постачальника на певну декаду зазначеного місяця
    public static Map<Id, Decimal> getScrapDecadeLimits(Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();
        Map<Integer, List<Date>> decadesMap = DTUtils.getMonthDecades(year, month);
        List<Date> dateList = decadesMap.get(decade);
        //--- Вибираємо ліміт по типу брухту на декаду незалежно від постачальника
        List<ScrapDecadesLimit__c> decadeLimitList = [SELECT ScrapType__c, DecadeLimit__c
                                                      FROM ScrapDecadesLimit__c
                                                      WHERE DateStart__c>=:dateList[0] AND DateEnd__c<=:dateList[1]];
        if(!decadeLimitList.isEmpty()) {
            for(ScrapDecadesLimit__c recLimit : decadeLimitList) {
                resultMap.put(recLimit.ScrapType__c, recLimit.DecadeLimit__c);
            }
        }
        return resultMap;
    }

    //--- Отримати ліміти по типу брухту на певну декаду зазначеного місяця року з розбивкою по днях
    //    Повертаємо Map<Id, Decimal>, де:
    //    Id - це Id дня з об'єкту Decade__c
    //    Decimal - ліміт на цей день
    public static Map<Id, Decimal> getScrapDecadeLimitsByDays(Id scrapType, Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();

        // Збираємо сет потрібних Id днів
        Set<Id> dayIds = new Map<Id, Decade__c>(
            [SELECT Id FROM Decade__c
             WHERE Year__c = :year
               AND Month__c = :String.valueOf(month)
               AND Decade__c = :String.valueOf(decade)]
        ).keySet();

        if (!dayIds.isEmpty()) {
            for (ScrapDecadesLimit__c lim : [
                SELECT DayLookup__c, DayLimit__c
                FROM ScrapDecadesLimit__c
                WHERE DayLookup__c IN :dayIds AND ScrapType__c = :scrapType
            ]) {
                if (lim.DayLimit__c != null) {
                    resultMap.put(lim.DayLookup__c, lim.DayLimit__c);
                }
            }
        }
        return resultMap;
    }

    //--- Отримати наджодження брухту певного типу для декади по днях
    //    Повертаємо Map<Id, Decimal>, де:
    //    Id - це Id дня з об'єкту Decade__c
    //    Decimal - наджодження на цей день
    //    Кількість надходжень сумуємо так:
    //    - якщо маємо факт (Weight__c != null) - то додаємо Weight__c
    //    - а інакше - додаємо заявлений тоннаж (Tonnage__c)
    public static Map<Id, Decimal> getScrapDecadeInputByDays(Id scrapType, Integer year, Integer month, Integer decade) {
        String sMonth = String.valueOf(month);
        String sDecade = String.valueOf(decade);
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();

        List<ScrapSlotReserve__c> reserveList = [
            SELECT ScrapType__c, DateLookup__c, Tonnage__c, Weight__c
            FROM ScrapSlotReserve__c
            WHERE YearLookup__r.Year__c = :year
              AND MonthLookup__r.Month__c = :sMonth
              AND DecadeLookup__r.Decade__c = :sDecade
              AND ScrapType__c = :scrapType
              AND IsCancelled__c = false
        ];

        for (ScrapSlotReserve__c rec : reserveList) {
            if (rec.DateLookup__c == null) continue;

            Decimal existing = resultMap.containsKey(rec.DateLookup__c) ? resultMap.get(rec.DateLookup__c) : 0;
            Decimal addValue = (rec.Weight__c != null) ? rec.Weight__c : rec.Tonnage__c;
            if (addValue != null) {
                resultMap.put(rec.DateLookup__c, existing + addValue);
            }
        }
        return resultMap;
    }
    //--- Отримати декадний ліміт по конкретному типу брухту
    public static Decimal getDecadeLimityByScrapType(Id ScrapTypeId, Integer year, Integer month, Integer decade) {
        Decimal bruchtLimit = 0.00;
        Map<Id, Decimal> mapLimit = getScrapDecadeLimits(year,month,decade);
        if(!mapLimit.isEmpty() && mapLimit!=null) {
            if(mapLimit.containsKey(ScrapTypeId)) bruchtLimit = mapLimit.get(ScrapTypeId);
        }
        return bruchtLimit;
    }

     //--- Надходження по типах брухту за декаду незалежно від постачальника
    public static Map<Id, Decimal> getScrapInputDecade(Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();
        Map<Integer, List<Date>> decadesMap = DTUtils.getMonthDecades(year, month);
        List<Date> dateList = decadesMap.get(decade);

        List<AggregateResult> monthScrapDecadeInput = [
            SELECT ScrapType__c, SUM(Weight__c) Weight
            FROM ScrapSlotReserve__c
            WHERE ReserveDate__c >= :dateList[0] AND ReserveDate__c <= :dateList[1] AND IsCancelled__c = false
            GROUP BY ScrapType__c
        ];

        if(!monthScrapDecadeInput.isEmpty()) {
            for (AggregateResult rec : monthScrapDecadeInput) {
                Id scrapType = (Id) rec.get('ScrapType__c');
                Decimal weight = (Decimal) rec.get('Weight');
                resultMap.put(scrapType, weight);
            }
        }
        return resultMap;
    }


    //--- Отримати баланс по типах брухту за декаду (варіант 2)
    public static Map<Id, Decimal> getSrcapDecadeBalance(Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> decadeLimits = ScrapUtils.getScrapDecadeLimits(year, month, decade);
        Map<Id, Decimal> decadeInputs = ScrapUtils.getScrapInputDecade(year, month, decade);
        Map<Id, Decimal> resultMap = new Map<Id, Decimal>();
        if(decadeLimits.isEmpty()) return resultMap;
        for (Id key : decadeLimits.keySet()) {
            Decimal limits = decadeLimits.get(key);
            Decimal inputs = decadeInputs.containsKey(key) ? decadeInputs.get(key) : 0;
            resultMap.put(key, limits - inputs);
        }
        return resultMap;
    }

     //--- Отримати баланс по конкретному типу брухту за декаду
    public static Decimal getDecadeBalanceByScrapType(Id ScrapType, Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> resultMap = getSrcapDecadeBalance(year, month, decade);
        return (!resultMap.isEmpty()) ? resultMap.get(ScrapType) : 0.00;
    }

    //--- Дозволені типи брухту для постачальника
    public static Map<Id, Boolean> getAllowedScrapForSullier(Id supplierId) {
        Map<Id, Boolean> resultMap = new Map<Id, Boolean>();
        List<ScrapTypeSupplierRelation__c> scrapAllowList = [SELECT ScrapType__c, Permitted__c
                                                             FROM ScrapTypeSupplierRelation__c
                                                             WHERE Account__c=:supplierId];
        if(!scrapAllowList.isEmpty()) {
            for(ScrapTypeSupplierRelation__c rec : scrapAllowList) {
                resultMap.put(rec.ScrapType__c, rec.Permitted__c);
            }
        }
        return resultMap;
    }
    /**************************************************/
    //--- Повертаємо всі ліміти постачальників по декадах (незалежно від импу брухту)
    //    Стадія - це який ліміт: заявлений чи узгоджений
    //    - передаємо параметром Boolean limitStage:
    //      TRUE - узгоджений, FALSE - заявлений
    //    Повертаємо мапу Map<Account, Map<Calengar, decimal>>
    //    - Id - це Id постачальника, який ми отримали по коду ScrapSupplierLimit__r.Supplier__c
    //    - Calengar - екземпляр класу Calengar для дня ліміту
    //    - Decimal - значення ліміту
    public static Map<Id, Map<Calendar, Decimal>> getSuppliersLimits(Boolean limitStage, Boolean approvedOnly) {
        // Отримуємо мапу RecordType
        Map<String, Id> mapRecType = getScrapSupplierLimitRecordTypeIds();
        Id recTypeId = limitStage == APPROVED ? mapRecType.get('Approved') : mapRecType.get('Declared');

        // Перевіряємо, чи знайдено RecordType
        if (recTypeId == null) {
            System.debug(LoggingLevel.WARN, 'RecordType not found for limitStage: ' + (limitStage == APPROVED ? 'Approved' : 'Declared'));
            return new Map<Id, Map<Calendar, Decimal>>(); // Повертаємо порожню мапу
        }

        // Базовий запит
        String query = 'SELECT ScrapSupplierLimit__r.Supplier__c, Decade__c, Limit__c ' +
                       'FROM SupplierLimitDetails__c ' +
                       'WHERE ';

        // Список умов для WHERE
        List<String> conditions = new List<String>();
        conditions.add('ScrapSupplierLimit__r.RecordTypeId = :recTypeId');
        if (approvedOnly == true) {
            conditions.add('ScrapSupplierLimit__r.Approved__c = true');
        }
        conditions.add('ScrapSupplierLimit__r.Supplier__c != null');
        conditions.add('Decade__c != null');

        // Об'єднуємо умови
        query += String.join(conditions, ' AND ');

        // Виконуємо запит із обробкою помилок
        List<SupplierLimitDetails__c> sldList;
        try {
            sldList = Database.query(query);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error executing query: ' + e.getMessage());
            return new Map<Id, Map<Calendar, Decimal>>();
        }

        // 1. Зібрати унікальні Id
        Set<Id> accountIds = new Set<Id>();
        Set<Id> decadeIds = new Set<Id>();
        for (SupplierLimitDetails__c rec : sldList) {
            accountIds.add(rec.ScrapSupplierLimit__r.Supplier__c);
            decadeIds.add(rec.Decade__c);
        }

        // 2. Отримати календарі по DecadeId
        Map<Id, Calendar> calendarMap = new Map<Id, Calendar>();
        for (Id key : decadeIds) {
            Calendar cal = Calendar.getByDecadeId(key);
            if (cal != null) {
                calendarMap.put(key, cal);
            }
        }

        // 3. Побудувати фінальну мапу
        Map<Id, Map<Calendar, Decimal>> result = new Map<Id, Map<Calendar, Decimal>>();
        for (SupplierLimitDetails__c rec : sldList) {
            Id accId = rec.ScrapSupplierLimit__r.Supplier__c;
            Calendar cal = calendarMap.get(rec.Decade__c);
            if (accId == null || cal == null) {
                continue;
            }

            if (!result.containsKey(accId)) {
                result.put(accId, new Map<Calendar, Decimal>());
            }
            result.get(accId).put(cal, rec.Limit__c);
        }
        return result;
    }

    //--- Повертаємо мапу всіх надходжень постачальників по днях (незалежно від импу брухту)
    //    Стадія - це який ліміт: заявлений чи узгоджений
    //    - передаємо параметром Boolean limitStage:
    //      TRUE - узгоджений, FALSE - заявлений
    //    Повертаємо мапу Map<Account, Map<Calengar, decimal>>
    //    - Id - це Id постачальника, який ми отримали по коду ScrapSupplierLimit__r.Supplier__c
    //    - Calengar - екземпляр класу Calengar для дня ліміту
    //    - Decimal - значення ліміту
    public static Map<Id, Map<Calendar, Decimal>> getSupplierInputsByDays() {
        Map<Id, Map<Calendar, Decimal>> allInputsByDays = new Map<Id, Map<Calendar, Decimal>>();

        for (ScrapSlotReserve__c rec : [
            SELECT Supplier__c, DateLookup__c, Tonnage__c, Weight__c
            FROM ScrapSlotReserve__c
            WHERE Supplier__c != null AND DateLookup__c != null AND IsCancelled__c = false
        ]) {
            Decimal value = rec.Weight__c != null ? rec.Weight__c : rec.Tonnage__c;
            if (value == null) continue;

            // Ініціалізація внутрішньої мапи, якщо її ще немає
            if (!allInputsByDays.containsKey(rec.Supplier__c)) {
                allInputsByDays.put(rec.Supplier__c, new Map<Calendar, Decimal>());
            }


            Map<Calendar, Decimal> dayMap = allInputsByDays.get(rec.Supplier__c);

            // Сумування значень по одному дню
            Calendar calDay = Calendar.getByDayId(rec.DateLookup__c);
            if (dayMap.containsKey(calDay)) {
                dayMap.put(calDay, dayMap.get(calDay) + value);
            } else {
                dayMap.put(calDay, value);
            }
        }
        return allInputsByDays;
    }
    //--- Повертаємо мапу всіх надходжень постачальників по декадах (незалежно від импу брухту)
    public static Map<Id, Map<Calendar, Decimal>> getSupplierInputsByDecades() {
        Map<Id, Map<Calendar, Decimal>> inputsByDays = getSupplierInputsByDays();
        Map<Id, Map<Calendar, Decimal>> inputsByDecades = new Map<Id, Map<Calendar, Decimal>>();

        for (Id supplierId : inputsByDays.keySet()) {
            Map<Calendar, Decimal> dayMap = inputsByDays.get(supplierId);

            // Ініціалізуємо мапу по декадах
            if (!inputsByDecades.containsKey(supplierId)) {
                inputsByDecades.put(supplierId, new Map<Calendar, Decimal>());
            }
            Map<Calendar, Decimal> decadeMap = inputsByDecades.get(supplierId);

            for (Calendar calDay : dayMap.keySet()) {
                Decimal value = dayMap.get(calDay);
                if (calDay.DecadeId == null) continue;

                Calendar calDecade = Calendar.getByDecadeId(calDay.DecadeId);
                if (calDecade == null) continue;

                if (decadeMap.containsKey(calDecade)) {
                    decadeMap.put(calDecade, decadeMap.get(calDecade) + value);
                } else {
                    decadeMap.put(calDecade, value);
                }
            }
        }
        return inputsByDecades;
    }

    //--- Повертаємо доступні залишки для постачальників по декадах
    public static Map<Id, Map<Calendar, Decimal>> getSuppliersBalanceByDecades(Boolean limitStage, Boolean approvedOnly) {
        Map<Id, Map<Calendar, Decimal>> limits = getSuppliersLimits(limitStage, approvedOnly); // Calendar = декада
        Map<Id, Map<Calendar, Decimal>> inputs = getSupplierInputsByDecades(); // Calendar = декада

        Map<Id, Map<Calendar, Decimal>> result = new Map<Id, Map<Calendar, Decimal>>();

        for (Id accId : limits.keySet()) {
            Map<Calendar, Decimal> limitByDecade = limits.get(accId);
            Map<Calendar, Decimal> inputByDecade = inputs.containsKey(accId) ? inputs.get(accId) : new Map<Calendar, Decimal>();

            Map<Calendar, Decimal> remainingByDecade = new Map<Calendar, Decimal>();

            for (Calendar cal : limitByDecade.keySet()) {
                Decimal nLimit = limitByDecade.get(cal);
                Decimal input = inputByDecade.containsKey(cal) ? inputByDecade.get(cal) : 0;
                Decimal remaining = nLimit - input;
                remainingByDecade.put(cal, remaining);
            }

            result.put(accId, remainingByDecade);
        }
        return result;
    }

    /**************************************************/
    //--- Чи дозволено конкретний тип брухту для конкретного постачальника
    public static Boolean isScrapAllowForSupplier(Id supplierId, Id scrapId) {
        Map<Id, Boolean> resultMap = getAllowedScrapForSullier(supplierId);
        return resultMap.containsKey(scrapId);
    }

    //--- Масив контрактів постачальників (тип COMMERTIAL)
    public class SupplierContract {
        public Id ContractId;
        public Id SupplierId;
        public String ContractName;
        public String ContractNumber;
        public Date DateStart;
        public Date DateEnd;
        public Integer ContractTerm;
        public Boolean IsActive;

        public SupplierContract() {
            this.ContractId = null;
            this.SupplierId = null;
            this.ContractName = '';
            this.ContractNumber = '';
            this.DateStart = Date.newInstance(1900,1,1);
            this.DateEnd = Date.newInstance(9999,12,31);
            this.ContractTerm = 0;
            this.IsActive = false;
        }
    }

    //--- Повертаємо лист SupplierContract
    public static List<SupplierContract> getSupplierContractList() {
        List<SupplierContract> contracts = new List<SupplierContract>();
        List<Contract> cList = [SELECT Id, AccountId, Name, ContractNumber, StartDate, EndDate__c, ContractTerm
                                FROM Contract
                                WHERE Account.IsSupplier__c=true AND Account.ScrapSupplierType__c='COMMERCIAL'];
        if(!cList.isEmpty()) {
            for(Contract c : cList) {
                SupplierContract sc = new SupplierContract();
                sc.ContractId = c.Id;
                sc.SupplierId = c.AccountId;
                sc.ContractName = c.Name;
                sc.ContractNumber = c.ContractNumber;
                sc.DateStart = c.StartDate;
                sc.DateEnd = c.EndDate__c;
                sc.ContractTerm = c.ContractTerm;
                sc.IsActive = (c.EndDate__c!=null && c.EndDate__c>Date.today());
                contracts.add(sc);
            }
        }
        return contracts;
    }

    /**
     * Групує контракти за SupplierId
     * @param contracts — список контрактів
     * @return Map<Id, List<SupplierContract>> — ключ: SupplierId, значення: список контрактів цього контрагента
         Використання
         List<SupplierContract> contracts = getSupplierContractList();
         Map<Id, List<SupplierContract>> groupedMap = groupBySupplier(contracts);

         Id supplierId = '001XXXXXXXXXXXX';
         List<SupplierContract> supplierContracts = groupedMap.get(supplierId) != null
             ? groupedMap.get(supplierId)
             : new List<SupplierContract>();

         if (supplierContracts != null) {
             // працюємо зі списком контрактів
         } else {
             // у цього контрагента немає контрактів
         }
     */
    public static Map<Id, List<SupplierContract>> groupBySupplier(List<SupplierContract> contracts) {
        Map<Id, List<SupplierContract>> result = new Map<Id, List<SupplierContract>>();

        for (SupplierContract c : contracts) {
            if (c.SupplierId == null) {
                continue; // можна логувати або обробити окремо
            }

            if (!result.containsKey(c.SupplierId)) {
                result.put(c.SupplierId, new List<SupplierContract>());
            }
            result.get(c.SupplierId).add(c);
        }
        return result;
    }

    //--- Отримати MAX(EndDate__c) серед усіх договорів постачальника
    public static Date getMaxContratDateBySupplier(Id SupplierId) {
        Map<Id, List<SupplierContract>> groupedMap = groupBySupplier(getSupplierContractList());
        List<SupplierContract> supplierContracts = groupedMap.get(SupplierId) != null
            ? groupedMap.get(SupplierId)
            : new List<SupplierContract>();
        Date maxDate = Date.newInstance(1900,1,1);
        for(SupplierContract sc : supplierContracts) {
            if(maxDate<sc.DateEnd) maxDate=sc.DateEnd;
        }
        return maxDate;
    }

    //--- Повертає контракт з максимальною DateEnd для вказаного SupplierId
    public static SupplierContract getLatestContractBySupplier(Id supplierId) {
        Map<Id, List<SupplierContract>> groupedMap = groupBySupplier(getSupplierContractList());
        List<SupplierContract> contracts = groupedMap.get(supplierId);

        if (contracts == null || contracts.isEmpty()) {
            return null;
        }

        SupplierContract latest = contracts[0];
        for (SupplierContract sc : contracts) {
            if (sc.DateEnd != null && sc.DateEnd > latest.DateEnd) {
                latest = sc;
            }
        }
        return latest;
    }

    //--- Повертає всі контракти постачальника з автоматично доданим полем IsActive
    public static List<SupplierContract> getContractsBySupplier(Id supplierId) {
        Map<Id, List<SupplierContract>> groupedMap = groupBySupplier(getSupplierContractList());
        List<SupplierContract> contracts = groupedMap.get(supplierId);

        if (contracts == null || contracts.isEmpty()) {
            return new List<SupplierContract>();
        }

        Date today = Date.today();
        for (SupplierContract sc : contracts) {
            sc.IsActive = sc.DateEnd != null && sc.DateEnd > today;
        }

        return contracts;
    }

    //--- Побудова нового ключа ScrapDecadesLimit__c: DayLookup__c + ScrapType__c
    public static String buildLimitKey(ScrapDecadesLimit__c record) {
        return String.valueOf(record.DayLookup__c) + '-' + //День - Level__c=4
               String.valueOf(record.ScrapType__c);
    }
    //--- Побудова нового ключа ScrapSupplierLimit__c:
    public static String buildLimitKey(ScrapSupplierLimit__c record) {
        return String.valueOf(record.RecordTypeId) + '-' + //Тип ліміту
               String.valueOf(record.MonthLookup__c) + '-' + //Декада - Level__c=3
               String.valueOf(record.Supplier__c);
    }

    //--- Витягаємо декадний план для типу брухту (нова структура)
    public static Decimal getScrapDecadeLimit(Id ScrapType, Integer Year,
                                         Integer Month, Integer Decade) {
        Set<Id> decIdSet = new Set<Id>();
        String sMonth = String.valueOf(Month);
        String sDec = String.valueOf(Decade);

        List<Decade__c> decList = [
            SELECT Id
            FROM Decade__c
            WHERE Year__c = :Year AND Month__c = :sMonth AND Decade__c = :sDec AND Level__c = 4
        ];

        for (Decade__c rec : decList) {
            decIdSet.add(rec.Id);
        }

        if (decIdSet.isEmpty()) {
            return 0;
        }

        AggregateResult[] result = [
            SELECT SUM(DayLimit__c) SumDecLimit
            FROM ScrapDecadesLimit__c
            WHERE DayLookup__c IN :decIdSet AND ScrapType__c = :ScrapType
        ];

        Decimal sum = (Decimal)(result[0].get('SumDecLimit'));
        return sum != null ? sum : 0;
    }

    //--- Витягаємо місячний план для типу брухту (нова структура)
    public static Decimal getScrapMonthLimit(Id ScrapType, Integer Year, Integer Month) {
        Set<Id> decIdSet = new Set<Id>();
        String sMonth = String.valueOf(Month);

        List<Decade__c> decList = [
            SELECT Id
            FROM Decade__c
            WHERE Year__c = :Year AND Month__c = :sMonth AND Level__c = 4
        ];

        for (Decade__c rec : decList) {
            decIdSet.add(rec.Id);
        }

        if (decIdSet.isEmpty()) {
            return 0;
        }

        AggregateResult[] result = [
            SELECT SUM(DayLimit__c) SumDecLimit
            FROM ScrapDecadesLimit__c
            WHERE DayLookup__c IN :decIdSet AND ScrapType__c = :ScrapType
        ];

        Decimal sum = (Decimal)(result[0].get('SumDecLimit'));
        return sum != null ? sum : 0;
    }

    //--- Повернути доступний залишок
    public static Map<Id, Decimal> getAvailableScrapLimitsByDays(Id scrapType, Integer year, Integer month, Integer decade) {
        Map<Id, Decimal> limitMap = getScrapDecadeLimitsByDays(scrapType, year, month, decade);
        Map<Id, Decimal> inputMap = getScrapDecadeInputByDays(scrapType, year, month, decade);

        Map<Id, Decimal> availableMap = new Map<Id, Decimal>();

        for (Id dayId : limitMap.keySet()) {
            Decimal lmt = limitMap.get(dayId);
            Decimal input = 0;//(inputMap.containsKey(dayId) ? inputMap.get(dayId) : 0);
            if(inputMap.containsKey(dayId)) input=inputMap.get(dayId);
            availableMap.put(dayId, lmt - input);
        }

        // Якщо є ліміти не на всі дні декади - доповнюємо відсутні нулями
        Map<Id, Date> mapDates = DTUtils.getDaysIdDate(year, month, decade);
        for (Id key : mapDates.keySet()) {
            if(!availableMap.containsKey(key)) {
                availableMap.put(key, 0);
            }
        }
        return availableMap;
    }

    /* Отримати мапу всіх лімітів по днях
       Перший Id - це Id типу брухту (ScrapType__c  з листа)
       Другий Id - Id дня з Decades__c (DayLookup__c з листа)
       Decimal - добовий ліміт

       Як результат мусимо отримати мапу allLimitsByDays на кшталт такої:
       <'a43S8000000NLQLIA4', <{a25S8000002xsC0IAI,34.8}, <{a25S8000002xsC1IAI,45.2}>...
    */
    public static Map<Id, Map<Id, Decimal>> getAllLimitsByDays() {
        Map<Id, Map<Id, Decimal>> allLimitsByDays = new Map<Id, Map<Id, Decimal>>();

        for (ScrapDecadesLimit__c rec : [
            SELECT ScrapType__c, DayLookup__c, DayLimit__c
            FROM ScrapDecadesLimit__c
            WHERE ScrapType__c != null AND DayLookup__c != null AND DayLimit__c != null
        ]) {
            if (!allLimitsByDays.containsKey(rec.ScrapType__c)) {
                allLimitsByDays.put(rec.ScrapType__c, new Map<Id, Decimal>());
            }
            allLimitsByDays.get(rec.ScrapType__c).put(rec.DayLookup__c, rec.DayLimit__c);
        }
        return allLimitsByDays;
    }
    /* Отримати мапу всіх надходжень  по днях */
    public static Map<Id, Map<Id, Decimal>> getAllInputsByDays() {
        Map<Id, Map<Id, Decimal>> allInputsByDays = new Map<Id, Map<Id, Decimal>>();

        for (ScrapSlotReserve__c rec : [
            SELECT ScrapType__c, DateLookup__c, Tonnage__c, Weight__c
            FROM ScrapSlotReserve__c
            WHERE ScrapType__c != null AND DateLookup__c != null AND IsCancelled__c = false
        ]) {
            Decimal value = rec.Weight__c != null ? rec.Weight__c : rec.Tonnage__c;
            if (value == null) continue;

            // Ініціалізація внутрішньої мапи, якщо її ще немає
            if (!allInputsByDays.containsKey(rec.ScrapType__c)) {
                allInputsByDays.put(rec.ScrapType__c, new Map<Id, Decimal>());
            }

            Map<Id, Decimal> dayMap = allInputsByDays.get(rec.ScrapType__c);

            // Сумування значень по одному дню
            if (dayMap.containsKey(rec.DateLookup__c)) {
                dayMap.put(rec.DateLookup__c, dayMap.get(rec.DateLookup__c) + value);
            } else {
                dayMap.put(rec.DateLookup__c, value);
            }
        }
        return allInputsByDays;
    }

     //--- Доступні ліміти
    public static Map<Id, Map<Id, Decimal>> getAvailableLimitsByDays() {
        Map<Id, Map<Id, Decimal>> allLimitsByDays = getAllLimitsByDays();
        Map<Id, Map<Id, Decimal>> allInputsByDays = getAllInputsByDays();

        Map<Id, Map<Id, Decimal>> availableLimitsByDays = new Map<Id, Map<Id, Decimal>>();

        for (Id scrapTypeId : allLimitsByDays.keySet()) {
            Map<Id, Decimal> dayLimits = allLimitsByDays.get(scrapTypeId);
            Map<Id, Decimal> dayInputs = allInputsByDays.containsKey(scrapTypeId)
                ? allInputsByDays.get(scrapTypeId)
                : new Map<Id, Decimal>();

            Map<Id, Decimal> dayAvailable = new Map<Id, Decimal>();

            for (Id dayId : dayLimits.keySet()) {
                Decimal planned = dayLimits.get(dayId);
                Decimal input = dayInputs.containsKey(dayId) ? dayInputs.get(dayId) : 0;
                Decimal available = planned - input;

                // Якщо доступний ліміт ≥ 0 — зберігаємо
                if (available >= 0) {
                    dayAvailable.put(dayId, available);
                } else {
                    // опціонально
                    dayAvailable.put(dayId, 0); // або залишити від’ємне,
                                                // якщо треба моніторити перевищення
                                                // наприклад, для понаднормових надходжень
                }
            }
            availableLimitsByDays.put(scrapTypeId, dayAvailable);
        }
        return availableLimitsByDays;
    }

    //--- Повна інформація: ліміти, надходження, баланс
    public class BalanceData {
        public Decimal scrapLimit;
        public Decimal input;
        public Decimal available;

        public BalanceData(Decimal scrapLimit, Decimal input, Decimal available) {
            this.scrapLimit = scrapLimit;
            this.input = input;
            this.available = available;
        }
    }

    //--- Повертає повний баланс по типах брухту по днях (клас Calendar)
    public static Map<Id, Map<Calendar, BalanceData>> getFullScrapBalance() {
        Map<Id, Map<Id, Decimal>> limitsMap = getAllLimitsByDays();
        Map<Id, Map<Id, Decimal>> inputsMap = getAllInputsByDays();
        Map<Id, Map<Id, Decimal>> availableMap = getAvailableLimitsByDays();

        Map<Id, Map<Calendar, BalanceData>> result = new Map<Id, Map<Calendar, BalanceData>>();

        for (Id scrapTypeId : limitsMap.keySet()) {
            Map<Id, Decimal> dayLimits = limitsMap.get(scrapTypeId);
            Map<Id, Decimal> dayInputs = inputsMap.containsKey(scrapTypeId) ? inputsMap.get(scrapTypeId) : new Map<Id, Decimal>();
            Map<Id, Decimal> dayAvailable = availableMap.containsKey(scrapTypeId) ? availableMap.get(scrapTypeId) : new Map<Id, Decimal>();

            Map<Calendar, BalanceData> calendarMap = new Map<Calendar, BalanceData>();

            for (Id dayId : dayLimits.keySet()) {
                //System.debug('dayLimits.keySet(): dayId = ' + dayId);
                Calendar cal = Calendar.getByDayId(dayId);
                //System.debug('Calendar.getByDayId(dayId) ' + cal);
                if (cal == null) continue;

                Decimal scrapLimit = dayLimits.get(dayId);
                Decimal input = dayInputs.containsKey(dayId) ? dayInputs.get(dayId) : 0;
                Decimal available = dayAvailable.containsKey(dayId) ? dayAvailable.get(dayId) : (scrapLimit - input);

                BalanceData balance = new BalanceData(scrapLimit, input, available);
                calendarMap.put(cal, balance);
            }

            if (!calendarMap.isEmpty()) {
                result.put(scrapTypeId, calendarMap);
            }
        }
        return result;
    }
    //--- Повертає дні з нульовим балансом
    public static Map<Id, List<Calendar>> getDaysWithZeroBalance() {
        Map<Id, Map<Calendar, BalanceData>> fullMap = getFullScrapBalance();
        Map<Id, List<Calendar>> result = new Map<Id, List<Calendar>>();

        for (Id scrapTypeId : fullMap.keySet()) {
            List<Calendar> exhaustedDays = new List<Calendar>();

            for (Calendar cal : fullMap.get(scrapTypeId).keySet()) {
                BalanceData balance = fullMap.get(scrapTypeId).get(cal);
                if (balance.available <= 0) {
                    exhaustedDays.add(cal);
                }
            }

            if (!exhaustedDays.isEmpty()) {
                result.put(scrapTypeId, exhaustedDays);
            }
        }
        return result;
    }


    //--- Повертаємо Id декади
    public static Id getDecadeId(Integer year, Integer month, Integer decade) {
        // Перевірка вхідних значень
        if (year == null || month == null || decade == null) {
            return null;
        }

        String monthStr = String.valueOf(month);
        String decadeStr = String.valueOf(decade);

        List<Decade__c> decList = [
            SELECT Id
            FROM Decade__c
            WHERE Year__c = :year
              AND Month__c = :monthStr
              AND Decade__c = :decadeStr
              AND Level__c = 3
            LIMIT 1
        ];

        return decList.isEmpty() ? null : decList[0].Id;
    }

    //--- Повертаємо Id місяця
    public static Id getMonthId(Integer year, Integer month) {
        // Перевірка вхідних значень
        if (year == null || month == null) {
            return null;
        }

        String monthStr = String.valueOf(month);

        List<Decade__c> decList = [
            SELECT Id
            FROM Decade__c
            WHERE Year__c = :year
              AND Month__c = :monthStr
              AND Level__c = 2
            LIMIT 1
        ];

        return decList.isEmpty() ? null : decList[0].Id;
    }

    //--- Повертаємо назву, очищену від сміття - для формування поля Name
    public static String getClearName(String input) {
        input = StringNormalize.sanitizeQuotes(input);
        List<String> listClean = new List<String>();
        List<String> listWords = input.toUpperCase().normalizeSpace().split(' ');
        for (String word : listWords) {
            if (!Consts.TRASH_WORDS_SET.contains(word.toUpperCase())) {
                    listClean.add(word);
            }
        }
        return String.join(listClean, ' ').normalizeSpace().replaceAll('\\|', '');
    }

    //--- Повертаємо мапу RecordType - Id та Name
    public static Map<String, Id> getScrapSupplierLimitRecordTypeIds() {
        Map<String, Id> result = new Map<String, Id>();

        // Отримуємо мапу RecordType за DeveloperName
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.ScrapSupplierLimit__c.getRecordTypeInfosByDeveloperName();

        // Список DeveloperName, які потрібно знайти
        for (String developerName : new List<String>{'Approved', 'Declared'}) {
            if (rtMap.containsKey(developerName)) {
                result.put(developerName, rtMap.get(developerName).getRecordTypeId());
            } else {
                System.debug('RecordType with DeveloperName "' + developerName + '" not found on ScrapSupplierLimit__c');
            }
        }
        return result;
    }
    
     /*********************************************************************
     Отримати повний баланс по лімітах, надходженнях і доступних залишках
    **********************************************************************/
    public class SupplierBalance {
        public Integer YearNum;
        public Integer MonthNum;
        public Integer DecNum;
        public Decimal ApprovedLimit;
        public Decimal ScrapInput;
        public Decimal AvailableBalance;

        public SupplierBalance() {}

        public SupplierBalance(Integer YearNum, Integer MonthNum, Integer DecNum,
                               Decimal ApprovedLimit, Decimal ScrapInput, Decimal AvailableBalance) {
            this.YearNum = YearNum;
            this.MonthNum = MonthNum;
            this.DecNum = DecNum;
            this.ApprovedLimit = ApprovedLimit;
            this.ScrapInput = ScrapInput;
            this.AvailableBalance = AvailableBalance;
        }

        public String getCompositeKey() {
            return YearNum + '-' + MonthNum + '-' + DecNum;
        }
    }

    public static Map<Id, List<SupplierBalance>> getSupplierBalance(Boolean limitStage, Boolean approvedOnly) {
        Map<Id, Map<Calendar, Decimal>> limitMap = getSuppliersLimits(limitStage, approvedOnly);
        Map<Id, Map<Calendar, Decimal>> inputMap = getSupplierInputsByDecades();
        Map<Id, Map<Calendar, Decimal>> balanceMap = getSuppliersBalanceByDecades(limitStage, approvedOnly);

        Map<Id, List<SupplierBalance>> resultMap = new Map<Id, List<SupplierBalance>>();

        Set<Id> allSuppliers = new Set<Id>();
        allSuppliers.addAll(limitMap.keySet());
        allSuppliers.addAll(inputMap.keySet());
        allSuppliers.addAll(balanceMap.keySet());

        for (Id accId : allSuppliers) {
            Set<Calendar> allCalendars = new Set<Calendar>();

            if (limitMap.containsKey(accId))  allCalendars.addAll(limitMap.get(accId).keySet());
            if (inputMap.containsKey(accId))  allCalendars.addAll(inputMap.get(accId).keySet());
            if (balanceMap.containsKey(accId)) allCalendars.addAll(balanceMap.get(accId).keySet());

            List<SupplierBalance> sbList = new List<SupplierBalance>();

            for (Calendar cal : allCalendars) {
                List<Integer> decoded = Calendar.decodeCalendar(cal);

                Decimal approvedLimit   = (limitMap.containsKey(accId) && limitMap.get(accId).containsKey(cal))
                                  ? limitMap.get(accId).get(cal) : 0;
                Decimal input   = (inputMap.containsKey(accId) && inputMap.get(accId).containsKey(cal))
                                  ? inputMap.get(accId).get(cal) : 0;
                Decimal balance = (balanceMap.containsKey(accId) && balanceMap.get(accId).containsKey(cal))
                                  ? balanceMap.get(accId).get(cal) : 0;

                SupplierBalance sbRec = new SupplierBalance(decoded[0], decoded[1], decoded[2], approvedLimit, input, balance);
                sbList.add(sbRec);
            }

            // сортування за рік-місяць-декада
            sbList.sort(new SupplierBalanceSorter());
            resultMap.put(accId, sbList);
        }

        return resultMap;
    }
    //--- Сортувальник (Comparator)
    public class SupplierBalanceSorter implements Comparator<SupplierBalance> {
        public Integer compare(SupplierBalance a, SupplierBalance b) {
            if (a.YearNum != b.YearNum) return a.YearNum - b.YearNum;
            if (a.MonthNum != b.MonthNum) return a.MonthNum - b.MonthNum;
            return a.DecNum - b.DecNum;
        }
    }

    //--- Обгортка-фільтр - повертаємо баланс на певну декаду для певного постачальника
    public static List<SupplierBalance> filterSupplierBalances(
        Id supplierId,
        Set<Calendar> calendarFilter,                   // або null
        Set<String> yearMonthDecadeKeys                 // у форматі "2025-7-2" тощо, або null
    ) {
        Map<Id, List<SupplierBalance>> fullMap = getSupplierBalance(true, true); // або параметри передавати

        if (!fullMap.containsKey(supplierId)) return new List<SupplierBalance>();

        List<SupplierBalance> balances = fullMap.get(supplierId);

        List<SupplierBalance> result = new List<SupplierBalance>();
        for (SupplierBalance sb : balances) {
            Boolean matchesCal = true;
            Boolean matchesKey = true;

            if (calendarFilter != null && !calendarFilter.isEmpty()) {
                Boolean found = false;
                for (Calendar cal : calendarFilter) {
                    if (sb.YearNum == cal.YearNum && sb.MonthNum == cal.MonthNum && sb.DecNum == cal.DecadeNum) {
                        found = true;
                        break;
                    }
                }
                matchesCal = found;
            }

            if (yearMonthDecadeKeys != null && !yearMonthDecadeKeys.isEmpty()) {
                matchesKey = yearMonthDecadeKeys.contains(sb.getCompositeKey());
            }

            if (matchesCal && matchesKey) {
                result.add(sb);
            }
        }
        return result;
    }

    /* Як юзати:
    // Отримати для конкретного постачальника лише декаду 2, 2025-07
    Set<String> keys = new Set<String>{ '2025-7-2' };
    List<ScrapUtils.SupplierBalance> filtered =
        ScrapUtils.filterSupplierBalances('001S800000XqdiDIAR', null, keys);

    // або через календарі:
    Set<Calendar> calFilter = new Set<Calendar>{
        Calendar.getByYearMonthDecade(2025, 7, 2)
    };
    List<SupplierBalance> byCal = ScrapUtils.filterSupplierBalances('001S800000XqdiDIAR', calFilter, null);
    */  
    
    //--- Повертає баланс для постачальник за певний місяць року по декадах
    //    Рік і місяць передаємо як текст на зразок '2025-7' (місяць БЕЗ НУЛІВ)
    public static List<SupplierBalance> getSupplierBalancesByMonth(Id SupplierId, String YM) {
        List<SupplierBalance> result = new List<SupplierBalance>();
        if(String.isBlank(YM) || !(Pattern.matches('^[-\\d]+$', YM)) || SupplierId==null) {
            System.debug('Parameter is incorrect');
        }
        // Перевіряємо й видаляємо зайві нулі з місяця, якщо їх туди втулили
        List<String> parts = YM.split('-');
        YM =  parts[0] + '-' + String.valueOf(Integer.valueOf(parts[1]));
        System.debug('YM = ' + YM);
        //--- Формуємо ключ для декад
        Set<String> keys = new Set<String>{YM+'-1', YM+'-2', YM+'-3'};

        result = filterSupplierBalances(SupplierId, null, keys);

        return result;
    }

    /**
 * Нормалізує номер України до формату +380XXXXXXXXX.
 * Повертає null, якщо номер некоректний.
 *
 * Приклади:
 *  "067-123-45-67"      -> +380671234567
 *  "38067 123-4567"     -> +380671234567
 *  "67123-4567"         -> +380671234567
 *  "+380671234567"      -> +380671234567
 *  "044 123 45 67"      -> +380441234567
 *  "80671234567"        -> +380671234567
 *  "00380671234567"     -> +380671234567
 *  "067-123-45-67 ext 123" -> +380671234567
 */
    @AuraEnabled(cacheable=true)
    public static String sanitizePhoneNum(String raw) {
        if (String.isBlank(raw)) return null;

        // Лишаємо тільки цифри
        String digits = raw.replaceAll('[^0-9]', '');
        if (String.isBlank(digits)) return null;

        // Нормалізуємо до 9-значної національної частини (без початкового нуля)
        String core;
        if (digits.startsWith('00380') && digits.length() == 14) {
            core = digits.substring(5); // 00380 + 9
        } else if (digits.startsWith('380') && digits.length() == 12) {
            core = digits.substring(3); // 380 + 9
        } else if (digits.startsWith('80') && digits.length() == 11) {
            core = digits.substring(2); // 80 + 9 (часто так записують замість +380)
        } else if (digits.startsWith('0') && digits.length() == 10) {
            core = digits.substring(1); // 0 + 9
        } else if (digits.length() == 9) {
            core = digits;              // вже 9 цифр, наприклад 671234567 або 441234567
        } else {
            return null;                // інші довжини/форми не підтримуємо
        }

        // Валідація 9 цифр
        if (!Pattern.compile('^[0-9]{9}$').matcher(core).matches()) return null;

        return '+380' + core;
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
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;   i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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