public with sharing class InboundBatchCoordinator {

    public class Result {
        public Integer httpStatus;
        public String responseBody;
        public Boolean duplicate;
        public String batchKey;
        public Integer partNumber;
        public Integer totalParts;
        public Integer receivedParts;
    }

    public static Result acceptPart(String rawJson) {

        if (String.isBlank(rawJson)) {
            return badRequest('Empty payload');
        }

        Map<String,Object> root =
            (Map<String,Object>) JSON.deserializeUntyped(rawJson);

        // ============================================
        // Metadata (tolerant)
        // ============================================
        Map<String,Object> metadata =
            (Map<String,Object>) (
                root.containsKey('Metadata')
                    ? root.get('Metadata')
                    : root.get('metadata')
            );

        if (metadata == null) {
            return badRequest('Missing metadata');
        }

        // ============================================
        // msgType
        // ============================================
        String msgType;

        if (metadata.containsKey('MsgType')) {
            msgType = String.valueOf(metadata.get('MsgType'));
        } else if (metadata.containsKey('msgType')) {
            msgType = String.valueOf(metadata.get('msgType'));
        }

        if (String.isBlank(msgType)) {
            msgType = 'UNKNOWN';
        }

        // ============================================
        // partNumber
        // ============================================
        Integer partNo;

        if (metadata.containsKey('PartNumber')) {
            partNo = Integer.valueOf(String.valueOf(metadata.get('PartNumber')));
        } else if (metadata.containsKey('partNumber')) {
            partNo = Integer.valueOf(String.valueOf(metadata.get('partNumber')));
        }

        if (partNo == null) {
            return badRequest('Missing partNumber');
        }

        // ============================================
        // totalParts
        // ============================================
        Integer total;

        if (metadata.containsKey('TotalParts')) {
            total = Integer.valueOf(String.valueOf(metadata.get('TotalParts')));
        } else if (metadata.containsKey('totalParts')) {
            total = Integer.valueOf(String.valueOf(metadata.get('totalParts')));
        }

        // ============================================
        // timestamp
        // ============================================
        String timestamp;

        if (metadata.containsKey('MsgTimestamp')) {
            timestamp = String.valueOf(metadata.get('MsgTimestamp'));
        } else if (metadata.containsKey('msgTimestamp')) {
            timestamp = String.valueOf(metadata.get('msgTimestamp'));
        }

        if (String.isBlank(timestamp)) {
            timestamp = String.valueOf(System.now().getTime());
        }

        // ============================================
        // batch key
        // ============================================
        //String batchKey = msgType + '_' + timestamp;
        String normalizedTs = normalizeTimestamp(timestamp);
        String batchKey = msgType + '_' + normalizedTs;

        ERP_InboundBatch__c batch =
            getOrCreateHeader(batchKey, total);

        // ============================================
        // 🔥 NEW FIX: prevent overfill
        // ============================================
        if (batch.TotalParts__c != null &&
            batch.ReceivedParts__c != null &&
            batch.ReceivedParts__c >= batch.TotalParts__c) {

            return ackDuplicate(batchKey, partNo, total);
        }

        // ============================================
        // insert part
        // ============================================
        ERP_InboundPart__c part = new ERP_InboundPart__c();

        part.BatchKey__c = batchKey;
        part.PartNumber__c = partNo;
        part.Payload__c = rawJson;
        part.BatchPartKey__c = batchKey + '_' + partNo;

        try {
            insert part;
        } catch (DmlException e) {
            return ackDuplicate(batchKey, partNo, total);
        }

        Integer newCount = incrementReceived(batch.Id);
        if (total != null && newCount >= total) {

            ERP_InboundBatch__c b = new ERP_InboundBatch__c(
                Id = batch.Id,
                Status__c = InboundBatchStatusProvider.processing()
            );

            update b;
        }
        return ackAccepted(batchKey, partNo, total, newCount);
    }

    // ============================================
    // HEADER
    // ============================================
    private static ERP_InboundBatch__c getOrCreateHeader(
        String batchKey,
        Integer totalParts
    ) {

        List<ERP_InboundBatch__c> existing = [
            SELECT Id, Status__c, TotalParts__c, ReceivedParts__c
            FROM ERP_InboundBatch__c
            WHERE BatchKey__c = :batchKey
            LIMIT 1
        ];

        if (!existing.isEmpty()) {

            ERP_InboundBatch__c b = existing[0];

            if (InboundBatchStatusProvider.isTerminal(b.Status__c)) {
                return b;
            }

            if ((b.TotalParts__c == null || b.TotalParts__c == 0)
                && totalParts != null
                && totalParts > 0) {

                b.TotalParts__c = totalParts;
                update b;
            }

            return b;
        }

        ERP_InboundBatch__c newBatch = new ERP_InboundBatch__c();

        newBatch.BatchKey__c = batchKey;
        newBatch.Direction__c = 'ERP_SF';
        newBatch.Status__c = InboundBatchStatusProvider.accepted();
        newBatch.FirstSeenAt__c = System.now();
        newBatch.LastSeenAt__c = System.now();
        newBatch.TotalParts__c = totalParts != null ? totalParts : 0;
        newBatch.ReceivedParts__c = 0;

        insert newBatch;

        return newBatch;
    }

    // ============================================
    // COUNTER
    // ============================================
    private static Integer incrementReceived(Id batchId) {

        ERP_InboundBatch__c locked = [
            SELECT Id, ReceivedParts__c, LastSeenAt__c, Status__c
            FROM ERP_InboundBatch__c
            WHERE Id = :batchId
            FOR UPDATE
        ];

        if (InboundBatchStatusProvider.isTerminal(locked.Status__c)) {
            return locked.ReceivedParts__c == null
                ? 0
                : Integer.valueOf(locked.ReceivedParts__c);
        }

        Integer current =
            locked.ReceivedParts__c == null
            ? 0
            : Integer.valueOf(locked.ReceivedParts__c);

        locked.ReceivedParts__c = current + 1;
        locked.LastSeenAt__c = System.now();

        update locked;

        return current + 1;
    }

    // ============================================
    // RESPONSES
    // ============================================
    private static Result ackAccepted(
        String batchKey,
        Integer partNo,
        Integer total,
        Integer received
    ) {

        Result r = new Result();

        r.httpStatus = 202;
        r.batchKey = batchKey;
        r.partNumber = partNo;
        r.totalParts = total;
        r.receivedParts = received;

        r.responseBody =
            '{"status":"ACK","batchKey":"' + batchKey +
            '","received":' + received +
            ',"total":' + total + '}';

        return r;
    }

    private static Result ackDuplicate(
        String batchKey,
        Integer partNo,
        Integer total
    ) {

        Result r = new Result();

        r.httpStatus = 200;
        r.duplicate = true;
        r.batchKey = batchKey;
        r.partNumber = partNo;
        r.totalParts = total;

        r.responseBody =
            '{"status":"DUPLICATE","batchKey":"' + batchKey + '"}';

        return r;
    }

    private static Result badRequest(String message) {

        Result r = new Result();

        r.httpStatus = 400;

        r.responseBody =
            '{"status":"BAD_REQUEST","message":"' +
            String.escapeSingleQuotes(message) + '"}';

        return r;
    }

    private static String normalizeTimestamp(String ts) {

        if (String.isBlank(ts)) return ts;

        Integer dot = ts.indexOf('.');
        if (dot > 0) {
            return ts.substring(0, dot);
        }

        return ts;
    }    
}