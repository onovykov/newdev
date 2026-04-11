public with sharing class XmlInboundAdapter {

    public static IntegrationResponse process(String xml) {

        try {

            String messageType = detectMessageType(xml);

            if (messageType == 'EDI_ORDERS05') {

                // 1. Parse
                EDI_ORDERS05_DTO transportDto =
                    EDI_ORDERS05_Parser.parse(xml);

                // 2. Map
                OrderInboundDTO canonicalDto =
                    EDI_ORDERS05_Mapper.mapToCanonical(transportDto);

                // 3. Handle
                OrderInboundHandler.Result handlerResult =
                    OrderInboundHandler.handle(canonicalDto);

                // 4. Build response
                return buildResponse(handlerResult);
            }

            throw new IntegrationDomainException(
                'XmlInboundAdapter',
                'UNKNOWN_XML_TYPE',
                messageType
            );

        } catch (Exception ex) {

            IntegrationResponse error = new IntegrationResponse();
            error.status = 'ERROR';
            error.message = ex.getMessage();
            error.statusCode = 500;
            error.timestamp = System.now();

            return error;
        }
    }

    // =========================================================
    // MESSAGE TYPE DETECTION
    // =========================================================
    private static String detectMessageType(String xml) {

        if (xml.contains('<ORDERS05')) return 'EDI_ORDERS05';
        if (xml.contains('<DESADV')) return 'EDI_DESADV';

        return 'UNKNOWN';
    }

    // =========================================================
    // RESPONSE BUILDER
    // =========================================================
    private static IntegrationResponse buildResponse(OrderInboundHandler.Result r) {

        IntegrationResponse resp = new IntegrationResponse();

        resp.timestamp = System.now();
        resp.status = r.status;
        resp.statusCode = 200;

        // legacy compatibility
        resp.success = (r.status == 'FULL_SUCCESS');

        // correlation (optional but recommended)
        resp.correlationId = String.valueOf(Crypto.getRandomLong());

        String warningsText = (r.warnings != null && !r.warnings.isEmpty())
            ? String.join(r.warnings, '; ')
            : '';

        String errorsText = (r.errors != null && !r.errors.isEmpty())
            ? String.join(r.errors, '; ')
            : '';

        if (r.status == 'FULL_SUCCESS') {
            resp.message = 'Full Success';
        }
        else if (r.status == 'PARTIAL_SUCCESS') {
            resp.message = 'Partial success' +
                (warningsText != '' ? ': ' + warningsText : '');
        }
        else {
            resp.message = 'Error' +
                (errorsText != '' ? ': ' + errorsText : '');
        }

        resp.data = r;

        // bridge old ↔ new
        IntegrationResponse.syncPayload(resp);

        return resp;
    }
}
