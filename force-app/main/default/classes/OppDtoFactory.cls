public with sharing class OppDtoFactory {
    public class Parsed {
        public OppEnvelope.Metadata metadata;
        public OppEnvelope.DataBase data;
    }

    public static Parsed parse(String rawJson) {
        if (String.isBlank(rawJson)) {
            throw new AuraHandledException('Empty JSON');
        }
        // Peek at OrderType
        Map<String, Object> un = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
        if (un == null || !un.containsKey('Data')) {
            throw new AuraHandledException('JSON has no Data node');
        }
        Map<String, Object> dataNode = (Map<String, Object>) un.get('Data');
        String orderType = (String) dataNode.get('OrderType');

        OppEnvelope.Metadata md = (OppEnvelope.Metadata) JSON.deserialize(
            JSON.serialize(un.get('Metadata')), OppEnvelope.Metadata.class
        );

        OppEnvelope.DataBase dataDto;
        String dataJson = JSON.serialize(dataNode);
        if (orderType != null && orderType.equalsIgnoreCase('Tubes')) {
            dataDto = (OppEnvelope.DataBase) JSON.deserialize(dataJson, TubesData.class);
        } else if (orderType != null && orderType.equalsIgnoreCase('Wheels')) {
            dataDto = (OppEnvelope.DataBase) JSON.deserialize(dataJson, WheelsData.class);
        } else {
            throw new AuraHandledException('Unsupported OrderType: ' + orderType);
        }

        Parsed res = new Parsed();
        res.metadata = md;
        res.data = dataDto;
        return res;
    }
}