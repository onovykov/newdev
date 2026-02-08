public class DataQualityRequest {
    @InvocableVariable(required=true)
    public String objectName;   // alias або API (Lead / Account)

    @InvocableVariable(required=true)
    public String fieldName;    // alias або API (Email / Phone)

    @InvocableVariable(required=true)
    public Id recordId;         // Id запису
}