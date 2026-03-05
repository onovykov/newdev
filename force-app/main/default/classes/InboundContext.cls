public class InboundContext {

    // -------- transport --------
    public String correlationId;
    public String rawPayload;
    public String sourceSystem;

    // -------- execution --------
    public ERPMessageParser.MessageMetadata metadata;
    public IntegrationMessageRoute__mdt route;
    public Datetime startedAt;

    // -------- optional --------
    public Map<String, Object> attributes = new Map<String, Object>();

    public InboundContext(
        String correlationId,
        String rawPayload,
        String sourceSystem
    ) {
        this.correlationId = correlationId;
        this.rawPayload = rawPayload;
        this.sourceSystem = sourceSystem;
    }
}