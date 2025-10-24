@IsTest
public class AllPricesDatatableControllerTest {
    @TestSetup
    static void setupTestData() {
        Country__c country = new Country__c(Name = 'USA', NumCode__c = '840', A2Code__c = 'US', A3Code__c = 'USA');
        insert country;

        ShippingPoint__c shippingPoint = new ShippingPoint__c(Name = 'Test Shipping Point', Country__c = country.Id);
        insert shippingPoint;

        TubeOD__c odRecord1 = new TubeOD__c(Name = '100', OD_mm__c = 100);
        TubeOD__c odRecord2 = new TubeOD__c(Name = '200', OD_mm__c = 200);
        TubeWT__c wtRecord1 = new TubeWT__c(Name = '10', WT_mm__c = 10);
        TubeWT__c wtRecord2 = new TubeWT__c(Name = '20', WT_mm__c = 20);

        insert new List<TubeOD__c>{ odRecord1, odRecord2 };
        insert new List<TubeWT__c>{ wtRecord1, wtRecord2 };

        List<Price__c> prices = new List<Price__c>{
            new Price__c(
                OD_mm__c = odRecord1.Id,
                WT_mm__c = wtRecord1.Id,
                Weight_ppf__c = 5.0,
                Incoterms__c = 'FOB',
                ShippingPoint__c = shippingPoint.Id,
                Price__c = 1000,
                Margin__c = 10,
                MarginBG__c = 5,
                Product_Type__c = 'OCTG'
            ),
            new Price__c(
                OD_mm__c = odRecord2.Id,
                WT_mm__c = wtRecord2.Id,
                Weight_ppf__c = 10.0,
                Incoterms__c = 'CIF',
                ShippingPoint__c = shippingPoint.Id,
                Price__c = 2000,
                Margin__c = 20,
                MarginBG__c = 10,
                Product_Type__c = 'LP/GU'
            )
        };

        insert prices;
    }

    @IsTest
    static void testGetPrices() {
        Test.startTest();
        List<AllPricesDatatableController.PriceWrapper> priceWrappers = AllPricesDatatableController.getPrices();
        Test.stopTest();

        System.assertEquals(2, priceWrappers.size(), 'Expected two PriceWrappers to be returned');

        AllPricesDatatableController.PriceWrapper wrapper1 = priceWrappers[0];
        AllPricesDatatableController.PriceWrapper wrapper2 = priceWrappers[1];

        System.assertEquals('100.00', wrapper1.odmm, 'Incorrect OD_mm__c value');
        System.assertEquals('10.00', wrapper1.wtmm, 'Incorrect WT_mm__c value');
        System.assertEquals(5.0, wrapper1.ppf, 'Incorrect Weight_ppf__c value');
        System.assertEquals('FOB', wrapper1.incoterms, 'Incorrect Incoterms__c value');
        System.assertEquals('Test Shipping Point', wrapper1.shippingPoint, 'Incorrect ShippingPoint__r.Name value');
        System.assertEquals(1000, wrapper1.price, 'Incorrect Price__c value');
        System.assertEquals(10, wrapper1.margin, 'Incorrect Margin__c value');
        System.assertEquals(5, wrapper1.budgetMargin, 'Incorrect MarginBG__c value');
        System.assertEquals('OCTG', wrapper1.prodType, 'Incorrect Product_Type__c value');

        System.assertEquals('200.00', wrapper2.odmm, 'Incorrect OD_mm__c value');
        System.assertEquals('20.00', wrapper2.wtmm, 'Incorrect WT_mm__c value');
        System.assertEquals(10.0, wrapper2.ppf, 'Incorrect Weight_ppf__c value');
        System.assertEquals('CIF', wrapper2.incoterms, 'Incorrect Incoterms__c value');
        System.assertEquals(2000, wrapper2.price, 'Incorrect Price__c value');
    }

    @IsTest
    static void testGetFilteredPrices() {
        Map<String, String> filters = new Map<String, String>{
            'Product_Type__c' => 'OCTG'
        };
        Map<String, String> fieldsTypes = new Map<String, String>{
            'Product_Type__c' => 'text'
        };
        Map<String, String> fieldsMax = new Map<String, String>{
            'Product_Type__c' => null
        };

        Test.startTest();
        List<AllPricesDatatableController.PriceWrapper> filteredPrices = AllPricesDatatableController.getFilteredPrices(filters, fieldsTypes, fieldsMax);
        Test.stopTest();

        System.assertEquals(1, filteredPrices.size(), 'Expected one result for Product_Type__c = "OCTG"');
        System.assertEquals('OCTG', filteredPrices[0].prodType, 'Incorrect Product_Type__c value');

        filters.clear();
        filters.put('Price__c', '>=1500');
        fieldsTypes.clear();
        fieldsTypes.put('Price__c', 'number');
        fieldsMax.clear();
        fieldsMax.put('Price__c', null);

        filteredPrices = AllPricesDatatableController.getFilteredPrices(filters, fieldsTypes, fieldsMax);

        System.assertEquals(1, filteredPrices.size(), 'Expected one result for Price__c >= 1500');
        System.assertEquals(2000, filteredPrices[0].price, 'Incorrect Price__c value');

        filters.clear();
        filters.put('Price__c', '<=2000');
        filters.put('Incoterms__c', 'CIF');
        fieldsTypes.put('Incoterms__c', 'text');
        fieldsMax.put('Incoterms__c', null);
        filters.put('OD_mm__r.OD_mm__c', '200');
        fieldsTypes.put('OD_mm__r.OD_mm__c', 'number');
        fieldsMax.put('OD_mm__r.OD_mm__c', 'OD_mm_max__r.OD_mm__c');


        filteredPrices = AllPricesDatatableController.getFilteredPrices(filters, fieldsTypes, fieldsMax);

        System.assertEquals(1, filteredPrices.size(), 'Expected one result for Price__c <= 2000 and Incoterms__c = "CIF"');
        System.assertEquals(2000, filteredPrices[0].price, 'Incorrect Price__c value');
        System.assertEquals('CIF', filteredPrices[0].incoterms, 'Incorrect Incoterms__c value');
    }
}