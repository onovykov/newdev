@IsTest
private class ProdTypeRepositoryTest {

    @TestSetup
    static void setupData() {
        List<ProductType__c> prodTypes = new List<ProductType__c>{
            new ProductType__c(
                Name = 'Pipe Type',
                ShortName__c = 'PIPE',
                Code__c = 'P001',
                IsActive__c = true
            ),
            new ProductType__c(
                Name = 'Wheel Type',
                ShortName__c = 'WHL',
                Code__c = 'W001',
                IsActive__c = true
            ),
            new ProductType__c(
                Name = 'Other Type',
                ShortName__c = 'OTHER',
                Code__c = 'O001',
                IsActive__c = true
            )
        };

        insert prodTypes;
    }

    //====================================================
    @IsTest
    static void testGetById() {
        ProductType__c pt = [
            SELECT Id, Code__c
            FROM ProductType__c
            WHERE Code__c = 'P001'
            LIMIT 1
        ];

        ProductType__c result = ProdTypeRepository.getById(pt.Id);

        System.assertNotEquals(null, result);
        System.assertEquals(pt.Id, result.Id);
        System.assertEquals('P001', result.Code__c);
    }

    //====================================================
    @IsTest
    static void testGetByCode() {
        ProductType__c result = ProdTypeRepository.getByCode('W001');

        System.assertNotEquals(null, result);
        System.assertEquals('Wheel Type', result.Name);
        System.assertEquals('W001', result.Code__c);
    }

    //====================================================
    @IsTest
    static void testGetByNormCode() {

        ProductType__c pt = [
            SELECT Id, Name, Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Code__c = 'P001'
            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            pt.NormalizedCode__c,
            'Trigger should populate NormalizedCode__c'
        );

        ProductType__c result =
            ProdTypeRepository.getByNormCode(pt.NormalizedCode__c);

        System.assertNotEquals(null, result);
        System.assertEquals(pt.Id, result.Id);
        System.assertEquals(pt.NormalizedCode__c, result.NormalizedCode__c);
    }

    //====================================================
    @IsTest
    static void testGetAllProdTypes() {
        List<ProductType__c> result = ProdTypeRepository.getAllProdTypes();

        System.assertNotEquals(null, result);
        System.assert(result.size() >= 3);

        Set<String> names = new Set<String>();

        for (ProductType__c pt : result) {
            names.add(pt.Name);
        }

        System.assert(names.contains('Pipe Type'));
        System.assert(names.contains('Wheel Type'));
        System.assert(names.contains('Other Type'));
    }

    //====================================================
    @IsTest
    static void testGetIdByCode() {
        ProductType__c pt = [
            SELECT Id
            FROM ProductType__c
            WHERE Code__c = 'P001'
            LIMIT 1
        ];

        Id result = ProdTypeRepository.getIdByCode('P001');

        System.assertEquals(pt.Id, result);
    }

    //====================================================
    @IsTest
    static void testGetIdByNormCode() {

        ProductType__c pt = [
            SELECT Id, Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Code__c = 'W001'
            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            pt.NormalizedCode__c,
            'Trigger should populate NormalizedCode__c'
        );

        Id result = ProdTypeRepository.getIdByNormCode(pt.NormalizedCode__c);

        System.assertEquals(pt.Id, result);
    }

    //====================================================
    @IsTest
    static void testGetByCodeReturnsNull() {
        ProductType__c result = ProdTypeRepository.getByCode('UNKNOWN');
        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testGetByNormCodeReturnsNull() {
        ProductType__c result = ProdTypeRepository.getByNormCode('UNKNOWN_STD');
        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testGetIdByCodeReturnsNull() {
        Id result = ProdTypeRepository.getIdByCode('UNKNOWN');
        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testGetIdByNormCodeReturnsNull() {
        Id result = ProdTypeRepository.getIdByNormCode('UNKNOWN_STD');
        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testClearCacheAndRefresh() {
        ProductType__c pt = [
            SELECT Id, Code__c
            FROM ProductType__c
            WHERE Code__c = 'P001'
            LIMIT 1
        ];

        ProductType__c firstLoad = ProdTypeRepository.getById(pt.Id);

        System.assertNotEquals(null, firstLoad);

        ProdTypeRepository.clearCache();

        ProductType__c afterClear = ProdTypeRepository.getById(pt.Id);

        System.assertNotEquals(null, afterClear);
        System.assertEquals(pt.Id, afterClear.Id);

        ProdTypeRepository.refresh();

        ProductType__c afterRefresh =
            ProdTypeRepository.getByCode('P001');

        System.assertNotEquals(null, afterRefresh);
        System.assertEquals(pt.Id, afterRefresh.Id);
    }
}
