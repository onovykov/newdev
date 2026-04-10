@RestResource(urlMapping='/ERPtoSF/v1/*')
global with sharing class ERPtoSF {

    @HttpPost
    global static void postCST() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String rawJson = req.requestBody.toString();
        String messageType = resolveMessageType(rawJson);

        try {

            // =====================================================
            // 1. GLOBAL SWITCH (UseOld__c)
            // =====================================================
            if (useOldPipeline()) {
                ERPMessageHandler.postCSTfromHelper(req, res);
                return;
            }

            // =====================================================
            // 2. RESOLVE ROUTE
            // =====================================================
            IntegrationMessageRoute__mdt route =
                resolveRoute(messageType);

            if (route == null || !route.Active__c) {
                ERPMessageHandler.postCSTfromHelper(req, res);
                return;
            }

            // =====================================================
            // 3. PROCESSING MODE (via IsAsync__c)
            // =====================================================
            if (route.IsAsync__c == true) {

                // ASYNC FLOW
                handleAsync(rawJson, res);
                return;

            } else {

                // SYNC FLOW
                handleSync(rawJson, res);
                return;
            }

        } catch (Exception e) {

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                '{"status":"ERROR","message":"' +
                escapeJson(e.getMessage()) +
                '"}'
            );
        }
    }

    // =========================================================
    // SYNC FLOW
    // =========================================================
    private static void handleSync(String rawJson, RestResponse res) {

        IntegrationResponse r =
            IntegrationOrchestrator.process(
                rawJson,
                IntegrationDirection.ERP_SF
            );

        res.statusCode = r.statusCode;

        if (r.payload != null) {
            res.responseBody = Blob.valueOf(r.payload);
        } else {
            res.responseBody = Blob.valueOf(
                '{"status":"' + r.code +
                '","message":"' + escapeJson(r.message) + '"}'
            );
        }
    }

    // =========================================================
    // ASYNC FLOW
    // =========================================================
    private static void handleAsync(String rawJson, RestResponse res) {

        InboundBatchCoordinator.Result r =
            InboundBatchCoordinator.acceptPart(rawJson);

        res.statusCode = r.httpStatus;
        res.responseBody = Blob.valueOf(r.responseBody);
    }

    // =========================================================
    // GLOBAL SWITCH
    // =========================================================
    private static Boolean useOldPipeline() {

        ERPtoSF_Switcher__mdt cfg =
            ERPtoSF_Switcher__mdt.getInstance('Default');

        return (cfg == null || cfg.UseOld__c == true);
    }

    // =========================================================
    // ROUTE RESOLVER
    // =========================================================
    private static IntegrationMessageRoute__mdt resolveRoute(
        String messageType
    ) {

        if (String.isBlank(messageType)) return null;

        List<IntegrationMessageRoute__mdt> routes = [
            SELECT MessageCode__c,
                   Direction__c,
                   HandlerClass__c,
                   Active__c,
                   IsAsync__c
            FROM IntegrationMessageRoute__mdt
            WHERE MessageCode__c = :messageType
              AND Direction__c   = :IntegrationDirection.ERP_SF
            LIMIT 1
        ];

        return routes.isEmpty() ? null : routes[0];
    }

    // =========================================================
    // METADATA PARSER
    // =========================================================
    private static String resolveMessageType(String rawJson) {

        try {
            Map<String,Object> root =
                (Map<String,Object>) JSON.deserializeUntyped(rawJson);

            Map<String,Object> meta =
                (Map<String,Object>) root.get('metadata');

            return (String) meta.get('msgType');

        } catch (Exception e) {
            return null;
        }
    }

    // =========================================================
    // JSON SAFE
    // =========================================================
    private static String escapeJson(String s) {
        if (s == null) return '';
        return s
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\r', '\\r')
            .replace('\n', '\\n');
    }
}