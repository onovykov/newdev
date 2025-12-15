public with sharing class CmdtRuntimeUpdateService {

    // Special keys in fieldsValues map:
    // - 'Label' or 'MasterLabel' or 'LABEL' will update CMDT record label (MasterLabel)
    private static final Set<String> LABEL_KEYS = new Set<String>{
        'LABEL', 'Label', 'MasterLabel'
    };

    // Disallowed keys (system-ish / unsafe)
    private static final Set<String> FORBIDDEN_KEYS = new Set<String>{
        'DeveloperName', 'FullName', 'fullName', 'NamespacePrefix', 'Id'
    };

    /**
     * Update (runtime) selected fields of a single CMDT record by DeveloperName.
     *
     * @param cmdtName      e.g. 'ShipmentStatus__mdt'   (required)
     * @param developerName e.g. 'SHIPPED'               (required)
     * @param fieldsValues  fieldName -> newValue. Custom fields must be '__c'.
     *                     Special: 'Label' / 'MasterLabel' / 'LABEL' to update record label.
     */
    public static Id updateCMDTCustomFields(
        String cmdtName,
        String developerName,
        Map<String, String> fieldsValues
    ) {
        validateInput(cmdtName, developerName, fieldsValues);

        // Normalize CMDT type name (allow passing without __mdt as convenience)
        String typeName = normalizeCmdtTypeName(cmdtName);

        Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();
        cmdt.fullName = typeName + '.' + developerName;

        // Apply Label (MasterLabel) if provided
        String labelValue = extractLabel(fieldsValues);
        if (labelValue != null) {
            cmdt.label = labelValue;
        }

        // Apply custom fields
        for (String fieldName : fieldsValues.keySet()) {
            if (LABEL_KEYS.contains(fieldName)) {
                continue; // already handled as cmdt.label
            }
            Metadata.CustomMetadataValue v = buildCustomFieldValue(fieldName, fieldsValues.get(fieldName));
            cmdt.values.add(v);
        }

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        dc.addMetadata(cmdt);

        // Enqueue async metadata deployment
        CmdtDeployCallback cb = new CmdtDeployCallback(typeName, developerName);
        Id deployId = Metadata.Operations.enqueueDeployment(dc, cb);

        System.debug(LoggingLevel.INFO,
            'CMDT runtime update enqueued. DeployId=' + deployId +
            ' Record=' + cmdt.fullName +
            (labelValue != null ? ' Label=' + labelValue : '') +
            ' Fields=' + fieldsValues.keySet()
        );

        return deployId;
    }

    // -------------------------
    // Validation
    // -------------------------
    private static void validateInput(
        String cmdtName,
        String developerName,
        Map<String, String> fieldsValues
    ) {
        if (String.isBlank(cmdtName)) {
            throw new IllegalArgumentException('cmdtName is required.');
        }
        if (String.isBlank(developerName)) {
            throw new IllegalArgumentException('developerName is required.');
        }
        if (fieldsValues == null || fieldsValues.isEmpty()) {
            throw new IllegalArgumentException('fieldsValues must not be empty.');
        }

        // Validate keys
        for (String key : fieldsValues.keySet()) {
            if (String.isBlank(key)) {
                throw new IllegalArgumentException('fieldsValues contains an empty field name.');
            }
            if (FORBIDDEN_KEYS.contains(key)) {
                throw new IllegalArgumentException('Forbidden field key in fieldsValues: ' + key);
            }
            // Allow label keys, otherwise require __c (custom field)
            if (!LABEL_KEYS.contains(key) && !key.endsWith('__c')) {
                throw new IllegalArgumentException(
                    'Only custom fields (__c) are allowed (or Label/MasterLabel). Invalid: ' + key
                );
            }
            if (fieldsValues.get(key) == null) {
                throw new IllegalArgumentException('Null value is not allowed for field: ' + key);
            }
        }
    }

    private static String normalizeCmdtTypeName(String cmdtName) {
        String n = cmdtName.trim();
        if (n.endsWith('__mdt')) return n;
        return n + '__mdt';
    }

    private static String extractLabel(Map<String, String> fieldsValues) {
        // Prefer MasterLabel > Label > LABEL, if multiple provided
        if (fieldsValues.containsKey('MasterLabel')) return nullIfBlank(fieldsValues.get('MasterLabel'));
        if (fieldsValues.containsKey('Label')) return nullIfBlank(fieldsValues.get('Label'));
        if (fieldsValues.containsKey('LABEL')) return nullIfBlank(fieldsValues.get('LABEL'));
        return null;
    }

    private static String nullIfBlank(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t == '' ? null : t;
    }

    // -------------------------
    // Build CustomMetadataValue
    // -------------------------
    private static Metadata.CustomMetadataValue buildCustomFieldValue(String fieldName, String rawValue) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = fieldName;
        v.value = coerceValue(rawValue);
        return v;
    }

    /**
     * Best-effort coercion from string:
     * - Boolean: true/false
     * - Integer: 123
     * - Decimal: 12.34
     * - Date: yyyy-MM-dd
     * - Datetime: yyyy-MM-ddTHH:mm:ssZ OR yyyy-MM-dd HH:mm:ss (best-effort)
     * - fallback: String
     *
     * NOTE: Apex can't describe __mdt field types at runtime, so we fail-soft here.
     */
    private static Object coerceValue(String raw) {
        if (raw == null) return null;
        String s = raw.trim();

        // Boolean
        if (s.equalsIgnoreCase('true') || s.equalsIgnoreCase('false')) {
            return Boolean.valueOf(s);
        }

        // Integer
        try {
            if (!s.contains('.') && s != '' && s != '+' && s != '-') {
                return Integer.valueOf(s);
            }
        } catch (Exception ignore) {}

        // Decimal
        try {
            // Decimal.valueOf throws if not numeric
            return Decimal.valueOf(s);
        } catch (Exception ignore) {}

        // Date (ISO)
        try {
            return Date.valueOf(s);
        } catch (Exception ignore) {}

        // Datetime (best-effort)
        // Accept: 2025-11-12T10:11:12Z or 2025-11-12 10:11:12
        try {
            if (s.contains('T') && (s.endsWith('Z') || s.contains('+') || s.contains('-'))) {
                return DateTime.valueOfGmt(s.replace('Z', ''));
            }
        } catch (Exception ignore) {}
        try {
            if (s.contains(' ')) {
                return DateTime.valueOf(s);
            }
        } catch (Exception ignore) {}

        // Fallback string
        return s;
    }
}