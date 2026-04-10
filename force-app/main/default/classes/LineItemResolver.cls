public with sharing class LineItemResolver {

    public class InputItem {
        public Map<String, Object> json;
        public Id orderItemId;
        public Id oliId;
        public String sourceType; // 'ORDER' або 'OLI'
    }

    public static List<LineItemDetails__c> resolve(List<InputItem> inputs) {

        List<LineItemDetails__c> result = new List<LineItemDetails__c>();

        if (inputs == null || inputs.isEmpty()) return result;

        String domain = 'Tubes';

        // 1. MDT
        List<FacetSetting__mdt> settings = [
            SELECT Facet__c, FacetType__c, WhereIsIn__c,
                   StartPos__c, EndPos__c, ValuePos__c
            FROM FacetSetting__mdt
            WHERE Domain__c = :domain
        ];

        // 2. Map Facet → Setting
        Map<String, FacetSetting__mdt> settingByFacet = new Map<String, FacetSetting__mdt>();
        for (FacetSetting__mdt s : settings) {
            settingByFacet.put(s.Facet__c, s);
        }

        // 3. Збір всіх raw values (для 1 SOQL)
        Set<String> allRawValues = new Set<String>();

        // 4. Тимчасове збереження facet → raw
        List<Map<String, String>> allFacetMaps = new List<Map<String, String>>();

        for (InputItem input : inputs) {

            Map<String, Object> itemJson = input.json;
            String kmat = (String)itemJson.get('KMAT');
            Map<String, Object> pc = (Map<String, Object>)itemJson.get('ProductCharacteristic');

            Map<String, String> facetRawValues = new Map<String, String>();

            for (FacetSetting__mdt s : settings) {

                // --- KMAT ---
                if (s.WhereIsIn__c == 'KMAT') {

                    if (kmat == null || kmat.length() < s.EndPos__c) continue;

                    Integer startIdx = Integer.valueOf(s.StartPos__c) - 1;
                    Integer endIdx   = Integer.valueOf(s.EndPos__c);

                    String value = kmat.substring(startIdx, endIdx);

                    facetRawValues.put(s.Facet__c, value);
                    allRawValues.add(value);
                }

                // --- JSON ---
                else if (s.WhereIsIn__c == 'JSON') {

                    if (pc == null) continue;

                    for (String key : pc.keySet()) {

                        Object node = pc.get(key);
                        if (!(node instanceof Map<String, Object>)) continue;

                        Map<String, Object> m = (Map<String, Object>)node;

                        // Standard (Facet object)
                        if (m.containsKey('Facet')) {

                            Map<String, Object> f = (Map<String, Object>)m.get('Facet');
                            String facetCode = (String)f.get('Code');

                            if (facetCode == s.Facet__c) {
                                String val = (String)f.get('Id');
                                facetRawValues.put(facetCode, val);
                                allRawValues.add(val);
                            }
                        }

                        // стандарт
                        else if (m.containsKey('FacetCode')) {

                            String facetCode = (String)m.get('FacetCode');

                            if (facetCode == s.Facet__c) {
                                String val = (String)m.get('Id');
                                facetRawValues.put(facetCode, val);
                                allRawValues.add(val);
                            }
                        }
                    }
                }
            }

            allFacetMaps.add(facetRawValues);
        }

        if (allRawValues.isEmpty()) return result;

        // 5. Dictionary (1 SOQL)
        Map<String, ProdTechRefDetails__c> dict = new Map<String, ProdTechRefDetails__c>();

        for (ProdTechRefDetails__c d : [
            SELECT Id, Facet__c, ID_ERP__c, CompositeKey__c
            FROM ProdTechRefDetails__c
            WHERE ID_ERP__c IN :allRawValues
              AND OrderType__c = :domain
              AND CompositeKey__c != null
        ]) {
            String key = d.Facet__c + '|' + d.ID_ERP__c;
            dict.put(key, d);
        }

        // 6. Побудова результату
        for (Integer i = 0; i < inputs.size(); i++) {

            InputItem input = inputs[i];
            Map<String, String> facetRawValues = allFacetMaps[i];

            Id itemId = (input.sourceType == 'ORDER')
                ? input.orderItemId
                : input.oliId;

            for (String facet : facetRawValues.keySet()) {

                String raw = facetRawValues.get(facet);
                String lookupKey = facet + '|' + raw;

                ProdTechRefDetails__c ref = dict.get(lookupKey);
                if (ref == null) continue;

                FacetSetting__mdt s = settingByFacet.get(facet);
                if (s == null) continue;

                LineItemDetails__c d = new LineItemDetails__c();

                d.SourceType__c = input.sourceType;

                if (input.sourceType == 'ORDER') {
                    d.OrderItem__c = input.orderItemId;
                } else {
                    d.OLI__c = input.oliId;
                }

                d.Facet__c = facet;
                d.ProdTechRefDetails__c = ref.Id;

                // з MDT
                d.FacetType__c = s.FacetType__c;
                d.ItemPos__c   = s.ValuePos__c;

                if (s.FacetType__c == 'SKU') {
                    d.PosPirority__c = 1;
                } else if (s.FacetType__c == 'SALE_ITEM') {
                    d.PosPirority__c = 2;
                }

                // CompositeKey
                d.CompositeKey__c = String.valueOf(itemId) + '|' + facet;

                result.add(d);
            }
        }

        // 7. UPSERT (dedup + update)
        if (!result.isEmpty()) {
            upsert result CompositeKey__c;
        }

        return result;
    }
}