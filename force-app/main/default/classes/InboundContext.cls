public class InboundContext {
    public String correlationId;
    public String rawPayload;
    public String sourceSystem;

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