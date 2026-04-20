public with sharing class EDI_ORDERS05_Handler implements IIntegrationHandler {

    public void handle(IntegrationContext context) {

        System.debug('=== EDI_ORDERS05_Handler START ===');

        try {
            // =====================================================
            // 1. Parse envelope
            // =====================================================
            Map<String, Object> envelope =
                (Map<String, Object>) JSON.deserializeUntyped(context.rawJson);

            Map<String, Object> payload =
                (Map<String, Object>) envelope.get('Payload');

            if (payload == null) {
                context.addError('Payload is null');
                context.stopProcessing = true;
                return;
            }

            // =====================================================
            // 2. Deserialize DTO
            // =====================================================
            OrderInboundDTO dto =
                (OrderInboundDTO) JSON.deserialize(
                    JSON.serialize(payload),
                    OrderInboundDTO.class
                );

            if (dto == null) {
                context.addError('Failed to deserialize OrderInboundDTO');
                context.stopProcessing = true;
                return;
            }

            System.debug('Order: ' + dto.externalOrderNumber);

            // =====================================================
            // 3. Process items
            // =====================================================
            List<Map<String, Object>> resultItems = new List<Map<String, Object>>();

            Boolean hasErrors = false;
            Boolean hasSuccess = false;
            Boolean hasFallback = false; // Статус fallback

            for (OrderInboundDTO.Item item : dto.items) {

                String matchedBy = null;
                Boolean success = false;
                String message;

                // -------------------------------
                // PRIMARY: ExtKey
                // -------------------------------
                if (!String.isBlank(item.externalItemKey)) {
                    matchedBy = 'EXT_KEY';
                    success = true;
                    message = 'Matched by ExtKey (mock)';
                }

                // -------------------------------
                // FALLBACK: POSEX
                // -------------------------------
                else if (!String.isBlank(item.sapItemNumber)) {
                    matchedBy = 'POSEX';
                    success = true;
                    message = 'Matched by POSEX (fallback mock)';
                    hasFallback = true; // КЛЮЧОВЕ
                }

                // -------------------------------
                // NO MATCH
                // -------------------------------
                else {
                    success = false;
                    message = 'No identifiers provided';
                    hasErrors = true;

                    context.addError(
                        'Item error: no ExtKey and no POSEX'
                    );
                }

                // tracking
                if (success) {
                    hasSuccess = true;
                } else {
                    hasErrors = true;
                }

                // result
                resultItems.add(new Map<String, Object>{
                    'externalItemKey' => item.externalItemKey,
                    'sapItemNumber' => item.sapItemNumber,
                    'matchedBy' => matchedBy,
                    'success' => success,
                    'message' => message
                });
            }

            // =====================================================
            // 4. Resolve status
            // =====================================================
            Integer httpStatus;
            String statusText;

            if (hasErrors) {
                httpStatus = hasSuccess ? 207 : 400;
                statusText = hasSuccess ? 'PARTIAL_SUCCESS' : 'ERROR';
            }
            else if (hasFallback) {
                httpStatus = 207;
                statusText = 'PARTIAL_SUCCESS';
            }
            else {
                httpStatus = 200;
                statusText = 'SUCCESS';
            }

            // =====================================================
            // 5. Build response body
            // =====================================================
            Map<String, Object> body = new Map<String, Object>{
                'externalOrderNumber' => dto.externalOrderNumber,
                'items' => resultItems,
                'status' => statusText
            };

            // =====================================================
            // 6. Build response
            // =====================================================
            IntegrationHandlerResponse resp =
                new IntegrationHandlerResponse(
                    httpStatus,
                    body,
                    JSON.serialize(body)
                );

            context.setResponse(resp);

            System.debug('=== EDI_ORDERS05_Handler END ===');

        } catch (Exception ex) {
            context.addError('Handler exception: ' + ex.getMessage());
            context.stopProcessing = true;
        }
    }
}