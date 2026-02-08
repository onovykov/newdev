public class DataQualityRecord {
    public Id recordId;
    public String recordName;
    public Map<String, Map<String, String>> fields = new Map<String, Map<String, String>>();
    // fields:
    //  Email -> { "Invalid": "1@1.1" } або { "Suspicious": "1@1.com" }
}