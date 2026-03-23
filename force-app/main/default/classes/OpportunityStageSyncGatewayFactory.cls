/*
    Gateway factory
    Зараз повертає legacy-реалізацію. Потім просто поміняємо factory
*/
public with sharing class OpportunityStageSyncGatewayFactory {
    //public static IOpportunityStageSyncGateway create() {
    //    return new LegacyOpportunityStageSyncGateway();
    //}
    /*
        Щоби тестувати без реального callout,
        нам потрібна можливість підмінити gateway у тестах
    */
    @TestVisible
    private static IOpportunityStageSyncGateway testOverride;

    public static IOpportunityStageSyncGateway create() {
        if (Test.isRunningTest() && testOverride != null) {
            return testOverride;
        }
        return new LegacyOpportunityStageSyncGateway();
    }

    @TestVisible
    public static void setTestOverride(IOpportunityStageSyncGateway mockGateway) {
        testOverride = mockGateway;
    }

    @TestVisible
    public static void reset() {
        testOverride = null;
    }
}