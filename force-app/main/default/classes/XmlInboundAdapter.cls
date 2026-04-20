public with sharing class XmlInboundAdapter {

    public static IntegrationResponse process(String xml) {

        try {

            // -------------------------------------
            // 1. Detect root tag
            // -------------------------------------
            String rootTag = detectRootTag(xml);

            // -------------------------------------
            // 2. Load config from MDT
            // -------------------------------------
            //EdiMessageConfig__mdt cfg =
            //    EdiMessageConfig__mdt.getInstance(rootTag);

            List<EdiMessageConfig__mdt> configs = [
                SELECT DeveloperName, RootTag__c, ParserClass__c, MapperClass__c, TargetMessageCode__c, Active__c
                FROM EdiMessageConfig__mdt
                WHERE RootTag__c = :rootTag
                AND Active__c = true
                LIMIT 1
            ];

            if (configs.isEmpty()) {
                return IntegrationResponseBuilder.error(
                    'UNKNOWN_XML_TYPE',
                    'Unsupported XML type: ' + rootTag
                );
            }

            EdiMessageConfig__mdt cfg = configs[0];

            // -------------------------------------
            // 3. Parser (dynamic через interface)
            // -------------------------------------
            IEdiParser parser =
                (IEdiParser) Type.forName(cfg.ParserClass__c).newInstance();

            Object transportDto = parser.parse(xml);

            // -------------------------------------
            // 4. Mapper
            // -------------------------------------
            IEdiMapper mapper =
                (IEdiMapper) Type.forName(cfg.MapperClass__c).newInstance();

            Object canonicalDto = mapper.mapToCanonical(transportDto);

            // -------------------------------------
            // 5. Call Orchestrator (старий метод)
            // -------------------------------------
            /*
            IntegrationResponse resp =
                IntegrationOrchestrator.process(
                    JSON.serialize(canonicalDto),
                    cfg.TargetMessageCode__c
                );
            */
            // =====================================================
            // Build canonical envelope (CRITICAL FIX)
            // =====================================================
            Map<String, Object> envelope = new Map<String, Object>{
                'Metadata' => new Map<String, Object>{
                    'MsgType' => cfg.TargetMessageCode__c
                },
                'Payload' => canonicalDto
            };

            // =====================================================
            // Call orchestrator
            // =====================================================
            IntegrationResponse resp =
                IntegrationOrchestrator.process(
                    JSON.serialize(envelope),
                    cfg.TargetMessageCode__c
                );            
            return resp;

        } catch (Exception ex) {

            return IntegrationResponseBuilder.error(
                'XML_PROCESSING_ERROR',
                ex.getMessage()
            );
        }
    }

    // =========================================================
    // ROOT TAG DETECTION (твій hybrid — ✔ правильний)
    // =========================================================
    private static String detectRootTag(String xml) {

        if (String.isBlank(xml)) return 'UNKNOWN';

        // 1. TRY DOM
        try {
            Dom.Document doc = new Dom.Document();
            doc.load(xml);

            Dom.XmlNode root = doc.getRootElement();

            if (root != null && root.getName() != 'IDOC') {
                return root.getName();
            }
        } catch (Exception e) {
            // ignore
        }

        // 2. FALLBACK MDT
        List<EdiMessageConfig__mdt> configs = [
            SELECT RootTag__c
            FROM EdiMessageConfig__mdt
            WHERE Active__c = true
        ];

        for (EdiMessageConfig__mdt cfg : configs) {
            if (xml.contains('<' + cfg.RootTag__c)) {
                return cfg.RootTag__c;
            }
        }

        return 'UNKNOWN';
    }
}
