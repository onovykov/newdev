public abstract class IntegrationResolution {

    public Boolean found { get; protected set; }
    public String  reason { get; protected set; }

    protected IntegrationResolution(Boolean found, String reason) {
        this.found  = found;
        this.reason = reason;
    }
}