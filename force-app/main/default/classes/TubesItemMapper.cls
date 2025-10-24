public with sharing class TubesItemMapper {

    public static ItemMapperResult upsertItems(
        List<TubesData.TubesItem> items,
        OppEnvelope.Header hdr,
        String orderCurrency
    ) {
        ItemMapperResult res = new ItemMapperResult();
        if (items == null || items.isEmpty()) return res;

        for (TubesData.TubesItem it : items) {
            if (it == null) { res.itemsSkipped++; continue; }
            if (it.ProductCharacteristic == null) {
                res.warnings.add('Missing ProductCharacteristic for item ' + it.IteNumber);
                res.itemsSkipped++;
                continue;
            }
            // Example read
            Decimal od = (it.ProductCharacteristic.Diameter == null) ? null : it.ProductCharacteristic.Diameter.OD_mm;
            Decimal wt = (it.ProductCharacteristic.Thickness == null) ? null : it.ProductCharacteristic.Thickness.Wt_mm;
            res.itemsProcessed++;
        }
        return res;
    }
}