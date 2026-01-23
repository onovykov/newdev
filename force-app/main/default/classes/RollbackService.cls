public with sharing class RollbackService {

    public class RollbackResponse {
        @AuraEnabled public Integer totalRows;
        @AuraEnabled public Integer successCount;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public List<String> errors;
    }

    @AuraEnabled
    public static RollbackResponse rollbackFromContentVersion(
        String sObjectApi,
        Id contentVersionId,
        Boolean allOrNone
    ) {
        if (String.isBlank(sObjectApi)) throw new AuraHandledException('sObjectApi is required');
        if (contentVersionId == null) throw new AuraHandledException('contentVersionId is required');

        ContentVersion cv = [
            SELECT Id, VersionData, Title
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];

        String csv = cv.VersionData.toString();
        return rollbackFromCsvString(sObjectApi, csv, allOrNone);
    }

    @AuraEnabled
    public static RollbackResponse rollbackFromCsvString(
        String sObjectApi,
        String csv,
        Boolean allOrNone
    ) {
        if (String.isBlank(csv)) throw new AuraHandledException('CSV is empty');

        List<List<String>> rows = parseCsv(csv);
        if (rows.isEmpty()) throw new AuraHandledException('CSV has no rows');

        List<String> header = rows[0];
        Integer idIdx = header.indexOf('Id');
        if (idIdx < 0) throw new AuraHandledException('CSV must contain Id column');

        List<SObject> updates = new List<SObject>();
        for (Integer i = 1; i < rows.size(); i++) {
            List<String> r = rows[i];
            if (r.size() == 0) continue;

            String idVal = safeGet(r, idIdx);
            if (String.isBlank(idVal)) continue;

            SObject sob = (SObject) Type.forName('Schema', sObjectApi).newInstance();
            sob.put('Id', (Id) idVal);

            for (Integer c = 0; c < header.size(); c++) {
                if (c == idIdx) continue;
                String field = header[c];
                if (String.isBlank(field)) continue;
                sob.put(field, safeGet(r, c));
            }
            updates.add(sob);
        }

        Database.SaveResult[] res = Database.update(updates, allOrNone == true);

        RollbackResponse out = new RollbackResponse();
        out.totalRows = updates.size();
        out.errors = new List<String>();

        Integer ok = 0, err = 0;
        for (Database.SaveResult sr : res) {
            if (sr.isSuccess()) ok++;
            else {
                err++;
                for (Database.Error e : sr.getErrors()) out.errors.add(e.getMessage());
            }
        }
        out.successCount = ok;
        out.errorCount = err;
        return out;
    }

    // --- helpers ---

    private static String safeGet(List<String> row, Integer idx) {
        return (idx >= 0 && idx < row.size()) ? row[idx] : null;
    }

    // Minimal CSV parser (supports quoted values with commas)
    private static List<List<String>> parseCsv(String input) {
        List<List<String>> rows = new List<List<String>>();
        List<String> currentRow = new List<String>();
        String current = '';
        Boolean inQuotes = false;

        for (Integer i = 0; i < input.length(); i++) {
            String ch = input.substring(i, i + 1);

            if (ch == '"') {
                // double quote inside quoted string
                if (inQuotes && i + 1 < input.length() && input.substring(i + 1, i + 2) == '"') {
                    current += '"';
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
                continue;
            }

            if (!inQuotes && (ch == ',')) {
                currentRow.add(current);
                current = '';
                continue;
            }

            if (!inQuotes && (ch == '\n')) {
                currentRow.add(current);
                rows.add(currentRow);
                currentRow = new List<String>();
                current = '';
                continue;
            }

            if (!inQuotes && ch == '\r') {
                continue;
            }

            current += ch;
        }

        // last cell
        currentRow.add(current);
        rows.add(currentRow);
        return rows;
    }
}