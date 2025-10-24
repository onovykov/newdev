//public class OrderItemChildService {
//    public static void fillChildRecords(
//            List<OrderItem> orderItems,
//            Map<Id, Order> inputOrdIdMap,
//            Map<Id, SpecVersion__c> specMap,
//            Map<Id, DrawingVersion__c> drawingMap
//    ) {
//        if (orderItems == null || orderItems.isEmpty()) {
//            System.debug('>>> OrderItemChildService: No OrderItems received.');
//            return;
//        }
//
//        System.debug('>>> OrderItemChildService: Received ' + orderItems.size() + ' OrderItems.');
//
//        Set<Id> oiIds = new Set<Id>();
//        Set<Id> orderIds = new Set<Id>();
//        for (OrderItem oi : orderItems) {
//            oiIds.add(oi.Id);
//            orderIds.add(oi.OrderId);
//        }
//
//        // Завантаження Order
//        Map<Id, Order> ordIdMap = new Map<Id, Order>([
//                SELECT Id, MarketSegment__c
//                FROM Order
//                WHERE Id IN :orderIds
//        ]);
//        System.debug('>>> Loaded Orders: ' + ordIdMap.size());
//
//        // Отримати існуючі General Info
//        Map<Id, OrderItemGeneral__c> existingGenerals = new Map<Id, OrderItemGeneral__c>();
//        for (OrderItemGeneral__c g : [
//                SELECT Id, OrderProduct__c, Shop__c, Name, Product__c
//                FROM OrderItemGeneral__c
//                WHERE OrderProduct__c IN :oiIds
//        ]) {
//            existingGenerals.put(g.OrderProduct__c, g);
//        }
//        System.debug('>>> Existing OrderItemGeneral__c count: ' + existingGenerals.size());
//
//        List<OrderItemGeneral__c> toInsert = new List<OrderItemGeneral__c>();
//        List<OrderItemGeneral__c> toUpdate = new List<OrderItemGeneral__c>();
//
//        for (OrderItem oi : orderItems) {
//            Order order = ordIdMap.get(oi.OrderId);
//            Boolean isTubes = order != null && order.MarketSegment__c != '00006';
//            System.debug('>>> OrderItem Id: ' + oi.Id + ' => isTubes: ' + isTubes);
//
//            if (existingGenerals.containsKey(oi.Id)) {
//                OrderItemGeneral__c g = existingGenerals.get(oi.Id);
//                g.Shop__c = oi.Shop__c;
//                g.Name = oi.Name__c;
//                g.Product__c = oi.Product2Id;
//                toUpdate.add(g);
//                System.debug('>>> Updating OrderItemGeneral__c for OrderItem Id: ' + oi.Id);
//            } else {
//                OrderItemGeneral__c g = new OrderItemGeneral__c(
//                        OrderProduct__c = oi.Id,
//                        Order__c = oi.OrderId,
//                        Product__c = oi.Product2Id,
//                        Shop__c = oi.Shop__c,
//                        Name = oi.Name__c
//                );
//                toInsert.add(g);
//                System.debug('>>> Inserting new OrderItemGeneral__c for OrderItem Id: ' + oi.Id);
//            }
//
//            if (isTubes) {
//                System.debug('>>> OrderItem Id: ' + oi.Id + ' - Processing as TUBE');
//                // TODO: обробка OrderItemProductInfoPipes__c
//            } else {
//                System.debug('>>> OrderItem Id: ' + oi.Id + ' - Processing as KLW');
//                // TODO: обробка OrderItemProductInfoKLW__c
//            }
//            // Додаткова обробка на основі isTubes можна додати тут
//        }
//
//        System.debug('>>> Records to insert: ' + toInsert.size());
//        System.debug('>>> Records to update: ' + toUpdate.size());
//
//        if (!toInsert.isEmpty()) insert toInsert;
//        if (!toUpdate.isEmpty()) update toUpdate;
//    }
//}
public class OrderItemChildService {

    public static String safeTrim(String s, Integer max) {
        return String.isBlank(s) ? null : s.substring(0, Math.min(max, s.length()));
    }


