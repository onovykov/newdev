public class DataQualityAggregator {

    public static Map<Id, DataQualityOwnerReport> aggregate(
        List<DataQualityFinding> findings
    ) {
        Map<Id, DataQualityOwnerReport> result = new Map<Id, DataQualityOwnerReport>();

        // preload owner names
        Set<Id> ownerIds = new Set<Id>();
        for (DataQualityFinding f : findings) ownerIds.add(f.ownerId);

        Map<Id, User> owners = new Map<Id, User>(
            [SELECT Id, Name FROM User WHERE Id IN :ownerIds]
        );

        for (DataQualityFinding f : findings) {
            if (!result.containsKey(f.ownerId)) {
                DataQualityOwnerReport r = new DataQualityOwnerReport();
                r.ownerId = f.ownerId;
                r.ownerName = owners.containsKey(f.ownerId)
                    ? owners.get(f.ownerId).Name
                    : 'Unknown';

                result.put(f.ownerId, r);
            }

            DataQualityOwnerReport report = result.get(f.ownerId);

            DataQualityRecord rec = findOrCreateRecord(
                report, f.objectApi, f.recordId
            );

            if (!rec.fields.containsKey(f.fieldApi)) {
                rec.fields.put(f.fieldApi, new Map<String, String>());
            }

            rec.fields.get(f.fieldApi).put(f.level, f.value);
        }

        return result;
    }

    // ------------------------------------------------------------

    private static DataQualityRecord findOrCreateRecord(
        DataQualityOwnerReport report,
        String objectApi,
        Id recordId
    ) {
        List<DataQualityRecord> bucket;

        if (objectApi == 'Account') bucket = report.accounts;
        else if (objectApi == 'Contact') bucket = report.contacts;
        else bucket = report.clientLeads;

        for (DataQualityRecord r : bucket) {
            if (r.recordId == recordId) return r;
        }

        DataQualityRecord r = new DataQualityRecord();
        r.recordId = recordId;
        bucket.add(r);
        return r;
    }
}