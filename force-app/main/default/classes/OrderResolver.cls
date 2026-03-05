public class OrderResolver {
    @TestVisible
    static OrderLookup lookup = new OrderLookupImpl();

    public static OrderResolutionResult resolve(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        if (msg == null || msg.data == null || msg.data.header == null) {
            return OrderResolutionResult.notFound(
                ExceptionMessageProvider.getByDeveloperName('HEADER_MISSING')
            );
        }

        String ite   = msg.data.header.iteNumber;
        String erpId = String.valueOf(msg.data.header.unDoc);

        // 1️. ITE first
        if (String.isNotBlank(ite)) {
            OrderResolutionResult res = resolveByIte(ite);
            if (res.found) {
                return res;
            }
        }

        // 2️. ERP fallback
        if (String.isNotBlank(erpId)) {
            return resolveByErpId(erpId);
        }

        return OrderResolutionResult.notFound(
            ExceptionMessageProvider.getByDeveloperName('MSG_BODY_EMPTY')
        );
    }

    private static OrderResolutionResult resolveByIte(String ite) {

        //Id orderId = OrderCache.getOneByIte(ite);
        Id orderId = lookup.findByIte(ite);

        if (orderId == null) {
            return OrderResolutionResult.notFound(
                ExceptionMessageProvider.buildByDeveloperName(
                    'NOT_FOUND_ORDER_ITE',
                    ite
                )
            );
        }

        return loadOrder(orderId);
    }

    private static OrderResolutionResult resolveByErpId(String erpId) {

        //Id orderId = OrderCache.getOneByErpId(erpId);
        Id orderId = lookup.findByIte(erpId);

        if (orderId == null) {
            return OrderResolutionResult.notFound(
                ExceptionMessageProvider.buildByDeveloperName(
                    'NOT_FOUND_ORDER_ERP',
                    erpId
                )
            );
        }

        return loadOrder(orderId);
    }

    private static OrderResolutionResult loadOrder(Id orderId) {

        Order ord = [
            SELECT Id, Status, AccountId, EffectiveDate
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        return OrderResolutionResult.found(ord);
    }
}