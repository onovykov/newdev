public with sharing class IntegrationOrchestrator {

    public static IntegrationResponse process(
        String rawJson,
        String sourceSystem
    ) {

        IntegrationResponse response = new IntegrationResponse();
        response.timestamp = System.now();

        IIntegrationHandler handler; // 🔥 оголошено тут

        try {

            // 1️. Parse metadata
            Map<String, Object> untyped =
                (Map<String, Object>) JSON.deserializeUntyped(rawJson);

            Map<String, Object> metaMap =
                (Map<String, Object>) untyped.get('metadata');

            if (metaMap == null) {
                return buildError(
                    'Orchestrator',
                    'INVALID_METADATA',
                    null,
                    400
                );
            }

            ERPMessageParser.MessageMetadata meta =
                (ERPMessageParser.MessageMetadata)
                    JSON.deserialize(
                        JSON.serialize(metaMap),
                        ERPMessageParser.MessageMetadata.class
                    );

            if (String.isBlank(meta.msgType)) {
                return buildError(
                    'Orchestrator',
                    'INVALID_MESSAGE_TYPE',
                    null,
                    400
                );
            }

            // 2️. Resolve route
            IntegrationMessageRoute__mdt route =
                getRoute(meta.msgType, 'IN');

            if (route == null || !route.Active__c) {
                return buildError(
                    'Orchestrator',
                    'ROUTE_NOT_FOUND',
                    meta.msgType,
                    404
                );
            }

            // 3️. Build context
            IntegrationContext context = new IntegrationContext();
            context.rawJson     = rawJson;
            context.direction   = 'ERP_SF';
            context.messageType = meta.msgType;
            context.handlerKey  = route.HandlerClass__c;

            // 4️. Instantiate handler
            handler = instantiateHandler(route.HandlerClass__c);

            if (handler == null) {
                return buildError(
                    'Orchestrator',
                    'HANDLER_NOT_FOUND',
                    route.HandlerClass__c,
                    500
                );
            }

            // 5️. Execute
            handler.handle(context);

            if (context.hasErrors()) {
                return buildError(
                    route.HandlerClass__c,
                    'DOMAIN_ERROR',
                    context.getErrorsAsString(),
                    409
                );
            }

            // 6️. Success
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

    // =========================
    // Error builder
    // =========================
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

    // =========================
    // Helpers
    // =========================
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

    private static IIntegrationHandler instantiateHandler(
        String className
    ) {
        try {
            Type t = Type.forName(className);
            return (IIntegrationHandler) t.newInstance();
        } catch (Exception e) {
            return null;
        }
    }
}