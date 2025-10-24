public with sharing class WheelsItemMapper {

    public static ItemMapperResult upsertItems(
        List<WheelsData.WheelsItem> items,
        OppEnvelope.Header hdr,
        String orderCurrency
    ) {
        ItemMapperResult res = new ItemMapperResult();
        if (items == null || items.isEmpty()) return res;

        for (WheelsData.WheelsItem it : items) {
            if (it == null) { res.itemsSkipped++; continue; }
            if (it.ProductCharacteristic == null) {
                res.warnings.add('Missing ProductCharacteristic for item ' + it.IteNumber);
                res.itemsSkipped++;
                continue;
            }
            Decimal hub = (it.ProductCharacteristic.Hub == null) ? null : it.ProductCharacteristic.Hub.Wt_mm;
            res.itemsProcessed++;
        }
        return res;
    }
}