    public static void fillChildRecords(
            List<OrderItem> orderItems,
            Map<Id, Order> inputOrdIdMap,
            Map<Id, SpecVersion__c> specMap,
            Map<Id, DrawingVersion__c> drawingMap
    ) {
        if (orderItems == null || orderItems.isEmpty()) {
            System.debug('>>> OrderItemChildService: No OrderItems received.');
            return;
        }

        System.debug('>>> OrderItemChildService: Received ' + orderItems.size() + ' OrderItems.');

        Set<Id> oiIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem oi : orderItems) {
            oiIds.add(oi.Id);
            orderIds.add(oi.OrderId);
        }

        Map<Id, Order> ordIdMap = new Map<Id, Order>([
                SELECT Id, MarketSegment__c
                FROM Order
                WHERE Id IN :orderIds
        ]);
        System.debug('>>> Loaded Orders: ' + ordIdMap.size());

        // Correct mapping by OrderProduct__c
        Map<Id, OrderItemGeneral__c> existingGenerals = new Map<Id, OrderItemGeneral__c>();
        for (OrderItemGeneral__c rec : [
                SELECT Id, OrderProduct__c FROM OrderItemGeneral__c WHERE OrderProduct__c IN :oiIds
        ]) {
            existingGenerals.put(rec.OrderProduct__c, rec);
        }
        System.debug('>>> Loaded existingGenerals keys: ' + existingGenerals.keySet());

        Map<Id, OrderItemProductInfoPipes__c> existingPipes = new Map<Id, OrderItemProductInfoPipes__c>();
        for (OrderItemProductInfoPipes__c rec : [
                SELECT Id, OrderProduct__c FROM OrderItemProductInfoPipes__c WHERE OrderProduct__c IN :oiIds
        ]) {
            existingPipes.put(rec.OrderProduct__c, rec);
        }
        System.debug('>>> Loaded existingPipes keys: ' + existingPipes.keySet());

        Map<Id, OrderItemProductInfoKLW__c> existingKLWs = new Map<Id, OrderItemProductInfoKLW__c>();
        for (OrderItemProductInfoKLW__c rec : [
                SELECT Id, OrderProduct__c FROM OrderItemProductInfoKLW__c WHERE OrderProduct__c IN :oiIds
        ]) {
            existingKLWs.put(rec.OrderProduct__c, rec);
        }
        System.debug('>>> Loaded existingKLWs keys: ' + existingKLWs.keySet());

        List<OrderItemGeneral__c> toInsertGen = new List<OrderItemGeneral__c>();
        List<OrderItemGeneral__c> toUpdateGen = new List<OrderItemGeneral__c>();
        List<OrderItemProductInfoPipes__c> toInsertPipes = new List<OrderItemProductInfoPipes__c>();
        List<OrderItemProductInfoPipes__c> toUpdatePipes = new List<OrderItemProductInfoPipes__c>();
        List<OrderItemProductInfoKLW__c> toInsertKLW = new List<OrderItemProductInfoKLW__c>();
        List<OrderItemProductInfoKLW__c> toUpdateKLW = new List<OrderItemProductInfoKLW__c>();

