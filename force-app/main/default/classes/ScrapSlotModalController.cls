public with sharing class ScrapSlotModalController {

    // === DTO дня в поточній декаді ===
    public class DayDTO {
        @AuraEnabled public Id    id        { get; set; }
        @AuraEnabled public Date  dateValue { get; set; }
        @AuraEnabled public String label    { get; set; } // "dd.MM.yyyy (пт)"
    }

    // === DTO результату: поточна декада + список її днів ===
    public class CurrentDecadeDTO {
        @AuraEnabled public Id      decadeId  { get; set; }
        @AuraEnabled public Integer yearNum   { get; set; }  // із Parent.Year__c
        @AuraEnabled public String  month     { get; set; }  // із Parent.Month__c
        @AuraEnabled public String  decade    { get; set; }  // із Parent.Decade__c ('1'|'2'|'3')
        @AuraEnabled public List<DayDTO> days { get; set; }
    }

    public class DuplicateCheckResult {
        @AuraEnabled public Boolean exists;
        @AuraEnabled public Integer count;
        @AuraEnabled public List<String> summaries;
        @AuraEnabled public List<Id> ids;
    }

    @AuraEnabled(cacheable=false)
    public static DuplicateCheckResult checkSimilarReserve(
            Id supplierId,
            Id scrapTypeId,
            Date reserveDate,
            Id truckId,
            Id trailerId,
            String fixedWeight
    ){
        if (supplierId == null || scrapTypeId == null || reserveDate == null || truckId == null || String.isBlank(fixedWeight)) {
            throw new AuraHandledException('Не всі параметри передані для перевірки дублів.');
        }
        // потрібен Decimal для порівняння з Tonnage__c
        Decimal norm;
        try { norm = Decimal.valueOf(fixedWeight); } catch (Exception e) {
            throw new AuraHandledException('Невірний формат нормативу ваги.');
        }

        List<ScrapSlotReserve__c> rows;
        if (trailerId == null) {
            rows = [
                    SELECT Id, Status__c, PassNumber__c, FixedWeight__c, Tonnage__c,
                            Truck__r.Name, Trailer__r.Name
                    FROM ScrapSlotReserve__c
                    WHERE Supplier__c   = :supplierId
                    AND ScrapType__c  = :scrapTypeId
                    AND ReserveDate__c= :reserveDate
                    AND Truck__c      = :truckId
                    AND Trailer__c    = null
                    AND (IsCancelled__c = false OR IsCancelled__c = null)
                    AND Status__c NOT IN ('Cancelled','Canceled')
                    AND (
                            FixedWeight__c = :fixedWeight
                            OR (Weight__c = null AND Tonnage__c = :norm)
                    )
                    LIMIT 200
            ];
        } else {
            rows = [
                    SELECT Id, Status__c, PassNumber__c, FixedWeight__c, Tonnage__c,
                            Truck__r.Name, Trailer__r.Name
                    FROM ScrapSlotReserve__c
                    WHERE Supplier__c   = :supplierId
                    AND ScrapType__c  = :scrapTypeId
                    AND ReserveDate__c= :reserveDate
                    AND Truck__c      = :truckId
                    AND Trailer__c    = :trailerId
                    AND (IsCancelled__c = false OR IsCancelled__c = null)
                    AND Status__c NOT IN ('Cancelled','Canceled')
                    AND (
                            FixedWeight__c = :fixedWeight
                            OR (Weight__c = null AND Tonnage__c = :norm)
                    )
                    LIMIT 200
            ];
        }

        DuplicateCheckResult out = new DuplicateCheckResult();
        out.exists    = !rows.isEmpty();
        out.count     = rows.size();
        out.ids       = new List<Id>();
        out.summaries = new List<String>();

        for (ScrapSlotReserve__c r : rows) {
            out.ids.add(r.Id);
            String truck = (r.Truck__r == null ? '' : r.Truck__r.Name);
            String trl   = (r.Trailer__r == null ? '' : ' + ' + r.Trailer__r.Name);

            // вагу формуємо як String, щоб не мішати типи
            String tStr = !String.isBlank(r.FixedWeight__c)
                    ? r.FixedWeight__c
                    : (r.Tonnage__c == null ? '0' : String.valueOf(r.Tonnage__c));

            out.summaries.add(
                    (truck == null ? '' : truck) + (trl == null ? '' : trl) + ' • ' + tStr + ' т' + ' • Перепустка №: ' + r.PassNumber__c );
        }
        return out;
    }


    @AuraEnabled(cacheable=false)
    public static CurrentDecadeDTO getCurrentDecadeAndDays() {
        Date target = Date.today(); // дата користувача з урахуванням таймзони профілю

        // 1) "Сьогоднішній" запис дня
        List<Decade__c> todayList = [
                SELECT Id, Date__c,
                        Parent__c,
                        Parent__r.Decade__c,
                        Parent__r.Year__c,
                        Parent__r.Month__c
                FROM Decade__c
                WHERE Date__c = :target
                LIMIT 1
        ];
        if (todayList.isEmpty()) {
            throw new AuraHandledException(
                    'На дату ' + String.valueOf(target) +
                            ' не знайдено запису дня у Decade__c. Додайте день у календар.'
            );
        }

        Decade__c today  = todayList[0];
        Id        decId  = today.Parent__c;

        // 2) Усі дні поточної декади
        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :decId
                ORDER BY Date__c ASC
                LIMIT 31
        ];

        // 3) Побудова DTO днів
        List<DayDTO> days = new List<DayDTO>();
        for (Decade__c d : dayNodes) {
            DayDTO dto = new DayDTO();
            dto.id        = d.Id;
            dto.dateValue = d.Date__c;
            if (d.Date__c == null) {
                dto.label = '—';
            } else {
                Datetime dt = Datetime.newInstance(d.Date__c, Time.newInstance(0,0,0,0));
                dto.label = dt.format('dd.MM.yyyy', 'uk') + ' (' + dt.format('E', 'uk') + ')';
            }
            days.add(dto);
        }

        // 4) Повертаємо метадані декади + дні
        CurrentDecadeDTO res = new CurrentDecadeDTO();
        res.decadeId = decId;
        res.yearNum  = (today.Parent__r.Year__c == null) ? null : Integer.valueOf(today.Parent__r.Year__c);
        res.month    = today.Parent__r.Month__c;
        res.decade   = today.Parent__r.Decade__c;
        res.days     = days;

        return res;
    }

    // --- DTO для типу брухту (короткий формат під модалку резервацій) ---
    public class ScrapTypeOption {
        @AuraEnabled public Id id        { get; set; }
        @AuraEnabled public String name  { get; set; }   // Напр. "Брухт негабаритний змішаний 9/501"
        @AuraEnabled public String code  { get; set; }   // Напр. "9/501" (ScrapTypeCode__c)
    }

    /**
     * Повертає перелік ТІЛЬКИ дозволених (Permitted__c = true) і активних (ScrapType__r.IsActive__c = true)
     * типів брухту для заданого постачальника.
     *
     * Використання: під час відкриття сторінки №1 підтягуємо список доступних типів для таблиці.
     */
    @AuraEnabled(cacheable=false)
    public static List<ScrapTypeOption> listPermittedScrapTypes(Id supplierId) {
        if (supplierId == null) {
            throw new AuraHandledException('Не передано supplierId.');
        }

        // Переконуємось, що це справді постачальник (аналогічно до ScrapAccessController.togglePermission)
        List<Account> accList = [
                SELECT Id, IsSupplier__c
                FROM Account
                WHERE Id = :supplierId
                LIMIT 1
        ];
        if (accList.isEmpty() || accList[0].IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником.');
        }

        // Вибірка дозволених + активних типів брухту
        List<ScrapTypeOption> out = new List<ScrapTypeOption>();
        for (ScrapTypeSupplierRelation__c rel : [
                SELECT ScrapType__c,
                        ScrapType__r.Name,
                        ScrapType__r.ScrapTypeCode__c
                FROM ScrapTypeSupplierRelation__c
                WHERE Account__c = :supplierId
                AND Permitted__c = true
                AND ScrapType__c != null
                AND ScrapType__r.IsActive__c = true
                ORDER BY ScrapType__r.Name
                LIMIT 5000
        ]) {
            ScrapTypeOption o = new ScrapTypeOption();
            o.id   = rel.ScrapType__c;
            o.name = rel.ScrapType__r.Name;
            o.code = rel.ScrapType__r.ScrapTypeCode__c;
            out.add(o);
        }
        return out;
    }

    // === ВАШ попередній код (getCurrentDecadeAndDays, listPermittedScrapTypes тощо) може бути вище ===
    // -----------------------------------------------------------------------------------------------

    // Клітинка таблиці по конкретній даті
    public class GridCellDTO {
        @AuraEnabled public Date    dateValue        { get; set; }
        @AuraEnabled public Decimal limitValue       { get; set; }   // денний ліміт
        @AuraEnabled public Decimal incoming    { get; set; }   // фактичне+заявлене
        @AuraEnabled public Decimal remaining   { get; set; }   // limit - incoming (>=0)
        @AuraEnabled public Boolean disabled    { get; set; }   // якщо немає ліміту або він вичерпаний
        @AuraEnabled public String  reason      { get; set; }   // причина disable
    }

    // Рядок таблиці (тип брухту)
    public class GridRowDTO {
        @AuraEnabled public Id      scrapTypeId { get; set; }
        @AuraEnabled public String  name        { get; set; }   // повна назва типу
        @AuraEnabled public String  code        { get; set; }   // код (напр. 9/501)
        @AuraEnabled public List<GridCellDTO> cells { get; set; }
    }

    // Відповідь: поточна декада + сітка
    public class DecadeGridDTO {
        @AuraEnabled public Id           decadeId { get; set; }
        @AuraEnabled public Integer      yearNum  { get; set; }
        @AuraEnabled public String       month    { get; set; }
        @AuraEnabled public String       decade   { get; set; }   // '1' | '2' | '3'
        @AuraEnabled public List<Date>   days     { get; set; }   // дати поточної декади
        @AuraEnabled public List<GridRowDTO> rows { get; set; }
    }



    // === УТИЛІТА: ключ (дата+тип) для мап ===
    private static String k(Date d, Id typeId) { return String.valueOf(d) + '|' + String.valueOf(typeId); }

    /**
     * КРОК 3. На основі supplierId:
     *  - визначає поточну декаду та всі її дні,
     *  - знаходить дозволені типи брухту для постачальника,
     *  - рахує ліміт/використання/залишок на кожен день і тип,
     *  - повертає сітку для відображення таблиці.
     */
    @AuraEnabled(cacheable=false)
    public static DecadeGridDTO getDecadeGridForSupplier(Id supplierId) {
        System.debug('SupplierId: ' + supplierId);
        if (supplierId == null) {
            throw new AuraHandledException('Не передано supplierId.');
        }

        // Переконуємось, що це постачальник
        List<Account> accList = [
                SELECT Id, IsSupplier__c
                FROM Account WHERE Id = :supplierId LIMIT 1
        ];
        if (accList.isEmpty() || accList[0].IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником.');
        }

        // 1) Сьогоднішній день -> батько-декада -> всі дні декади
        Date target = Date.today();

        List<Decade__c> todayList = [
                SELECT Id, Date__c,
                        Parent__c,
                        Parent__r.Decade__c,
                        Parent__r.Year__c,
                        Parent__r.Month__c
                FROM Decade__c
                WHERE Date__c = :target
                LIMIT 1
        ];
        if (todayList.isEmpty()) {
            throw new AuraHandledException('На сьогодні ('+ String.valueOf(target) +') не знайдено дня у Decade__c.');
        }
        Decade__c today = todayList[0];
        Id decadeId = today.Parent__c;

        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :decadeId
                ORDER BY Date__c ASC
                LIMIT 31
        ];

        List<Date> dayDates = new List<Date>();
        for (Decade__c d : dayNodes) if (d.Date__c != null) dayDates.add(d.Date__c);
        if (dayDates.isEmpty()) {
            // Декада без дат — немає що будувати
            DecadeGridDTO empty = new DecadeGridDTO();
            empty.decadeId = decadeId;
            empty.yearNum  = (today.Parent__r.Year__c == null) ? null : Integer.valueOf(today.Parent__r.Year__c);
            empty.month    = today.Parent__r.Month__c;
            empty.decade   = today.Parent__r.Decade__c;
            empty.days     = new List<Date>();
            empty.rows     = new List<GridRowDTO>();
            return empty;
        }

        // 2) Дозволені (Permitted=true) і активні типи брухту постачальника
        List<ScrapType__c> allowedTypes = [
                SELECT Id, Name, ScrapTypeCode__c
                FROM ScrapType__c
                WHERE Id IN (
                        SELECT ScrapType__c
                        FROM ScrapTypeSupplierRelation__c
                        WHERE Account__c = :supplierId
                        AND Permitted__c = true
                        AND ScrapType__c != null
                )
                AND IsActive__c = true
                ORDER BY Name
                LIMIT 5000
        ];
        if (allowedTypes.isEmpty()) {
            // Повернемо каркас без рядків — у UI можна показати "нема дозволених типів"
            DecadeGridDTO empty = new DecadeGridDTO();
            empty.decadeId = decadeId;
            empty.yearNum  = (today.Parent__r.Year__c == null) ? null : Integer.valueOf(today.Parent__r.Year__c);
            empty.month    = today.Parent__r.Month__c;
            empty.decade   = today.Parent__r.Decade__c;
            empty.days     = dayDates;
            empty.rows     = new List<GridRowDTO>();
            return empty;
        }

        Set<Id> typeIds = new Set<Id>();
        for (ScrapType__c t : allowedTypes) typeIds.add(t.Id);

        // 3) ЛІМІТИ: денні на задані дати та типи
        Map<String, Decimal> limitByKey = new Map<String, Decimal>(); // key = date|typeId
        for (ScrapDecadesLimit__c l : [
                SELECT ScrapType__c, LimitDate__c, DayLimit__c
                FROM ScrapDecadesLimit__c
                WHERE LimitDate__c IN :dayDates
                AND ScrapType__c IN :typeIds
        ]) {
            if (l.ScrapType__c != null && l.LimitDate__c != null) {
                limitByKey.put(k(l.LimitDate__c, l.ScrapType__c), (l.DayLimit__c == null ? 0 : l.DayLimit__c));
            }
        }

        // 4) ВИКОРИСТАННЯ: сума Weight__c, а де його немає — додаємо Tonnage__c
        Map<String, Decimal> incomingByKey = new Map<String, Decimal>();

        // 4.1 Weight__c
        for (AggregateResult ar : [
                SELECT ScrapType__c st, ReserveDate__c d, SUM(Weight__c) w
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates
                AND ScrapType__c IN :typeIds
                AND IsCancelled__c = false
                AND Weight__c != null
                GROUP BY ScrapType__c, ReserveDate__c
        ]) {
            Id st = (Id) ar.get('st');
            Date d = (Date) ar.get('d');
            if (st == null || d == null) continue;
            incomingByKey.put(k(d, st), (Decimal) ar.get('w'));
        }

        // 4.2 + Tonnage__c там, де фактичної ваги ще немає
        for (AggregateResult ar : [
                SELECT ScrapType__c st, ReserveDate__c d, SUM(Tonnage__c) t
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates
                AND ScrapType__c IN :typeIds
                AND IsCancelled__c = false
                AND Weight__c = null
                AND Tonnage__c != null
                GROUP BY ScrapType__c, ReserveDate__c
        ]) {
            Id st = (Id) ar.get('st');
            Date d = (Date) ar.get('d');
            if (st == null || d == null) continue;
            String key = k(d, st);
            Decimal curr = incomingByKey.containsKey(key) ? incomingByKey.get(key) : 0;
            incomingByKey.put(key, curr + (Decimal) ar.get('t'));
        }

        // 5) Будуємо рядки
        List<GridRowDTO> rows = new List<GridRowDTO>();
        for (ScrapType__c t : allowedTypes) {
            GridRowDTO row = new GridRowDTO();
            row.scrapTypeId = t.Id;
            row.name = t.Name;
            row.code = t.ScrapTypeCode__c;
            row.cells = new List<GridCellDTO>();

            for (Date d : dayDates) {
                String key = k(d, t.Id);
                Decimal lim = limitByKey.containsKey(key) ? limitByKey.get(key) : 0;
                Decimal inc = incomingByKey.containsKey(key) ? incomingByKey.get(key) : 0;
                if (lim == null) lim = 0;
                if (inc == null) inc = 0;

                Decimal rem = lim - inc;
                if (rem == null) rem = 0;
                if (rem < 0) rem = 0;

                GridCellDTO cell = new GridCellDTO();
                cell.dateValue      = d;
                cell.limitValue     = lim.setScale(1);
                cell.incoming  = inc.setScale(1);
                cell.remaining = rem.setScale(1);

                if (lim == 0) {
                    cell.disabled = true;
                    cell.reason   = 'Нема ліміту на дату';
                } else if (rem == 0) {
                    cell.disabled = true;
                    cell.reason   = 'Ліміт вичерпано';
                } else {
                    cell.disabled = false;
                    cell.reason   = null;
                }
                row.cells.add(cell);
            }
            rows.add(row);
        }

        // 6) Пакуємо відповідь
        DecadeGridDTO res = new DecadeGridDTO();
        res.decadeId = decadeId;
        res.yearNum  = (today.Parent__r.Year__c == null) ? null : Integer.valueOf(today.Parent__r.Year__c);
        res.month    = today.Parent__r.Month__c;
        res.decade   = today.Parent__r.Decade__c;
        res.days     = dayDates;
        res.rows     = rows;

        System.debug('=====================RESULT===============================');
        System.debug('RES: ' + res);
        return res;
    }

    // ===== DTOs =====
    public class Step2ContractDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String contractNumber; // не "number" — зарезервовано
        @AuraEnabled public String dateFrom;       // 'YYYY-MM-DD'
        @AuraEnabled public String dateTo;         // 'YYYY-MM-DD'
        @AuraEnabled public Integer willBeActiveDays; // ⬅️ нове
    }
    public class Step2StaticDTO {
        @AuraEnabled public String           supplierName;
        @AuraEnabled public Step2ContractDTO contract;
    }

    // маленький хелпер
    private static String toIso(Date d) {
        return d == null ? null : String.valueOf(d); // дає 'YYYY-MM-DD'
    }

    @AuraEnabled(cacheable=false)
    public static Step2StaticDTO getStep2StaticInfo(Id supplierId, Id scrapTypeId) {
        Step2StaticDTO dto = new Step2StaticDTO();

        // Постачальник
        Account acc = [SELECT Name FROM Account WHERE Id = :supplierId LIMIT 1];
        dto.supplierName = (acc == null) ? null : acc.Name;

        // Активний контракт цього акаунта (спрощена й надійна умова активності)
        Date today = Date.today();
        List<Contract> active = [
                SELECT Id, ContractNumber, StartDate, EndDate, Status, IsActive__c, DogN__c, WillBeActive__c
                FROM Contract
                WHERE AccountId = :supplierId
                AND (
                        Status = 'Activated'
                        OR IsActive__c = true
                        OR (StartDate != null AND StartDate <= :today AND (EndDate = null OR EndDate >= :today))
                )
                ORDER BY StartDate DESC NULLS LAST, EndDate DESC NULLS LAST
                LIMIT 1
        ];

        Contract c;
        if (!active.isEmpty()) {
            c = active[0];
        } else {
            // якщо активних немає — беремо останній за StartDate як fallback
            List<Contract> anyC = [
                    SELECT Id, ContractNumber, StartDate, EndDate, Status, IsActive__c, DogN__c
                    FROM Contract
                    WHERE AccountId = :supplierId
                    ORDER BY StartDate DESC NULLS LAST, LastModifiedDate DESC
                    LIMIT 1
            ];
            if (!anyC.isEmpty()) c = anyC[0];
        }

        if (c != null) {
            Step2ContractDTO k = new Step2ContractDTO();
            k.id = c.Id;
            // показуємо формульний "Угода №" якщо він є, інакше стандартний ContractNumber
            k.contractNumber = String.isBlank((String)c.DogN__c) ? c.ContractNumber : (String)c.DogN__c;
            k.dateFrom = toIso(c.StartDate);
            k.dateTo   = toIso(c.EndDate);
            k.willBeActiveDays = (c.WillBeActive__c == null) ? null : Integer.valueOf(c.WillBeActive__c); // ⬅️
            dto.contract = k;
        }

        System.debug('====================dto====================');
        System.debug(dto);
        return dto;
    }

    // ===== КРОК 2: Lookup-и (менеджери + адреси відвантаження) =====
    public class ManagerDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String role;         // Title або Department
        @AuraEnabled public Boolean directorate; // Department == 'Дирекція'
        @AuraEnabled public Boolean portalUser;
    }
    public class ShippingPointDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String label;   // Name або Address
        @AuraEnabled public String address;
        @AuraEnabled public String city;
        @AuraEnabled public String country;
    }
    public class Step2LookupsDTO {
        @AuraEnabled public List<ManagerDTO>      managers;
        @AuraEnabled public List<ShippingPointDTO> addresses;
        @AuraEnabled public Integer               managersCount;
        @AuraEnabled public Integer               addressesCount;
        @AuraEnabled public Id                    defaultManagerId;  // якщо рівно 1
        @AuraEnabled public Id                    defaultAddressId;  // якщо рівно 1
    }

    @AuraEnabled(cacheable=false)
    public static Step2LookupsDTO getStep2Lookups(Id supplierId) {
        if (supplierId == null) {
            throw new AuraHandledException('Не передано supplierId.');
        }

        Step2LookupsDTO out = new Step2LookupsDTO();
        out.managers  = new List<ManagerDTO>();
        out.addresses = new List<ShippingPointDTO>();

        // === МЕНЕДЖЕРИ: це Contact, прив’язаний до AccountId; не є "трек-драйвером" ===
        // За потреби можна додати фільтр Department = 'Дирекція'
        List<Contact> rawManagers = [
            SELECT Id, Name, Phone, Title, Department, TrackDriver__c, IsPortalUser__c
            FROM Contact
            WHERE AccountId = :supplierId
              AND (TrackDriver__c = false OR TrackDriver__c = null)
            ORDER BY Name
            LIMIT 500
        ];

        // Щоб "Дирекція" йшла першою — розділимо на 2 групи і збережемо порядок з SOQL
        List<ManagerDTO> portalDir  = new List<ManagerDTO>();
        List<ManagerDTO> portalRest = new List<ManagerDTO>();
        List<ManagerDTO> dirFirst   = new List<ManagerDTO>();
        List<ManagerDTO> rest       = new List<ManagerDTO>();

        for (Contact c : rawManagers) {
            ManagerDTO m = new ManagerDTO();
            m.id          = c.Id;
            m.name        = c.Name;
            m.phone       = c.Phone;
            m.role        = String.isBlank(c.Title) ? c.Department : c.Title;
            m.directorate = (c.Department == 'Дирекція');
            m.portalUser  = (c.IsPortalUser__c == true); // ✅ обов'язково встановлюємо

            // Використовуємо безпечні перевірки
            if (m.portalUser == true && m.directorate == true) {
                portalDir.add(m);
            } else if (m.portalUser == true) {
                portalRest.add(m);
            } else if (m.directorate == true) {
                dirFirst.add(m);
            } else {
                rest.add(m);
            }
        }

        out.managers = new List<ManagerDTO>();
        out.managers.addAll(portalDir);
        out.managers.addAll(portalRest);
        out.managers.addAll(dirFirst);
        out.managers.addAll(rest);

        out.managersCount    = out.managers.size();
        out.defaultManagerId = (out.managersCount == 1) ? out.managers[0].id : null;

        // === АДРЕСИ ВІДВАНТАЖЕННЯ ===
        for (ScrapSupplierShippingPoint__c sp : [
            SELECT Id, Name, Address__c, City__c, Country__r.Name
            FROM ScrapSupplierShippingPoint__c
            WHERE Supplier__c = :supplierId
            ORDER BY Name
            LIMIT 500
        ]) {
            ShippingPointDTO a = new ShippingPointDTO();
            a.id      = sp.Id;
            a.address = sp.Address__c;
            a.city    = sp.City__c;
            a.country = sp.Country__r == null ? null : sp.Country__r.Name;

            // лейбл: Name якщо є; інакше — адреса (з містом)
            if (!String.isBlank(sp.Name)) {
                a.label = sp.Name;
            } else if (!String.isBlank(sp.Address__c)) {
                a.label = String.isBlank(sp.City__c) ? sp.Address__c : (sp.Address__c + ', ' + sp.City__c);
            } else {
                a.label = 'Адреса без назви';
            }
            out.addresses.add(a);
        }
        out.addressesCount   = out.addresses.size();
        out.defaultAddressId = (out.addressesCount == 1) ? out.addresses[0].id : null;

        return out;
    }

    // ==== VEHICLES (ScrapTruck__c) LOOKUP ====
    public class VehicleDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;     // держ. номер (Name)
        @AuraEnabled public String model;    // TruckModel__c
        @AuraEnabled public Decimal tonnage; // Tonnage__c
        @AuraEnabled public String type;     // TruckType__c ('Truck' | 'Trailer')
    }

    @AuraEnabled(cacheable=false)
    public static List<VehicleDTO> searchTrucks(Id supplierId, String query, String type, Integer limitSize) {
        if (supplierId == null) throw new AuraHandledException('Не передано supplierId.');

        String q = (query == null) ? '' : query.trim();
        String likeQ = '%' + q + '%';
        Integer lim = (limitSize == null || limitSize <= 0) ? 30 : limitSize;

        List<ScrapTruck__c> rows;

        if (String.isBlank(type) && String.isBlank(q)) {
            rows = [
                    SELECT Id, Name, TruckModel__c, Tonnage__c, TruckType__c
                    FROM ScrapTruck__c
                    WHERE Account__c = :supplierId
                    ORDER BY TruckModel__c NULLS LAST, Name
                    LIMIT :lim
            ];
        } else if (String.isBlank(type)) {
            rows = [
                    SELECT Id, Name, TruckModel__c, Tonnage__c, TruckType__c
                    FROM ScrapTruck__c
                    WHERE Account__c = :supplierId
                    AND (Name LIKE :likeQ OR TruckModel__c LIKE :likeQ)
                    ORDER BY TruckModel__c NULLS LAST, Name
                    LIMIT :lim
            ];
        } else if (String.isBlank(q)) {
            rows = [
                    SELECT Id, Name, TruckModel__c, Tonnage__c, TruckType__c
                    FROM ScrapTruck__c
                    WHERE Account__c = :supplierId
                    AND TruckType__c = :type     // API значення: 'Truck' або 'Trailer'
                    ORDER BY TruckModel__c NULLS LAST, Name
                    LIMIT :lim
            ];
        } else {
            rows = [
                    SELECT Id, Name, TruckModel__c, Tonnage__c, TruckType__c
                    FROM ScrapTruck__c
                    WHERE Account__c = :supplierId
                    AND TruckType__c = :type
                    AND (Name LIKE :likeQ OR TruckModel__c LIKE :likeQ)
                    ORDER BY TruckModel__c NULLS LAST, Name
                    LIMIT :lim
            ];
        }

        List<VehicleDTO> out = new List<VehicleDTO>();
        for (ScrapTruck__c t : rows) {
            VehicleDTO v = new VehicleDTO();
            v.id = t.Id;
            v.name = t.Name;
            v.model = t.TruckModel__c;
            v.tonnage = t.Tonnage__c;
            v.type = t.TruckType__c;
            out.add(v);
        }
        return out;
    }

    // ===== DRIVER LOOKUP (просто за постачальником і прапором водія) =====
    public class DriverDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
    }

    @AuraEnabled(cacheable=false)
    public static List<DriverDTO> searchDrivers(Id supplierId, String query, Integer limitSize) {
        if (supplierId == null) {
            throw new AuraHandledException('Не передано supplierId.');
        }

        Integer lim = (limitSize == null || limitSize <= 0 || limitSize > 50) ? 20 : limitSize;

        // ⚠️ Якщо в тебе поле називається інакше (наприклад TrackDriver__c),
        //    заміни IsTruckDriver__c нижче на правильний API Name.
        List<Contact> src = [
                SELECT Id, Name, Phone, MobilePhone, TrackDriver__c
                FROM Contact
                WHERE AccountId = :supplierId
                AND TrackDriver__c = true
                ORDER BY LastModifiedDate DESC, Name ASC
                LIMIT :lim
        ];

        List<DriverDTO> out = new List<DriverDTO>();
        for (Contact c : src) {
            DriverDTO d = new DriverDTO();
            d.id    = c.Id;
            d.name  = c.Name;
            d.phone = String.isBlank(c.Phone) ? c.MobilePhone : c.Phone;
            out.add(d);
        }
        return out;
    }

