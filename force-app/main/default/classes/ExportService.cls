public with sharing class ExportService {

    /**
     * Serialize records to JSON
     */
    public static String toJson(List<SObject> records) {
        if (records == null) {
            return '[]';
        }
        return JSON.serializePretty(records);
    }

    /**
     * Serialize records to CSV
     */
    public static String toCsv(
        List<SObject> records,
        List<String> fields
    ) {
        if (records == null || records.isEmpty()) {
            return '';
        }

        List<String> lines = new List<String>();

        // header
        lines.add(String.join(fields, ','));

        // rows
        for (SObject s : records) {
            List<String> row = new List<String>();
            for (String f : fields) {
                Object val = s.get(f);
                row.add(escape(val));
            }
            lines.add(String.join(row, ','));
        }

        return String.join(lines, '\n');
    }

    /**
     * Save CSV as Salesforce File
     */
    public static ContentVersion exportCsvToFile(
        String fileName,
        String csvContent
    ) {
        ContentVersion cv = new ContentVersion();
        cv.Title        = fileName;
        cv.PathOnClient = fileName + '.csv';
        cv.VersionData  = Blob.valueOf(csvContent);

        insert cv;
        return cv;
    }

    // --- helpers ---

    private static String escape(Object val) {
        if (val == null) {
            return '';
        }
        String s = String.valueOf(val);
        s = s.replace('"', '""');
        return '"' + s + '"';
    }
}