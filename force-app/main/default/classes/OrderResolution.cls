// OrderResolution.cls
public class OrderResolution extends IntegrationResolution {

    public Order order { get; private set; }

    private OrderResolution(Boolean found, Order ord, String reason) {
        super(found, reason);
        this.order = ord;
    }

    public static OrderResolution found(Order ord) {
        return new OrderResolution(true, ord, null);
    }

    public static OrderResolution notFound(String reason) {
        return new OrderResolution(false, null, reason);
    }
}