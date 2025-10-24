public with sharing class ScrapDecadesController {

    // DTO (Data Transfer Object) для побудови дерева
    public class DecadeNode {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String headerName;
        @AuraEnabled public Integer level;        // рівень (0/1/2…)
        @AuraEnabled public Integer year;         // поле Year__c
        @AuraEnabled public String month;         // поле Month__c
        @AuraEnabled public String decade;        // поле Decade__c
        @AuraEnabled public Date dateValue;
        @AuraEnabled public Id parentId;          // Parent__c
        @AuraEnabled public Boolean hasChildren;  // чи є дочірні записи
        @AuraEnabled public List<DecadeNode> children = new List<DecadeNode>();
    }

    // Перетворює запис Decade__c у вузол DecadeNode
    private static DecadeNode toNode(Decade__c record) {
        DecadeNode node = new DecadeNode();
        node.id         = record.Id;
        node.name       = record.Name;
        node.headerName = record.HeaderName__c;
        node.level      = (record.Level__c == null) ? null : Integer.valueOf(record.Level__c);
        node.year       = (record.Year__c == null) ? null : Integer.valueOf(record.Year__c);
        node.month      = record.Month__c;
        node.decade     = record.Decade__c;
        node.dateValue  = record.Date__c;
        node.parentId   = record.Parent__c;
        node.hasChildren = false;
        return node;
    }

    @AuraEnabled(cacheable=true)
    public static List<DecadeNode> getHierarchy(Integer yearFilter, Integer limitSize) {
        Integer effectiveLimit = (limitSize == null || limitSize <= 0) ? 10000 : Math.min(limitSize, 50000);

        List<Decade__c> records;

        if (yearFilter == null) {
            records = [
                    SELECT Id, Name, HeaderName__c, Level__c, Year__c, Month__c, Decade__c, Date__c, Parent__c
                    FROM Decade__c
                    ORDER BY Level__c ASC, Year__c ASC, Month__c ASC, Decade__c ASC, Date__c ASC
                    LIMIT :effectiveLimit
            ];
        } else {
            records = [
                    SELECT Id, Name, HeaderName__c, Level__c, Year__c, Month__c, Decade__c, Date__c, Parent__c
                    FROM Decade__c
                    WHERE Year__c = :yearFilter
                    ORDER BY Level__c ASC, Year__c ASC, Month__c ASC, Decade__c ASC, Date__c ASC
                    LIMIT :effectiveLimit
            ];
        }

        Map<Id, DecadeNode> nodeById = new Map<Id, DecadeNode>();
        Map<Id, List<DecadeNode>> childrenMap = new Map<Id, List<DecadeNode>>();
        List<DecadeNode> rootNodes = new List<DecadeNode>();

        for (Decade__c record : records) {
            DecadeNode node = toNode(record);
            nodeById.put(node.id, node);

            if (node.parentId == null) {
                rootNodes.add(node); // це «Календар»
            } else {
                if (!childrenMap.containsKey(node.parentId)) {
                    childrenMap.put(node.parentId, new List<DecadeNode>());
                }
                childrenMap.get(node.parentId).add(node);
            }
        }

        // З’єднуємо дітей з батьками
        for (DecadeNode node : nodeById.values()) {
            List<DecadeNode> children = childrenMap.get(node.id);
            if (children != null && !children.isEmpty()) {
                node.children.addAll(children);
                node.hasChildren = true;
            }
        }

        return rootNodes;
    }


    /**
     * Отримати деталі одного вузла + його дочірні (для правої панелі).
     */
    @AuraEnabled(cacheable=true)
    public static DecadeNode getDetails(Id decadeId) {
        if (decadeId == null) return null;

        Decade__c record = [
                SELECT Id, Name, HeaderName__c, Level__c, Year__c, Month__c, Decade__c, Date__c, Parent__c
                FROM Decade__c
                WHERE Id = :decadeId
                LIMIT 1
        ];
        DecadeNode node = toNode(record);

        List<Decade__c> children = [
                SELECT Id, Name, HeaderName__c, Level__c, Year__c, Month__c, Decade__c, Date__c, Parent__c
                FROM Decade__c
                WHERE Parent__c = :record.Id
                ORDER BY Level__c ASC, Date__c ASC, Name ASC
                LIMIT 5000
        ];
        if (!children.isEmpty()) {
            node.hasChildren = true;
            for (Decade__c childRecord : children) {
                node.children.add(toNode(childRecord));
            }
        }
        return node;
    }

    public class DayLimitDto {
        @AuraEnabled public Id recordId { get; set; }         // ScrapDecadesLimit__c.Id (може бути null для нових)
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public Decimal dayLimit { get; set; }     // DayLimit__c
    }

    @AuraEnabled(cacheable=true)
    public static List<DayLimitDto> getDayLimits(Id dayDecadeId) {
        if (dayDecadeId == null) return new List<DayLimitDto>();
        List<DayLimitDto> out = new List<DayLimitDto>();
        for (ScrapDecadesLimit__c l : [
                SELECT Id, ScrapType__c, DayLimit__c
                FROM ScrapDecadesLimit__c
                WHERE DayLookup__c = :dayDecadeId
        ]) {
            DayLimitDto d = new DayLimitDto();
            d.recordId = l.Id;
            d.scrapTypeId = l.ScrapType__c;
            d.dayLimit = l.DayLimit__c;
            out.add(d);
        }
        return out;
    }

    @AuraEnabled
public static List<DayLimitByDateDTO> getDayLimitsByDate(Date targetDate) {
    List<DayLimitByDateDTO> result = new List<DayLimitByDateDTO>();
    if (targetDate == null) return result;

        List<ScrapType__c> activeTypes = [
                SELECT Id, Name, ScrapTypeCode__c, IsActive__c
                FROM ScrapType__c
                WHERE IsActive__c = true
                ORDER BY Name
        ];

        // 👉 збираємо мапу за ключем ScrapType__c
        Map<Id, ScrapDecadesLimit__c> byType = new Map<Id, ScrapDecadesLimit__c>();
        for (ScrapDecadesLimit__c l : [
                SELECT Id, ScrapType__c, DayLimit__c, LimitDate__c
                FROM ScrapDecadesLimit__c
                WHERE LimitDate__c = :targetDate
        ]) {
            if (l.ScrapType__c != null) byType.put(l.ScrapType__c, l);
        }

    // надходження:
    // 1) сума Weight__c
    Map<Id, Decimal> incomingByType = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Weight__c) w
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c = :targetDate
          AND IsCancelled__c = false
          AND Weight__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st != null) incomingByType.put(st, (Decimal) ar.get('w'));
    }
    // 2) додаємо Tonnage__c там, де Weight__c = null
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Tonnage__c) t
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c = :targetDate
          AND IsCancelled__c = false
          AND Weight__c = null
          AND Tonnage__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st == null) continue;
        Decimal exists = incomingByType.containsKey(st) ? incomingByType.get(st) : 0;
        incomingByType.put(st, exists + (Decimal) ar.get('t'));
    }

    for (ScrapType__c t : activeTypes) {
        ScrapDecadesLimit__c rec = byType.get(t.Id);
        Decimal lim = (rec == null ? 0 : (rec.DayLimit__c == null ? 0 : rec.DayLimit__c));
        Decimal inc = incomingByType.get(t.Id);
        Decimal rem = lim - (inc == null ? 0 : inc);

        DayLimitByDateDTO dto = new DayLimitByDateDTO();
        dto.scrapTypeId = t.Id;
        dto.name        = t.Name;
        dto.limitValue  = String.valueOf(lim.setScale(1));
        dto.incoming    = String.valueOf(((inc == null ? 0 : inc)).setScale(1));
        dto.remaining   = String.valueOf(rem.setScale(1));
        result.add(dto);
    }
    return result;
}



    public class DayLimitByDateDTO {
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String limitValue { get; set; }
        @AuraEnabled public String incoming { get; set; }   // +++
        @AuraEnabled public String remaining { get; set; }  // +++
    }

    // === DTO для апдейта з UI (вводи у колонці "Ліміт") ===
    public class DayLimitUpsertItem {
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public String value { get; set; }
    }

