@IsTest
private class TestDataFactoryCoverageTest {

    // Проста генерація валідного 15-символьного Id
    private static Id fakeId(String prefix) {
        return (Id)(prefix + '000000000000000');
    }

    @IsTest
    static void coverMostFactoryMethods() {

        Account acc = TestDataFactory.createTestAccount();
        System.assertNotEquals(null, acc.Id);

        Contact c =
            TestDataFactory.createTestContact(
                UserInfo.getUserId()
            );
        System.assertNotEquals(null, c.Id);

        InvoiceOrderDebt__c inv =
            TestDataFactory.createTestInvoice(acc.Id);
        System.assertNotEquals(null, inv.Id);

        Product2 p =
            TestDataFactory.createTestProduct2('Tubes');
        System.assertEquals('Test Product', p.Name);

        ProductStandard__c ps =
            TestDataFactory.createTestProductStandard();
        System.assertEquals('Test Standard', ps.Name);

        Pricebook2 pb =
            TestDataFactory.getStandardPricebook2();
        System.assertNotEquals(null, pb.Id);

        // Product2 prefix = 01t
        PricebookEntry pbe =
            TestDataFactory.createTestPricebookEntry(
                pb.Id,
                fakeId('01t')
            );
        System.assertEquals(true, pbe.IsActive);

        Country__c country =
            TestDataFactory.createTestCountry(
                'TestCountry',
                '999'
            );
        System.assertEquals('TestCountry', country.Name);

        // Country__c custom object prefix зазвичай починається з a0
        Order o =
            TestDataFactory.createTestOrder(
                acc.Id,
                UserInfo.getUserId(),
                pb.Id,
                fakeId('a00'),
                '00002'
            );
        System.assertEquals('Draft', o.Status);

        SteelGrade__c sg =
            TestDataFactory.createTestSteelGrade();
        System.assertEquals('Test Grade', sg.Name);

        TubeOD__c od =
            TestDataFactory.createTestTubeOD(1.0, 25.4);
        System.assertEquals(25.4, od.OD_mm__c);

        TubeWT__c wt =
            TestDataFactory.createTestTubeWT(0.1, 2.54);
        System.assertEquals(2.54, wt.WT_mm__c);

        TubeLengthSize__c ls =
            TestDataFactory.createTestTubeLengthSize(
                'LS',
                10,
                5
            );
        System.assertEquals('LS', ls.Name);

        OrderItem oi =
            TestDataFactory.createTestOrderItem(
                fakeId('801'), // Order
                fakeId('01t'), // Product2
                fakeId('a01'), // TubeOD__c
                fakeId('a02'), // TubeWT__c
                fakeId('a03'), // SteelGrade__c
                fakeId('a04'), // TubeLengthSize__c
                fakeId('01u')  // PricebookEntry
            );
        System.assertEquals(1, oi.Quantity);

        System.assertEquals(
            0,
            TestDataFactory.createAccounts(0).size()
        );

        System.assertEquals(
            2,
            TestDataFactory.createAccounts(2).size()
        );

        AsyncConfig cfg =
            TestDataFactory.defaultAsyncConfig();
        System.assertNotEquals(null, cfg);

        System.assertEquals(true, TestDataFactory.isTestFactory());
        System.assertEquals(true, TestDataFactory.coveragePing());
    }
}