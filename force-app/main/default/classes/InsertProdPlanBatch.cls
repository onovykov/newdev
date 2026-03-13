public class InsertProdPlanBatch implements Database.Batchable<SObject> {

    public List<ERPMessageParser.ItemNode> items;
    public Set<String> itemNumbers;
    public ERPMessageParser.PeriodInfo orderItemsPeriodInfo;
    public Boolean recreatePlans = true;

    private final Map<Integer, Id> erpShopToShopIdMap = new Map<Integer, Id>();
    private final Map<String, OrderItem> iteToOrderItemMap = new Map<String, OrderItem>();
    private final Map<String, Order> shortIteToOrderMap = new Map<String, Order>();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id FROM Order WHERE Id != NULL LIMIT 1]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        loadOrderItems();
        loadOrders();
        loadShops();
        insertMonthAndWeekPlans();
    }

    private void loadOrderItems() {
        if (itemNumbers == null || itemNumbers.isEmpty()) return;
        for (OrderItem oi : [
                SELECT Id, ITENumber__c
                FROM OrderItem
                WHERE ITENumber__c IN :itemNumbers
        ]) {
            iteToOrderItemMap.put(oi.ITENumber__c, oi);
        }
    }

    private void loadShops() {
        Set<String> shopErpIds = new Set<String>();
        for (ERPMessageParser.ItemNode item : items) {
            if (item.Shop != null) {
                shopErpIds.add(String.valueOf(item.Shop));
            }
        }
        if (shopErpIds.isEmpty()) return;
        for (Shop__c shop : [
                SELECT Id, ID_ERP__c
                FROM Shop__c
                WHERE ID_ERP__c IN :shopErpIds
        ]) {
            erpShopToShopIdMap.put(Integer.valueOf(shop.ID_ERP__c.trim()), shop.Id);
        }
    }

    private void insertMonthAndWeekPlans() {
        List<OrderItemMonthlyPlans__c> toInsertMonth = new List<OrderItemMonthlyPlans__c>();
        List<OrderItemMonthlyPlans__c> toUpdateMonth = new List<OrderItemMonthlyPlans__c>();
        Map<String, OrderItemMonthlyPlans__c> newMonthPlans = new Map<String, OrderItemMonthlyPlans__c>();

        Integer yearInt = Integer.valueOf(orderItemsPeriodInfo.YearMonth.substring(0, 4));

        Map<String, Id> prodWeekKeyToId = new Map<String, Id>();
        for (ProdWeeksH__c pw : [
                SELECT Id, Year__c, Month__c, WeekNum__c
                FROM ProdWeeksH__c
                WHERE Year__c = :yearInt
        ]) {
            String k = pw.Year__c + '-' + pw.Month__c + '-' + pw.WeekNum__c;
            prodWeekKeyToId.put(k, pw.Id);
        }

        Map<String, List<ERPMessageParser.WeekPlanNode>> monthKeyToWeeks = new Map<String, List<ERPMessageParser.WeekPlanNode>>();
        Map<String, ERPMessageParser.MonthPlanNode> monthKeyToMonthNode = new Map<String, ERPMessageParser.MonthPlanNode>();

        for (ERPMessageParser.ItemNode item : items) {
            OrderItem oi = iteToOrderItemMap.get(item.IteNumber);
            Id shopId = erpShopToShopIdMap.get(item.Shop);
            if (oi == null || shopId == null) continue;

            for (ERPMessageParser.MonthPlanNode month : item.monthPlans) {
                String key = oi.Id + '-' + month.ProdPlanType + '-' + month.Year + '-' + month.Month;
                ERPMessageParser.MonthPlanNode source = month;
                monthKeyToWeeks.put(key, month.monthWeeks);
                monthKeyToMonthNode.put(key, month);

                OrderItemMonthlyPlans__c m = new OrderItemMonthlyPlans__c();
                m.Order_Item__c = oi.Id;
                m.Shop__c = shopId;
                m.ProdPlanType__c = String.valueOf(month.ProdPlanType);
                m.MonthlyProdPlan__c = month.MonthPlanQty_t;
                m.BalanceForProduction__c = month.MonthProdBalance_t;
                m.DateSnapshot__c = month.DateSnapshot;
                m.Month__c = String.valueOf(month.Month);
                m.Year__c = String.valueOf(month.Year);

                // Генеруємо читабельний Name: ITE#Month#Year
                m.Name = item.IteNumber + '#' + String.valueOf(month.Month) + '#' + String.valueOf(month.Year);

                String fullIte = item.IteNumber;
                String shortIte = fullIte != null && fullIte.length() >= 9 ? fullIte.substring(0, 9) : null;
                Id orderId = shortIte != null && shortIteToOrderMap.containsKey(shortIte)
                        ? shortIteToOrderMap.get(shortIte).Id : null;
                m.Order__c = orderId;

                newMonthPlans.put(key, m);
            }
        }

        Map<String, OrderItemMonthlyPlans__c> existingMonthPlans = new Map<String, OrderItemMonthlyPlans__c>();
        for (OrderItemMonthlyPlans__c m : [
                SELECT Id, Order_Item__c, Shop__c, ProdPlanType__c, Year__c, Month__c, MonthlyProdPlan__c, BalanceForProduction__c, DateSnapshot__c
                FROM OrderItemMonthlyPlans__c
                WHERE Order_Item__c IN :iteToOrderItemMap.values()
        ]) {
            String key = m.Order_Item__c + '-' + Integer.valueOf(m.ProdPlanType__c) + '-' + Integer.valueOf(m.Year__c) + '-' + Integer.valueOf(m.Month__c);
            existingMonthPlans.put(key, m);
        }

        Map<String, Id> monthKeyToId = new Map<String, Id>();

        if (recreatePlans) {
            // Режим DELETE + INSERT: Видаляємо існуючі місячні плани (тижневі видаляться каскадно через Master-Detail)
            System.debug('🗑️ RECREATE mode: Removing existing monthly plans (weekly plans will be deleted automatically via cascade)');

            List<OrderItemMonthlyPlans__c> monthPlansToDelete = new List<OrderItemMonthlyPlans__c>();
            for (String key : newMonthPlans.keySet()) {
                if (existingMonthPlans.containsKey(key)) {
                    monthPlansToDelete.add(existingMonthPlans.get(key));
                }
            }

            if (!monthPlansToDelete.isEmpty()) {
                delete monthPlansToDelete;
                System.debug('✅ Deleted ' + monthPlansToDelete.size() + ' monthly plans (with cascading weekly plans)');
            }

            // Вставляємо всі нові місячні плани
            toInsertMonth.addAll(newMonthPlans.values());
        } else {
            // Режим UPSERT: оновлюємо існуючі або вставляємо нові
            for (String key : newMonthPlans.keySet()) {
                if (existingMonthPlans.containsKey(key)) {
                    OrderItemMonthlyPlans__c existing = existingMonthPlans.get(key);
                    OrderItemMonthlyPlans__c incoming = newMonthPlans.get(key);

                    Boolean changed =
                            existing.MonthlyProdPlan__c != incoming.MonthlyProdPlan__c ||
                                    existing.BalanceForProduction__c != incoming.BalanceForProduction__c ||
                                    existing.DateSnapshot__c != incoming.DateSnapshot__c;

                    if (changed) {
                        existing.MonthlyProdPlan__c = incoming.MonthlyProdPlan__c;
                        existing.BalanceForProduction__c = incoming.BalanceForProduction__c;
                        existing.DateSnapshot__c = incoming.DateSnapshot__c;
                        toUpdateMonth.add(existing);
                    }

                    monthKeyToId.put(key, existing.Id);
                } else {
                    toInsertMonth.add(newMonthPlans.get(key));
                }
            }
        }

        if (!toInsertMonth.isEmpty()) insert toInsertMonth;
        if (!toUpdateMonth.isEmpty()) update toUpdateMonth;

        for (OrderItemMonthlyPlans__c m : toInsertMonth) {
            String key = m.Order_Item__c + '-' + Integer.valueOf(m.ProdPlanType__c) + '-' + Integer.valueOf(m.Year__c) + '-' + Integer.valueOf(m.Month__c);
            monthKeyToId.put(key, m.Id);
        }

        Set<Id> monthPlanIds = new Set<Id>(monthKeyToId.values());

        if (recreatePlans) {
            // Режим RECREATE: Створюємо нові тижневі плани
            List<OrderItemWeekPlans__c> toInsertWeeks = new List<OrderItemWeekPlans__c>();
            for (String key : monthKeyToWeeks.keySet()) {
                Id monthPlanId = monthKeyToId.get(key);
                if (monthPlanId == null) continue;

                ERPMessageParser.MonthPlanNode sourceMonth = monthKeyToMonthNode.get(key);

                for (ERPMessageParser.WeekPlanNode week : monthKeyToWeeks.get(key)) {
                    String prodKey = sourceMonth.Year + '-' + sourceMonth.Month + '-' + week.WeekNum;
                    Id prodWeekId = prodWeekKeyToId.get(prodKey);
                    if (prodWeekId == null) continue;

                    OrderItemWeekPlans__c w = new OrderItemWeekPlans__c();
                    w.OrderItemMonthPlan__c = monthPlanId;
                    w.ProdWeeksH__c = prodWeekId;
                    w.ProdPlanType__c = String.valueOf(week.ProdPlanType);
                    w.PlanQty_t__c = week.PlanQty_t;
                    w.ValidDate__c = sourceMonth.ValidDate;

                    toInsertWeeks.add(w);
                }
            }

            if (!toInsertWeeks.isEmpty()) {
                insert toInsertWeeks;
                System.debug('✅ Inserted ' + toInsertWeeks.size() + ' new weekly plans');
            }
        } else {
            // Режим UPSERT: Оновлюємо існуючі або створюємо нові тижневі плани БЕЗ видалення
            System.debug('🔄 UPSERT mode: Updating or inserting weekly plans without deletion');

            // Завантажуємо існуючі тижневі плани
            Map<String, OrderItemWeekPlans__c> existingWeekPlans = new Map<String, OrderItemWeekPlans__c>();
            for (OrderItemWeekPlans__c w : [
                    SELECT Id, OrderItemMonthPlan__c, ProdWeeksH__c, ProdPlanType__c, PlanQty_t__c, ValidDate__c
                    FROM OrderItemWeekPlans__c
                    WHERE OrderItemMonthPlan__c IN :monthPlanIds
            ]) {
                String weekKey = w.OrderItemMonthPlan__c + '-' + w.ProdWeeksH__c;
                existingWeekPlans.put(weekKey, w);
            }

            List<OrderItemWeekPlans__c> toInsertWeeks = new List<OrderItemWeekPlans__c>();
            List<OrderItemWeekPlans__c> toUpdateWeeks = new List<OrderItemWeekPlans__c>();

            for (String key : monthKeyToWeeks.keySet()) {
                Id monthPlanId = monthKeyToId.get(key);
                if (monthPlanId == null) continue;

                ERPMessageParser.MonthPlanNode sourceMonth = monthKeyToMonthNode.get(key);

                for (ERPMessageParser.WeekPlanNode week : monthKeyToWeeks.get(key)) {
                    String prodKey = sourceMonth.Year + '-' + sourceMonth.Month + '-' + week.WeekNum;
                    Id prodWeekId = prodWeekKeyToId.get(prodKey);
                    if (prodWeekId == null) continue;

                    String weekKey = monthPlanId + '-' + prodWeekId;

                    if (existingWeekPlans.containsKey(weekKey)) {
                        // Оновлюємо існуючий тижневий план
                        OrderItemWeekPlans__c existing = existingWeekPlans.get(weekKey);
                        Boolean changed =
                                existing.ProdPlanType__c != String.valueOf(week.ProdPlanType) ||
                                        existing.PlanQty_t__c != week.PlanQty_t ||
                                        existing.ValidDate__c != sourceMonth.ValidDate;

                        if (changed) {
                            existing.ProdPlanType__c = String.valueOf(week.ProdPlanType);
                            existing.PlanQty_t__c = week.PlanQty_t;
                            existing.ValidDate__c = sourceMonth.ValidDate;
                            toUpdateWeeks.add(existing);
                        }
                    } else {
                        // Створюємо новий тижневий план
                        OrderItemWeekPlans__c w = new OrderItemWeekPlans__c();
                        w.OrderItemMonthPlan__c = monthPlanId;
                        w.ProdWeeksH__c = prodWeekId;
                        w.ProdPlanType__c = String.valueOf(week.ProdPlanType);
                        w.PlanQty_t__c = week.PlanQty_t;
                        w.ValidDate__c = sourceMonth.ValidDate;

                        toInsertWeeks.add(w);
                    }
                }
            }

            if (!toInsertWeeks.isEmpty()) {
                insert toInsertWeeks;
                System.debug('✅ Inserted ' + toInsertWeeks.size() + ' new weekly plans');
            }
            if (!toUpdateWeeks.isEmpty()) {
                update toUpdateWeeks;
                System.debug('✅ Updated ' + toUpdateWeeks.size() + ' weekly plans');
            }
        }
    }

    private void loadOrders() {
        Set<String> shortIteNumbers = new Set<String>();
        for (String fullIte : itemNumbers) {
            if (String.isNotBlank(fullIte) && fullIte.length() >= 9) {
                shortIteNumbers.add(fullIte.substring(0, 9));
            }
        }
        if (shortIteNumbers.isEmpty()) return;
        for (Order o : [
                SELECT Id, ITENumber__c
                FROM Order
                WHERE ITENumber__c IN :shortIteNumbers
        ]) {
            shortIteToOrderMap.put(o.ITENumber__c, o);
        }
    }

    public void finish(Database.BatchableContext context) {
        Database.executeBatch(new LinkProductionLotsToProdWeeksBatch(), 200);
    }
}