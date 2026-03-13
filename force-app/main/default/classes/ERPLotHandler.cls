public with sharing class ERPLotHandler {
    // --- Структура для аґреґації лотів
    public class LotsValues {
        public String  lotType;
        public Decimal lotQty;
        public Date    lotDate;
        public Id      prodWeekId;

        public LotsValues() {
            this.lotType    = '';
            this.lotQty     = 0.0;
            this.lotDate    = null;
            this.prodWeekId = null;
        }

        public LotsValues(String lt, Decimal lq, Date ld, Id pwId) {
            this.lotType    = lt;
            this.lotQty     = lq;
            this.lotDate    = ld;
            this.prodWeekId = pwId;
        }
    }

    public static List<Lot__c> lotsList = new List<Lot__c>();
    // --- Хелпер для парсингу Decimal зі String (DTO → Decimal)
    private static Decimal parseDecimal(String src, Integer scale) {
        if (String.isBlank(src)) {
            return 0;
        }
        try {
            Decimal d = Decimal.valueOf(src);
            if (scale != null) {
                d = d.setScale(scale);
            }
            return d;
        } catch (Exception e) {
            // тут можна залогувати, якщо треба
            return 0;
        }
    }

    // --- Хелпер для парсингу Date з рядка DateTime "YYYY-MM-DDTHH:MM:SS"
    private static Date parseDateFromDateTimeString(String dtString) {
        if (dtString == null || dtString.length() < 10) {
            return null;
        }
        try {
            return Date.valueOf(dtString.substring(0, 10)); // yyyy-MM-dd
        } catch (Exception e) {
            // тут можна залогувати, якщо треба
            return null;
        }
    }

    // --- Основний метод аґреґації лотів
    public static void fillAggregateLots(ERPMessageParser.ErpToSfMessage_OpportunityData parsed, Boolean isDryRun) {
        // Захист від null на верхньому рівні
        if (parsed == null || parsed.data == null || parsed.data.items == null || parsed.data.items.isEmpty()) {
            System.debug('parsed error');
            return;
        }

        // Локальна мапа ITENumber -> список агрегованих значень
        Map<String, List<LotsValues>> mapLotsItem = new Map<String, List<LotsValues>>();

        // Сет ITENumber-ів для пошуку OrderItem
        Set<String> ites = new Set<String>();

        // --- Проходимося по item-ах з ERP
        for (Integer i = 0; i < parsed.data.items.size(); i++) {
            ERPMessageParser.ERPObject_OrderItem itemDto = parsed.data.items[i];
            if (itemDto == null || itemDto.lots == null || itemDto.lots.isEmpty()) {
                continue;
            }

            String iteNumber = itemDto.iteNumber;
            if (String.isBlank(iteNumber)) {
                // Якщо немає ITENumber — не зможемо змепити на OrderItem
                continue;
            }

            ites.add(iteNumber);

            // >>> Скидаємо підсумки та дати для конкретного ITENumber
            Decimal producedSum   = 0;
            Decimal dispatchedSum = 0;
            Decimal shippedSum    = 0;

            Date producedMaxDate;
            Date dispatchedMaxDate;
            Date shippedMaxDate;

            // --- Агрегація по лотах
            for (Integer j = 0; j < itemDto.lots.size(); j++) {
                ERPMessageParser.ERPObject_ProductLot lotDto = itemDto.lots[j];
                if (lotDto == null) {
                    continue;
                }

                // Дата лота (одна на всі три показники)
                Date lotDate = parseDateFromDateTimeString(lotDto.lotDate);

                // DTO: все ще String → парсимо
                // УВАГА: scale=2, як у тебе було. Якщо треба 3 знаки — міняємо на 3.
                Decimal lotProd  = parseDecimal(lotDto.produced,   2);
                Decimal lotShip  = parseDecimal(lotDto.dispatched, 2);
                Decimal lotDeliv = parseDecimal(lotDto.shipped,    2);

                if (lotDate != null) {
                    if (lotProd != 0) {
                        producedSum += lotProd;
                        if (producedMaxDate == null || lotDate > producedMaxDate) {
                            producedMaxDate = lotDate;
                        }
                    }
                    if (lotShip != 0) {
                        dispatchedSum += lotShip;
                        if (dispatchedMaxDate == null || lotDate > dispatchedMaxDate) {
                            dispatchedMaxDate = lotDate;
                        }
                    }
                    if (lotDeliv != 0) {
                        shippedSum += lotDeliv;
                        if (shippedMaxDate == null || lotDate > shippedMaxDate) {
                            shippedMaxDate = lotDate;
                        }
                    }
                }
            }

            // Формуємо список агрегованих значень для цього ITENumber
            List<LotsValues> lvList = new List<LotsValues>();

            // Produced
            if (producedSum != 0 && producedMaxDate != null) {
                ProdWeeksH__c prodWeek = DTUtils.getPWeekByDate(producedMaxDate);
                if (prodWeek != null) {
                    lvList.add(new LotsValues('Produced', producedSum, producedMaxDate, prodWeek.Id));
                }
            }

            // Dispatched -> Shipped (історична кривизна, але така логіка бізнесу)
            if (dispatchedSum != 0 && dispatchedMaxDate != null) {
                ProdWeeksH__c shipWeek = DTUtils.getPWeekByDate(dispatchedMaxDate);
                if (shipWeek != null) {
                    lvList.add(new LotsValues('Shipped', dispatchedSum, dispatchedMaxDate, shipWeek.Id));
                }
            }

            // Shipped -> Delivered
            if (shippedSum != 0 && shippedMaxDate != null) {
                ProdWeeksH__c delivWeek = DTUtils.getPWeekByDate(shippedMaxDate);
                if (delivWeek != null) {
                    lvList.add(new LotsValues('Delivered', shippedSum, shippedMaxDate, delivWeek.Id));
                }
            }

            if (!lvList.isEmpty()) {
                mapLotsItem.put(iteNumber, lvList);
            }
        }

        // Якщо немає що мапити — зупиняємось
        if (ites.isEmpty() || mapLotsItem.isEmpty()) {
            return;
        }

        // --- Отримуємо OrderItem по ITENumber з Platform-кеша/БД
        Map<String, OrderItem> byIte = OrderItemPlatformCache.getMany(ites);
        if (byIte == null || byIte.isEmpty()) {
            return;
        }

        // --- Формуємо лоти для upsert
        List<Lot__c> lotList = new List<Lot__c>();

        for (String ite : mapLotsItem.keySet()) {
            OrderItem oi = byIte.get(ite);
            if (oi == null) {
                // ITENumber прийшов з ERP, але в SF немає OrderItem — пропускаємо
                continue;
            }

            List<LotsValues> lvList = mapLotsItem.get(ite);
            if (lvList == null || lvList.isEmpty()) {
                continue;
            }

            for (LotsValues lv : lvList) {
                Lot__c lt = new Lot__c();
                lt.OrderItem__c  = oi.Id;
                lt.LotDate__c    = lv.lotDate;
                lt.LotType__c    = lv.lotType;
                lt.LotQty_t__c   = lv.lotQty;
                lt.ProdWeek__c   = lv.prodWeekId;

                // Унікальний ключ для upsert:
                lt.ExtKey__c = String.valueOf(oi.Id) + '#' +
                               String.valueOf(lv.prodWeekId) + '#' +
                               lv.lotType;

                lotList.add(lt);
            }
            System.debug('lotList.size() = ' + lotList.size());
        }
        if(!isDryRun) {
            if (!lotList.isEmpty()) {
                Database.UpsertResult[] res = Database.upsert(
                    lotList,
                    Lot__c.Fields.ExtKey__c,
                    false // allOrNone = false
                );
                // За бажанням — тут можна пройтись по res і залогувати помилки
            }
        } else {
            lotsList = lotList;
        }
    }

    public static List<Lot__c> getLotList(ERPMessageParser.ErpToSfMessage_OpportunityData parsed) {
        fillAggregateLots(parsed, true);
        return lotsList;
    }
}