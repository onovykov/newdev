public with sharing class UserKeySnapshotHook {

    public static void afterUpdate(
        Map<Id, User> oldMap,
        Map<Id, User> newMap
    ) {
        Set<String> fieldsToAudit =
            UserAuditFieldProvider.getEnabledFields();

        if (fieldsToAudit.isEmpty()) {
            return;
        }

        List<Field_Audit_Log__c> logs = new List<Field_Audit_Log__c>();

        for (Id userId : newMap.keySet()) {
            User oldU = oldMap.get(userId);
            User newU = newMap.get(userId);

            for (String fieldName : fieldsToAudit) {
                Object oldVal = oldU.get(fieldName);
                Object newVal = newU.get(fieldName);

                if (oldVal != newVal) {
                    Blob digest = Crypto.generateDigest(
                        'SHA1',
                        Blob.valueOf(userId + '|' + fieldName + '|' + System.now().getTime())
                    );
                    String auditKeySHA = EncodingUtil.convertToHex(digest);                  
                    logs.add(new Field_Audit_Log__c(
                        AuditKey__c      = auditKeySHA, //'User.' + userId + '.' + fieldName,
                        ObjectApiName__c = 'User',
                        FieldApiName__c  = fieldName,
                        RecordId__c      = userId,
                        OldValue__c      = oldVal == null ? null : String.valueOf(oldVal),
                        NewValue__c      = newVal == null ? null : String.valueOf(newVal),
                        ChangedAt__c     = System.now(),
                        ChangedBy__c     = UserInfo.getUserId()
                    ));
                }
            }
        }

        if (!logs.isEmpty()) {
            System.enqueueJob(
                new UserAuditLogQueueable(logs)
            );
        }
    }
}