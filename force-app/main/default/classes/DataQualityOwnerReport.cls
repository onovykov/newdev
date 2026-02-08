public class DataQualityOwnerReport {
    public Id ownerId;
    public String ownerName;

    public List<DataQualityRecord> accounts = new List<DataQualityRecord>();
    public List<DataQualityRecord> contacts = new List<DataQualityRecord>();
    public List<DataQualityRecord> clientLeads = new List<DataQualityRecord>();
}