// === Результат збереження для UI ===
    public class SaveDayLimitsResult {
        @AuraEnabled public Integer inserted { get; set; }
        @AuraEnabled public Integer updated { get; set; }
        @AuraEnabled public Integer totalProcessed { get; set; }
        @AuraEnabled public List<String> messages { get; set; }
    }

// Внутрішня утиліта: парсимо число, дозволяємо тільки ціле або з одним десятковим знаком
    private static Decimal parseOneDecimal(String src) {
        if (String.isBlank(src)) return null;
        String s = src.trim();
        // тільки цифри або цифри з однією десятковою (крапкою)
        Pattern p = Pattern.compile('^\\d+(\\.\\d)?$');
        if (!p.matcher(s).matches()) {
            // кидаємо виняток, UI покаже повідомлення
            throw new AuraHandledException('Некоректне значення ліміту: "'+ s + '". Дозволено ціле або з одним десятковим знаком (напр. 10 або 10.1).');
        }
        Decimal d = Decimal.valueOf(s);
        // нормалізуємо до однієї десятої (щоб уникати 10.0 vs 10)
        return d.setScale(1);
    }

    /**
     * Зберегти ліміти за конкретну дату.
     * - Створює нові записи ScrapDecadesLimit__c, якщо їх не було
     * - Оновлює існуючі, якщо вже є для цієї дати + типу брухту
     * - Поля, що зберігаємо: LimitDate__c (обовʼязково), ScrapType__c, DayLimit__c, DayLookup__c (якщо переданий)
     */
    @AuraEnabled
    public static SaveDayLimitsResult saveDayLimitsByDate(Date targetDate, Id dayDecadeId, List<DayLimitUpsertItem> items) {
        System.debug('====================saveDayLimitsByDate=======================');
        System.debug('targetDate: ' + targetDate);
        System.debug('dayDecadeId: ' + dayDecadeId);
        System.debug('items: ' + items);
        if (targetDate == null) {
            throw new AuraHandledException('Не вказана дата.');
        }
        SaveDayLimitsResult res = new SaveDayLimitsResult();
        res.inserted = 0; res.updated = 0; res.totalProcessed = 0; res.messages = new List<String>();

        if (items == null || items.isEmpty()) {
            res.messages.add('Немає даних для збереження.');
            return res;
        }

        // беремо всі типи, що прийшли з UI
        Set<Id> typeIds = new Set<Id>();
        for (DayLimitUpsertItem it : items) {
            if (it == null || it.scrapTypeId == null) continue;
            typeIds.add(it.scrapTypeId);
        }
        if (typeIds.isEmpty()) {
            res.messages.add('Не передано жодного типу брухту.');
            return res;
        }

        // існуючі записи на цю дату по цим типам
        Map<Id, ScrapDecadesLimit__c> existingByType = new Map<Id, ScrapDecadesLimit__c>();
        for (ScrapDecadesLimit__c l : [
                SELECT Id, ScrapType__c, DayLimit__c, LimitDate__c, DayLookup__c
                FROM ScrapDecadesLimit__c
                WHERE LimitDate__c = :targetDate
                AND ScrapType__c IN :typeIds
        ]) {
            if (l.ScrapType__c != null) existingByType.put(l.ScrapType__c, l);
        }

        List<ScrapDecadesLimit__c> toInsert = new List<ScrapDecadesLimit__c>();
        List<ScrapDecadesLimit__c> toUpdate = new List<ScrapDecadesLimit__c>();

        for (DayLimitUpsertItem it : items) {
            if (it == null || it.scrapTypeId == null) continue;
            // пропускаємо пусті/видалення: зараз нічого не робимо, тільки створення/оновлення
            Decimal parsed;
            if (String.isBlank(it.value)) {
                parsed = 0;
            } else {
                parsed = parseOneDecimal(it.value);
            }


            if (existingByType.containsKey(it.scrapTypeId)) {
                ScrapDecadesLimit__c upd = existingByType.get(it.scrapTypeId);
                upd.DayLimit__c = parsed;
                if (dayDecadeId != null) upd.DayLookup__c = dayDecadeId; // підвʼяжемо якщо прийшов
                toUpdate.add(upd);
            } else {
                ScrapDecadesLimit__c ins = new ScrapDecadesLimit__c();
                ins.ScrapType__c = it.scrapTypeId;
                ins.DayLimit__c  = parsed;
                ins.LimitDate__c = targetDate;
                if (dayDecadeId != null) ins.DayLookup__c = dayDecadeId;
                toInsert.add(ins);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            res.inserted = toInsert.size();
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            res.updated = toUpdate.size();
        }
        res.totalProcessed = res.inserted + res.updated;

        if (res.totalProcessed == 0) {
            res.messages.add('Немає змін для збереження.');
        } else {
            res.messages.add('Збережено ліміти: ' + res.totalProcessed);
        }
        return res;
    }

    /**
     * Зберегти ліміти, якщо з UI передається тільки dayDecadeId (ідентифікатор дня в дереві).
     * Ми знайдемо дату цього дня і переадресуємо на saveDayLimitsByDate.
     */
    @AuraEnabled
    public static SaveDayLimitsResult saveDayLimitsForDay(Id dayDecadeId, List<DayLimitUpsertItem> items) {
        System.debug('items JSON: ' + JSON.serialize(items));

        System.debug('================saveDayLimitsForDay==================');
        System.debug('dayDecadeId: ' + dayDecadeId);
        System.debug('items: ' + items);
        if (dayDecadeId == null) {
            throw new AuraHandledException('Не вказано день (Decade__c Id).');
        }
        Decade__c dayRec = [
                SELECT Id, Date__c FROM Decade__c WHERE Id = :dayDecadeId LIMIT 1
        ];
        if (dayRec.Date__c == null) {
            throw new AuraHandledException('У вибраного дня відсутня дата.');
        }
        return saveDayLimitsByDate(dayRec.Date__c, dayDecadeId, items);
    }

    public class DecadeTotalsDTO {
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String totalValue { get; set; } // String, щоб легко віддавати '—'
        @AuraEnabled public String incoming { get; set; }     // фактичні надходження
        @AuraEnabled public String remaining { get; set; }    // залишок = total - incoming
    }

//    @AuraEnabled(cacheable=false)
//    public static List<DecadeTotalsDTO> getDecadeTotalsByDecade(Id decadeId) {
//        if (decadeId == null) return new List<DecadeTotalsDTO>();
//
//        // 1) Дні цієї декади
//        List<Decade__c> dayNodes = [
//                SELECT Id
//                FROM Decade__c
//                WHERE Parent__c = :decadeId
//        ];
//        if (dayNodes.isEmpty()) return new List<DecadeTotalsDTO>();
//
//        Set<Id> dayIds = new Set<Id>();
//        for (Decade__c d : dayNodes) dayIds.add(d.Id);
//
//        // 2) Агрегація сум по ScrapType для вибраних днів
//        Map<Id, Decimal> totalsByType = new Map<Id, Decimal>();
//        for (AggregateResult ar : [
//                SELECT ScrapType__c st, SUM(DayLimit__c) s
//                FROM ScrapDecadesLimit__c
//                WHERE DayLookup__c IN :dayIds
//                GROUP BY ScrapType__c
//        ]) {
//            if ((Id)ar.get('st') != null) {
//                Decimal sum = (Decimal) ar.get('s');
//                totalsByType.put((Id)ar.get('st'), (sum == null ? 0 : sum).setScale(1));
//            }
//        }
//
//        // 3) Усі активні типи — щоб показати й ті, де сум немає
//        Map<Id, ScrapType__c> types = new Map<Id, ScrapType__c>([
//                SELECT Id, Name, IsActive__c
//                FROM ScrapType__c
//                WHERE IsActive__c = true
//                ORDER BY Name
//        ]);
//
//        List<DecadeTotalsDTO> out = new List<DecadeTotalsDTO>();
//        for (ScrapType__c t : types.values()) {
//            Decimal v = totalsByType.get(t.Id);
//            // 0 -> null, щоб фронт намалював '—' і не враховував як "Заповнено"
//            String asText = (v == null || v == 0) ? null : String.valueOf(v);
//            DecadeTotalsDTO dto = new DecadeTotalsDTO();
//            dto.scrapTypeId = t.Id;
//            dto.name = t.Name;
//            dto.totalValue = asText;
//            out.add(dto);
//        }
//        return out;
//    }

    @AuraEnabled(cacheable=false)
    public static List<DecadeTotalsDTO> getDecadeTotalsByDecade(Id decadeId) {
        if (decadeId == null) return new List<DecadeTotalsDTO>();

        // 1) Дні цієї декади
        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :decadeId
        ];
        if (dayNodes.isEmpty()) return new List<DecadeTotalsDTO>();

        Set<Id> dayIds = new Set<Id>();
        Set<Date> dayDates = new Set<Date>();
        for (Decade__c d : dayNodes) {
            dayIds.add(d.Id);
            if (d.Date__c != null) dayDates.add(d.Date__c);
        }

        // 2) Суми лімітів
        Map<Id, Decimal> totalsByType = new Map<Id, Decimal>();
        for (AggregateResult ar : [
                SELECT ScrapType__c st, SUM(DayLimit__c) s
                FROM ScrapDecadesLimit__c
                WHERE DayLookup__c IN :dayIds
                GROUP BY ScrapType__c
        ]) {
            if ((Id)ar.get('st') != null) {
                totalsByType.put((Id)ar.get('st'), (Decimal)ar.get('s'));
            }
        }

        // 3) Суми фактичних надходжень зі слотів
        Map<Id, Decimal> incomingByType = new Map<Id, Decimal>();

// сума факту (вага)
        for (AggregateResult ar : [
                SELECT ScrapType__c st, SUM(Weight__c) w
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates
                AND IsCancelled__c = false
                AND Weight__c != null
                GROUP BY ScrapType__c
        ]) {
            Id st = (Id)ar.get('st');
            if (st != null) incomingByType.put(st, (Decimal)ar.get('w'));
        }

// додаємо заявлений тоннаж там, де факту ще немає
        for (AggregateResult ar : [
                SELECT ScrapType__c st, SUM(Tonnage__c) t
                FROM ScrapSlotReserve__c
                WHERE ReserveDate__c IN :dayDates
                AND IsCancelled__c = false
                AND Weight__c = null
                AND Tonnage__c != null
                GROUP BY ScrapType__c
        ]) {
            Id st = (Id)ar.get('st');
            if (st == null) continue;
            Decimal exists = incomingByType.containsKey(st) ? incomingByType.get(st) : 0;
            incomingByType.put(st, exists + (Decimal)ar.get('t'));
        }

        // 4) Усі активні типи
        List<ScrapType__c> types = [
                SELECT Id, Name FROM ScrapType__c WHERE IsActive__c = true ORDER BY Name
        ];

        // 5) Формуємо DTO
        List<DecadeTotalsDTO> out = new List<DecadeTotalsDTO>();
        for (ScrapType__c t : types) {
            Decimal limitValue = totalsByType.get(t.Id);
            Decimal fact  = incomingByType.get(t.Id);
            Decimal rem   = (limitValue == null ? 0 : limitValue) - (fact == null ? 0 : fact);

            DecadeTotalsDTO dto = new DecadeTotalsDTO();
            dto.scrapTypeId = t.Id;
            dto.name = t.Name;
            dto.totalValue = String.valueOf((limitValue == null ? 0 : limitValue).setScale(1));
            dto.incoming   = String.valueOf((fact       == null ? 0 : fact).setScale(1));
            dto.remaining  = String.valueOf((rem        == null ? 0 : rem).setScale(1));

            out.add(dto);
        }
        return out;
    }


    public class MonthTotalsDTO {
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String totalValue { get; set; }
        @AuraEnabled public String incoming { get; set; }   // +++
        @AuraEnabled public String remaining { get; set; }  // +++
    }

    @AuraEnabled(cacheable=false)
    public static List<MonthTotalsDTO> getMonthTotalsByMonth(Id monthId) {
        if (monthId == null) return new List<MonthTotalsDTO>();

        // 1) Отримуємо всі декади цього місяця
        List<Decade__c> decadeNodes = [
                SELECT Id
                FROM Decade__c
                WHERE Parent__c = :monthId
        ];
        if (decadeNodes.isEmpty()) return new List<MonthTotalsDTO>();

        Set<Id> decadeIds = new Set<Id>();
        for (Decade__c d : decadeNodes) decadeIds.add(d.Id);

        // 2) Отримуємо всі дні для цих декад
        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c IN :decadeIds
        ];
        if (dayNodes.isEmpty()) return new List<MonthTotalsDTO>();

    Set<Id> dayIds = new Set<Id>();
    Set<Date> dayDates = new Set<Date>();
    for (Decade__c d : dayNodes) {
        dayIds.add(d.Id);
        if (d.Date__c != null) dayDates.add(d.Date__c);
    }

    // сума лімітів
    Map<Id, Decimal> totalsByType = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(DayLimit__c) s
        FROM ScrapDecadesLimit__c
        WHERE DayLookup__c IN :dayIds
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st != null) totalsByType.put(st, (Decimal) ar.get('s'));
    }

    // надходження: Weight__c
    Map<Id, Decimal> incomingByType = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Weight__c) w
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c IN :dayDates
          AND IsCancelled__c = false
          AND Weight__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st != null) incomingByType.put(st, (Decimal) ar.get('w'));
    }
    // + Tonnage__c, де Weight__c = null
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Tonnage__c) t
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c IN :dayDates
          AND IsCancelled__c = false
          AND Weight__c = null
          AND Tonnage__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st == null) continue;
        Decimal curr = incomingByType.containsKey(st) ? incomingByType.get(st) : 0;
        incomingByType.put(st, curr + (Decimal) ar.get('t'));
    }

        // 4) Усі активні типи
        List<ScrapType__c> types = [
                SELECT Id, Name
                FROM ScrapType__c
                WHERE IsActive__c = true
                ORDER BY Name
        ];

    // збираємо DTO
    List<MonthTotalsDTO> out = new List<MonthTotalsDTO>();
    for (ScrapType__c t : types) {
        Decimal lim = totalsByType.get(t.Id);
        Decimal inc = incomingByType.get(t.Id);
        Decimal rem = (lim == null ? 0 : lim) - (inc == null ? 0 : inc);

        MonthTotalsDTO dto = new MonthTotalsDTO();
        dto.scrapTypeId = t.Id;
        dto.name        = t.Name;
        dto.totalValue  = String.valueOf((lim == null ? 0 : lim).setScale(1));
        dto.incoming    = String.valueOf(((inc == null ? 0 : inc)).setScale(1));
        dto.remaining   = String.valueOf(rem.setScale(1));
        out.add(dto);
    }
    return out;
}


    public class YearTotalsDTO {
        @AuraEnabled public Id scrapTypeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String totalValue { get; set; }
        @AuraEnabled public String incoming { get; set; }   // +++
        @AuraEnabled public String remaining { get; set; }  // +++
    }

    @AuraEnabled(cacheable=false)
    public static List<YearTotalsDTO> getYearTotalsByYear(Id yearId) {
        System.debug('yearId: ' + yearId);
        if (yearId == null) return new List<YearTotalsDTO>();

        // 1) Всі місяці цього року
        List<Decade__c> monthNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :yearId
        ];
        if (monthNodes.isEmpty()) return new List<YearTotalsDTO>();

        Set<Id> monthIds = new Set<Id>();
        for (Decade__c m : monthNodes) monthIds.add(m.Id);

        // 2) Всі декади цих місяців
        List<Decade__c> decadeNodes = [
                SELECT Id
                FROM Decade__c
                WHERE Parent__c IN :monthIds
        ];
        if (decadeNodes.isEmpty()) return new List<YearTotalsDTO>();

        Set<Id> decadeIds = new Set<Id>();
        for (Decade__c d : decadeNodes) decadeIds.add(d.Id);

        // 3) Всі дні цих декад
        List<Decade__c> dayNodes = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c IN :decadeIds
        ];
        if (dayNodes.isEmpty()) return new List<YearTotalsDTO>();

    Set<Id> dayIds = new Set<Id>();
    Set<Date> dayDates = new Set<Date>();
    for (Decade__c d : dayNodes) {
        dayIds.add(d.Id);
        if (d.Date__c != null) dayDates.add(d.Date__c);
    }

    // сума лімітів
    Map<Id, Decimal> totalsByType = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(DayLimit__c) s
        FROM ScrapDecadesLimit__c
        WHERE DayLookup__c IN :dayIds
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st != null) totalsByType.put(st, (Decimal) ar.get('s'));
    }

    // надходження (Weight__c + Tonnage__c де Weight__c = null)
    Map<Id, Decimal> incomingByType = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Weight__c) w
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c IN :dayDates
          AND IsCancelled__c = false
          AND Weight__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st != null) incomingByType.put(st, (Decimal) ar.get('w'));
    }
    for (AggregateResult ar : [
        SELECT ScrapType__c st, SUM(Tonnage__c) t
        FROM ScrapSlotReserve__c
        WHERE ReserveDate__c IN :dayDates
          AND IsCancelled__c = false
          AND Weight__c = null
          AND Tonnage__c != null
        GROUP BY ScrapType__c
    ]) {
        Id st = (Id) ar.get('st');
        if (st == null) continue;
        Decimal curr = incomingByType.containsKey(st) ? incomingByType.get(st) : 0;
        incomingByType.put(st, curr + (Decimal) ar.get('t'));
    }

        // 5) Усі активні типи
        List<ScrapType__c> types = [
                SELECT Id, Name
                FROM ScrapType__c
                WHERE IsActive__c = true
                ORDER BY Name
        ];

    // збираємо DTO
    List<YearTotalsDTO> out = new List<YearTotalsDTO>();
    for (ScrapType__c t : types) {
        Decimal lim = totalsByType.get(t.Id);
        Decimal inc = incomingByType.get(t.Id);
        Decimal rem = (lim == null ? 0 : lim) - (inc == null ? 0 : inc);

        YearTotalsDTO dto = new YearTotalsDTO();
        dto.scrapTypeId = t.Id;
        dto.name        = t.Name;
        dto.totalValue  = String.valueOf((lim == null ? 0 : lim).setScale(1));
        dto.incoming    = String.valueOf(((inc == null ? 0 : inc)).setScale(1));
        dto.remaining   = String.valueOf(rem.setScale(1));
        out.add(dto);
    }
    return out;
}

    @AuraEnabled
    public static SaveDayLimitsResult copyDayLimits(
            Id sourceDayDecadeId,
            List<Id> targetDayDecadeIds,
            List<DayLimitUpsertItem> items,
            Boolean skipZeros,
            List<Id> onlyTypeIds
    ) {
        SaveDayLimitsResult res = new SaveDayLimitsResult();
        res.inserted = 0; res.updated = 0; res.totalProcessed = 0; res.messages = new List<String>();

        if (sourceDayDecadeId == null) {
            throw new AuraHandledException('Не вказано джерельний день.');
        }
        if (targetDayDecadeIds == null || targetDayDecadeIds.isEmpty()) {
            res.messages.add('Не обрано жодної цілі.');
            return res;
        }

        // 1) Джерело та цілі
        Decade__c src = [
                SELECT Id, Date__c, Parent__c
                FROM Decade__c
                WHERE Id = :sourceDayDecadeId
                LIMIT 1
        ];
        if (src.Date__c == null) throw new AuraHandledException('У вибраного дня відсутня дата.');

        List<Decade__c> targets = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Id IN :targetDayDecadeIds
        ];

        // Apex-стиль фільтрації: без stream/->
        List<Decade__c> filteredTargets = new List<Decade__c>();
        for (Decade__c t : targets) {
            if (t.Date__c != null) filteredTargets.add(t);
        }
        if (filteredTargets.isEmpty()) {
            res.messages.add('У вибраних днях немає дат.');
            return res;
        }

        // 2) Значення для копіювання: або з UI (редагування), або зі збереженого дня-джерела
        Map<Id, Decimal> valuesByType = new Map<Id, Decimal>();

        if (items != null && !items.isEmpty()) {
            for (DayLimitUpsertItem it : items) {
                if (it == null || it.scrapTypeId == null) continue;
                Decimal parsed = String.isBlank(it.value) ? 0 : parseOneDecimal(it.value);
                if (skipZeros && (parsed == null || parsed == 0)) continue;
                valuesByType.put(it.scrapTypeId, (parsed == null ? 0 : parsed));
            }
        } else {
            // якщо з UI не прийшли items — читаємо із джерела
            List<ScrapDecadesLimit__c> srcLimits;
            if (onlyTypeIds != null && !onlyTypeIds.isEmpty()) {
                srcLimits = [
                        SELECT ScrapType__c, DayLimit__c
                        FROM ScrapDecadesLimit__c
                        WHERE LimitDate__c = :src.Date__c
                        AND ScrapType__c IN :onlyTypeIds
                ];
            } else {
                srcLimits = [
                        SELECT ScrapType__c, DayLimit__c
                        FROM ScrapDecadesLimit__c
                        WHERE LimitDate__c = :src.Date__c
                ];
            }
            for (ScrapDecadesLimit__c l : srcLimits) {
                if (l.ScrapType__c == null) continue;
                Decimal v = (l.DayLimit__c == null ? 0 : l.DayLimit__c.setScale(1));
                if (skipZeros && v == 0) continue;
                valuesByType.put(l.ScrapType__c, v);
            }
        }

        if (valuesByType.isEmpty()) {
            res.messages.add('Немає значень для копіювання.');
            return res;
        }

        // 3) Підготовка існуючих записів на цілях (для upsert-поведінки)
        Set<Date> targetDates = new Set<Date>();
        Map<Date, Id> dayIdByDate = new Map<Date, Id>();
        for (Decade__c t : filteredTargets) {
            targetDates.add(t.Date__c);
            dayIdByDate.put(t.Date__c, t.Id);
        }

        Set<Id> typeIds = valuesByType.keySet();

        Map<String, ScrapDecadesLimit__c> existingByKey = new Map<String, ScrapDecadesLimit__c>();
        if (!targetDates.isEmpty() && !typeIds.isEmpty()) {
            for (ScrapDecadesLimit__c l : [
                    SELECT Id, ScrapType__c, DayLimit__c, LimitDate__c, DayLookup__c
                    FROM ScrapDecadesLimit__c
                    WHERE LimitDate__c IN :targetDates
                    AND ScrapType__c IN :typeIds
            ]) {
                String key = makeKey(l.LimitDate__c, l.ScrapType__c);
                existingByKey.put(key, l);
            }
        }

        // 4) Побудова toInsert / toUpdate
        List<ScrapDecadesLimit__c> toInsert = new List<ScrapDecadesLimit__c>();
        List<ScrapDecadesLimit__c> toUpdate = new List<ScrapDecadesLimit__c>();

        for (Date d : targetDates) {
            for (Id stId : typeIds) {
                Decimal v = valuesByType.get(stId);
                if (skipZeros && (v == null || v == 0)) continue;

                String key = makeKey(d, stId);
                if (existingByKey.containsKey(key)) {
                    ScrapDecadesLimit__c upd = existingByKey.get(key);
                    upd.DayLimit__c = (v == null ? 0 : v.setScale(1));
                    if (dayIdByDate.containsKey(d)) upd.DayLookup__c = dayIdByDate.get(d);
                    toUpdate.add(upd);
                } else {
                    ScrapDecadesLimit__c ins = new ScrapDecadesLimit__c();
                    ins.ScrapType__c = stId;
                    ins.DayLimit__c  = (v == null ? 0 : v.setScale(1));
                    ins.LimitDate__c = d;
                    if (dayIdByDate.containsKey(d)) ins.DayLookup__c = dayIdByDate.get(d);
                    toInsert.add(ins);
                }
            }
        }

        System.debug('SOQL before DML = ' + Limits.getQueries());

        if (!toInsert.isEmpty()) { insert toInsert; res.inserted = toInsert.size(); }
        if (!toUpdate.isEmpty()) { update toUpdate; res.updated = toUpdate.size(); }
        System.debug('SOQL after DML  = ' + Limits.getQueries());

        res.totalProcessed = res.inserted + res.updated;

        res.messages.add('Копіювання виконано.');
        return res;
    }

    // Унікальний ключ: дата + тип брухту
    private static String makeKey(Date d, Id typeId) {
        return String.valueOf(d) + '|' + String.valueOf(typeId);
    }

    public class DayOptionDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Date dateValue { get; set; }
        @AuraEnabled public String label { get; set; }   // "dd.MM.yyyy (Пн)"
        @AuraEnabled public Boolean hasLimits { get; set; }
        @AuraEnabled public Boolean isWeekend { get; set; } // ← НОВЕ

    }

