public with sharing class IntegrationResponseBuilder {

    // =========================================
    // FULL SUCCESS
    // =========================================
    public static IntegrationResponse fullSuccess(Object data) {

        IntegrationResponse r = baseResponse();

        r.status = 'FULL_SUCCESS';
        r.success = true;
        r.statusCode = 200;
        r.message = 'Full Success';
        r.data = data;

        finalizeResponse(r);

        return r;
    }

    // =========================================
    // PARTIAL SUCCESS
    // =========================================
    public static IntegrationResponse partialSuccess(
        Object data,
        List<String> warnings
    ) {

        IntegrationResponse r = baseResponse();

        r.status = 'PARTIAL_SUCCESS';
        r.success = false;
        r.statusCode = 200;
        r.data = data;

        r.warnings = toMessages(warnings, 'WARNING');

        if (warnings != null && !warnings.isEmpty()) {
            r.message = 'Partial success: ' + String.join(warnings, '; ');
        } else {
            r.message = 'Partial success';
        }

        finalizeResponse(r);

        return r;
    }

    // =========================================
    // ERROR
    // =========================================
    public static IntegrationResponse error(
        String code,
        String message
    ) {

        IntegrationResponse r = baseResponse();

        r.status = 'ERROR';
        r.success = false;
        r.statusCode = 500;
        r.code = code;
        r.message = message;

        r.errors = new List<IntegrationResponse.IntegrationMessage>();

        IntegrationResponse.IntegrationMessage msg =
            new IntegrationResponse.IntegrationMessage();

        msg.code = code;
        msg.message = message;

        r.errors.add(msg);

        finalizeResponse(r);

        return r;
    }

    // =========================================
    // BASE RESPONSE
    // =========================================
    private static IntegrationResponse baseResponse() {

        IntegrationResponse r = new IntegrationResponse();

        r.timestamp = System.now();
        r.correlationId = generateCorrelationId();

        return r;
    }

    // =========================================
    // FINALIZE (bridge data → payload)
    // =========================================
    private static void finalizeResponse(IntegrationResponse r) {

        IntegrationResponse.syncPayload(r);
    }

    // =========================================
    // HELPERS
    // =========================================
    private static List<IntegrationResponse.IntegrationMessage> toMessages(
        List<String> listValues,
        String type
    ) {

        List<IntegrationResponse.IntegrationMessage> res =
            new List<IntegrationResponse.IntegrationMessage>();

        if (listValues == null) return res;

        for (String s : listValues) {

            IntegrationResponse.IntegrationMessage msg =
                new IntegrationResponse.IntegrationMessage();

            msg.code = type;
            msg.message = s;

            res.add(msg);
        }

        return res;
    }

    private static String generateCorrelationId() {
        return String.valueOf(Crypto.getRandomLong());
    }
}