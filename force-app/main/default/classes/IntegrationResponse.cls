public class IntegrationResponse {

    // =========================================
    // CORE
    // =========================================

    public Boolean success;
    public String status;

    public Integer statusCode;
    public String code;
    public String message;

    public Datetime timestamp;
    public String correlationId;

    // =========================================
    // NEW MODEL
    // =========================================

    public Object data;

    public List<IntegrationMessage> errors;
    public List<IntegrationMessage> warnings;

    public Map<String, Object> meta;

    // =========================================
    // LEGACY (ВАЖЛИВО)
    // =========================================

    public String payload;

    // =========================================
    // INNER CLASS
    // =========================================

    public class IntegrationMessage {
        public String code;
        public String message;
        public String field;
        public String details;
    }

    // =========================================================
    // STATIC HELPERS
    // =========================================================    
    public static void syncPayload(IntegrationResponse resp) {
        if (resp != null && resp.data != null) {
            resp.payload = JSON.serialize(resp.data);
        }
    }

    private static IntegrationResponse buildResponse(OrderInboundHandler.Result r) {
        
        IntegrationResponse resp = new IntegrationResponse();

        resp.status = r.status;
        resp.success = (r.status == 'FULL_SUCCESS');
        resp.statusCode = 200;

        resp.data = r;

        IntegrationResponse.syncPayload(resp);

        return resp;
    }    
}