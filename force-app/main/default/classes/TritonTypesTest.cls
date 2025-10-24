@IsTest
private class TritonTypesTest {

    @IsTest
    static void test_Area_values_and_order() {
        List<TritonTypes.Area> expected = new List<TritonTypes.Area>{
            TritonTypes.Area.OpportunityManagement,
            TritonTypes.Area.LeadConversion,
            TritonTypes.Area.Community,
            TritonTypes.Area.RestAPI,
            TritonTypes.Area.Accounts,
            TritonTypes.Area.LWC,
            TritonTypes.Area.Flow,
            TritonTypes.Area.OpportunityData,
            TritonTypes.Area.PriceApprovalRequest,
            TritonTypes.Area.SendToBackoffice,
            TritonTypes.Area.SFtoERPOpportunityStage,
            TritonTypes.Area.SalesPlanFact,
            TritonTypes.Area.NewSpecification,
            TritonTypes.Area.AdjustmentQuotaRequest,
            TritonTypes.Area.SalesBudget
        };
        List<TritonTypes.Area> actual = TritonTypes.Area.values();

        System.assertEquals(expected.size(), actual.size(), 'Area: size must match');
        System.assertEquals(expected, actual, 'Area: order and contents must match declaration');
    }

    @IsTest
    static void test_Category_values_and_order() {
        List<TritonTypes.Category> expected = new List<TritonTypes.Category>{
            TritonTypes.Category.Apex,
            TritonTypes.Category.Flow,
            TritonTypes.Category.LWC,
            TritonTypes.Category.Aura,
            TritonTypes.Category.Warning,
            TritonTypes.Category.Event,
            TritonTypes.Category.Debug,
            TritonTypes.Category.Integration
        };
        System.assertEquals(expected, TritonTypes.Category.values(), 'Category: order/contents must match');
    }

    @IsTest
    static void test_Level_roundtrip_and_order() {
        // Перевіряємо порядок (від ERROR до FINEST)
        List<TritonTypes.Level> expected = new List<TritonTypes.Level>{
            TritonTypes.Level.ERROR,
            TritonTypes.Level.WARNING,
            TritonTypes.Level.INFO,
            TritonTypes.Level.DEBUG,
            TritonTypes.Level.FINE,
            TritonTypes.Level.FINER,
            TritonTypes.Level.FINEST
        };
        System.assertEquals(expected, TritonTypes.Level.values(), 'Level: order/contents must match');

        // Round-trip: String -> enum -> String
        System.assertEquals(TritonTypes.Level.DEBUG, TritonTypes.Level.valueOf('DEBUG'));
        System.assertEquals('FINEST', String.valueOf(TritonTypes.Level.FINEST));
    }

    @IsTest
    static void test_Type_values_and_valueOf_negative() {
        // sanity: клас торкнуто
        List<TritonTypes.Type> vals = TritonTypes.Type.values();
        System.assert(vals.contains(TritonTypes.Type.Backend), 'Type should contain Backend');
        System.assert(vals.contains(TritonTypes.Type.ApexException), 'Type should contain ApexException');

        // Negative: unknown enum name
        Boolean threw = false;
        try {
            TritonTypes.Type.valueOf('DoesNotExist');
            System.assert(false, 'valueOf must throw for unknown value');
        } catch (System.NoSuchElementException e) {
            threw = true;
        } catch (System.TypeException e) {
            // деякі рантайми/версії можуть кидати TypeException
            threw = true;
        }
        System.assert(threw, 'Type.valueOf must throw for unknown value');
    }

}