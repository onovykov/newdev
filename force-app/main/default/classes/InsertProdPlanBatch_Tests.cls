@IsTest
private class InsertProdPlanBatch_Tests {

    // ==== Helpers: базові довідники для Order/OrderItem ====

    private static Id ensureStandardPricebook() {
        Pricebook2 std = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (!std.IsActive) { std.IsActive = true; update std; }
        return std.Id;
    }

    private static Id makePbe(Id pbId) {
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId, Product2Id = p.Id, UnitPrice = 100, IsActive = true
        );
        insert pbe;
        return pbe.Id;
    }

    private static Order makeOrder(String iteShort) {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Order o = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ITENumber__c = iteShort
        );
        insert o;
        return o;
    }

    private static OrderItem makeOrderItem(Order o, Id pbeId, String iteFull) {
        OrderItem oi = new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbeId,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = iteFull
        );
        insert oi;
        return oi;
    }

    private static void makeProdWeeks(Integer year, Integer month, List<Integer> weekNums) {
        List<ProdWeeksH__c> rows = new List<ProdWeeksH__c>();
        for (Integer w : weekNums) {
            rows.add(new ProdWeeksH__c(Year__c = year, Month__c = month, WeekNum__c = w));
        }
        insert rows;
    }

    // Якщо ID_ERP__c у Shop__c — текстове поле (найчастіше так)
    private static Shop__c makeShop(String erpIdText) {
        Shop__c s = new Shop__c(Name = 'Shop ' + erpIdText, ID_ERP__c = erpIdText);
        insert s;
        return s;
    }

    // ==== Builders для ERPMessageParser.* з ПРАВИЛЬНИМИ типами ====

    // WeekNum — String; ProdPlanType — String
    private static ERPMessageParser.WeekPlanNode wk(Integer weekNum, String type, Decimal qty, Date valid) {
        ERPMessageParser.WeekPlanNode w = new ERPMessageParser.WeekPlanNode();
        w.WeekNum = String.valueOf(weekNum); // <-- String
        w.ProdPlanType = type;               // <-- String
        w.PlanQty_t = qty;
        w.ValidDate = valid;
        return w;
    }

    // ProdPlanType — Integer
    private static ERPMessageParser.MonthPlanNode mon(Integer y, Integer m, Integer type,
                                                      Decimal mQty, Decimal bal, Date snap, Date valid,
                                                      List<ERPMessageParser.WeekPlanNode> weeks) {
        ERPMessageParser.MonthPlanNode node = new ERPMessageParser.MonthPlanNode();
        node.Year = y;
        node.Month = m;
        node.ProdPlanType = type;            // <-- Integer
        node.MonthPlanQty_t = mQty;
        node.MonthProdBalance_t = bal;
        node.DateSnapshot = snap;
        node.ValidDate = valid;
        node.monthWeeks = weeks;
        return node;
    }

    // Shop — String
    private static ERPMessageParser.ItemNode item(String ite, String shopErpIdText,
                                                  List<ERPMessageParser.MonthPlanNode> months) {
        ERPMessageParser.ItemNode n = new ERPMessageParser.ItemNode();
        n.IteNumber = ite;
        n.Shop = shopErpIdText;              // <-- String
        n.monthPlans = months;
        return n;
    }

    // ==== Tests ====

    @IsTest
    static void testInsertAndUpdate_MonthAndWeekPlans() {
        Id pbId = ensureStandardPricebook();
        Id pbeId = makePbe(pbId);

        String ite1Full = '123456789AA';
        String ite1Short = ite1Full.substring(0,9);

        Integer y1 = Date.today().year();
        Integer y2 = y1 + 1;

        makeProdWeeks(y1, 10, new List<Integer>{41,42});
        makeProdWeeks(y2,  1, new List<Integer>{1,2});

        Order o1 = makeOrder(ite1Short);
        OrderItem oi1 = makeOrderItem(o1, pbeId, ite1Full);

        // Shop — текстом (бо ItemNode.Shop — String)
        String shopErp = '777';
        makeShop(shopErp);

        Date snap = Date.today();
        Date valid1 = Date.today();
        Date valid2 = Date.today().addDays(7);

        ERPMessageParser.MonthPlanNode m1 =
            mon(y1, 10, /*type (Integer)*/ 1, /*mQty*/ 50, /*bal*/ 5, snap, valid1,
                new List<ERPMessageParser.WeekPlanNode>{
                    wk(41, /*type (String)*/ '1', 30, valid1),
                    wk(42, /*type (String)*/ '1', 20, valid1)
                });

        ERPMessageParser.MonthPlanNode m2 =
            mon(y2, 1, /*type (Integer)*/ 1, /*mQty*/ 60, /*bal*/ 6, snap, valid2,
                new List<ERPMessageParser.WeekPlanNode>{
                    wk(1,  /*type (String)*/ '1', 25, valid2),
                    wk(2,  /*type (String)*/ '1', 35, valid2)
                });

        List<ERPMessageParser.ItemNode> payload = new List<ERPMessageParser.ItemNode>{
            item(ite1Full, shopErp, new List<ERPMessageParser.MonthPlanNode>{ m1, m2 })
        };

        // ПЕРШИЙ ПРОГІН — створення
        Test.startTest();
        Database.executeBatch(new InsertProdPlanBatch(payload, new Set<String>{ ite1Full }, null), 1);
        Test.stopTest();

        // Місяці
        List<OrderItemMonthlyPlans__c> months = [
            SELECT Id, Order_Item__c, Shop__c, ProdPlanType__c, Year__c, Month__c,
                   MonthlyProdPlan__c, BalanceForProduction__c, DateSnapshot__c
            FROM OrderItemMonthlyPlans__c
            WHERE Order_Item__c = :oi1.Id
            ORDER BY Year__c, Month__c
        ];
        System.assertEquals(2, months.size(), 'Має бути 2 місячні плани');

        // Тижні — використовуємо просто Set<Id>
        Set<Id> monthIds = new Map<Id, OrderItemMonthlyPlans__c>(months).keySet();
        List<OrderItemWeekPlans__c> weeks = [
            SELECT Id, OrderItemMonthPlan__c, ProdWeeksH__c, ProdPlanType__c, PlanQty_t__c, ValidDate__c
            FROM OrderItemWeekPlans__c
            WHERE OrderItemMonthPlan__c IN :monthIds
        ];
        System.assertEquals(4, weeks.size(), 'Має бути 4 тижневі плани');

        // ДРУГИЙ ПРОГІН — оновлення (без дублювання)
        m1.MonthPlanQty_t = 55; // було 50
        m1.monthWeeks[0].PlanQty_t = 33; // було 30
        m2.MonthPlanQty_t = 65; // було 60

        Test.startTest();
        Database.executeBatch(new InsertProdPlanBatch(payload, new Set<String>{ ite1Full }, null), 1);
        Test.stopTest();

        months = [
            SELECT Id, MonthlyProdPlan__c
            FROM OrderItemMonthlyPlans__c
            WHERE Order_Item__c = :oi1.Id
            ORDER BY Id
        ];
        System.assertEquals(2, months.size());
        Set<Decimal> expectedMonthQty = new Set<Decimal>{55,65};
        Set<Decimal> actualMonthQty = new Set<Decimal>{
            months[0].MonthlyProdPlan__c, months[1].MonthlyProdPlan__c
        };
        System.assertEquals(expectedMonthQty, actualMonthQty, 'Місячні кількості повинні оновитися без дублювання');

        monthIds = new Map<Id, OrderItemMonthlyPlans__c>(months).keySet();
        weeks = [
            SELECT Id, PlanQty_t__c
            FROM OrderItemWeekPlans__c
            WHERE OrderItemMonthPlan__c IN :monthIds
        ];
        System.assertEquals(4, weeks.size(), 'Кількість тижневих записів не повинна змінитися');
        Boolean has33 = false;
        for (OrderItemWeekPlans__c w : weeks) if (w.PlanQty_t__c == 33) { has33 = true; break; }
        System.assertEquals(true, has33, 'Один із тижнів мав бути оновлений до 33');
    }

    @IsTest
    static void testSkipsUnknownShopOrItem() {
        makeProdWeeks(2025, 10, new List<Integer>{41});
        makeShop('999'); // Shop як String

        ERPMessageParser.MonthPlanNode m =
            mon(2025, 10, 1, 10, 1, Date.today(), Date.today(),
                new List<ERPMessageParser.WeekPlanNode>{ wk(41, '1', 10, Date.today()) });

        List<ERPMessageParser.ItemNode> payload = new List<ERPMessageParser.ItemNode>{
            item('NO_ORDERITEM_000', '999', new List<ERPMessageParser.MonthPlanNode>{ m })
        };

        Test.startTest();
        Database.executeBatch(new InsertProdPlanBatch(payload, new Set<String>{ 'NO_ORDERITEM_000' }, null), 50);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM OrderItemMonthlyPlans__c]);
        System.assertEquals(0, [SELECT count() FROM OrderItemWeekPlans__c]);
    }
}