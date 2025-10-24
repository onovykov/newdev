@IsTest
private class RecordTypeRegistryTest {

    @IsTest
    static void test_isRecordType_byId_true_and_false() {
        // Given
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = RecordTypeRegistry.RT_OPP_TUBES_SIMPLE_RFP;

        // When / Then
        System.assertEquals(
            true,
            RecordTypeRegistry.isRecordType(opp, RecordTypeRegistry.RT_OPP_TUBES_SIMPLE_RFP),
            'Should match the same RecordTypeId'
        );

        System.assertEquals(
            false,
            RecordTypeRegistry.isRecordType(opp, RecordTypeRegistry.RT_OPP_WHEELS_TENDER),
            'Should NOT match a different RecordTypeId'
        );
    }

    @IsTest
    static void test_isRecordType_byName_true_and_false_on_standard_objects() {
        // Given
        Contact c = new Contact();
        c.RecordTypeId = RecordTypeRegistry.RT_CONTACT_INTERNAL;

        // Positive by name
        System.assertEquals(
            true,
            RecordTypeRegistry.isRecordType(c, 'Contact', 'Internal'),
            'Contact must be Internal by name'
        );

        // Negative by name
        System.assertEquals(
            false,
            RecordTypeRegistry.isRecordType(c, 'Contact', 'External'),
            'Contact must NOT be External by name'
        );

        // Cross-object name check (method не перевіряє тип sObject, лише ID у мапі)
        // Підміняємо RecordTypeId на SPF:Plan і перевіряємо назвою "SalesPlanFact:Plan"
        c.RecordTypeId = RecordTypeRegistry.RT_SPF_PLAN;
        System.assertEquals(
            true,
            RecordTypeRegistry.isRecordType(c, 'SalesPlanFact', 'Plan'),
            'Name-based lookup must match SPF:Plan ID regardless of concrete sObject type'
        );
    }

    @IsTest
    static void test_isRecordType_null_record_and_unknown_key() {
        // Null record -> false
        System.assertEquals(
            false,
            RecordTypeRegistry.isRecordType((SObject) null, RecordTypeRegistry.RT_OPP_TUBES_TENDER),
            'Null record must return false'
        );

        // Unknown mapping key -> false
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = RecordTypeRegistry.RT_OPP_TUBES_TENDER;

        System.assertEquals(
            false,
            RecordTypeRegistry.isRecordType(opp, 'Account', 'DoesNotExist'),
            'Unknown ObjectName:RecordTypeName must return false'
        );
    }

    @IsTest
    static void test_maps_bidirectional_consistency() {
        // NameToId -> IdToName
        for (String keyName : RecordTypeRegistry.NameToId.keySet()) {
            Id idVal = RecordTypeRegistry.NameToId.get(keyName);
            String backName = RecordTypeRegistry.IdToName.get(idVal);
            System.assertEquals(
                keyName, backName,
                'IdToName must be reverse of NameToId for ' + keyName
            );
        }

        // IdToName -> NameToId
        for (Id idKey : RecordTypeRegistry.IdToName.keySet()) {
            String nameVal = RecordTypeRegistry.IdToName.get(idKey);
            Id backId = RecordTypeRegistry.NameToId.get(nameVal);
            System.assertEquals(
                idKey, backId,
                'NameToId must be reverse of IdToName for ' + nameVal
            );
        }
    }

    @IsTest
    static void test_id_constants_are_not_null_like_ids() {
        // Базова перевірка: константи мають бути 15/18-символьними Id (тільки sanity check)
        List<Id> ids = new List<Id>{
            RecordTypeRegistry.RT_OPP_NEW_CLIENT_ENQUIRY,
            RecordTypeRegistry.RT_OPP_TUBES_SIMPLE_RFP,
            RecordTypeRegistry.RT_OPP_TUBES_TENDER,
            RecordTypeRegistry.RT_OPP_WHEELS_SIMPLE_RFP,
            RecordTypeRegistry.RT_OPP_WHEELS_TENDER,
            RecordTypeRegistry.RT_CONTACT_INTERNAL,
            RecordTypeRegistry.RT_CONTACT_EXTERNAL,
            RecordTypeRegistry.RT_SPF_ACTUAL_BUDGET,
            RecordTypeRegistry.RT_SPF_CORRECTED_BUDGET,
            RecordTypeRegistry.RT_SPF_FACT,
            RecordTypeRegistry.RT_SPF_INITIAL_BUDGET,
            RecordTypeRegistry.RT_SPF_OPPORTUNITY,
            RecordTypeRegistry.RT_SPF_ORDER,
            RecordTypeRegistry.RT_SPF_PLAN,
            RecordTypeRegistry.RT_SBR_PLAN_MONTH,
            RecordTypeRegistry.RT_SBR_PLAN_QUARTER
        };

        for (Id i : ids) {
            System.assertNotEquals(null, i, 'RecordType constant must not be null');
            String s = String.valueOf(i);
            System.assert(
                s.length() == 15 || s.length() == 18,
                'RecordType Id should look like a Salesforce Id (15/18 chars), got: ' + s
            );
        }
    }
}