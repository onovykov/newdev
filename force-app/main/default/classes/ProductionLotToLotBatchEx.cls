global class ProductionLotToLotBatchEx implements Database.Batchable<SObject>, Database.Stateful {

    private Date DateFrom;
    List<ProdWeeksH__c> ProdWeeks;

    // Конструктор із параметром дати
    global ProductionLotToLotBatchEx(Date dateFrom) {
        this.DateFrom = dateFrom;
        this.ProdWeeks = [SELECT Id, DateFrom__c, DateTo__c FROM ProdWeeksH__c];
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, LotDate__c, ITENumber__c, Order__c, OrderItem__c,
                   ProducedQuantity__c, DispatchedQuantity__c, ShippedQuantity__c
            FROM ProductionLot__c
            WHERE (ProducedQuantity__c != null OR DispatchedQuantity__c != null OR ShippedQuantity__c != null)
              AND LotDate__c >= :DateFrom
        ]);
    }

    global void execute(Database.BatchableContext bc, List<ProductionLot__c> productionLots) {
        List<Lot__c> lotsToInsert = new List<Lot__c>();

        for (ProductionLot__c pl : productionLots) {
            if (pl.ProducedQuantity__c != null && pl.ProducedQuantity__c != 0) {
                lotsToInsert.add(createLot(pl, pl.ProducedQuantity__c, 'Produced'));
            }
            if (pl.DispatchedQuantity__c != null && pl.DispatchedQuantity__c != 0) {
                lotsToInsert.add(createLot(pl, pl.DispatchedQuantity__c, 'Shipped'));
            }
            if (pl.ShippedQuantity__c != null && pl.ShippedQuantity__c != 0) {
                lotsToInsert.add(createLot(pl, pl.ShippedQuantity__c, 'Delivered'));
            }
        }

        if (!lotsToInsert.isEmpty()) {
            insert lotsToInsert;
        }
    }

    private Lot__c createLot(ProductionLot__c pl, Decimal qty, String lotType) {
        Lot__c lot = new Lot__c();
        lot.ITENumber__c = pl.ITENumber__c;
        lot.Order__c = pl.Order__c;
        lot.OrderItem__c = pl.OrderItem__c;
        lot.LotDate__c = pl.LotDate__c;
        lot.LotQty_t__c = qty;
        lot.LotType__c = lotType;
        lot.Name = pl.ITENumber__c + ' ' + String.valueOf(Date.today()) + ' ' + lotType;

        for(ProdWeeksH__c prodWeek : ProdWeeks) {
            if (pl.LotDate__c >= prodWeek.DateFrom__c && pl.LotDate__c <= prodWeek.DateTo__c) {
                lot.ProdWeek__c = prodWeek.Id;
                break;
            } 
        }

        return lot;
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: логування, email тощо
    }
}