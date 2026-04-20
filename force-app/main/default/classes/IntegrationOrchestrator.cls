public with sharing class IntegrationOrchestrator {

    public static IntegrationResponse process(
        String rawJson,
        String fallbackMessageType
    ) {

        IntegrationResponse response = new IntegrationResponse();
        response.timestamp = System.now();

        try {

            // =====================================================
            // 1. Parse envelope
            // =====================================================
            Map<String, Object> untyped =
                (Map<String, Object>) JSON.deserializeUntyped(rawJson);

            Map<String, Object> metaMap =
                (Map<String, Object>) (
                    untyped.containsKey('Metadata')
                        ? untyped.get('Metadata')
                        : untyped.get('metadata')
                );

            if (metaMap == null) {
                return buildError('Orchestrator', 'INVALID_METADATA', null, 400);
            }

            ERPMessageParser.MessageMetadata meta =
                (ERPMessageParser.MessageMetadata)
                    JSON.deserialize(
                        JSON.serialize(metaMap),
                        ERPMessageParser.MessageMetadata.class
                    );

            // =====================================================
            // 2. Resolve messageType
            // =====================================================
            String messageType = !String.isBlank(meta.msgType)
                ? meta.msgType
                : fallbackMessageType;

            if (String.isBlank(messageType)) {
                return buildError('Orchestrator', 'INVALID_MESSAGE_TYPE', null, 400);
            }

            // =====================================================
            // 3. Resolve direction
            // =====================================================
            String direction = resolveDirection(messageType);

            // =====================================================
            // 4. Resolve route (CMDT)
            // =====================================================
            IntegrationMessageRoute__mdt route =
                getRoute(messageType, direction);

            if (route == null || !route.Active__c) {
                return buildError('Orchestrator', 'ROUTE_NOT_FOUND', messageType, 404);
            }

            // =====================================================
            // 5. Build context
            // =====================================================
            IntegrationContext context = new IntegrationContext();
            context.rawJson     = rawJson;
            context.direction   = direction;
            context.messageType = messageType;
            context.handlerKey  = route.HandlerClass__c;

            // =====================================================
            // 6. Instantiate handler
            // =====================================================
            IIntegrationHandler handler =
                instantiateHandler(route.HandlerClass__c);

            if (handler == null) {
                return buildError('Orchestrator', 'HANDLER_NOT_FOUND', route.HandlerClass__c, 500);
            }

            // =====================================================
            // 7. Execute handler
            // =====================================================
            handler.handle(context);

            // =====================================================
            // 8. Handle domain errors
            // =====================================================
            if (context.stopProcessing || context.hasErrors()) {
                return buildError(
                    route.HandlerClass__c,
                    'DOMAIN_ERROR',
                    context.getErrorsAsString(),
                    409
                );
            }

            // =====================================================
            // 9. Handler response
            // =====================================================
            IntegrationHandlerResponse handlerResp = context.getResponse();

            if (handlerResp != null) {

                response.success    = true;
                response.statusCode = handlerResp.httpStatus != null ? handlerResp.httpStatus : 200;
                response.code       = 'SUCCESS';
                response.message    = 'OK';
                response.payload    = JSON.serialize(handlerResp.body);

                // =====================================================
                // ПІДНІМАЄМО status З HANDLER
                // =====================================================
                if (handlerResp.body instanceof Map<String, Object>) {
                    Map<String, Object> bodyMap = (Map<String, Object>) handlerResp.body;

                    if (bodyMap.containsKey('status')) {
                        response.status = (String) bodyMap.get('status');
                    }
                }

                return response;
            }

            // =====================================================
            // 10. Default success
            // =====================================================
            response.success    = true;
            response.statusCode = 200;
            response.code       = 'SUCCESS';
            response.message    = 'OK';

            return response;

        } catch (IntegrationDomainException ex) {

            return buildError(
                ex.handlerName,
                ex.code,
                ex.contextValue,
                409
            );

        } catch (Exception ex) {

            return buildError(
                'Orchestrator',
                'UNEXPECTED_ERROR',
                ex.getMessage(),
                500
            );
        }
    }

    // =========================================================
    // Direction resolver
    // =========================================================
    private static String resolveDirection(String messageType) {

        if (messageType != null && messageType.startsWith('EDI_')) {
            return 'EDI_SF';
        }

        return 'ERP_SF';
    }

    // =========================================================
    // CMDT route resolver
    // =========================================================
    private static IntegrationMessageRoute__mdt getRoute(
        String messageType,
        String direction
    ) {
        List<IntegrationMessageRoute__mdt> routes = [
            SELECT MessageCode__c,
                   Direction__c,
                   HandlerClass__c,
                   Active__c
            FROM IntegrationMessageRoute__mdt
            WHERE MessageCode__c = :messageType
              AND Direction__c   = :direction
            LIMIT 1
        ];

        return routes.isEmpty() ? null : routes[0];
    }

    // =========================================================
    // Dynamic handler instantiation
    // =========================================================
    private static IIntegrationHandler instantiateHandler(String className) {
        try {
            Type t = Type.forName(className);
            return (IIntegrationHandler) t.newInstance();
        } catch (Exception e) {
            return null;
        }
    }

    // =========================================================
    // Error builder
    // =========================================================
    private static IntegrationResponse buildError(
        String handler,
        String code,
        String value,
        Integer httpStatus
    ) {
        IntegrationResponse response = new IntegrationResponse();
        response.success    = false;
        response.statusCode = httpStatus;
        response.code       = code;

        response.message =
            ExceptionMessageProvider.buildByHandler(
                handler,
                code,
                value,
                true
            );

        return response;
    }
}