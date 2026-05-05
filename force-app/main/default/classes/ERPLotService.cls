public with sharing class ERPLotService {

    public class Result {
        public List<Lot__c> lots = new List<Lot__c>();
        public Database.UpsertResult[] upsertResults;
    }

    public Result process(
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed,
        Boolean isDryRun
    ) {
        Result result = new Result();

        if (!isValid(parsed)) {
            return result;
        }

        ERPLotAggregationService.AggregationResult aggregation =
            new ERPLotAggregationService().aggregate(parsed);

        if (aggregation.isEmpty()) {
            return result;
        }

        Map<String, OrderItem> orderItemsByIte =
            OrderItemPlatformCache.getMany(aggregation.iteNumbers);

        if (orderItemsByIte == null || orderItemsByIte.isEmpty()) {
            return result;
        }

        List<ERPLotAggregate> aggregates =
            new ERPLotBuilder().buildAggregatesWithOrderItems(
                aggregation.aggregatesByIte,
                orderItemsByIte
            );

        if (aggregates.isEmpty()) {
            return result;
        }

        LotRepository lotRepo = new LotRepository();
        Map<String, Lot__c> existingLotsByExtKey =
            lotRepo.getByExtKeys(ERPLotKeyUtil.collectExtKeys(aggregates));

        List<Lot__c> lotsForUpsert =
            new ERPLotBuilder().buildLotsForUpsert(aggregates, existingLotsByExtKey);

        result.lots = lotsForUpsert;

        if (!isDryRun && !lotsForUpsert.isEmpty()) {
            result.upsertResults = lotRepo.upsertByExtKey(lotsForUpsert);
        }

        return result;
    }

    private static Boolean isValid(
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed
    ) {
        return parsed != null
            && parsed.data != null
            && parsed.data.items != null
            && !parsed.data.items.isEmpty();
    }
}