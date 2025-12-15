public with sharing class CmdtRuntimeService {
    // =========================
    // PUBLIC API
    // =========================

    /**
     * Create new CMDT record.
     */
    public static Id insertCmdtRecord(
        String cmdtName,
        String developerName,
        Map<String, String> fields
    ) {
        return deploySingle(
            cmdtName,
            developerName,
            fields,
            CmdtOperation.CREATE_REC
        );
    }

    /**
     * Update existing CMDT record.
     */
    public static Id updateCmdtRecord(
        String cmdtName,
        String developerName,
        Map<String, String> fields
    ) {
        return deploySingle(
            cmdtName,
            developerName,
            fields,
            CmdtOperation.UPDATE_REC
        );
    }

    /**
     * Create or update CMDT record by DeveloperName.
     * NOTE:
     * For CMDT this is semantic upsert:
     * - if record exists → update
     * - if not → create (MasterLabel required)
     */
    public static Id upsertCmdtRecord(
        String cmdtName,
        String developerName,
        Map<String, String> fields
    ) {
        return deploySingle(
            cmdtName,
            developerName,
            fields,
            CmdtOperation.UPSERT_REC
        );
    }
    /**
     * Soft-disable CMDT record via IsActive__c = false
     */
    public static Id disableCmdtRecord(
        String cmdtName,
        String developerName
    ) {
        return deploySingle(
            cmdtName,
            developerName,
            new Map<String, String>{
                'IsActive__c' => 'false'
            },
            CmdtOperation.UPDATE_REC
        );
    }

    /**
     * (Optional) Re-enable CMDT record via IsActive__c = true
     */
    public static Id enableCmdtRecord(
        String cmdtName,
        String developerName
    ) {
        return deploySingle(
            cmdtName,
            developerName,
            new Map<String, String>{
                'IsActive__c' => 'true'
            },
            CmdtOperation.UPDATE_REC
        );
    }

    // =========================
    // CORE IMPLEMENTATION
    // =========================
    private static Id deploySingle(
        String cmdtName,
        String developerName,
        Map<String, String> fields,
        CmdtOperation op
    ) {
        if (String.isBlank(cmdtName)) {
            throw new IllegalArgumentException('cmdtName is required');
        }
        if (String.isBlank(developerName)) {
            throw new IllegalArgumentException('developerName is required');
        }
        if (fields == null || fields.isEmpty()) {
            throw new IllegalArgumentException('fields must not be empty');
        }

        String typeName = normalizeCmdtTypeName(cmdtName);
        String fullName = typeName + '.' + developerName;

        Metadata.CustomMetadata md = new Metadata.CustomMetadata();
        md.fullName = fullName;

        // MasterLabel is REQUIRED for create.
        // For update/upsert it is safe to always provide it.
        String label = extractLabel(fields);
        if (String.isBlank(label)) {
            label = developerName.replace('_', ' ');
        }
        md.label = label;

        for (String fieldName : fields.keySet()) {
            if (isLabelKey(fieldName)) {
                continue;
            }

            Metadata.CustomMetadataValue v =
                new Metadata.CustomMetadataValue();
            v.field = fieldName;
            v.value = coerceValue(fields.get(fieldName));
            md.values.add(v);
        }

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        dc.addMetadata(md);

        //Id deployId = Metadata.Operations.enqueueDeployment(dc, null);
        Id deployId;

        if (Test.isRunningTest()) {
            // Fake deploy id for test context
            deployId = (Id) '0Af000000000000AAA';
        } else {
            deployId = Metadata.Operations.enqueueDeployment(dc, null);
        }       

        System.debug(LoggingLevel.INFO,
            'CMDT ' + op +
            ' enqueued: ' + fullName +
            ' deployId=' + deployId
        );

        return deployId;
    }

    // =========================
    // HELPERS
    // =========================
    private static String normalizeCmdtTypeName(String name) {
        return name.endsWith('__mdt') ? name : name + '__mdt';
    }

    private static Boolean isLabelKey(String key) {
        return key == 'MasterLabel' || key == 'Label';
    }

    private static String extractLabel(Map<String, String> fields) {
        if (fields.containsKey('MasterLabel')) {
            return trim(fields.get('MasterLabel'));
        }
        if (fields.containsKey('Label')) {
            return trim(fields.get('Label'));
        }
        return null;
    }

    private static String trim(String s) {
        if (s == null) return null;
        String t = s.trim();
        return String.isBlank(t) ? null : t;
    }

    private static Object coerceValue(String raw) {
        if (raw == null) return null;
        String s = raw.trim();

        if (s.equalsIgnoreCase('true') || s.equalsIgnoreCase('false')) {
            return Boolean.valueOf(s);
        }
        try { return Integer.valueOf(s); } catch (Exception ignore) {}
        try { return Decimal.valueOf(s); } catch (Exception ignore) {}
        try { return Date.valueOf(s); } catch (Exception ignore) {}
        try { return DateTime.valueOf(s); } catch (Exception ignore) {}

        return s;
    }

    // =========================
    // INTERNAL ENUM
    // =========================
    private enum CmdtOperation {
        CREATE_REC,
        UPDATE_REC,
        UPSERT_REC
    }
}