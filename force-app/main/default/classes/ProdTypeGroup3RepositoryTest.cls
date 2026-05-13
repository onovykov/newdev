@IsTest
private class ProdTypeGroup3RepositoryTest {

    @TestSetup
    static void setupData() {

        Product2 product = new Product2(
            Name = 'GU',
            IsActive = true,
            Type__c = 'Tube',
            Family = 'LP/GU',
            Dencity__c = 7850,
            Material__c = 'CARBON_STEEL',
            ID_ERP__c = '20'
        );
        insert product;

        List<ProductType__c> prodTypes = new List<ProductType__c>{
            new ProductType__c(
                Name = 'General Purpose Pipes',
                ShortName__c = 'GPP',
                Code__c = 'PB',
                IsActive__c = true
            ),
            new ProductType__c(
                Name = 'Mechanical Tube',
                ShortName__c = 'MT',
                Code__c = 'PC',
                IsActive__c = true
            )
        };
        insert prodTypes;

        Map<String, ProductType__c> prodTypesByCode = new Map<String, ProductType__c>();

        for (ProductType__c pt : [
            SELECT Id, Code__c
            FROM ProductType__c
            WHERE Code__c IN ('PB', 'PC')
        ]) {
            prodTypesByCode.put(pt.Code__c, pt);
        }

        List<ProdType_Group3__c> links = new List<ProdType_Group3__c>{
            new ProdType_Group3__c(
                Product2Id__c = product.Id,
                ProductType__c = prodTypesByCode.get('PB').Id,
                CompositeKey__c = String.valueOf(product.Id) + '_' +
                                  String.valueOf(prodTypesByCode.get('PB').Id)
                //Group3__c = '20'
            ),
            new ProdType_Group3__c(
                Product2Id__c = product.Id,
                ProductType__c = prodTypesByCode.get('PC').Id,
                CompositeKey__c = String.valueOf(product.Id) + '_' +
                                  String.valueOf(prodTypesByCode.get('PC').Id)
                //Group3__c = '20'
            )
        };

        insert links;
    }

    //====================================================
    @IsTest
    static void testGetById() {

        ProdType_Group3__c link = [
            SELECT Id
            FROM ProdType_Group3__c
            LIMIT 1
        ];

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getById(link.Id);

        System.assertNotEquals(null, result);
        System.assertEquals(link.Id, result.Id);
    }

    //====================================================
    @IsTest
    static void testGetByCompositeKey() {

        ProdType_Group3__c link = [
            SELECT Id, CompositeKey__c
            FROM ProdType_Group3__c
            WHERE CompositeKey__c != null
            LIMIT 1
        ];

        System.assertNotEquals(null, link.CompositeKey__c);

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByCompositeKey(link.CompositeKey__c);

        System.assertNotEquals(null, result);
        System.assertEquals(link.Id, result.Id);
        System.assertEquals(link.CompositeKey__c, result.CompositeKey__c);
    }

    //====================================================
    @IsTest
    static void testGetByProductAndType() {

        ProdType_Group3__c link = [
            SELECT Id, Product2Id__c, ProductType__c
            FROM ProdType_Group3__c
            WHERE ProductType__r.Code__c = 'PB'
            LIMIT 1
        ];

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByProductAndType(
                link.Product2Id__c,
                link.ProductType__c
            );

        System.assertNotEquals(null, result);
        System.assertEquals(link.Id, result.Id);
    }

    //====================================================
    @IsTest
    static void testGetByErpGroupAndTypeCode() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByErpGroupAndTypeCode('20', 'PB');

        System.assertNotEquals(null, result);
        System.assertEquals('20', result.Group3__c);
        System.assertEquals('PB', result.ProductType__r.Code__c);
    }

    //====================================================
    @IsTest
    static void testGetByErpGroupAndKmat() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByErpGroupAndKmat(
                '20',
                'PB5820112MУИ004'
            );

        System.assertNotEquals(null, result);
        System.assertEquals('20', result.Group3__c);
        System.assertEquals('PB', result.ProductType__r.Code__c);
    }

    //====================================================
    @IsTest
    static void testExtractProductTypeCodeFromKmat() {

        System.assertEquals(
            'PB',
            ProdTypeGroup3Repository.extractProductTypeCodeFromKmat(
                'PB5820112MУИ004'
            )
        );

        System.assertEquals(
            'PC',
            ProdTypeGroup3Repository.extractProductTypeCodeFromKmat(
                '  PC123456 '
            )
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.extractProductTypeCodeFromKmat(null)
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.extractProductTypeCodeFromKmat('')
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.extractProductTypeCodeFromKmat('P')
        );
    }

    //====================================================
    @IsTest
    static void testBuildCompositeKey() {

        ProdType_Group3__c link = [
            SELECT Product2Id__c, ProductType__c, CompositeKey__c
            FROM ProdType_Group3__c
            WHERE CompositeKey__c != null
            LIMIT 1
        ];

        String result =
            ProdTypeGroup3Repository.buildCompositeKey(
                link.Product2Id__c,
                link.ProductType__c
            );

        System.assertEquals(link.CompositeKey__c, result);
    }

    //====================================================
    @IsTest
    static void testGetAll() {

        List<ProdType_Group3__c> result =
            ProdTypeGroup3Repository.getAll();

        System.assertNotEquals(null, result);
        System.assert(result.size() >= 2);
    }

    //====================================================
    @IsTest
    static void testReturnsNullForUnknownCompositeKey() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByCompositeKey('UNKNOWN_KEY');

        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testReturnsNullForUnknownErpGroup() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByErpGroupAndTypeCode(
                'UNKNOWN',
                'PB'
            );

        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testReturnsNullForUnknownProductTypeCode() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByErpGroupAndTypeCode(
                '20',
                'UNKNOWN'
            );

        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testReturnsNullForInvalidKmat() {

        ProdType_Group3__c result =
            ProdTypeGroup3Repository.getByErpGroupAndKmat(
                '20',
                'P'
            );

        System.assertEquals(null, result);
    }

    //====================================================
    @IsTest
    static void testNullInputs() {

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByCompositeKey(null)
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByProductAndType(null, null)
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByErpGroupAndTypeCode(null, 'PB')
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByErpGroupAndTypeCode('20', null)
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByErpGroupAndKmat(null, 'PB123')
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.getByErpGroupAndKmat('20', null)
        );

        System.assertEquals(
            null,
            ProdTypeGroup3Repository.buildCompositeKey(null, null)
        );
    }

    //====================================================
    @IsTest
    static void testClearCacheAndRefresh() {

        ProdType_Group3__c link = [
            SELECT Id, CompositeKey__c
            FROM ProdType_Group3__c
            WHERE CompositeKey__c != null
            LIMIT 1
        ];

        ProdType_Group3__c firstLoad =
            ProdTypeGroup3Repository.getByCompositeKey(link.CompositeKey__c);

        System.assertNotEquals(null, firstLoad);

        ProdTypeGroup3Repository.clearCache();

        ProdType_Group3__c afterClear =
            ProdTypeGroup3Repository.getByCompositeKey(link.CompositeKey__c);

        System.assertNotEquals(null, afterClear);
        System.assertEquals(link.Id, afterClear.Id);

        ProdTypeGroup3Repository.refresh();

        ProdType_Group3__c afterRefresh =
            ProdTypeGroup3Repository.getByCompositeKey(link.CompositeKey__c);

        System.assertNotEquals(null, afterRefresh);
        System.assertEquals(link.Id, afterRefresh.Id);
    }
}