public class OrderItemResolutionResult extends ResolutionResult {

    public final OrderItem entity;
    public final String ite;

    private OrderItemResolutionResult(
        Boolean found,
        OrderItem entity,
        String ite,
        String reason
    ) {
        super(found, reason);
        this.entity = entity;
        this.ite = ite;
    }

    public static OrderItemResolutionResult found(OrderItem oi, String ite) {
        return new OrderItemResolutionResult(true, oi, ite, null);
    }

    public static OrderItemResolutionResult notFound(String ite) {
        return new OrderItemResolutionResult(false, null, ite, 'NOT_FOUND');
    }
}