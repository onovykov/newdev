@IsTest
private class OrderCacheTest {

    @IsTest
    static void test_erp_and_ite_single_and_many() {

        // ---------- test data ----------
        String erpId = String.valueOf(System.now().getTime());
        String ite   = '25-' + String.valueOf(Math.mod(System.now().getTime(), 100000));

        Account acc = new Account(Name = 'T-Acc-OrderCache');
        insert acc;

        Id stdPbId = Test.getStandardPricebookId();

        Order ord = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = stdPbId,
            ID_ERP__c     = erpId,
            ITENumber__c  = ite
        );
        insert ord;

        // ---------- SINGLE ----------
        Id byErp = OrderCache.getOneByErpId(erpId);
        Id byIte = OrderCache.getOneByIte(ite);

        System.assertEquals(
            ord.Id,
            byErp,
            'getOneByErpId must return Order.Id'
        );

        System.assertEquals(
            ord.Id,
            byIte,
            'getOneByIte must return Order.Id'
        );

        // ---------- MANY ----------
        Map<String, Id> manyByErp =
            OrderCache.getManyByErpId(
                new Set<String>{ erpId }
            );

        Map<String, Id> manyByIte =
            OrderCache.getManyByIte(
                new Set<String>{ ite }
            );

        System.assertEquals(
            ord.Id,
            manyByErp.get(erpId),
            'getManyByErpId must return correct Id'
        );

        System.assertEquals(
            ord.Id,
            manyByIte.get(ite),
            'getManyByIte must return correct Id'
        );
    }

    @IsTest
    static void test_blank_and_empty_inputs() {

        System.assertEquals(
            null,
            OrderCache.getOneByErpId(null),
            'null ERP id must return null'
        );

        System.assertEquals(
            null,
            OrderCache.getOneByIte(''),
            'blank ITE must return null'
        );

        System.assertEquals(
            0,
            OrderCache.getManyByErpId(new Set<String>()).size(),
            'empty ERP set must return empty map'
        );

        System.assertEquals(
            0,
            OrderCache.getManyByIte(null).size(),
            'null ITE set must return empty map'
        );
    }
}