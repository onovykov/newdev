@RestResource(urlMapping = '/ERPtoSF/v1/*')
global with sharing class ERPtoSF {

    // =====================================================
    // TEST OVERRIDE
    // =====================================================

    @TestVisible
    static Boolean overrideUseOld;

    // =====================================================
    // SWITCH RESOLUTION
    // =====================================================

    private static Boolean useOldPipeline() {
        // Allow tests to override behavior
        if (Test.isRunningTest() && overrideUseOld != null) {
            return overrideUseOld;
        }

        ERPtoSF_Switcher__mdt cfg =
            ERPtoSF_Switcher__mdt.getInstance('Default');

        return (cfg == null || cfg.UseOld__c == true);
    }

    // =====================================================
    // REST ENTRYPOINT
    // =====================================================

    @HttpPost
    global static void postCST() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {

            Boolean useOld = useOldPipeline();

            System.debug(
                'ERP inbound pipeline = ' +
                (useOld ? 'OLD_HANDLER' : 'NEW_PIPELINE')
            );

            if (useOld) {
                // =================================
                // OLD PIPELINE
                // =================================
                ERPMessageHandler.postCSTfromHelper(
                    request,
                    response
                );

            } else {
                // =================================
                // NEW PIPELINE
                // =================================
                ERPInboundController.handle(
                    request,
                    response
                );
            }

        } catch (Exception e) {

            System.debug(
                'ERP endpoint error: ' + e.getMessage()
            );

            response.statusCode = 500;

            response.responseBody =
                Blob.valueOf(
                    '{"status":"ERROR","message":"' +
                    String.escapeSingleQuotes(e.getMessage()) +
                    '"}'
                );
        }
    }
}