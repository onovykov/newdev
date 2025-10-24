public with sharing class OppProcessingService {

    public class Result {
        public String orderType;
        public Integer processed;
        public Integer skipped;
        public String orderCurrency;
    }

    public static Result processIncoming(String rawJson) {
        OppDtoFactory.Parsed parsed = OppDtoFactory.parse(rawJson);
        Result r = new Result();
        r.orderCurrency = parsed.data.OrderCurrency;
        r.orderType = parsed.data.OrderType;

        if (parsed.data instanceof TubesData) {
            TubesData td = (TubesData) parsed.data;
            ItemMapperResult mr = TubesItemMapper.upsertItems(td.Items, parsed.data.Header, parsed.data.OrderCurrency);
            r.processed = (mr == null) ? 0 : mr.itemsProcessed;
            r.skipped   = (mr == null) ? 0 : mr.itemsSkipped;
        } else if (parsed.data instanceof WheelsData) {
            WheelsData wd = (WheelsData) parsed.data;
            ItemMapperResult mr = WheelsItemMapper.upsertItems(wd.Items, parsed.data.Header, parsed.data.OrderCurrency);
            r.processed = (mr == null) ? 0 : mr.itemsProcessed;
            r.skipped   = (mr == null) ? 0 : mr.itemsSkipped;
        } else {
            throw new AuraHandledException('Unknown data type');
        }
        return r;
    }
}