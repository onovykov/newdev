public class InsertProdPlanBatch implements Database.Batchable<ERPMessageParser.ItemNode> {
    List<ERPMessageParser.ItemNode> items;
    Set<String> itemNumbers;
    ERPMessageParser.PeriodInfo orderItemsPeriodInfo;

    // ВАЖЛИВО: оголошуємо мапи як поля класу
    private Map<Integer, Id> erpShopToShopIdMap = new Map<Integer, Id>();
    private Map<String, OrderItem> iteToOrderItemMap = new Map<String, OrderItem>();
    private Map<String, Order> shortIteToOrderMap = new Map<String, Order>();

    public InsertProdPlanBatch(List<ERPMessageParser.ItemNode> items,
                               Set<String> itemNumbers,
                               ERPMessageParser.PeriodInfo p){
        this.items = items;
        this.itemNumbers = itemNumbers;
        this.orderItemsPeriodInfo = p;
    }

    public Iterable<ERPMessageParser.ItemNode> start(Database.BatchableContext bc) {
        return items;
    }

    public void execute(Database.BatchableContext bc,
                        List<ERPMessageParser.ItemNode> scope) {
        // 1) Скидаємо стани між скопами
        erpShopToShopIdMap.clear();
        iteToOrderItemMap.clear();
        shortIteToOrderMap.clear();

        // 2) Працюємо ЛИШЕ зі scope
        this.items = scope;

        // 3) Побудувати локальні множини itemNumbers/shortIteNumbers і years
        Set<String> scopeItemNumbers = new Set<String>();
        Set<String> shortIteNumbers  = new Set<String>();
        Set<Integer> yearsInScope    = new Set<Integer>();

        for (ERPMessageParser.ItemNode it : scope) {
            if (String.isNotBlank(it.IteNumber)) {
                scopeItemNumbers.add(it.IteNumber);
                if (it.IteNumber.length() >= 9) shortIteNumbers.add(it.IteNumber.substring(0, 9));
            }
            if (it.monthPlans != null) {
                for (ERPMessageParser.MonthPlanNode m : it.monthPlans) {
                    if (m != null) yearsInScope.add(m.Year);
                }
            }
        }

        // 4) Завантаження даних по локальних множинах
        loadOrderItems(scopeItemNumbers);
        loadOrders(shortIteNumbers);
        loadShops(scope);

        // 5) insert/update (передамо yearsInScope всередину)
        insertMonthAndWeekPlans(yearsInScope);
    }

    // --- DATA LOADERS (параметризовані під scope) ---
    private void loadOrderItems(Set<String> scopeItemNumbers) {
        if (scopeItemNumbers.isEmpty()) return;
        for (OrderItem oi : [
            SELECT Id, ITENumber__c
            FROM OrderItem
            WHERE ITENumber__c IN :scopeItemNumbers
        ]) {
            iteToOrderItemMap.put(oi.ITENumber__c, oi);
        }
    }

    private void loadOrders(Set<String> shortIteNumbers) {
        if (shortIteNumbers.isEmpty()) return;
        for (Order o : [
            SELECT Id, ITENumber__c
            FROM Order
            WHERE ITENumber__c IN :shortIteNumbers
        ]) {
            shortIteToOrderMap.put(o.ITENumber__c, o);
        }
    }

    private void loadShops(List<ERPMessageParser.ItemNode> scopeItems) {
        Set<String> shopErpIds = new Set<String>();
        for (ERPMessageParser.ItemNode item : scopeItems) {
            if (item.Shop != null) shopErpIds.add(String.valueOf(item.Shop));
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

    // --- MAIN UPSERT LOGIC ---
    private void insertMonthAndWeekPlans(Set<Integer> yearsInScope) {
        List<OrderItemMonthlyPlans__c> toInsertMonth = new List<OrderItemMonthlyPlans__c>();
        List<OrderItemMonthlyPlans__c> toUpdateMonth = new List<OrderItemMonthlyPlans__c>();
        Map<String, OrderItemMonthlyPlans__c> newMonthPlans = new Map<String, OrderItemMonthlyPlans__c>();

        // Прод. тижні по ВСІХ роках скопа
        Map<String, Id> prodWeekKeyToId = new Map<String, Id>();
        if (!yearsInScope.isEmpty()) {
            for (ProdWeeksH__c pw : [
                SELECT Id, Year__c, Month__c, WeekNum__c
                FROM ProdWeeksH__c
                WHERE Year__c IN :yearsInScope
            ]) {
                String k = pw.Year__c + '-' + pw.Month__c + '-' + pw.WeekNum__c;
                prodWeekKeyToId.put(k, pw.Id);
            }
        }

        Map<String, List<ERPMessageParser.WeekPlanNode>> monthKeyToWeeks = new Map<String, List<ERPMessageParser.WeekPlanNode>>();
        Map<String, ERPMessageParser.MonthPlanNode> monthKeyToMonthNode = new Map<String, ERPMessageParser.MonthPlanNode>();

        for (ERPMessageParser.ItemNode item : items) {
            OrderItem oi = iteToOrderItemMap.get(item.IteNumber);
            Id shopId = erpShopToShopIdMap.get(item.Shop);
            if (oi == null || shopId == null || item.monthPlans == null) continue;

            for (ERPMessageParser.MonthPlanNode month : item.monthPlans) {
                String key = oi.Id + '-' + month.ProdPlanType + '-' + month.Year + '-' + month.Month;
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

                String shortIte = (String.isNotBlank(item.IteNumber) && item.IteNumber.length() >= 9)
                    ? item.IteNumber.substring(0, 9) : null;
                m.Order__c = (shortIte != null && shortIteToOrderMap.containsKey(shortIte))
                    ? shortIteToOrderMap.get(shortIte).Id : null;

                newMonthPlans.put(key, m);
            }
        }

        // EXISTING month plans by Order_Item__c Ids
        Set<Id> orderItemIds = new Set<Id>();
        for (OrderItem oi : iteToOrderItemMap.values()) orderItemIds.add(oi.Id);
        Map<String, OrderItemMonthlyPlans__c> existingMonthPlans = new Map<String, OrderItemMonthlyPlans__c>();
        if (!orderItemIds.isEmpty()) {
            for (OrderItemMonthlyPlans__c m : [
                SELECT Id, Order_Item__c, Shop__c, ProdPlanType__c, Year__c, Month__c,
                       MonthlyProdPlan__c, BalanceForProduction__c, DateSnapshot__c
                FROM OrderItemMonthlyPlans__c
                WHERE Order_Item__c IN :orderItemIds
            ]) {
                String key = m.Order_Item__c + '-' + Integer.valueOf(m.ProdPlanType__c) + '-' +
                             Integer.valueOf(m.Year__c) + '-' + Integer.valueOf(m.Month__c);
                existingMonthPlans.put(key, m);
            }
        }

        Map<String, Id> monthKeyToId = new Map<String, Id>();

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

        if (!toInsertMonth.isEmpty()) Database.insert(toInsertMonth, false);
        if (!toUpdateMonth.isEmpty()) Database.update(toUpdateMonth, false);

        for (OrderItemMonthlyPlans__c m : toInsertMonth) {
            String key = m.Order_Item__c + '-' + Integer.valueOf(m.ProdPlanType__c) +
                        '-' + Integer.valueOf(m.Year__c) + '-' + Integer.valueOf(m.Month__c);
            monthKeyToId.put(key, m.Id);
        }

        // WEEK PLANS
        Set<Id> monthPlanIds = new Set<Id>(monthKeyToId.values());
        Map<String, OrderItemWeekPlans__c> existingWeekPlans = new Map<String, OrderItemWeekPlans__c>();
        if (!monthPlanIds.isEmpty()) {
            for (OrderItemWeekPlans__c w : [
                SELECT Id, OrderItemMonthPlan__c, ProdWeeksH__c, ProdPlanType__c, PlanQty_t__c, ValidDate__c
                FROM OrderItemWeekPlans__c
                WHERE OrderItemMonthPlan__c IN :monthPlanIds
            ]) {
                String key = w.OrderItemMonthPlan__c + '-' + w.ProdWeeksH__c + '-' + w.ProdPlanType__c;
                existingWeekPlans.put(key, w);
            }
        }

        Map<String, OrderItemWeekPlans__c> newWeekPlans = new Map<String, OrderItemWeekPlans__c>();
        for (String key : monthKeyToWeeks.keySet()) {
            Id monthPlanId = monthKeyToId.get(key);
            if (monthPlanId == null) continue;

            ERPMessageParser.MonthPlanNode sourceMonth = monthKeyToMonthNode.get(key);
            if (sourceMonth == null || monthKeyToWeeks.get(key) == null) continue;

            for (ERPMessageParser.WeekPlanNode week : monthKeyToWeeks.get(key)) {
                String prodKey = sourceMonth.Year + '-' + sourceMonth.Month + '-' + week.WeekNum;
                Id prodWeekId = prodWeekKeyToId.get(prodKey);
                if (prodWeekId == null) continue;

                String wkKey = monthPlanId + '-' + prodWeekId + '-' + String.valueOf(week.ProdPlanType);
                OrderItemWeekPlans__c w = new OrderItemWeekPlans__c();
                w.OrderItemMonthPlan__c = monthPlanId;
                w.ProdWeeksH__c = prodWeekId;
                w.ProdPlanType__c = String.valueOf(week.ProdPlanType);
                w.PlanQty_t__c = week.PlanQty_t;
                w.ValidDate__c = sourceMonth.ValidDate;
                newWeekPlans.put(wkKey, w);
            }
        }

        List<OrderItemWeekPlans__c> toInsert = new List<OrderItemWeekPlans__c>();
        List<OrderItemWeekPlans__c> toUpdate = new List<OrderItemWeekPlans__c>();

        for (String key : newWeekPlans.keySet()) {
            if (existingWeekPlans.containsKey(key)) {
                OrderItemWeekPlans__c existing = existingWeekPlans.get(key);
                OrderItemWeekPlans__c updated = newWeekPlans.get(key);
                Boolean changed = existing.PlanQty_t__c != updated.PlanQty_t__c ||
                                  existing.ValidDate__c != updated.ValidDate__c;
                if (changed) {
                    existing.PlanQty_t__c = updated.PlanQty_t__c;
                    existing.ValidDate__c = updated.ValidDate__c;
                    toUpdate.add(existing);
                }
                existingWeekPlans.remove(key);
            } else {
                toInsert.add(newWeekPlans.get(key));
            }
        }

        if (!toInsert.isEmpty()) Database.insert(toInsert, false);
        if (!toUpdate.isEmpty()) Database.update(toUpdate, false);
    }

    public void finish(Database.BatchableContext bc){
        // Якщо потрібно продовження — Queueable
        System.enqueueJob(new LinkProductionLotsToProdWeeksQueueable());
    }
}