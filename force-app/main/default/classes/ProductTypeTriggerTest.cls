@IsTest
private class ProductTypeTriggerTest {

    @IsTest
    static void testBeforeInsert() {
        ProductType__c pt = new ProductType__c(
            Name = 'Test PT',
            Code__c = 'ABC123'
        );

        insert pt;

        ProductType__c inserted = [
            SELECT Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Id = :pt.Id
        ];

        System.assertEquals(
            CanonicalKeyService.encode('ABC123'),
            inserted.NormalizedCode__c
        );
    }

    @IsTest
    static void testBeforeUpdate_CodeChanged() {
        ProductType__c pt = new ProductType__c(
            Name = 'Test PT',
            Code__c = 'ABC123'
        );
        insert pt;

        pt = [
            SELECT Id, Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Id = :pt.Id
        ];

        pt.Code__c = 'XYZ789';
        update pt;

        ProductType__c updated = [
            SELECT NormalizedCode__c
            FROM ProductType__c
            WHERE Id = :pt.Id
        ];

        System.assertEquals(
            CanonicalKeyService.encode('XYZ789'),
            updated.NormalizedCode__c
        );
    }

    @IsTest
    static void testBeforeUpdate_CodeNotChanged() {
        ProductType__c pt = new ProductType__c(
            Name = 'Test PT',
            Code__c = 'ABC123'
        );
        insert pt;

        // ОБОВ'ЯЗКОВО re-query
        pt = [
            SELECT Id, Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Id = :pt.Id
        ];

        String oldNormalized = pt.NormalizedCode__c;

        pt.Name = 'Updated Name';
        update pt;

        ProductType__c updated = [
            SELECT NormalizedCode__c
            FROM ProductType__c
            WHERE Id = :pt.Id
        ];

        System.assertEquals(
            oldNormalized,
            updated.NormalizedCode__c,
            'NormalizedCode should not change if Code__c is unchanged'
        );
    }

    @IsTest
    static void testCodeCaseSensitivity() {
        ProductType__c pt1 = new ProductType__c(
            Name = 'PT1',
            Code__c = 'ABC123'
        );

        ProductType__c pt2 = new ProductType__c(
            Name = 'PT2',
            Code__c = 'abc123'
        );

        insert new List<ProductType__c>{ pt1, pt2 };

        List<ProductType__c> res = [
            SELECT Code__c, NormalizedCode__c
            FROM ProductType__c
            WHERE Id IN :new List<Id>{pt1.Id, pt2.Id}
        ];

        System.assertEquals(2, res.size(), 'Case sensitive field should allow both values');

        System.assertNotEquals(
            res[0].NormalizedCode__c,
            res[1].NormalizedCode__c,
            'Encoded values should differ if encode is case-sensitive'
        );
    }

    @IsTest
    static void testHandlerDirectBlank() {
        ProductType__c pt = new ProductType__c(
            Name = 'Test PT',
            Code__c = '   '
        );

        Test.startTest();
        ProductTypeTriggerHandler.handleBefore(
            new List<ProductType__c>{ pt },
            null,
            true,
            false
        );
        Test.stopTest();

        System.assertEquals(null, pt.NormalizedCode__c);
    }    
}