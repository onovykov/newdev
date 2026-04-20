@IsTest
private class ProdTechRefDetailsTriggerTest {

    // ---------- HELPERS ----------

    private static ProdTechRef__c createRef(String itRef, String suffix) {

        String orderType = 'OT' + suffix;
        String order = 'ORD' + suffix;

        ProdTechRef__c ref = new ProdTechRef__c(
            Name = 'Ref ' + itRef + suffix,
            ITRef__c = itRef,
            OrderType__c = orderType,
            Object__c = order,
            ExtKey__c = orderType + '_' + order
        );

        insert ref;
        return ref;
    }

    private static ProdTechRefDetails__c createRecord(String code, Id refId) {
        ProdTechRefDetails__c rec = new ProdTechRefDetails__c(
            Name = 'Test Rec ' + code,
            ID_ERP__c = code,
            ProdTechRef__c = refId
        );
        insert rec;
        return rec;
    }

    // ---------- TESTS ----------

    @IsTest
    static void testBeforeInsert() {
        ProdTechRef__c ref = createRef('DIMP', '1');

        ProdTechRefDetails__c rec = new ProdTechRefDetails__c(
            Name = 'Insert Test',
            ID_ERP__c = 'ABC123',
            ProdTechRef__c = ref.Id
        );

        insert rec;

        rec = [
            SELECT NormalizedCode__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        String encoded = CanonicalKeyService.encode('ABC123');

        System.assertEquals(encoded, rec.NormalizedCode__c);
        System.assertEquals('DIMP|' + encoded, rec.CompositeKey__c);
    }

    @IsTest
    static void testBeforeUpdate_CodeChanged() {
        ProdTechRef__c ref = createRef('DIMP', '2');

        ProdTechRefDetails__c rec = createRecord('ABC123', ref.Id);

        rec = [
            SELECT Id, ID_ERP__c, ProdTechRef__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        rec.ID_ERP__c = 'XYZ789';
        update rec;

        rec = [
            SELECT NormalizedCode__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        String encoded = CanonicalKeyService.encode('XYZ789');

        System.assertEquals(encoded, rec.NormalizedCode__c);
        System.assertEquals('DIMP|' + encoded, rec.CompositeKey__c);
    }

    @IsTest
    static void testBeforeUpdate_NoChanges() {
        ProdTechRef__c ref = createRef('DIMP', '3');

        ProdTechRefDetails__c rec = createRecord('ABC123', ref.Id);

        rec = [
            SELECT Id, NormalizedCode__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        String oldNormalized = rec.NormalizedCode__c;
        String oldComposite = rec.CompositeKey__c;

        rec.Name = 'Updated Name';
        update rec;

        rec = [
            SELECT NormalizedCode__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        System.assertEquals(oldNormalized, rec.NormalizedCode__c);
        System.assertEquals(oldComposite, rec.CompositeKey__c);
    }

    @IsTest
    static void testBeforeUpdate_LookupChanged() {
        ProdTechRef__c ref1 = createRef('DIMP', '4');
        ProdTechRef__c ref2 = createRef('WLMP', '5');

        ProdTechRefDetails__c rec = createRecord('ABC123', ref1.Id);

        rec = [
            SELECT Id, ID_ERP__c, ProdTechRef__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        rec.ProdTechRef__c = ref2.Id;
        update rec;

        rec = [
            SELECT NormalizedCode__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        String encoded = CanonicalKeyService.encode('ABC123');

        System.assertEquals(encoded, rec.NormalizedCode__c);
        System.assertEquals('WLMP|' + encoded, rec.CompositeKey__c);
    }

    @IsTest
    static void testUpdateToBlankCode() {
        ProdTechRef__c ref = createRef('DIMP', '6');

        ProdTechRefDetails__c rec = createRecord('ABC123', ref.Id);

        rec = [
            SELECT Id, ID_ERP__c
            FROM ProdTechRefDetails__c
            WHERE Id = :rec.Id
        ];

        rec.ID_ERP__c = '   ';

        try {
            update rec;

            rec = [
                SELECT NormalizedCode__c, CompositeKey__c
                FROM ProdTechRefDetails__c
                WHERE Id = :rec.Id
            ];

            System.assertEquals(null, rec.NormalizedCode__c);
            System.assertEquals(null, rec.CompositeKey__c);

        } catch (DmlException e) {
            // якщо org не дозволяє blank — це ок
            System.assert(e.getMessage().contains('REQUIRED_FIELD'));
        }
    }

    @IsTest
    static void testHandlerDirectBlankFallback() {
        ProdTechRefDetails__c rec = new ProdTechRefDetails__c(
            Name = 'Direct Test',
            ID_ERP__c = '   '
        );

        Test.startTest();
        ProdTechRefDetailsTriggerHandler.handleBefore(
            new List<ProdTechRefDetails__c>{ rec },
            null,
            true,
            false
        );
        Test.stopTest();

        System.assertEquals(null, rec.NormalizedCode__c);
        System.assertEquals(null, rec.CompositeKey__c);
    }
}