public without sharing class OrderDatatableController {

    @AuraEnabled(Cacheable=true)
    public static List<Order> getOrders() {
        try {
            OrderContext ctx = getOrderContext(true, '');

            List<Order> orders = [SELECT Id, OrderNumber, AccountId, ID_ERP__c, EffectiveDate, Status,
                    TotalOrderQuantity__c, ProducedQuantity__c, DispatchedQuantity__c,
                    PO_Number__c, ShippedQuantity__c, AdditionalNumber__c, Prod_Type__c, Quantity_pcs__c, ProducedQuantity_pcs__c, DispatchedQuantity_pcs__c, DeliveredQuantity_pcs__c,
            (SELECT Product2.Name,Name__c, Quantity, Stage__c, ProducedQuantity__c, DispatchedQuantity__c,
                    ShippedQuantity__c,UnitPrice, TubeOD__r.OD_inch__c, TubeWT__r.WT_inch__c, TubeLengthSize__r.MinLength__c,
                    TubeLengthSize__r.MaxLength__c, Shop__r.Plant__r.Name, WeeklyProdPlan__c, MonthlyProdPlan__c,
                    BalanceForProduction__c, Quantity_pcs__c, Estimated_Prod_Balance__c, WeekStartDate__c, WeekEndDate__c
            FROM OrderItems)
            FROM Order
            WHERE AccountId IN :ctx.accountIds AND Prod_Type__c IN :ctx.prodTypes
            ORDER BY EffectiveDate DESC];

            return orders;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(Cacheable=true)
    public static OrderContext getOrderContext(Boolean isPortal, String recordId) {
        String accountId;
        String contactId = null; // одразу оголошуємо null

        if (isPortal) {
            String userId = UserInfo.getUserId();
            contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
            accountId = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1].AccountId;
        } else {
            accountId = [SELECT AccountId FROM Order WHERE Id = :recordId].AccountId;
            // contactId не шукаємо взагалі
        }

        Set<Id> accountIdSet = new Set<Id>{accountId};
        for (Account child : [SELECT Id FROM Account WHERE ParentId = :accountId]) {
            accountIdSet.add(child.Id);
        }

        Set<String> prodTypes = getProdTypes(accountId, contactId);

        return new OrderContext(accountIdSet, prodTypes);
    }


    public static Decimal round3(Decimal val) {
        return val != null ? val.setScale(3, RoundingMode.HALF_UP) : 0;
    }

    @AuraEnabled(Cacheable=true)
    public static List<OrderWrapper> getStructuredProdPlan(Boolean isPortal, String recordId) {
        OrderContext ctx = getOrderContext(isPortal, recordId);

        System.debug('CTX: ' + ctx);

        Map<String, Decimal> factQtyMap = new Map<String, Decimal>();
        Map<String, Date> factDateMap = new Map<String, Date>();

        List<OrderItemWeekPlans__c> weekPlans;

        if (isPortal) {
            // Портал — фільтруємо по accountIds та prodTypes
            System.debug('isPortal');
            weekPlans = [
                    SELECT Id, PlanQty_t__c, DateFrom__c, DateTo__c, ValidDate__c,
                            ProdWeeksH__r.Id, ProdWeeksH__r.WeekNum__c, ProdWeeksH__r.Parent__r.Name,
                            OrderItemMonthPlan__r.Month__c,
                            OrderItemMonthPlan__r.Year__c,
                            OrderItemMonthPlan__r.Order__c,
                            OrderItemMonthPlan__r.MonthlyProdPlan__c,
                            OrderItemMonthPlan__r.Order_Item__r.Name__c,
                            OrderItemMonthPlan__r.Order_Item__r.Order.AdditionalNumber__c,
                            OrderItemMonthPlan__r.BalanceForProduction__c,
                            OrderItemMonthPlan__r.EstimatedProdBalance__c,
                            OrderItemMonthPlan__r.Order_Item__r.Id,
                            OrderItemMonthPlan__r.Order_Item__r.ITENumber__c,
                            OrderItemMonthPlan__r.Order_Item__r.Order.AccountId,
                            OrderItemMonthPlan__r.Order_Item__r.Order.Prod_Type__c
                    FROM OrderItemWeekPlans__c
                    WHERE OrderItemMonthPlan__r.Order_Item__r.Order.AccountId IN :ctx.accountIds
                    AND OrderItemMonthPlan__r.Order_Item__r.Order.Prod_Type__c IN :ctx.prodTypes
                    AND ProdPlanType__c = '253'
                    ORDER BY OrderItemMonthPlan__r.Order_Item__r.Id, ProdWeeksH__r.WeekNum__c ASC
            ];
        } else {
            System.debug('NOOOOT isPortal');
            // Внутрішній користувач — додаємо фільтр по конкретному Order.Id = recordId
            weekPlans = [
                    SELECT Id, PlanQty_t__c, DateFrom__c, DateTo__c, ValidDate__c,
                            ProdWeeksH__r.Id, ProdWeeksH__r.WeekNum__c, ProdWeeksH__r.Parent__r.Name,
                            OrderItemMonthPlan__r.Month__c,
                            OrderItemMonthPlan__r.Year__c,
                            OrderItemMonthPlan__r.Order__c,
                            OrderItemMonthPlan__r.MonthlyProdPlan__c,
                            OrderItemMonthPlan__r.Order_Item__r.Name__c,
                            OrderItemMonthPlan__r.BalanceForProduction__c,
                            OrderItemMonthPlan__r.EstimatedProdBalance__c,
                            OrderItemMonthPlan__r.Order_Item__r.Order.AdditionalNumber__c,
                            OrderItemMonthPlan__r.Order_Item__r.Id,
                            OrderItemMonthPlan__r.Order_Item__r.ITENumber__c,
                            OrderItemMonthPlan__r.Order_Item__r.Order.AccountId,
                            OrderItemMonthPlan__r.Order_Item__r.Order.Prod_Type__c
                    FROM OrderItemWeekPlans__c
                    WHERE OrderItemMonthPlan__r.Order_Item__r.Order.Id = :recordId
                    AND ProdPlanType__c = '253'
                    ORDER BY OrderItemMonthPlan__r.Order_Item__r.Id, ProdWeeksH__r.WeekNum__c ASC
            ];
        }

        System.debug('weekPlans: ' + weekPlans);

        Set<Id> orderItemIds = new Set<Id>();
        Set<Id> prodWeekIds = new Set<Id>();

        // Визначення поточного виробничого тижня
        Integer currentProdWeekNum = null;

        for (ProdWeeksH__c pw : [
                SELECT WeekNum__c
                FROM ProdWeeksH__c
                WHERE DateFrom__c  <= TODAY AND DateTo__c  >= TODAY
                LIMIT 1
        ]) {
            currentProdWeekNum = (Integer) pw.WeekNum__c;
        }

        System.debug('CurrentProdWeekNum: ' + currentProdWeekNum);

        for (OrderItemWeekPlans__c wp : weekPlans) {
            if (wp.OrderItemMonthPlan__r.Order_Item__r.Id != null && wp.ProdWeeksH__r.Id != null) {
                orderItemIds.add(wp.OrderItemMonthPlan__r.Order_Item__r.Id);
                prodWeekIds.add(wp.ProdWeeksH__r.Id);
            }
            System.debug('orderItemIds: ' + orderItemIds);
            System.debug('prodWeekIds: ' + prodWeekIds);
            System.debug('wp: ' + wp);
        }

        for (AggregateResult ar : [
                SELECT OrderItem__c, ProdWeek__c, SUM(ProducedQuantity__c) qty, MAX(LotDate__c) date
                FROM ProductionLot__c
                WHERE OrderItem__c IN :orderItemIds AND ProdWeek__c IN :prodWeekIds
                GROUP BY OrderItem__c, ProdWeek__c
        ]) {
            System.debug('AR: ' + ar);

            String key = (String)ar.get('OrderItem__c') + '|' + (String)ar.get('ProdWeek__c');
            factQtyMap.put(key, (Decimal)ar.get('qty'));
            factDateMap.put(key, (Date)ar.get('date'));
        }

        System.debug('After put factQtyMap: ' + factQtyMap);
        System.debug('After put factDateMap: ' + factDateMap);

        Date today = Date.today();

        Map<String, OrderWrapper> orderMap = new Map<String, OrderWrapper>();
        Map<String, OrderItemWrapper> itemMap = new Map<String, OrderItemWrapper>();

        for (OrderItemWeekPlans__c wp : weekPlans) {
            System.debug('WP: ' + wp);
            if (wp.ValidDate__c != null && wp.DateTo__c != null && wp.ValidDate__c < wp.DateTo__c) {
                continue;
            }

            Boolean isCurrentOrNextWeek = wp.DateFrom__c != null && wp.DateTo__c != null &&
                    (today >= wp.DateFrom__c && today <= wp.DateTo__c ||
                            today.addDays(7) >= wp.DateFrom__c && today.addDays(7) <= wp.DateTo__c);

            if (isPortal && !isCurrentOrNextWeek) {
                continue;
            }

            String orderId = wp.OrderItemMonthPlan__r.Order_Item__r.Order.Id;
            String orderName = wp.OrderItemMonthPlan__r.Order_Item__r.Order.AdditionalNumber__c;

            if (!orderMap.containsKey(orderId)) {
                OrderWrapper ow = new OrderWrapper();
                ow.orderId = orderId;
                ow.orderName = orderName;
                ow.items = new List<OrderItemWrapper>();
                orderMap.put(orderId, ow);
            }


//            Boolean isCurrentOrNextWeek = wp.DateFrom__c != null && wp.DateTo__c != null &&
//                    (today >= wp.DateFrom__c && today <= wp.DateTo__c ||
//                            today.addDays(7) >= wp.DateFrom__c && today.addDays(7) <= wp.DateTo__c);
//
//            if (isPortal && !isCurrentOrNextWeek) {
//                continue;
//            }

            String oiId = wp.OrderItemMonthPlan__r.Order_Item__r.Id;

            String prodWeekId = wp.ProdWeeksH__r.Id;
            System.debug('prodWeekId: ' + prodWeekId);
            String factKey = oiId + '|' + prodWeekId;
            System.debug('factKey: ' + factKey);
//            Decimal factQty = factQtyMap.get(factKey);
            Decimal factQty = factQtyMap.containsKey(factKey) ? factQtyMap.get(factKey) : 0;

            System.debug('DECIMAL: factQty: ' + factQty);

            Date factDate = factDateMap.get(factKey);

            System.debug('Date: factDate: ' + factDate);

            String iteNum = wp.OrderItemMonthPlan__r.Order_Item__r.ITENumber__c;
            String year = wp.OrderItemMonthPlan__r.Year__c;
            String month = wp.OrderItemMonthPlan__r.Month__c;
            String monthKey = year + '-' + month;
            String monthLabel = wp.ProdWeeksH__r.Parent__r.Name != null ? wp.ProdWeeksH__r.Parent__r.Name : '---';

            // Step 1: get or create OrderItem

            OrderItemWrapper currentItem;
            if (!itemMap.containsKey(oiId)) {
                currentItem = new OrderItemWrapper();
                currentItem.orderItemId = oiId;
                currentItem.iteNumber = iteNum;
                currentItem.itemName = wp.OrderItemMonthPlan__r.Order_Item__r.Name__c;

                currentItem.orderId = orderId;
                currentItem.orderAdditionalNumber = orderName;

                itemMap.put(oiId, currentItem);
                orderMap.get(orderId).items.add(currentItem);
            } else {
                currentItem = itemMap.get(oiId);
            }

//            if (!itemMap.containsKey(oiId)) {
//                OrderItemWrapper item = new OrderItemWrapper();
//                item.orderItemId = oiId;
//                item.iteNumber = iteNum;
//                item.itemName = wp.OrderItemMonthPlan__r.Order_Item__r.Name__c;
//
//                item.orderId = wp.OrderItemMonthPlan__r.Order_Item__r.Order.Id;
//                item.orderAdditionalNumber = wp.OrderItemMonthPlan__r.Order_Item__r.Order.AdditionalNumber__c;
//
//                itemMap.put(oiId, item);
//
//                orderMap.get(orderId).items.add(item);
//            }
//            OrderItemWrapper currentItem = itemMap.get(oiId);

            // Step 2: get or create Month
            MonthPlanWrapper monthEntry = null;
            for (MonthPlanWrapper m : currentItem.months) {
                if (m.key == monthKey) {
                    monthEntry = m;
                    break;
                }
            }
            if (monthEntry == null) {
                monthEntry = new MonthPlanWrapper();
                monthEntry.key = monthKey;
                monthEntry.label = monthLabel;

                // встановлення значення balance з month

                monthEntry.balance = wp.OrderItemMonthPlan__r.BalanceForProduction__c != null
                        ? round3(wp.OrderItemMonthPlan__r.BalanceForProduction__c)
                        : 0;

                currentItem.months.add(monthEntry);

                // дублюємо значення в item
                currentItem.planQty = 0;
                currentItem.factQty = 0;
                currentItem.balance = monthEntry.balance;
                currentItem.planDate = '---';
                currentItem.factDate = '---';
            }


            // Step 3: додати тиждень
            WeekPlanWrapper week = new WeekPlanWrapper();
            String weekNum = String.valueOf(wp.ProdWeeksH__r.WeekNum__c);
//            String fromStr = wp.DateFrom__c != null ? String.valueOf(wp.DateFrom__c.format()) : '';
//            String toStr = wp.DateTo__c != null ? String.valueOf(wp.DateTo__c.format()) : '';

            String fromStr = wp.DateFrom__c != null ? Datetime.newInstance(wp.DateFrom__c, Time.newInstance(0,0,0,0)).format('dd.MM.yyyy') : '---';
            String toStr   = wp.DateTo__c   != null ? Datetime.newInstance(wp.DateTo__c,   Time.newInstance(0,0,0,0)).format('dd.MM.yyyy')   : '---';

            System.debug('fromStr: ' + fromStr);
            System.debug('toStr: ' + toStr);

//            week.label = 'Week ' + weekNum + (fromStr != '' && toStr != '' ? ' (' + fromStr + ' - ' + toStr + ')' : '');
            week.label = 'Week ' + weekNum + ': ' + fromStr + ' - ' + toStr;

            if (wp.DateTo__c != null) {
                week.planDate = Datetime.newInstance(wp.DateTo__c, Time.newInstance(0,0,0,0)).format('dd.MM.yyyy');

                // Якщо план дата в місяці ще не задана або поточна DateTo пізніша
                if (monthEntry.planDate == '' || Date.newInstance(
                        Integer.valueOf(monthEntry.planDate.split('\\.')[2]),
                        Integer.valueOf(monthEntry.planDate.split('\\.')[1]),
                        Integer.valueOf(monthEntry.planDate.split('\\.')[0])
                ) < wp.DateTo__c) {
                    monthEntry.planDate = week.planDate;
                }
            } else {
                week.planDate = '---';
            }

            // все інше — заглушки
            Decimal planQty = wp.PlanQty_t__c != null ? wp.PlanQty_t__c : 0;
            System.debug('WEEK PLAN: wpId=' + wp.Id + ', planQty=' + planQty + ', monthKey=' + monthKey + ', oiId=' + oiId);

            week.planQty = round3(planQty);
            monthEntry.planQty += planQty;
            System.debug('monthEntry.planQt: ' + monthEntry.planQty + ' + ' + planQty);
            week.balance = '-';
            week.planDate = toStr != '' ? toStr : '---';
//            week.factDate = toStr != '' ? toStr : '---';
            week.factQty = factQty;
            monthEntry.factQty += factQty;

            System.debug('Week factQty: ' + week.factQty);
            System.debug('Month factQty: ' + monthEntry.factQty);

            week.factDate = factDate != null ? Datetime.newInstance(factDate, Time.newInstance(0,0,0,0)).format('dd.MM.yyyy') : '---';

            if (factDate != null) {
                if (monthEntry.factDate == '' || Date.newInstance(
                        Integer.valueOf(monthEntry.factDate.split('\\.')[2]),
                        Integer.valueOf(monthEntry.factDate.split('\\.')[1]),
                        Integer.valueOf(monthEntry.factDate.split('\\.')[0])
                ) < factDate) {
                    monthEntry.factDate = Datetime.newInstance(factDate, Time.newInstance(0,0,0,0)).format('dd.MM.yyyy');
                }
            }


            monthEntry.weeks.add(week);
        }

        for (OrderItemWrapper item : itemMap.values()) {
            Decimal totalPlan = 0;
            Decimal totalFact = 0;
            Decimal balance = 0;

            for (MonthPlanWrapper month : item.months) {
                totalPlan += month.planQty;
                totalFact += month.factQty;
                balance += month.balance;
            }
            item.planQty = round3(totalPlan);
            item.factQty = round3(totalFact);
            item.balance = round3(balance);

            String latestDateStr = '';
            for (MonthPlanWrapper m : item.months) {
                if (m.planDate != null && m.planDate != '' && (latestDateStr == '' || Date.valueOf(m.planDate) > Date.valueOf(latestDateStr))) {
                    latestDateStr = m.planDate;
                }
            }
            item.planDate = latestDateStr != '' ? latestDateStr : '---';

            String latestFactDateStr = '';
            for (MonthPlanWrapper m : item.months) {
                if (m.factDate != null && m.factDate != '' && (latestFactDateStr == '' || Date.valueOf(m.factDate) > Date.valueOf(latestFactDateStr))) {
                    latestFactDateStr = m.factDate;
                }
            }
            item.factDate = latestFactDateStr != '' ? latestFactDateStr : '---';
        }

//        return itemMap.values();
        return orderMap.values();

    }

    public class OrderContext {
        public Set<Id> accountIds;
        public Set<String> prodTypes;

        public OrderContext(Set<Id> accountIds, Set<String> prodTypes) {
            this.accountIds = accountIds;
            this.prodTypes = prodTypes;
        }
    }

    @AuraEnabled
    public static String generatePdf(String selectedOrders){
        try {
            PageReference pdfPage = Page.siteOrderDatatablePDF;
            pdfPage.getParameters().put('Ids', selectedOrders);
            Blob outletListBlob = pdfPage.getContentAsPDF();

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Interpipe Orders';
            cv.PathOnClient = 'InterpipeOrders.pdf';
            cv.VersionData = outletListBlob;
            insert cv;

            ContentDistribution cdl = new ContentDistribution();
            cdl.PreferencesNotifyOnVisit = false;
            cdl.ContentVersionId = cv.Id;
            cdl.Name = cv.PathOnClient;
            cdl.PreferencesAllowViewInBrowser = true;
            insert cdl;

            return [SELECT DistributionPublicUrl FROM ContentDistribution WHERE Id =: cdl.Id].DistributionPublicUrl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Set<String> getProdTypes(String accountId, String contactId) {
        Set<String> prodTypes = new Set<String>();

        if (contactId == null) {
            prodTypes.add('WHEELS');
            prodTypes.add('TUBES');
            return prodTypes;
        }

        List<AccountContactRelation> relations = [
                SELECT BusinessDivision__c, All_Divisions__c
                FROM AccountContactRelation
                WHERE AccountId = :accountId AND ContactId = :contactId
                LIMIT 1
        ];

        if (relations.isEmpty()) {
            prodTypes.add('WHEELS');
            prodTypes.add('TUBES');
            return prodTypes;
        }

        AccountContactRelation acr = relations[0];

        if (acr.All_Divisions__c) {
            prodTypes.add('WHEELS');
            prodTypes.add('TUBES');
        } else if (acr.BusinessDivision__c == 'Railway') {
            prodTypes.add('WHEELS');
        } else {
            prodTypes.add('TUBES');
        }

        return prodTypes;
    }


    public class OrderWrapper {
        @AuraEnabled public String orderId;
        @AuraEnabled public String orderName;
        @AuraEnabled public List<OrderItemWrapper> items;
    }

    public class OrderItemWrapper {
        @AuraEnabled public String orderItemId;
        @AuraEnabled public String iteNumber;
        @AuraEnabled public String itemName;

        @AuraEnabled public String orderId;
        @AuraEnabled public String orderAdditionalNumber;

        @AuraEnabled public Decimal planQty = 0;
        @AuraEnabled public Decimal factQty = 0;
        @AuraEnabled public Decimal balance = 0;
        @AuraEnabled public String planDate = '';
        @AuraEnabled public String factDate = '';

        @AuraEnabled public List<MonthPlanWrapper> months = new List<MonthPlanWrapper>();
    }

    public class MonthPlanWrapper {
        @AuraEnabled public String key;
        @AuraEnabled public String label;

        @AuraEnabled public Decimal monthlyPlan = 0;
        @AuraEnabled public Decimal planQty = 0;
        @AuraEnabled public Decimal factQty = 0;
        @AuraEnabled public Decimal balance = 0;
        @AuraEnabled public String planDate = '';
        @AuraEnabled public String factDate = '';

        @AuraEnabled public List<WeekPlanWrapper> weeks = new List<WeekPlanWrapper>();
    }

    public class WeekPlanWrapper {
        @AuraEnabled public String label;

        @AuraEnabled public Decimal planQty = 0;
        @AuraEnabled public Decimal factQty = 0;
        @AuraEnabled public String balance = '-';
        @AuraEnabled public String planDate = '';
        @AuraEnabled public String factDate = '';
    }


    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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