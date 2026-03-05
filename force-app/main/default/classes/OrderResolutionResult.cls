public class OrderResolutionResult extends ResolutionResult {

    public Order order;

    private OrderResolutionResult(
        Boolean found,
        Order order,
        String reason
    ) {
        super(found, reason);
        this.order = order;
    }

    public static OrderResolutionResult found(Order ord) {
        return new OrderResolutionResult(true, ord, null);
    }

    public static OrderResolutionResult notFound(String reason) {
        return new OrderResolutionResult(false, null, reason);
    }
}