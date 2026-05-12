@IsTest
private class Product2RepositoryTest {

    @TestSetup
    static void setupData() {
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Test Product 1',
                IsActive = true,
                Family = 'OCTG',
                Type__c = 'Tube',
                Dencity__c = 7850,
                Material__c = 'CARBON_STEEL',
                ID_ERP__c = 'ERP-001'
            ),
            new Product2(
                Name = 'Test Product 2',
                IsActive = true,
                Family = 'Wheels',
                Type__c = 'Wheel',
                Dencity__c = 7900,
                Material__c = 'CARBON_STEEL',
                ID_ERP__c = 'ERP-002'
            ),
            new Product2(
                Name = 'Test Product Without ERP',
                IsActive = true,
                Family = 'LP/GU',
                Type__c = 'Tube',
                Dencity__c = 8000.00,
                Material__c = 'CARBON_STEEL',
                ID_ERP__c = 'ERP-003'
            )
        };

        insert products;
    }

    @IsTest
    static void testGetById() {
        Product2 p = [
            SELECT Id, Name, ID_ERP__c
            FROM Product2
            WHERE ID_ERP__c = 'ERP-001'
            LIMIT 1
        ];

        Product2 result = Product2Repository.getById(p.Id);

        System.assertNotEquals(null, result, 'Product should be found by Id');
        System.assertEquals(p.Id, result.Id);
        System.assertEquals('ERP-001', result.ID_ERP__c);
    }

    @IsTest
    static void testGetByErp() {
        Product2 result = Product2Repository.getByErp('ERP-002');

        System.assertNotEquals(null, result, 'Product should be found by ERP id');
        System.assertEquals('ERP-002', result.ID_ERP__c);
        System.assertEquals('Test Product 2', result.Name);
    }

    @IsTest
    static void testGetAllProds() {
        List<Product2> result = Product2Repository.getAllProds();

        System.assertNotEquals(null, result);
        System.assert(result.size() >= 3, 'Should return at least test products');

        Set<String> erpIds = new Set<String>();
        for (Product2 p : result) {
            erpIds.add(p.ID_ERP__c);
        }

        System.assert(erpIds.contains('ERP-001'));
        System.assert(erpIds.contains('ERP-002'));
    }

    @IsTest
    static void testGetIdByErp() {
        Product2 p = [
            SELECT Id
            FROM Product2
            WHERE ID_ERP__c = 'ERP-001'
            LIMIT 1
        ];

        Id result = Product2Repository.getIdByErp('ERP-001');

        System.assertEquals(p.Id, result);
    }

    @IsTest
    static void testGetByErpReturnsNullForUnknownErp() {
        Product2 result = Product2Repository.getByErp('ERP-NOT-EXISTS');

        System.assertEquals(null, result);
    }

    @IsTest
    static void testGetIdByErpReturnsNullForUnknownErp() {
        Id result = Product2Repository.getIdByErp('ERP-NOT-EXISTS');

        System.assertEquals(null, result);
    }

    @IsTest
    static void testProductWithoutErpIsNotIndexedByErp() {
        Product2 p = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product Without ERP'
            LIMIT 1
        ];

        Product2 byId = Product2Repository.getById(p.Id);
        Product2 byErp = Product2Repository.getByErp(null);

        System.assertNotEquals(null, byId, 'Product without ERP should still be indexed by Id');
        System.assertEquals(null, byErp, 'Blank/null ERP should not be indexed');
    }

    @IsTest
    static void testClearCacheAndRefresh() {
        Product2 p = [
            SELECT Id, ID_ERP__c
            FROM Product2
            WHERE ID_ERP__c = 'ERP-001'
            LIMIT 1
        ];

        Product2 firstLoad = Product2Repository.getById(p.Id);
        System.assertNotEquals(null, firstLoad);

        Product2Repository.clearCache();

        Product2 afterClear = Product2Repository.getById(p.Id);
        System.assertNotEquals(null, afterClear);
        System.assertEquals(p.Id, afterClear.Id);

        Product2Repository.refresh();

        Product2 afterRefresh = Product2Repository.getByErp('ERP-001');
        System.assertNotEquals(null, afterRefresh);
        System.assertEquals(p.Id, afterRefresh.Id);
    }
}