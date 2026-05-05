public with sharing class ERPLotHandler {

    @TestVisible
    private static List<Lot__c> dryRunLots = new List<Lot__c>();

    public static void fillAggregateLots(
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed,
        Boolean isDryRun
    ) {
        ERPLotService service = new ERPLotService();
        ERPLotService.Result result = service.process(parsed, isDryRun == true);

        if (isDryRun == true) {
            dryRunLots = result.lots;
        }
    }

    public static List<Lot__c> getLotList(
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed
    ) {
        fillAggregateLots(parsed, true);
        return dryRunLots;
    }
}