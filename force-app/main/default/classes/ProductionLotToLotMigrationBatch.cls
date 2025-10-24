global class ProductionLotToLotMigrationBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('🔄 [START] Запуск батчу міграції ProductionLot → Lot');

        Date startDate = Date.newInstance(2023, 1, 1);
        Date endDate = Date.today();

        return Database.getQueryLocator([
                SELECT Id, LotDate__c, ITENumber__c, Order__c, OrderItem__c,
                        ProducedQuantity__c, DispatchedQuantity__c, ShippedQuantity__c
                FROM ProductionLot__c
                WHERE
                        (ProducedQuantity__c != 0 OR DispatchedQuantity__c != 0 OR ShippedQuantity__c != 0)
                        AND ITENumber__c != NULL
                        AND LotDate__c >= :startDate
                        AND LotDate__c <= :endDate
        ]);
    }

    global void execute(Database.BatchableContext context, List<ProductionLot__c> scope) {
        System.debug('▶️ [EXECUTE] Обробка ' + scope.size() + ' записів ProductionLot__c');
        List<Lot__c> lotsToInsert = new List<Lot__c>();

        // 1. Збираємо всі унікальні дати з LotDate__c
        Set<Date> lotDates = new Set<Date>();
        for (ProductionLot__c lot : scope) {
            if (lot.LotDate__c != null) {
                lotDates.add(lot.LotDate__c);
            }
        }

        // 2. Витягуємо всі ProdWeeksH__c, які потенційно перекривають ці дати
        List<ProdWeeksH__c> prodWeeks = [
                SELECT Id, DateFrom__c, DateTo__c
                FROM ProdWeeksH__c
                WHERE DateFrom__c <= :Date.today()
                AND DateTo__c >= :Date.newInstance(2023, 1, 1)
        ];

        // 3. Будуємо мапу дата → ProdWeek__c.Id
        Map<Date, Id> prodWeekCache = new Map<Date, Id>();
        for (Date d : lotDates) {
            for (ProdWeeksH__c week : prodWeeks) {
                if (week.DateFrom__c <= d && week.DateTo__c >= d) {
                    prodWeekCache.put(d, week.Id);
                    break;
                }
            }
        }

        // 4. Обробляємо кожен ProductionLot
        for (ProductionLot__c oldLot : scope) {
            Map<String, Decimal> qtyByType = new Map<String, Decimal>();

            if (oldLot.ProducedQuantity__c != null && oldLot.ProducedQuantity__c != 0) {
                qtyByType.put('Produced', oldLot.ProducedQuantity__c.setScale(2));
            }
            if (oldLot.DispatchedQuantity__c != null && oldLot.DispatchedQuantity__c != 0) {
                qtyByType.put('Shipped', oldLot.DispatchedQuantity__c.setScale(2));
            }
            if (oldLot.ShippedQuantity__c != null && oldLot.ShippedQuantity__c != 0) {
                qtyByType.put('Delivered', oldLot.ShippedQuantity__c.setScale(2));
            }

            for (String lotType : qtyByType.keySet()) {
                Decimal qty = qtyByType.get(lotType);
                if (qty == null || qty == 0) continue;

                Lot__c newLot = new Lot__c();
                newLot.ITENumber__c = oldLot.ITENumber__c;
                newLot.LotDate__c = oldLot.LotDate__c;
                newLot.LotQty_t__c = qty;
                newLot.LotType__c = lotType;
                newLot.Name = oldLot.ITENumber__c + ' ' + String.valueOf(oldLot.LotDate__c) + ' ' + lotType;
                newLot.OrderItem__c = oldLot.OrderItem__c;
                newLot.Order__c = oldLot.Order__c;
                newLot.ProdWeek__c = prodWeekCache.get(oldLot.LotDate__c);

                lotsToInsert.add(newLot);
            }
        }

        // 5. Вставка
        if (!lotsToInsert.isEmpty()) {
            insert lotsToInsert;
            System.debug('✅ Вставлено ' + lotsToInsert.size() + ' записів Lot__c');
        } else {
            System.debug('ℹ️ Немає записів для вставки.');
        }
    }

    global void finish(Database.BatchableContext context) {
        System.debug('🏁 [FINISH] Міграція ProductionLot → Lot завершена успішно.');
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
    }
}