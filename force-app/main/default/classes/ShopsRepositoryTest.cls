@IsTest
private class ShopsRepositoryTest {
    // Якщо у вашому org є додаткові обов’язкові поля/валідації —
    // просто додайте їх сюди (ключ — API name поля, значення — тестове значення)
    private static final Map<String, Object> PLANT_REQUIRED_FIELDS = new Map<String, Object>{
        'FullName__c' => 'Test Full Name' // <- критичне поле з помилки
        // 'Active__c' => true,
        // 'Code__c'   => 'TST',
    };
    private static final Map<String, Object> SHOP_REQUIRED_FIELDS = new Map<String, Object>{
        // При потребі додайте свої required поля Shop__c тут
        // Напр.: 'Active__c' => true
    };

    // ——— Helpers ———
    private static Id createPlant(String name) {
        Plant__c p = new Plant__c(Name = name);
        // Динамічно підставляємо обов'язкові поля (щоб не ламати компіляцію, якщо відрізняються між org’ами)
        for (String f : PLANT_REQUIRED_FIELDS.keySet()) {
            p.put(f, PLANT_REQUIRED_FIELDS.get(f));
        }
        insert p;
        return p.Id;
    }

    // Гарантовано унікальні ERP-значення для Shop__c
    private static Shop__c mkShop(String name, String erp, Id plantId) {
        Shop__c s = new Shop__c(
            Name      = name,
            ID_ERP__c = erp,
            Plant__c  = plantId
        );
        for (String f : SHOP_REQUIRED_FIELDS.keySet()) {
            s.put(f, SHOP_REQUIRED_FIELDS.get(f));
        }
        return s;
    }

    @testSetup
    static void setupData() {
        Id plantA = createPlant('Mill A');
        Id plantB = createPlant('Mill B');

        // Shops з Plant__c (мають потрапити в кеш)
        Shop__c s1 = mkShop('Shop 1', 'ERP-001', plantA);
        Shop__c s2 = mkShop('Shop 2', 'ERP-002', plantB);

        // Shop без Plant__c (НЕ має потрапити в кеш через WHERE Plant__c != null)
        Shop__c sNoPlant = new Shop__c(
            Name = 'Shop No Plant',
            ID_ERP__c = 'ERP-NONE'
        );
        for (String f : SHOP_REQUIRED_FIELDS.keySet()) {
            sNoPlant.put(f, SHOP_REQUIRED_FIELDS.get(f));
        }

        insert new List<Shop__c>{ s1, s2, sNoPlant };
    }

    @IsTest
    static void testGetByIdAndErp_BasicMapping() {
        // Почистили кеш, щоб тест був детермінований
        ShopsRepository.clearCacheShops();

        // Дістанемо довільно один з існуючих Shop__c
        Shop__c s1 = [SELECT Id, ID_ERP__c, Name, Plant__c, Plant__r.Name
                      FROM Shop__c WHERE ID_ERP__c = 'ERP-001' LIMIT 1];

        // Перевіряємо пошук за Id
        ShopsRepository.Shops rec1 = ShopsRepository.getShopById(s1.Id);
        System.assertNotEquals(null, rec1, 'Shop by Id must be found');
        System.assertEquals('ERP-001', rec1.ShopErpId, 'ERP must be mapped');
        System.assertEquals('Shop 1',  rec1.ShopName,  'Name must be mapped');
        System.assertEquals(s1.Plant__c, rec1.MillId, 'Plant (Mill) Id must be mapped');
        System.assertEquals('Mill A', rec1.MillName, 'Plant name must be mapped');

        // Перевіряємо пошук за ERP
        ShopsRepository.Shops rec2 = ShopsRepository.getShopByErp('ERP-002');
        System.assertNotEquals(null, rec2, 'Shop by ERP must be found');
        System.assertEquals('Shop 2',  rec2.ShopName);
        System.assertEquals('Mill B',  rec2.MillName);
    }

    @IsTest
    static void testExcludesNullPlant() {
        ShopsRepository.refreshShops(); // гарантуємо свіже завантаження

        Shop__c noPlant = [SELECT Id, ID_ERP__c FROM Shop__c WHERE ID_ERP__c = 'ERP-NONE' LIMIT 1];

        // Цей шоп не має Plant__c, отже НЕ повинен бути в кеші
        ShopsRepository.Shops none = ShopsRepository.getShopById(noPlant.Id);
        System.assertEquals(null, none, 'Shop without Plant__c must not be cached/returned');

        // І по ERP він теж має не знайтись
        ShopsRepository.Shops noneByErp = ShopsRepository.getShopByErp('ERP-NONE');
        System.assertEquals(null, noneByErp, 'Shop without Plant__c must not be in ERP map');
    }

    @IsTest
    static void testCaching_NoExtraQueriesOnSecondCall() {
        ShopsRepository.clearCacheShops();

        Test.startTest();
        // Перший виклик має зробити рівно 1 SOQL (loadAllShops)
        ShopsRepository.getShopByErp('ERP-001');
        Integer queriesAfterFirst = Limits.getQueries();

        // Другий виклик у тому самому транзакшені не повинен робити новий SOQL
        ShopsRepository.getShopByErp('ERP-002');
        Integer queriesAfterSecond = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(1, queriesAfterFirst,
            'First access should trigger exactly one SOQL to load cache');
        System.assertEquals(queriesAfterFirst, queriesAfterSecond,
            'Second access should use cache and not add more SOQLs');
    }

    @IsTest
    static void testRefreshShops_ForcesReload() {
        ShopsRepository.refreshShops(); // раз прогріли

        // Виберемо другий шоп для перевірки після рефрешу
        Shop__c s2 = [SELECT Id FROM Shop__c WHERE ID_ERP__c = 'ERP-002' LIMIT 1];

        Test.startTest();
        // refreshShops повинен скинути і знову завантажити (рівно 1 SOQL)
        ShopsRepository.refreshShops();
        // Подальший get не повинен додавати ще один SOQL
        ShopsRepository.getShopById(s2.Id);
        Integer queries = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(1, queries,
            'refreshShops should perform exactly one SOQL; subsequent get must hit cache');
    }

    @IsTest
    static void testEdgeCases_NullsAndUnknownKeys() {
        ShopsRepository.refreshShops();

        // Невідомий Id (використаємо OrgId як гарантовано не Shop__c)
        ShopsRepository.Shops byUnknownId = ShopsRepository.getShopById((Id)UserInfo.getOrganizationId());
        System.assertEquals(null, byUnknownId, 'Unknown Id must return null');

        // null аргументи
        System.assertEquals(null, ShopsRepository.getShopById(null), 'Null Id must return null');
        System.assertEquals(null, ShopsRepository.getShopByErp(null), 'Null ERP must return null');

        // Невідомий ERP
        System.assertEquals(null, ShopsRepository.getShopByErp('ERP-404'),
            'Unknown ERP must return null');
    }
}