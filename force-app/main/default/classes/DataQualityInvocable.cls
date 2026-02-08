public with sharing class DataQualityInvocable {

    @InvocableMethod(
        label='Check Data Quality'
        description='Validates Email / Phone / Mobile / Website using DataQualityService'
    )
    public static List<DataQualityResult> check(
        List<DataQualityRequest> requests
    ) {
        List<DataQualityResult> results = new List<DataQualityResult>();

        // preload records by object
        Map<String, Map<Id, SObject>> recordsByObject = new Map<String, Map<Id, SObject>>();

        for (DataQualityRequest r : requests) {
            if (!recordsByObject.containsKey(r.objectName)) {
                recordsByObject.put(r.objectName, new Map<Id, SObject>());
            }
            recordsByObject.get(r.objectName).put(r.recordId, null);
        }

        // query per object
        for (String objectName : recordsByObject.keySet()) {
            Set<Id> ids = recordsByObject.get(objectName).keySet();
            if (ids.isEmpty()) continue;

            String soql =
                'SELECT Id FROM ' + objectName +
                ' WHERE Id IN :ids';

            for (SObject s : Database.query(soql)) {
                recordsByObject.get(objectName).put((Id)s.get('Id'), s);
            }
        }

        // validation
        for (DataQualityRequest r : requests) {
            DataQualityResult res = new DataQualityResult();
            SObject record =
                recordsByObject
                    .get(r.objectName)
                    .get(r.recordId);

            if (record == null) {
                res.isInvalid = false;
                res.message = 'Record not found';
            } else {
                Boolean invalid =
                    DataQualityService.isInvalid(
                        r.objectName,
                        r.fieldName,
                        record
                    );

                res.isInvalid = invalid;
                res.message = invalid
                    ? r.fieldName + ' is invalid'
                    : null;
            }

            results.add(res);
        }

        return results;
    }
}