global without sharing class ProductionLotToLotBatchEx
    implements Database.Batchable<SObject>, Database.Stateful {

    private Date dateFrom;
    private List<ProdWeeksH__c> prodWeeks;

    global ProductionLotToLotBatchEx(Date dateFrom) {
        this.dateFrom = dateFrom;

        this.prodWeeks = [
            SELECT Id, DateFrom__c, DateTo__c
            FROM ProdWeeksH__c
            WHERE DateFrom__c != null
              AND DateTo__c != null
            ORDER BY DateFrom__c ASC
        ];
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   LotDate__c,
                   OrderItem__c,
                   ProducedQuantity__c,
                   DispatchedQuantity__c,
                   ShippedQuantity__c
            FROM ProductionLot__c
            WHERE LotDate__c >= :dateFrom
              AND OrderItem__c != null
              AND (
                   ProducedQuantity__c != null
                OR DispatchedQuantity__c != null
                OR ShippedQuantity__c != null
              )
        ]);
    }

    global void execute(Database.BatchableContext bc, List<ProductionLot__c> productionLots) {
        Map<String, Lot__c> lotsByExtKey = new Map<String, Lot__c>();

        for (ProductionLot__c pl : productionLots) {
            addLotIfValid(lotsByExtKey, pl, pl.ProducedQuantity__c, 'Produced');
            addLotIfValid(lotsByExtKey, pl, pl.DispatchedQuantity__c, 'Shipped');
            addLotIfValid(lotsByExtKey, pl, pl.ShippedQuantity__c, 'Delivered');
        }

        if (!lotsByExtKey.isEmpty()) {
            Database.upsert(
                lotsByExtKey.values(),
                Lot__c.Fields.ExtKey__c,
                false
            );
        }
    }

    private void addLotIfValid(
        Map<String, Lot__c> target,
        ProductionLot__c pl,
        Decimal qty,
        String lotType
    ) {
        if (qty == null || qty == 0) {
            return;
        }

        Lot__c lot = createLot(pl, qty, lotType);

        if (lot == null || String.isBlank(lot.ExtKey__c)) {
            return;
        }

        if (target.containsKey(lot.ExtKey__c)) {
            Lot__c existing = target.get(lot.ExtKey__c);
            existing.LotQty_t__c = (existing.LotQty_t__c == null ? 0 : existing.LotQty_t__c) + lot.LotQty_t__c;

            if (lot.LotDate__c != null && (existing.LotDate__c == null || lot.LotDate__c > existing.LotDate__c)) {
                existing.LotDate__c = lot.LotDate__c;
            }
        } else {
            target.put(lot.ExtKey__c, lot);
        }
    }

    private Lot__c createLot(
        ProductionLot__c pl,
        Decimal qty,
        String lotType
    ) {
        if (pl == null || qty == null || qty == 0) {
            return null;
        }

        if (pl.OrderItem__c == null || pl.LotDate__c == null || String.isBlank(lotType)) {
            return null;
        }

        Id prodWeekId = findProdWeekId(pl.LotDate__c);

        if (prodWeekId == null) {
            return null;
        }

        String extKey = ERPLotKeyUtil.buildExtKey(
            pl.OrderItem__c,
            prodWeekId,
            lotType
        );

        if (String.isBlank(extKey)) {
            return null;
        }

        Lot__c lot = new Lot__c();
        lot.OrderItem__c = pl.OrderItem__c;
        lot.ProdWeek__c = prodWeekId;
        lot.LotDate__c = pl.LotDate__c;
        lot.LotQty_t__c = qty;
        lot.LotType__c = lotType;
        lot.ExtKey__c = extKey;

        return lot;
    }

    private Id findProdWeekId(Date lotDate) {
        if (lotDate == null || prodWeeks == null || prodWeeks.isEmpty()) {
            return null;
        }

        for (ProdWeeksH__c prodWeek : prodWeeks) {
            if (
                prodWeek.DateFrom__c != null &&
                prodWeek.DateTo__c != null &&
                lotDate >= prodWeek.DateFrom__c &&
                lotDate <= prodWeek.DateTo__c
            ) {
                return prodWeek.Id;
            }
        }

        return null;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'ProductionLotToLotBatchEx finished.');
    }
}