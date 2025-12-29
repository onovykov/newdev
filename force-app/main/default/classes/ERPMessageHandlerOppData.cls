public class ERPMessageHandlerOppData {
    public static ERPMessageParser.ErpToSfMessage_OpportunityData getParsedJson(String requestBody) {
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();
        if(!String.isBlank(requestBody)) {
            parsed = (ERPMessageParser.ErpToSfMessage_OpportunityData) JSON.deserialize(requestBody,
            																   ERPMessageParser.ErpToSfMessage_OpportunityData.class);
        }
        return parsed;
    }   
}