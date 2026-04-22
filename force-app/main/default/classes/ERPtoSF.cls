@RestResource(urlMapping='/ERPtoSF/v1/*')
global with sharing class ERPtoSF {

    @HttpPost
    global static void postCST() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String rawJson = req.requestBody.toString();
        String messageType = resolveMessageType(rawJson);

        // DEBUG 1
        System.debug('=== ERPtoSF DEBUG START ===');
        System.debug('messageType=' + messageType);

        try {

            // =====================================================
            // 1. RESOLVE ROUTE
            // =====================================================
            IntegrationMessageRoute__mdt route =
                resolveRoute(messageType);

            // DEBUG 2
            System.debug('route=' + route);
            System.debug('IsNewPath=' + (route != null ? route.IsNewPath__c : null));
            System.debug('IsAsync=' + (route != null ? route.IsAsync__c : null));
            System.debug('Active=' + (route != null ? route.Active__c : null));

            // -----------------------------------------------------
            // FALLBACK → OLD FLOW
            // -----------------------------------------------------
            if (route == null || !route.Active__c) {

                System.debug('FALLBACK TO OLD FLOW (route null or inactive)');
                ERPMessageHandler.postCSTfromHelper(req, res);
                return;
            }

            // =====================================================
            // 2. NEW vs OLD PATH
            // =====================================================
            if (route.IsNewPath__c != true) {

                System.debug('OLD PATH (IsNewPath__c != true)');
                ERPMessageHandler.postCSTfromHelper(req, res);
                return;
            }

            // =====================================================
            // 3. PROCESS MODE
            // =====================================================
            if (route.IsAsync__c == true) {

                System.debug('NEW ASYNC FLOW → Coordinator');
                handleAsync(rawJson, res);

            } else {

                System.debug('NEW SYNC FLOW → Orchestrator');
                handleSync(rawJson, res);
            }

        } catch (Exception e) {

            System.debug('❌ EXCEPTION: ' + e.getMessage());

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                '{"status":"ERROR","message":"' +
                escapeJson(e.getMessage()) +
                '"}'
            );
        }

        System.debug('=== ERPtoSF DEBUG END ===');
    }

    // =========================================================
    // SYNC
    // =========================================================
    private static void handleSync(String rawJson, RestResponse res) {

        IntegrationResponse r =
            IntegrationOrchestrator.process(rawJson, null);

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
    // ASYNC
    // =========================================================
    private static void handleAsync(String rawJson, RestResponse res) {

        System.debug('➡️ Calling InboundBatchCoordinator.acceptPart');

        InboundBatchCoordinator.Result r =
            InboundBatchCoordinator.acceptPart(rawJson);

        System.debug('⬅️ Coordinator response status=' + r.httpStatus);
        System.debug('⬅️ Coordinator response body=' + r.responseBody);

        res.statusCode = r.httpStatus;
        res.responseBody = Blob.valueOf(r.responseBody);        
    }

    // =========================================================
    // ROUTE
    // =========================================================
    private static IntegrationMessageRoute__mdt resolveRoute(String messageType) {

        if (String.isBlank(messageType)) return null;

        List<IntegrationMessageRoute__mdt> routes = [
            SELECT MessageCode__c,
                   Direction__c,
                   HandlerClass__c,
                   Active__c,
                   IsAsync__c,
                   IsNewPath__c
            FROM IntegrationMessageRoute__mdt
            WHERE MessageCode__c = :messageType
              AND Direction__c   = :IntegrationDirection.ERP_SF
            LIMIT 1
        ];

        return routes.isEmpty() ? null : routes[0];
    }

    // =========================================================
    // MESSAGE TYPE PARSER
    // =========================================================
    private static String resolveMessageType(String rawJson) {

        try {
            Map<String,Object> root =
                (Map<String,Object>) JSON.deserializeUntyped(rawJson);

            Map<String,Object> meta =
                (Map<String,Object>) (
                    root.containsKey('Metadata')
                        ? root.get('Metadata')
                        : root.get('metadata')
                );

            if (meta == null) {
                System.debug('❌ Metadata NOT FOUND');
                return null;
            }

            Object mt =
                meta.containsKey('MsgType')
                    ? meta.get('MsgType')
                    : meta.get('msgType');

            String result = mt == null ? null : String.valueOf(mt);

            System.debug('Parsed messageType=' + result);

            return result;

        } catch (Exception e) {

            System.debug('❌ resolveMessageType EXCEPTION: ' + e.getMessage());
            return null;
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return '';
        return s
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\r', '\\r')
            .replace('\n', '\\n');
    }
}