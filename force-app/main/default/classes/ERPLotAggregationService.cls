public with sharing class ERPLotAggregationService {

    public class AggregationResult {
        public Set<String> iteNumbers = new Set<String>();
        public Map<String, List<ERPLotAggregate>> aggregatesByIte =
            new Map<String, List<ERPLotAggregate>>();

        public Boolean isEmpty() {
            return iteNumbers.isEmpty() || aggregatesByIte.isEmpty();
        }
    }

    public AggregationResult aggregate(
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed
    ) {
        AggregationResult result = new AggregationResult();

        for (ERPMessageParser.ERPObject_OrderItem itemDto : parsed.data.items) {
            if (itemDto == null || itemDto.lots == null || itemDto.lots.isEmpty()) {
                continue;
            }

            String iteNumber = itemDto.iteNumber;

            if (String.isBlank(iteNumber)) {
                continue;
            }

            ERPLotAccumulator acc = new ERPLotAccumulator(iteNumber);

            for (ERPMessageParser.ERPObject_ProductLot lotDto : itemDto.lots) {
                acc.add(lotDto);
            }

            List<ERPLotAggregate> itemAggregates = acc.toAggregates();

            if (!itemAggregates.isEmpty()) {
                result.iteNumbers.add(iteNumber);
                result.aggregatesByIte.put(iteNumber, itemAggregates);
            }
        }

        return result;
    }
}