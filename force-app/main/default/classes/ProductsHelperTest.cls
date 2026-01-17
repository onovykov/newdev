@IsTest
private class ProductsHelperTest {

    private static void mockCarbonSteel() {
        ProductsHelper.mockDensity = new ProductMaterialDensity__mdt(
            DeveloperName = 'CARBON_STEEL',
            MasterLabel   = 'CARBON STEEL',
            DencityKGMC__c = 7850,
            DencityLbInC__c = 0.284
        );
    }

    // ===========================
    // ASTM A53 – Round pipe (kg/m)
    // ===========================
    @IsTest
    static void testRoundPipeKgPerMeter_ASTM_A53() {
        mockCarbonSteel();

        Decimal result = ProductsHelper.weightPerMeterRoundTubeMM(
            60.325,   // 2.375 in
            3.91,     // 0.154 in
            'CARBON_STEEL'
        );

        // ASTM reference: 5.43 kg/m
        System.assertEquals(
            5.43,
            result,
            0.05,
            'ASTM A53 round pipe kg/m mismatch'
        );
    }

    // ===========================
    // ASTM A53 – Round pipe (lb/ft)
    // ===========================
    @IsTest
    static void testRoundPipeLbPerFoot_ASTM_A53() {
        mockCarbonSteel();

        Decimal result = ProductsHelper.weightPerFootRoundTubeInch(
            2.375,
            0.154,
            'CARBON_STEEL'
        );

        // ASTM reference: 3.65 lb/ft
        System.assertEquals(
            3.65,
            result,
            0.05,
            'ASTM A53 round pipe lb/ft mismatch'
        );
    }

    // ===========================
    // ASTM A500 – Rectangular tube (lb/ft)
    // ===========================
    @IsTest
    static void testRectangularTubeLbPerFoot_ASTM_A500() {
        mockCarbonSteel();

        Decimal result = ProductsHelper.weightPerFootRectTubeInch(
            2.0,
            1.0,
            0.125,
            'CARBON_STEEL'
        );

        // ASTM reference: 3.23 lb/ft
        System.assertEquals(
            3.23,
            result,
            0.05,
            'ASTM A500 rectangular tube lb/ft mismatch'
        );
    }

    // ===========================
    // ASTM A500 – Rectangular tube (kg/m)
    // ===========================
    @IsTest
    static void testRectangularTubeKgPerMeter_ASTM_A500() {
        mockCarbonSteel();

        Decimal result = ProductsHelper.weightPerMeterRectTubeMM(
            50.8,   // 2 in
            25.4,   // 1 in
            3.175,  // 0.125 in
            'CARBON_STEEL'
        );

        // ASTM reference: 4.80 kg/m
        System.assertEquals(
            4.80,
            result,
            0.05,
            'ASTM A500 rectangular tube kg/m mismatch'
        );
    }
}