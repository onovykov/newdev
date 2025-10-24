@IsTest
public class PriceDatatableControllerTest {

    @TestSetup
    static void setupTestData() {
        Country__c country = new Country__c(Name = 'USA', NumCode__c = '840', A2Code__c = 'US', A3Code__c = 'USA');
        insert country;

        ShippingPoint__c shippingPoint = new ShippingPoint__c(Name = 'Test Shipping Point', Country__c = country.Id);
        insert shippingPoint;

        TubeOD__c odRecord = new TubeOD__c(Name = '100', OD_mm__c = 100);
        TubeWT__c wtRecord = new TubeWT__c(Name = '10', WT_mm__c = 10);

        insert odRecord;
        insert wtRecord;

        PriceListH__c priceListHierarchy = new PriceListH__c(Name = 'Test Price List');
        insert priceListHierarchy;

        Price__c priceRecord = new Price__c(
            OD_mm__c = odRecord.Id,
            WT_mm__c = wtRecord.Id,
            Weight_ppf__c = 5.0,
            Incoterms__c = 'FOB',
            ShippingPoint__c = shippingPoint.Id,
            Price__c = 1000,
            Margin__c = 10,
            MarginBG__c = 5,
            Product_Type__c = 'OCTG',
            PriceListH__c = priceListHierarchy.Id
        );

        insert priceRecord;
    }

    @IsTest
    static void testGetPrices() {
        PriceListH__c priceListHierarchy = [SELECT Id FROM PriceListH__c LIMIT 1];

        Test.startTest();
        List<PriceDatatableController.PriceWrapper> priceWrappers = PriceDatatableController.getPrices(priceListHierarchy.Id);
        Test.stopTest();

        System.assertEquals(1, priceWrappers.size(), 'Expected one PriceWrapper to be returned');
        
        PriceDatatableController.PriceWrapper wrapper = priceWrappers[0];
        
        System.assertEquals(100, wrapper.odmm, 'Incorrect OD_mm__c value');
        System.assertEquals(10, wrapper.wtmm, 'Incorrect WT_mm__c value');
        System.assertEquals(5.0, wrapper.ppf, 'Incorrect Weight_ppf__c value');
        System.assertEquals('FOB', wrapper.incoterms, 'Incorrect Incoterms__c value');
        System.assertEquals('Test Shipping Point', wrapper.shippingPoint, 'Incorrect ShippingPoint__r.Name value');
        System.assertEquals(1000, wrapper.price, 'Incorrect Price__c value');
        System.assertEquals(10, wrapper.margin, 'Incorrect Margin__c value');
        System.assertEquals(5, wrapper.budgetMargin, 'Incorrect MarginBG__c value');
        System.assertEquals('OCTG', wrapper.prodType, 'Incorrect Product_Type__c value');
    }
}