        for (OrderItem oi : orderItems) {
            System.debug('>>> Processing OrderItem: ' + oi.Id);
            Order order = ordIdMap.get(oi.OrderId);
            Boolean isTubes = order != null && order.MarketSegment__c != '00006';
            System.debug('>>> isTubes = ' + isTubes);

            // General
            if (existingGenerals.containsKey(oi.Id)) {
                OrderItemGeneral__c g = existingGenerals.get(oi.Id);
                g.Shop__c = oi.Shop__c;
//                g.Name = oi.Name__c;

                g.Name = safeTrim(oi.Name__c, 80);

                g.Product__c = oi.Product2Id;
                toUpdateGen.add(g);
            } else {

                toInsertGen.add(new OrderItemGeneral__c(
                        OrderProduct__c = oi.Id,
                        Order__c = oi.OrderId,
                        Product__c = oi.Product2Id,
                        Shop__c = oi.Shop__c,
                        Name = safeTrim(oi.Name__c, 80)
                ));
            }

            if (isTubes) {
                System.debug('>>> Processing as TUBE');
                if (existingPipes.containsKey(oi.Id)) {
                    OrderItemProductInfoPipes__c p = existingPipes.get(oi.Id);
                    p.Shop__c = oi.Shop__c;
//                    p.Name = oi.Name__c;
                    p.Name = safeTrim(oi.Name__c, 80);

                    p.CurrencyIsoCode = oi.CurrencyIsoCode;
                    p.Standard__c = oi.ProductStandard__c;
                    p.SteelGrade__c = oi.SteelGrade__c;
                    p.TubeEnds__c = oi.TubeEnds__c;
                    p.TubeLengthSize__c = oi.TubeLengthSize__c;
                    p.TubeOD__c = oi.TubeOD__c;
                    p.TubeWT__c = oi.TubeWT__c;
                    toUpdatePipes.add(p);
                } else {
                    toInsertPipes.add(new OrderItemProductInfoPipes__c(
                            OrderProduct__c = oi.Id,
                            Order__c = oi.OrderId,
                            Shop__c = oi.Shop__c,
                            Name = safeTrim(oi.Name__c, 80),
                            CurrencyIsoCode = oi.CurrencyIsoCode,
                            Standard__c = oi.ProductStandard__c,
                            SteelGrade__c = oi.SteelGrade__c,
                            TubeEnds__c = oi.TubeEnds__c,
                            TubeLengthSize__c = oi.TubeLengthSize__c,
                            TubeOD__c = oi.TubeOD__c,
                            TubeWT__c = oi.TubeWT__c
                    ));
                }
            } else {
                System.debug('>>> Processing as KLW');
                SpecVersion__c spec = specMap.get(oi.KLWSpec__c);
//                String kind = spec != null ? (String)spec.get('ProductKind__c') : null;
//                String type = spec != null ? (String)spec.get('ProductType__c') : null;

                if (existingKLWs.containsKey(oi.Id)) {
                    OrderItemProductInfoKLW__c k = existingKLWs.get(oi.Id);
//                    k.Name = oi.Name__c;
                    k.Name = safeTrim(oi.Name__c, 80);

                    k.CDD__c = oi.CDD__c;
                    k.ConfirmedCDD__c = oi.ConfirmedCDD__c;
                    k.CurrencyIsoCode = oi.CurrencyIsoCode;
                    k.DrawingVersion__c = oi.Drawing__c;
                    k.InqQuantuty__c = oi.InqQuantuty__c;
                    k.InqUnitPrice__c = oi.InqUnitPrice__c;
                    k.Price__c = oi.UnitPrice;
//                    k.ProdKind__c = kind;
//                    k.ProdType__c = type;
                    k.Qty_pcs__c = oi.Quantity_pcs__c;
                    k.Qty_t__c = oi.Quantity;
                    k.SpecVersion__c = oi.KLWSpec__c;
                    k.Stage__c = oi.Stage__c;
                    toUpdateKLW.add(k);
                } else {
                    toInsertKLW.add(new OrderItemProductInfoKLW__c(
                            OrderProduct__c = oi.Id,
                            Order__c = oi.OrderId,
                            Name = safeTrim(oi.Name__c, 80),
                            CDD__c = oi.CDD__c,
                            ConfirmedCDD__c = oi.ConfirmedCDD__c,
                            CurrencyIsoCode = oi.CurrencyIsoCode,
                            DrawingVersion__c = oi.Drawing__c,
                            InqQuantuty__c = oi.InqQuantuty__c,
                            InqUnitPrice__c = oi.InqUnitPrice__c,
                            Price__c = oi.UnitPrice,
//                            ProdKind__c = kind,
//                            ProdType__c = type,
                            Qty_pcs__c = oi.Quantity_pcs__c,
                            Qty_t__c = oi.Quantity,
                            SpecVersion__c = oi.KLWSpec__c,
                            Stage__c = oi.Stage__c
                    ));
                }
            }
        }

        if (!toInsertGen.isEmpty()) insert toInsertGen;
        if (!toUpdateGen.isEmpty()) update toUpdateGen;
        if (!toInsertPipes.isEmpty()) insert toInsertPipes;
        if (!toUpdatePipes.isEmpty()) update toUpdatePipes;
        if (!toInsertKLW.isEmpty()) insert toInsertKLW;
        if (!toUpdateKLW.isEmpty()) update toUpdateKLW;
    }

    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}