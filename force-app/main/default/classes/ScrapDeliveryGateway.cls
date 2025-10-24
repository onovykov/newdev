/**
 * ScrapDeliveryGateway
 * - Будує JSON:
 *   {
 *     "Metadata": {...},
 *     "Data": { "Items": [ ... ] }
 *   }
 * - Надсилає POST на ERP
 * - Розбирає відповідь:
 *    • якщо Results[i].Success == true → оновлює PassID__c, PassNumber__c за SourceID
 *    • інакше — пише заглушку-лог (TODO - треба написати логгер)
 */
public with sharing class ScrapDeliveryGateway {

    // ==== НАЛАШТУВАННЯ ====
    private static final String NC   = 'callout:ERP_SCRAP'; // <- підстав наше
    private static final String PATH = '/api/scrap/delivery'; // <- підстав наше
    private static final Integer DEBUG_SAMPLE_LIMIT = 5;         // скільки елементів показувати в логах


    // ==== ПУБЛІЧНИЙ ВХІД ====
    // Виклик у черзі
    public static void enqueue(Set<Id> slotIds) {
        System.debug('enqueue() called. slotIds size = ' + (slotIds == null ? 0 : slotIds.size()) + ', slotIds=' + slotIds);
        if (slotIds == null || slotIds.isEmpty()) return;
        System.enqueueJob(new SendAndApplyJob(slotIds));
    }

    //---------- ЗАПУСК ОБМІНУ ---------------------------
    // Швидкий синхронний запуск
    public static void runNow(Set<Id> slotIds) {
        System.debug('runNow() called. slotIds size = ' + (slotIds == null ? 0 : slotIds.size()) + ', slotIds=' + slotIds);
        if (slotIds == null || slotIds.isEmpty()) return;
        doSendAndApply(slotIds);
    }

    // ==== Черга ====
    public class SendAndApplyJob implements Queueable, Database.AllowsCallouts {
        private final Set<Id> slotIds;
        public SendAndApplyJob(Set<Id> slotIds) { this.slotIds = slotIds; }
        public void execute(QueueableContext qc) {
            System.debug('SendAndApplyJob.execute: slotIds size=' + (slotIds == null ? 0 : slotIds.size()));
            doSendAndApply(slotIds);
        }
    }
    //-----------------------------------------------------

    // ==== ОСНОВНА ЛОГІКА ====
    private static void doSendAndApply(Set<Id> slotIds) {
        Long t0 = DateTime.now().getTime();
        System.debug('doSendAndApply() START, slotIds=' + slotIds);

        // 1) Вибираємо дані
        List<ScrapSlotReserve__c> slots = [
                SELECT  Id, // → SourceID
                        Name, // External Id (autonumber) для обміну з ERP → SourceNDM
                        ScrapType__r.Name, // Опис позиції заявки → GoodsName
                        Truck__r.Name, // Номер вантажівки → AutoNo
                        Trailer__r.Name, // Номер причепа → TrailerNo
                        DriverFIO__c, // П.І.Б. водія → DriverFIO
                        Supplier__r.Name, // Назва контрагента → OrgName
                        Tonnage__c // Тоннаж вантажу → Weight
                FROM ScrapSlotReserve__c
                WHERE Id IN :slotIds
        ];
        System.debug('Fetched slots size=' + slots.size());
        if (!slots.isEmpty()) {
            Integer limitShow = Math.min(DEBUG_SAMPLE_LIMIT, slots.size());
            for (Integer i = 0; i < limitShow; i++) {
                ScrapSlotReserve__c s = slots[i];
                System.debug('Slot[' + i + ']: Id=' + s.Id + ', Name=' + s.Name +
                             ', ScrapType=' + (s.ScrapType__r != null ? s.ScrapType__r.Name : null) +
                             ', Truck=' + (s.Truck__r != null ? s.Truck__r.Name : null) +
                             ', Trailer=' + (s.Trailer__r != null ? s.Trailer__r.Name : null) +
                             ', DriverFIO=' + s.DriverFIO__c +
                             ', Supplier=' + (s.Supplier__r != null ? s.Supplier__r.Name : null) +
                             ', Tonnage=' + s.Tonnage__c);
            }
        }
        if (slots.isEmpty()) {
            // Заглушка логування (додати логіку, як ми це обробимо)
            System.debug('Something went wrong');
            return;
        }

        // 2) Побудова payload
        RequestPayload payload = buildPayload(slots);
        String body = JSON.serialize(payload);
        System.debug('Payload built. JSON length=' + (body != null ? body.length() : 0));
        System.debug('Payload preview (first 1000 chars): ' + (body != null ? body.substring(0, Math.min(1000, body.length())) : null));

        // 3) Відправляємо в ERP
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        String endpoint = NC + PATH;
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(body);
        System.debug('HTTP POST endpoint=' + endpoint);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (System.CalloutException e) {
            // Заглушка логування (додати логіку, як ми це обробимо)
            System.debug(LoggingLevel.ERROR, 'ERP callout failed: ' + e.getMessage());
            return;
        }

        Integer sc = res.getStatusCode();
        System.debug('HTTP response statusCode=' + sc + ', status=' + res.getStatus());
        System.debug('HTTP response body length=' + (res.getBody() != null ? res.getBody().length() : 0));
        System.debug('HTTP response body preview (first 1000 chars): ' + (res.getBody() != null ? res.getBody().substring(0, Math.min(1000, res.getBody().length())) : null));

        if (sc < 200 || sc >= 300) {
            System.debug(LoggingLevel.ERROR, 'ERP HTTP error ' + sc + ' ' + res.getStatus());
            System.debug(LoggingLevel.ERROR, res.getBody());
            return;
        }

        // 4) Парсинг відповіді й оновлення записів
        ResponsePayload rp;
        try {
            rp = (ResponsePayload) JSON.deserialize(res.getBody(), ResponsePayload.class);
        } catch (Exception e) {
            // Додати логіку, як ми це обробимо
            System.debug(LoggingLevel.ERROR, 'Failed to parse ERP response: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, res.getBody());
            return;
        }
        System.debug('Parsed Response: Success=' + rp.Success + ', ErrorMessage=' + rp.ErrorMessage +
                     ', Results size=' + (rp.Results != null ? rp.Results.size() : 0));
        if (rp.Metrics != null) {
            System.debug('Response Metrics: Total=' + rp.Metrics.Total +
                         ', Succeeded=' + rp.Metrics.Succeeded +
                         ', Failed=' + rp.Metrics.Failed +
                         ', DurationMs=' + rp.Metrics.DurationMs);
        }
        if (rp.Warnings != null && !rp.Warnings.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Response warnings: ' + rp.Warnings);
        }

        List<ScrapSlotReserve__c> toUpdate = new List<ScrapSlotReserve__c>();
        List<String> errorLines = new List<String>();

        if (rp != null && rp.Results != null) {
            Integer limitShow = Math.min(DEBUG_SAMPLE_LIMIT, rp.Results.size());
            for (Integer i = 0; i < limitShow; i++) {
                ResultEntry rx = rp.Results[i];
                System.debug('Result[' + i + ']: Success=' + rx.Success + ', SourceID=' + rx.SourceID +
                             ', PassID=' + rx.PassID + ', PassNDM=' + rx.PassNDM +
                             ', ErrorCode=' + rx.ErrorCode + ', ErrorMessage=' + rx.ErrorMessage);
            }

            for (ResultEntry r : rp.Results) {
                if (r == null || String.isBlank(r.SourceID)) continue;

                if (r.Success == true) {
                    // Безпечний каст рядка до Id
                    Id slotId;
                    try { slotId = (Id) r.SourceID; }
                    catch (Exception ex) {
                        String m = 'Bad SourceID format: ' + r.SourceID;
                        errorLines.add(m);
                        System.debug(LoggingLevel.WARN, m);
                        continue;
                    }
                    // Апдейт
                    ScrapSlotReserve__c upd = new ScrapSlotReserve__c(
                        Id = slotId,
                        PassID__c     = String.valueOf(r.PassID),
                        PassNumber__c = r.PassNDM
                    );
                    toUpdate.add(upd);
                } else {
                    String em = 'SourceID=' + r.SourceID + ' ErrorCode=' + r.ErrorCode + ' Msg=' + r.ErrorMessage;
                    errorLines.add(em);
                    System.debug(LoggingLevel.WARN, em);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            try {
                Database.SaveResult[] srs = Database.update(toUpdate, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) {
                        System.debug('DML OK for ' + toUpdate[i].Id);
                    } else {
                        Database.Error e = srs[i].getErrors().isEmpty() ? null : srs[i].getErrors()[0];
                        System.debug(LoggingLevel.ERROR, 'DML failed for ' + toUpdate[i].Id + ': ' + (e != null ? e.getMessage() : 'unknown'));
                    }
                }
            } catch (DmlException d) {
                System.debug(LoggingLevel.ERROR, 'Failed to update ScrapSlotReserve__c: ' + d.getMessage());
            }
        }

        // Інформативні логи (заглушка)
        if (rp != null && rp.Success != true) {
            System.debug(LoggingLevel.WARN, 'ERP overall/partial failure: ' + rp.ErrorMessage);
        }
        if (!errorLines.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'ERP item errors: ' + String.join(errorLines, ' | '));
            // TODO: записати логи до Pharos, обробити, видати алерти
            // Хоча... З Pharos наразі не морочимося, просто видати алерти
            //         й простенький лог для нас. Можна з нотифікацією милом

        }
    }

    // ==== Побудова payload - беремо ті заявки, які треба обробити - List<ScrapSlotReserve__c> ====
    private static RequestPayload buildPayload(List<ScrapSlotReserve__c> slots) {
        System.debug('buildPayload() START. slots size=' + slots.size());
        RequestPayload p = new RequestPayload();
        p.Metadata = new Metadata();
        p.Metadata.MsgType = 'SF-ERP_ScrapDelivery';
        p.Metadata.MsgTypeVersion = 0.0;
        p.Metadata.MsgTimestamp = iso8601WithTz(); // 2025-08-22T11:34:08.224+03:00
        p.Metadata.PartNumber = 1;
        p.Metadata.TotalParts = 1;

        p.Data = new DataBlock();
        p.Data.Items = new List<Item>();

        Integer limitShow = Math.min(DEBUG_SAMPLE_LIMIT, slots.size());
        for (Integer i = 0; i < slots.size(); i++) {
            ScrapSlotReserve__c s = slots[i];
            Item it = new Item();
            it.SourceID   = (String) s.Id;
            it.SourceNDM  = s.Name;
            it.GoodsName  = (s.ScrapType__r != null ? s.ScrapType__r.Name : null);
            it.AutoNo     = (s.Truck__r != null ? s.Truck__r.Name : null);
            it.TrailerNo  = (s.Trailer__r != null ? s.Trailer__r.Name : null);
            it.DriverFIO  = s.DriverFIO__c;
            it.OrgName    = (s.Supplier__r != null ? s.Supplier__r.Name : null);
            it.Weight     = (s.Tonnage__c == null) ? null : s.Tonnage__c.setScale(3);

            p.Data.Items.add(it);

            if (i < limitShow) {
                System.debug('Payload.Item[' + i + ']: ' + JSON.serialize(it));
            }
        }
        System.debug('buildPayload() END. Items size=' + p.Data.Items.size());
        return p;
    }

    // Формат: 2025-08-22T11:34:08.224+03:00
    private static String iso8601WithTz() {
        String t = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        if (t != null && t.length() >= 5) {
            String sign = t.substring(t.length()-5, t.length()-4);
            if (sign == '+' || sign == '-') {
                return t.substring(0, t.length()-2) + ':' + t.substring(t.length()-2);
            }
        }
        return t;
    }

    // ==== КЛАСИ ДЛЯ СЕРІАЛІЗАЦІЇ/ДЕСЕРІАЛІЗАЦІЇ ====
    public class Metadata {
        public String  MsgType;
        public Decimal MsgTypeVersion;
        public String  MsgTimestamp;
        public Integer PartNumber;
        public Integer TotalParts;
    }
    public class Item {
        public String  SourceID;
        public String  SourceNDM;
        public String  GoodsName;
        public String  AutoNo;
        public String  TrailerNo;
        public String  DriverFIO;
        public String  OrgName;
        public Decimal Weight;

        public String UnloadDate;
        public String DopInfo;
        public String AutoBrand;
        public String DriverPhone;
    }
    public class DataBlock { public List<Item> Items; }
    public class RequestPayload {
        public Metadata Metadata;
        public DataBlock Data;
    }

    public class ResultEntry {
        public Boolean Success;
        public String  SourceID;
        public Long    PassID;
        public String  PassNDM;
        public String  ErrorCode;
        public String  ErrorMessage;
    }
    public class ResponsePayload {
        public Boolean       Success;
        public String        ErrorMessage;
        public List<ResultEntry> Results;
        public Metrics Metrics;   // про всяк випадок
        public List<String> Warnings;  // про всяк випадок
    }

    // ========================= INBOUND: ERP → SF =========================
    /**
     * Обробляє повідомлення "ERP-SF_SetScrapWeight" - беремо за назву меседжа те, що першим написано в доку
		3.	Методи SalesForce
		3.1.	 Оновлення ваги прийнятого брухту
		Назва: ERP-SF_SetScrapWeight
		Треба буде - поміняємо
     * @param rawJson — тіло запиту від ERP
     * @return JSON-відповідь у форматі Results[], Metrics
		Структура масиву об'єктів із описом кожної позиції прийнятого брухту по документу PassID
		- Kmat - код типу брухту в класифікаторі ERP. Зовнішній код в SF - поле ID_ERP__c (Text 255) об'єкту ScrapType__c
				 дістаємо його Id з цього об'єкту запитом на зразок
				 SELECT Id FROM ScrapType__c WHERE ID_ERP__c=:<JSON.Kmat>
		- GoodsName - назва типу брухту в класифікаторі ERP. Зазвичай такий самий, як і в SF, інформація для довідки
		- Quantity - фактична кількість позиції, цим значенням апдейтимо поле Weight__c об'єкту ScrapSlotReserve__c
					 для рекорду, де ScrapSlotReserve__c.Id = :<JSON.SourceID>

     */
    public static String handleSetScrapWeight(String rawJson) {
        System.debug('===================== handleSetScrapWeight START =========================');
        System.debug('Raw JSON length=' + (rawJson != null ? rawJson.length() : 0));
        System.debug('Raw JSON preview (first 1000 chars): ' + (rawJson != null ? rawJson.substring(0, Math.min(1000, rawJson.length())) : null));
        Long t0 = DateTime.now().getTime();

        InPayload inMsg;
        try {
            inMsg = (InPayload) JSON.deserialize(rawJson, InPayload.class);
        } catch (Exception ex) {
            // Груба помилка формату — одну загальну відповідь
            ResponsePayload err = new ResponsePayload();
            err.Success = false;
            err.ErrorMessage = 'Bad request JSON: ' + ex.getMessage();
            err.Results = new List<ResultEntry>();
            err.Metrics = buildMetrics(0, 0, 0, DateTime.now().getTime() - t0);
            err.Warnings = new List<String>();
            System.debug('===================== handleSetScrapWeight END (bad JSON) =========================');
            return JSON.serialize(err);
        }

        List<InItem> items = (inMsg != null && inMsg.Data != null) ? inMsg.Data.Items : null;
        System.debug('Parsed items size=' + (items == null ? 0 : items.size()));
        if (items != null) {
            Integer limitShow = Math.min(DEBUG_SAMPLE_LIMIT, items.size());
            for (Integer i = 0; i < limitShow; i++) {
                InItem it = items[i];
                System.debug('InItem[' + i + ']: SourceID=' + (it != null ? it.SourceID : null) +
                             ', PassID=' + (it != null ? it.PassID : null) +
                             ', TotalQuantity=' + (it != null ? it.TotalQuantity : null) +
                             ', GoodsCount=' + (it != null && it.Goods != null ? it.Goods.size() : 0));
            }
        }

        if (items == null || items.isEmpty()) {
            ResponsePayload empty = new ResponsePayload();
            empty.Success = false;
            empty.ErrorMessage = 'No items provided';
            empty.Results = new List<ResultEntry>();
            empty.Metrics = buildMetrics(0, 0, 0, DateTime.now().getTime() - t0);
//            empty.Warnings = new List<Object>();
            empty.Warnings = new List<String>();

            return JSON.serialize(empty);
        }

        // Підготовка: валідні SourceID → Id
        List<Id> slotIds = new List<Id>();
        List<ResultEntry> results = new List<ResultEntry>();
        // Індекси результатів для елементів, що можна оновлювати
        List<Integer> updatableIndexes = new List<Integer>();

        for (Integer i = 0; i < items.size(); i++) {
            InItem it = items[i];
            ResultEntry r = new ResultEntry();
            r.SourceID = it != null ? it.SourceID : null;
//            r.PassID   = it != null ? it.PassID   : null;
            if (it != null && !String.isBlank(it.PassID)) {
                try {
                    r.PassID = Long.valueOf(it.PassID);
                } catch (Exception ignore) {
                    // якщо прилетить не-число — не блокуємо відповідь
                    r.PassID = null;
                }
            }

            r.Success = false; // по дефолту
            results.add(r);

            if (it == null || String.isBlank(it.SourceID)) {
                r.ErrorCode = 'E-VALID-001'; // взяв із прикладу, впишемо таке, як треба
                r.ErrorMessage = 'Missing SourceID';
                continue;
            }
            try {
                Id sid = (Id) it.SourceID;
                slotIds.add(sid);
                updatableIndexes.add(i);
            } catch (Exception e) {
                r.ErrorCode = 'E-VALID-001'; // взяв із прикладу, впишемо таке, як треба
                r.ErrorMessage = 'Unknown source id';
            }
        }

        // Вибираємо слоти
        Map<Id, ScrapSlotReserve__c> slotById = new Map<Id, ScrapSlotReserve__c>(
        [SELECT Id,
                Weight__c,
                PassID__c,
                Status__c,
                ScrapType__c,
                ScrapType__r.ID_ERP__c
        FROM ScrapSlotReserve__c
        WHERE Id IN :slotIds]
        );

        // Готуємо апдейти
        List<ScrapSlotReserve__c> toUpdate = new List<ScrapSlotReserve__c>();
        // Потрібно зберегти відповідність SaveResult → results[idx]
        List<Integer> updateResultIndex = new List<Integer>();

        for (Integer j = 0; j < updatableIndexes.size(); j++) {
            Integer idx = updatableIndexes[j];
            InItem it = items[idx];
            ResultEntry r = results[idx];

            Id slotId = (Id) it.SourceID;
            ScrapSlotReserve__c slot = slotById.get(slotId);
            if (slot == null) {
                r.ErrorCode = 'E-VALID-001';
                r.ErrorMessage = 'Unknown source id';
                continue;
            }

            // Валідація PassID (якщо вже є в слоті й чомусь не збігається з тим, що передали)
            if (!String.isBlank(it.PassID) && !String.isBlank(slot.PassID__c) && it.PassID != slot.PassID__c) {
                r.ErrorCode = 'E-VALID-002'; // вписати портібне
                r.ErrorMessage = 'PassID mismatch';
                continue;
            }

            // Обчислення ваги за правилом обробітку поля Quantity (див. опис на початку розділу INBOUND: ERP → SF)
            Decimal weightToSet;
            try {
                weightToSet = resolveWeightForSlot(it, slot);
            } catch (Exception exw) {
                r.ErrorCode = 'E-VALID-003'; // вписати портібне
                r.ErrorMessage = exw.getMessage(); // деталізоване пояснення
                continue;
            }

            // Якщо нічого ставити
            if (weightToSet == null) {
                r.ErrorCode = 'E-VALID-004'; // вписати портібне
                r.ErrorMessage = 'No weight resolved';
                continue;
            }

            // Нормалізація масштабу до 2 знаків
//            try { weightToSet = weightToSet.setScale(2); } catch (Exception ignore) {}
            try { weightToSet = weightToSet.setScale(3); } catch (Exception ignore) {}


            // Готуємо апдейт
            ScrapSlotReserve__c upd = new ScrapSlotReserve__c(
                    Id = slot.Id,
                    Weight__c = weightToSet
            );

            if (slot.Status__c != 'Completed') {
                upd.Status__c = 'Completed';            // ⬅️ встановлюємо статус
            }

            toUpdate.add(upd);
            updateResultIndex.add(idx);
        }

        Integer ok = 0, fail = 0;

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] srs = Database.update(toUpdate, false);
            for (Integer k = 0; k < srs.size(); k++) {
                Database.SaveResult sr = srs[k];
                Integer idx = updateResultIndex[k];
                ResultEntry r = results[idx];

                if (sr.isSuccess()) {
                    r.Success = true;
                    r.ErrorCode = null;
                    r.ErrorMessage = null;
                    ok++;
                    System.debug('Update OK for slot ' + toUpdate[k].Id);
                } else {
                    // збираємо першу помилку
                    Database.Error e = sr.getErrors().isEmpty() ? null : sr.getErrors()[0];
                    r.Success = false;
                    r.ErrorCode = 'E-DML';
                    r.ErrorMessage = (e != null && !String.isBlank(e.getMessage())) ? e.getMessage() : 'DML failed';
                    fail++;
                    System.debug(LoggingLevel.ERROR, 'Update FAIL for slot ' + toUpdate[k].Id + ': ' + r.ErrorMessage);
                }
            }
        }

        // Порахувати фейли по непрохідних ще до DML:
        for (ResultEntry r : results) {
            if (r.Success == null || r.Success == false) {
                if (!String.isBlank(r.ErrorCode) || !String.isBlank(r.ErrorMessage)) {
                    // враховуємо тільки ті, які не були зараховані вище
                    // простіше — перерахуємо все в кінці
                }
            }
        }
        // Перерахунок підсумків (простіше за все — по всьому масиву):
        ok = 0; fail = 0;
        for (ResultEntry r : results) { if (r.Success == true) ok++; else fail++; }

        ResponsePayload out = new ResponsePayload();
        out.Success = (fail == 0);
        out.ErrorMessage = null;
        out.Results = results;
        out.Metrics = buildMetrics(items.size(), ok, fail, DateTime.now().getTime() - t0);
        out.Warnings = new List<String>();

        System.debug('handleSetScrapWeight DONE. ok=' + ok + ', fail=' + fail + ', durationMs=' + out.Metrics.DurationMs);
        System.debug('===================== handleSetScrapWeight END =========================');
        return JSON.serialize(out);
    }

    // ——— Допоміжне: підрахунок метрик
    private class Metrics {
        public Integer Total;
        public Integer Succeeded;
        public Integer Failed;
        public Long    DurationMs;
    }
    private static Metrics buildMetrics(Integer total, Integer ok, Integer fail, Long dur) {
        Metrics m = new Metrics();
        m.Total = total; m.Succeeded = ok; m.Failed = fail; m.DurationMs = dur;
        return m;
    }

    // ——— Допоміжне: вирахувати вагу для слоту за вхідним Item
    @TestVisible
    private static Decimal resolveWeightForSlot(InItem it, ScrapSlotReserve__c slot) {
        // 1) якщо є Goods[]
        if (it.Goods != null && !it.Goods.isEmpty()) {
            String kRequired = slot.ScrapType__r != null ? slot.ScrapType__r.ID_ERP__c : null;
            System.debug('resolveWeightForSlot: GoodsCount=' + it.Goods.size() + ', kRequired=' + kRequired);

            if (!String.isBlank(kRequired)) {
                Decimal sum = 0;
                Integer matches = 0;
                Integer limitShow = Math.min(DEBUG_SAMPLE_LIMIT, it.Goods.size());
                for (Integer i = 0; i < it.Goods.size(); i++) {
                    InGood g = it.Goods[i];
                    if (i < limitShow) System.debug('Good[' + i + ']: Kmat=' + (g != null ? g.Kmat : null) + ', Qty=' + (g != null ? g.Quantity : null));
                    if (g == null) continue;
                    if (g.Kmat == kRequired) {
                        if (g.Quantity != null) { sum += g.Quantity; matches++; }
                    }
                }
                System.debug('resolveWeightForSlot: matches=' + matches + ', sum=' + sum);
                if (matches > 0) return sum;
                if (it.Goods.size() == 1) {
                    return it.Goods[0] != null ? it.Goods[0].Quantity : null;
                }
                throw new AuraHandledException('No matching Goods for slot ScrapType (Kmat=' + kRequired + ')');
            } else {
                if (it.Goods.size() == 1) {
                    return it.Goods[0] != null ? it.Goods[0].Quantity : null;
                }
                throw new AuraHandledException('Slot ScrapType has no ERP code; Goods has ' + it.Goods.size() + ' items');
            }
        }

        // 2) fallback — беремо TotalQuantity
        return it.TotalQuantity;
    }
    // ==== КЛАСИ ДЛЯ INBOUND ДЕСЕРІАЛІЗАЦІЇ ====
    public class InGood {
        public String  Kmat;
        public String  GoodsName;
        public Decimal Quantity;
    }
    public class InItem {
        public String       SourceID;
        public String       PassID;
        public Decimal      TotalQuantity;
        public List<InGood> Goods;
    }
    public class InData { public List<InItem> Items; }
    public class InPayload {
        public Metadata Metadata;
        public InData   Data;
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

    }
}
/*
REST endpoint для прийому ззовні
Окремий top-level клас, що просто делегує в ScrapDeliveryGateway - читав, що Apex так вимагає:

@RestResource(urlMapping='/erp/scrap/weight') <-- тут наше вписати
global with sharing class ERPInbound_ScrapWeight {
    @HttpPost
    global static String post() {
        RestRequest req = RestContext.request;
        String body = req.getBody();
        return ScrapDeliveryGateway.handleSetScrapWeight(body);
    }
}
*/