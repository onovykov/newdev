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
            EdiMessageConfig__mdt cfg =
                EdiMessageConfig__mdt.getInstance(rootTag);

            if (cfg == null || !cfg.Active__c) {
                return IntegrationResponseBuilder.error(
                    'UNKNOWN_XML_TYPE',
                    'Unsupported XML type: ' + rootTag
                );
            }

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
            IntegrationResponse resp =
                IntegrationOrchestrator.process(
                    JSON.serialize(canonicalDto),
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