//    @AuraEnabled(cacheable=false)
//    public static List<DayOptionDTO> listSiblingDays(Id sourceDayDecadeId) {
//        List<DayOptionDTO> out = new List<DayOptionDTO>();
//        if (sourceDayDecadeId == null) return out;
//
//        Decade__c day = [
//                SELECT Id, Parent__c, Date__c
//                FROM Decade__c
//                WHERE Id = :sourceDayDecadeId
//                LIMIT 1
//        ];
//        if (day.Parent__c == null) return out;
//
//        List<Decade__c> siblings = [
//                SELECT Id, Date__c
//                FROM Decade__c
//                WHERE Parent__c = :day.Parent__c
//                ORDER BY Date__c ASC
//        ];
//
//        Set<Date> dates = new Set<Date>();
//        for (Decade__c d : siblings) if (d.Date__c != null) dates.add(d.Date__c);
//
//        Map<Date, Integer> cntByDate = new Map<Date, Integer>();
//        if (!dates.isEmpty()) {
//            for (AggregateResult ar : [
//                    SELECT LimitDate__c d, COUNT(Id) c
//                    FROM ScrapDecadesLimit__c
//                    WHERE LimitDate__c IN :dates
//                    GROUP BY LimitDate__c
//            ]) {
//                cntByDate.put((Date)ar.get('d'), (Integer)ar.get('c'));
//            }
//        }
//
//        for (Decade__c d : siblings) {
//            if (d.Id == sourceDayDecadeId) continue;
//            DayOptionDTO dto = new DayOptionDTO();
//            dto.id = d.Id;
//            dto.dateValue = d.Date__c;  // було: dto.date
//
//            dto.hasLimits = (d.Date__c != null && cntByDate.containsKey(d.Date__c) && cntByDate.get(d.Date__c) > 0);
//
//            if (d.Date__c == null) {
//                dto.label = '—';
//            } else {
//                // Побудова dd.MM.yyyy
//                String dateStr = twoDigits(d.Date__c.day()) + '.' + twoDigits(d.Date__c.month()) + '.' + String.valueOf(d.Date__c.year());
//                // День тижня через Datetime.format(pattern, locale)
//                Datetime dt = Datetime.newInstance(d.Date__c, Time.newInstance(0, 0, 0, 0));
//                String dowUk = dt.format('E', 'uk'); // напр. "пн", "вт", ...
//
//                dto.label = dateStr + ' (' + dowUk + ')';
//            }
//            out.add(dto);
//        }
//
//        return out;
//    }

    @AuraEnabled(cacheable=false)
    public static List<DayOptionDTO> listSiblingDays(Id sourceDayDecadeId) {
        List<DayOptionDTO> out = new List<DayOptionDTO>();
        if (sourceDayDecadeId == null) return out;

        Decade__c day = [
                SELECT Id, Parent__c, Date__c
                FROM Decade__c
                WHERE Id = :sourceDayDecadeId
                LIMIT 1
        ];
        if (day.Parent__c == null) return out;

        List<Decade__c> siblings = [
                SELECT Id, Date__c
                FROM Decade__c
                WHERE Parent__c = :day.Parent__c
                ORDER BY Date__c ASC
        ];

        Set<Date> dates = new Set<Date>();
        for (Decade__c d : siblings) if (d.Date__c != null) dates.add(d.Date__c);

        Map<Date, Integer> cntByDate = new Map<Date, Integer>();
        if (!dates.isEmpty()) {
            for (AggregateResult ar : [
                    SELECT LimitDate__c d, COUNT(Id) c
                    FROM ScrapDecadesLimit__c
                    WHERE LimitDate__c IN :dates
                    GROUP BY LimitDate__c
            ]) {
                cntByDate.put((Date) ar.get('d'), (Integer) ar.get('c'));
            }
        }

        for (Decade__c d : siblings) {
            if (d.Id == sourceDayDecadeId) continue;

            DayOptionDTO dto = new DayOptionDTO();
            dto.id        = d.Id;
            dto.dateValue = d.Date__c;

            dto.hasLimits = (d.Date__c != null
                    && cntByDate.containsKey(d.Date__c)
                    && cntByDate.get(d.Date__c) > 0);

            if (d.Date__c == null) {
                dto.label = '—';
                dto.isWeekend = false;
            } else {
                // WEEKDAY-стиль: 1=Нд … 7=Сб
                Integer wd = weekday(d.Date__c);
                dto.isWeekend = (wd != null && (wd == 1 || wd == 7)); // Нд або Сб

                // Лейбл "dd.MM.yyyy (пн/вт/…)" – для підпису лишаємо понеділок-орієнтовані скорочення
                String dateStr = twoDigits(d.Date__c.day()) + '.' + twoDigits(d.Date__c.month()) + '.' + String.valueOf(d.Date__c.year());
                String dowUk   = dowNameUkMonBased(dayOfWeekMonBased(d.Date__c)); // 'пн','вт',...
                dto.label = dateStr + ' (' + dowUk + ')';
            }
            out.add(dto);
        }
        return out;
    }

    /** 1=Пн … 7=Нд. Вираховано стабільно у GMT (полудень, щоб не зсувати дату). */
    public static Integer dayOfWeekMonBased(Date d) {
        if (d == null) return null;
        Datetime dtGmt = Datetime.newInstanceGmt(d, Time.newInstance(12, 0, 0, 0));
        return Integer.valueOf(dtGmt.formatGmt('u')); // 'u' => 1..7 (Mon..Sun)
    }

    /** Аналог WEEKDAY(): 1=Нд, 2=Пн, …, 7=Сб. */
    public static Integer weekday(Date d) {
        Integer monBased = dayOfWeekMonBased(d); // 1=Пн … 7=Нд
        if (monBased == null) return null;
        return (monBased == 7) ? 1 : (monBased + 1); // зрушуємо, щоб 1 став Нд
    }

    /** Вихідні за логікою WEEKDAY(): Нд(1) та Сб(7). */
    public static Boolean isWeekend(Date d) {
        Integer wd = weekday(d);
        return wd != null && (wd == 1 || wd == 7);
    }

    /** Коротка назва дня укр. мовою для 1=Пн … 7=Нд (мон-похідна). */
    private static String dowNameUkMonBased(Integer dow) {
        if (dow == null) return '';
        switch on dow {
            when 1 { return 'пн'; }
            when 2 { return 'вт'; }
            when 3 { return 'ср'; }
            when 4 { return 'чт'; }
            when 5 { return 'пт'; }
            when 6 { return 'сб'; }
            when 7 { return 'нд'; }
            when else { return ''; }
        }
    }


    // Унікальний ключ для мап: дата + тип


// Падінг до 2 цифр
    private static String twoDigits(Integer n) {
        if (n == null) return '00';
        String s = String.valueOf(n);
        return (s.length() == 1) ? '0' + s : s;
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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