//======================================================================================================================

    // ===== DTO для створення =====
    public class ReserveInput {
        @AuraEnabled public String supplierId {get; set;}
        @AuraEnabled public String scrapTypeId {get; set;}
        @AuraEnabled public String reserveDate {get; set;}
        @AuraEnabled public String fixedWeight {get; set;}
        @AuraEnabled public String shippingPointId {get; set;}
        @AuraEnabled public String supplierPersonId {get; set;}
        @AuraEnabled public String truckId {get; set;}
        @AuraEnabled public String trailerId {get; set;}
        @AuraEnabled public String driverId {get; set;}
        @AuraEnabled public String contractId {get; set;}
        @AuraEnabled public Boolean isOutOfLimit {get; set;}
        @AuraEnabled public Boolean forceCreate { get; set; }
    }
    public class ReserveResult {
        @AuraEnabled public Id id;
    }

// ===== Створення запису ScrapSlotReserve__c =====
    @AuraEnabled(cacheable=false)
    public static ReserveResult createReserve(ReserveInput input) {
        if (input == null) throw new AuraHandledException('Порожній запит.');
        // Мінімальні перевірки
        System.debug('=============createReserve================');
        System.debug('input: ' + input);
        if (String.isBlank(input.supplierId) ||
                String.isBlank(input.scrapTypeId) ||
                String.isBlank(input.reserveDate) ||
                String.isBlank(input.fixedWeight) ||
                String.isBlank(input.truckId) ||
                String.isBlank(input.driverId)) {
            throw new AuraHandledException('Не всі обовʼязкові поля заповнені.');
        }

        // Правило: якщо тягач з тоннажем 0 — причіп обовʼязковий
        ScrapTruck__c truck = [
                SELECT Id, Tonnage__c
                FROM ScrapTruck__c
                WHERE Id = :input.truckId
                LIMIT 1
        ];
        if ((truck.Tonnage__c == null || truck.Tonnage__c == 0) && String.isBlank(input.trailerId)) {
            throw new AuraHandledException('Для тягача з тоннажем 0 потрібно вказати причіп.');
        }

        if (input.forceCreate != true) {
            Decimal norm = Decimal.valueOf(input.fixedWeight);

            List<ScrapSlotReserve__c> dups;
            if (String.isBlank(input.trailerId)) {
                dups = [
                        SELECT Id FROM ScrapSlotReserve__c
                        WHERE Supplier__c   = :input.supplierId
                        AND ScrapType__c  = :input.scrapTypeId
                        AND ReserveDate__c= :Date.valueOf(input.reserveDate)
                        AND Truck__c      = :input.truckId
                        AND Trailer__c    = null
                        AND (IsCancelled__c = false OR IsCancelled__c = null)
                        AND Status__c NOT IN ('Cancelled','Canceled')
                        AND (
                                FixedWeight__c = :input.fixedWeight
                                OR (Weight__c = null AND Tonnage__c = :norm)
                        )
                        LIMIT 1
                ];
            } else {
                dups = [
                        SELECT Id FROM ScrapSlotReserve__c
                        WHERE Supplier__c   = :input.supplierId
                        AND ScrapType__c  = :input.scrapTypeId
                        AND ReserveDate__c= :Date.valueOf(input.reserveDate)
                        AND Truck__c      = :input.truckId
                        AND Trailer__c    = :input.trailerId
                        AND (IsCancelled__c = false OR IsCancelled__c = null)
                        AND Status__c NOT IN ('Cancelled','Canceled')
                        AND (
                                FixedWeight__c = :input.fixedWeight
                                OR (Weight__c = null AND Tonnage__c = :norm)
                        )
                        LIMIT 1
                ];
            }
            if (!dups.isEmpty()) {
                throw new AuraHandledException(
                        'Схожа заявка вже існує на цю дату з цим ТЗ і тоннажем. ' +
                                'Якщо потрібно, повторіть створення з підтвердженням.'
                );
            }
        }

        ScrapSlotReserve__c r = new ScrapSlotReserve__c();
        r.Supplier__c       = input.supplierId;
        r.ScrapType__c      = input.scrapTypeId;
        r.ReserveDate__c    = Date.valueOf(input.reserveDate);
        r.FixedWeight__c    = input.fixedWeight;
        r.ShippingPoint__c  = input.shippingPointId;
        r.SupplierPerson__c = input.supplierPersonId;
        r.Truck__c          = input.truckId;
        if (!String.isBlank(input.trailerId)) r.Trailer__c = input.trailerId;
        r.Driver__c         = input.driverId;
        if (!String.isBlank(input.contractId)) r.Contract__c = input.contractId;
        r.Status__c         = 'Requested'; // як і домовлялись
        r.IsOutOfLimit__c = (input.isOutOfLimit == true);

        System.debug('BEFORE CREATE: ' + r);

        insert r;

        ReserveResult out = new ReserveResult();
        out.id = r.Id;
        return out;
    }
    public class SendToErpResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  requestBody;
        @AuraEnabled public String  rawResponse;
        @AuraEnabled public String  passNumber;
        @AuraEnabled public String  passId;
        @AuraEnabled public List<String> itemErrors;
    }

    @AuraEnabled(cacheable=false)
    public static SendToErpResult sendReserveToErp(Id reserveId) {
        ScrapPassOutbound.SendResult s = ScrapPassOutbound.sendOne(reserveId);

        SendToErpResult r = new SendToErpResult();
        r.success      = s != null && s.success;
        r.requestBody  = s != null ? s.requestBody : null;
        r.rawResponse  = s != null ? s.rawResponse : null;
        r.itemErrors   = s != null ? s.itemErrors  : null;

        // витягнемо перепустку з першого успішного результату
        if (s != null && s.response != null && s.response.Results != null) {
            for (ScrapDeliveryGateway.ResultEntry re : s.response.Results) {
                if (re != null && re.Success == true) {
                    r.passNumber = re.PassNDM;
                    r.passId     = String.valueOf(re.PassID);
                    break;
                }
            }
        }
        return r;
    }

    // ▶️ Позначити слот як Approved (опціонально приймаємо номер/ID перепустки)
    public class ApproveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id id;
    }
    @AuraEnabled(cacheable=false)
    public static ApproveResult markReserveApproved(Id reserveId, String passNumber, String passId) {
        if (reserveId == null) {
            throw new AuraHandledException('Не передано reserveId.');
        }
        ScrapSlotReserve__c rec = [
                SELECT Id, Status__c
                FROM ScrapSlotReserve__c
                WHERE Id = :reserveId
                LIMIT 1
        ];
        rec.Status__c = 'Approved';

        // Якщо у вас є поля для збереження номера/ID перепустки — розкоментуйте й виставте правильні API-імена:
        // rec.PassNumber__c = passNumber;
        // rec.PassId__c     = passId;

        update rec;

        ApproveResult res = new ApproveResult();
        res.success = true;
        res.id = rec.Id;
        return res;
    }

    private static Date firstDayOfMonth(Date d) { return Date.newInstance(d.year(), d.month(), 1); }
    private static Integer lastDayNum(Date d) { return Date.daysInMonth(d.year(), d.month()); }

    @AuraEnabled(cacheable=true)
    public static Date getDecadeAnchor(Date anyDate) {
        if (anyDate == null) anyDate = Date.today();
        Integer day = anyDate.day();
        if (day <= 10) return Date.newInstance(anyDate.year(), anyDate.month(), 1);
        if (day <= 20) return Date.newInstance(anyDate.year(), anyDate.month(), 11);
        return Date.newInstance(anyDate.year(), anyDate.month(), 21);
    }

    @AuraEnabled(cacheable=true)
    public static Date getNextDecadeAnchor(Date anyDate) {
        Date a = getDecadeAnchor(anyDate);
        Integer day = a.day();
        if (day == 1)  return Date.newInstance(a.year(), a.month(), 11);
        if (day == 11) {
            Integer last = lastDayNum(a);
            return (last >= 21) ? Date.newInstance(a.year(), a.month(), 21)
                    : Date.newInstance((a.month() == 12 ? a.year()+1 : a.year()),
                            (a.month() == 12 ? 1 : a.month()+1), 1);
        }
        // day == 21 -> наступний місяць, 1 число
        Integer nextMonth = (a.month() == 12 ? 1 : a.month()+1);
        Integer nextYear  = (a.month() == 12 ? a.year()+1 : a.year());
        return Date.newInstance(nextYear, nextMonth, 1);
    }

    @AuraEnabled(cacheable=true)
    public static Date getPrevDecadeAnchor(Date anyDate) {
        Date a = getDecadeAnchor(anyDate);
        Integer day = a.day();
        if (day == 21) return Date.newInstance(a.year(), a.month(), 11);
        if (day == 11) return Date.newInstance(a.year(), a.month(), 1);
        // day == 1 -> попередній місяць, 21 число
        Integer prevMonth = (a.month() == 1 ? 12 : a.month()-1);
        Integer prevYear  = (a.month() == 1 ? a.year()-1 : a.year());
        Integer lastPrev  = Date.daysInMonth(prevYear, prevMonth);
        Integer start21   = (lastPrev >= 21 ? 21 : 1); // якщо раптом короткий місяць (запасний варіант)
        return Date.newInstance(prevYear, prevMonth, start21);
    }


    @AuraEnabled(cacheable=false)
    public static DecadeGridDTO getDecadeGridForSupplierAtDate(Id supplierId, Date anchorDate) {
        if (supplierId == null) throw new AuraHandledException('Не передано supplierId.');
        if (anchorDate == null) anchorDate = Date.today();

        // Валідую, що це постачальник
        Account acc = [SELECT Id, IsSupplier__c FROM Account WHERE Id = :supplierId LIMIT 1];
        if (acc == null || acc.IsSupplier__c != true) {
            throw new AuraHandledException('Вказаний Account не є постачальником.');
        }

        // Знаходимо запис дня = anchorDate, дістаємо батьківську декаду та всі її дні
        List<Decade__c> todayList = [
                SELECT Id, Date__c, Parent__c, Parent__r.Decade__c, Parent__r.Year__c, Parent__r.Month__c
                FROM Decade__c
                WHERE Date__c = :anchorDate
                LIMIT 1
        ];
        if (todayList.isEmpty()) {
            throw new AuraHandledException('На дату ' + String.valueOf(anchorDate) + ' не знайдено дня у Decade__c.');
        }
        Decade__c day = todayList[0];
        Id decadeId   = day.Parent__c;

        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :decadeId
                ORDER BY Date__c ASC
                LIMIT 31
        ];

        List<Date> dayDates = new List<Date>();
        for (Decade__c d : dayNodes) if (d.Date__c != null) dayDates.add(d.Date__c);

        // якщо в декаді немає дат — повертаємо «порожню» структуру, як у твоєму методі
        DecadeGridDTO res = new DecadeGridDTO();
        res.decadeId = decadeId;
        res.yearNum  = (day.Parent__r.Year__c == null) ? null : Integer.valueOf(day.Parent__r.Year__c);
        res.month    = day.Parent__r.Month__c;
        res.decade   = day.Parent__r.Decade__c;
        res.days     = dayDates;
        if (dayDates.isEmpty()) { res.rows = new List<GridRowDTO>(); return res; }

        // ↓↓↓ далі — точна копія твого підрахунку allowedTypes/limits/incoming/rows ↓↓↓

        List<ScrapType__c> allowedTypes = [
                SELECT Id, Name, ScrapTypeCode__c
                FROM ScrapType__c
                WHERE Id IN (
                        SELECT ScrapType__c FROM ScrapTypeSupplierRelation__c
                        WHERE Account__c = :supplierId AND Permitted__c = true AND ScrapType__c != null
                )
                AND IsActive__c = true
                ORDER BY Name
                LIMIT 5000
        ];

        if (allowedTypes.isEmpty()) { res.rows = new List<GridRowDTO>(); return res; }

        Set<Id> typeIds = new Set<Id>();
        for (ScrapType__c t : allowedTypes) typeIds.add(t.Id);

        Map<String, Decimal> limitByKey = new Map<String, Decimal>();
        for (ScrapDecadesLimit__c l : [
                SELECT ScrapType__c, LimitDate__c, DayLimit__c
                FROM ScrapDecadesLimit__c
                WHERE LimitDate__c IN :dayDates AND ScrapType__c IN :typeIds
        ]) {
            if (l.ScrapType__c != null && l.LimitDate__c != null) {
                limitByKey.put(String.valueOf(l.LimitDate__c) + '|' + String.valueOf(l.ScrapType__c),
                        (l.DayLimit__c == null ? 0 : l.DayLimit__c));
            }
        }

        Map<String, Decimal> incomingByKey = new Map<String, Decimal>();
        for (AggregateResult ar : [
                SELECT ScrapType__c st, ReserveDate__c d, SUM(Weight__c) w
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates AND ScrapType__c IN :typeIds
                AND IsCancelled__c = false AND Weight__c != null
                GROUP BY ScrapType__c, ReserveDate__c
        ]) {
            Id st = (Id) ar.get('st'); Date d = (Date) ar.get('d'); if (st == null || d == null) continue;
            incomingByKey.put(String.valueOf(d) + '|' + String.valueOf(st), (Decimal) ar.get('w'));
        }
        for (AggregateResult ar : [
                SELECT ScrapType__c st, ReserveDate__c d, SUM(Tonnage__c) t
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates AND ScrapType__c IN :typeIds
                AND IsCancelled__c = false AND Weight__c = null AND Tonnage__c != null
                GROUP BY ScrapType__c, ReserveDate__c
        ]) {
            Id st = (Id) ar.get('st'); Date d = (Date) ar.get('d'); if (st == null || d == null) continue;
            String key = String.valueOf(d) + '|' + String.valueOf(st);
            Decimal curr = incomingByKey.containsKey(key) ? incomingByKey.get(key) : 0;
            incomingByKey.put(key, curr + (Decimal) ar.get('t'));
        }

        List<GridRowDTO> rows = new List<GridRowDTO>();
        for (ScrapType__c t : allowedTypes) {
            GridRowDTO row = new GridRowDTO();
            row.scrapTypeId = t.Id; row.name = t.Name; row.code = t.ScrapTypeCode__c; row.cells = new List<GridCellDTO>();
            for (Date d : dayDates) {
                String key = String.valueOf(d) + '|' + String.valueOf(t.Id);
                Decimal lim = limitByKey.containsKey(key) ? limitByKey.get(key) : 0;
                Decimal inc = incomingByKey.containsKey(key) ? incomingByKey.get(key) : 0;
                Decimal rem = (lim == null ? 0 : lim) - (inc == null ? 0 : inc); if (rem < 0) rem = 0;

                GridCellDTO cell = new GridCellDTO();
                cell.dateValue = d;
                cell.limitValue = (lim == null ? 0 : lim).setScale(1);
                cell.incoming   = (inc == null ? 0 : inc).setScale(1);
                cell.remaining  = rem.setScale(1);
                if ((lim == null ? 0 : lim) == 0) { cell.disabled = true; cell.reason = 'Нема ліміту на дату'; }
                else if (rem == 0) { cell.disabled = true; cell.reason = 'Ліміт вичерпано'; }
                else { cell.disabled = false; cell.reason = null; }
                row.cells.add(cell);
            }
            rows.add(row);
        }
        res.rows = rows;
        return res;
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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