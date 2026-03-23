public with sharing class OrderItemResolver {

    private final OrderItemLookup lookup;

    public OrderItemResolver(OrderItemLookup lookup) {
        this.lookup = lookup;
    }

    public OrderItemResolutionResult resolveByIte(String ite) {

        if (String.isBlank(ite)) {
            return OrderItemResolutionResult.notFound(ite);
        }

        OrderItem oi = lookup.findEntityByIte(ite);

        if (oi != null) {
            return OrderItemResolutionResult.found(oi, ite);
        }

        return OrderItemResolutionResult.notFound(ite);
    }

    public Map<String, OrderItemResolutionResult> resolveMany(Set<String> ites) {

        Map<String, OrderItemResolutionResult> result = new Map<String, OrderItemResolutionResult>();

        if (ites == null || ites.isEmpty()) {
            return result;
        }

        Map<String, OrderItem> foundMap = lookup.findEntitiesByItes(ites);

        for (String ite : ites) {
            OrderItem oi = foundMap.get(ite);

            if (oi != null) {
                result.put(ite, OrderItemResolutionResult.found(oi, ite));
            } else {
                result.put(ite, OrderItemResolutionResult.notFound(ite));
            }
        }

        return result;
    }
}