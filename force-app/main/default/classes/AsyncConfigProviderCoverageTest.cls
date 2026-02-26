@IsTest
public class AsyncConfigProviderCoverageTest {

    @IsTest
    static void coverGetMethods() {

        // default config
        AsyncConfig cfg1 = AsyncConfigProvider.get();
        System.assertNotEquals(null, cfg1);

        // explicit by developer name
        AsyncConfig cfg2 =
            AsyncConfigProvider.getByDeveloperName('Default_Setting');

        System.assertNotEquals(null, cfg2);
    }

    @IsTest
    static void coverInvalidConfig() {

        try {
            AsyncConfigProvider.getByDeveloperName('NOT_EXISTING');
            System.assert(false, 'Exception expected');
        } catch (Exception e) {
            System.assert(true);
        }
    }
}