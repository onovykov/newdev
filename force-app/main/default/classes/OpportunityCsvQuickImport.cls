public with sharing class OpportunityCsvQuickImport {

    public class ImportError {
        public Integer rowNum;
        public String accountErp;
        public String ownerErp;
        public String assignedBosErp;
        public String countryNumCode;
        public String recordTypeDevName;
        public String opportunityName;
        public String message;

        public ImportError(
            Integer rowNum,
            String accountErp,
            String ownerErp,
            String assignedBosErp,
            String countryNumCode,
            String recordTypeDevName,
            String opportunityName,
            String message
        ) {
            this.rowNum = rowNum;
            this.accountErp = accountErp;
            this.ownerErp = ownerErp;
            this.assignedBosErp = assignedBosErp;
            this.countryNumCode = countryNumCode;
            this.recordTypeDevName = recordTypeDevName;
            this.opportunityName = opportunityName;
            this.message = message;
        }
    }

    public class ImportResult {
        public Integer totalRows = 0;
        public Integer successCount = 0;
        public Integer errorCount = 0;
        public List<ImportError> errors = new List<ImportError>();
    }

    public static ImportResult importFromLatestFileByTitle(String fileTitle, Boolean dryRun) {
        ContentVersion cv = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Title = :fileTitle
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        String csvText = cv.VersionData.toString();
        return importFromCsv(csvText, dryRun);
    }

    public static ImportResult importFromCsv(String csvText, Boolean dryRun) {
        ImportResult result = new ImportResult();

        if (String.isBlank(csvText)) {
            throw new IllegalArgumentException('CSV is empty');
        }

        List<String> lines = csvText.replace('\r\n', '\n').replace('\r', '\n').split('\n');
        if (lines.isEmpty()) {
            throw new IllegalArgumentException('CSV is empty');
        }

        List<String> headers = parseCsvLine(lines[0]);
        Map<String, Integer> headerIndex = new Map<String, Integer>();
        for (Integer i = 0; i < headers.size(); i++) {
            headerIndex.put(headers[i].trim(), i);
        }

        List<Map<String, String>> rows = new List<Map<String, String>>();

        Set<String> accountErpIds = new Set<String>();
        Set<String> userErpIds = new Set<String>();
        Set<String> countryNumCodes = new Set<String>();
        Set<String> recordTypeNames = new Set<String>();

        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) {
                continue;
            }

            List<String> cols = parseCsvLine(line);
            Map<String, String> row = new Map<String, String>();

            for (String h : headerIndex.keySet()) {
                Integer idx = headerIndex.get(h);
                row.put(h, idx < cols.size() ? cols[idx].trim() : null);
            }

            rows.add(row);

            if (!String.isBlank(row.get('AccountId'))) {
                accountErpIds.add(row.get('AccountId'));
            }
            if (!String.isBlank(row.get('Owner'))) {
                userErpIds.add(row.get('Owner'));
            }
            if (!String.isBlank(row.get('AssignedBOS'))) {
                userErpIds.add(row.get('AssignedBOS'));
            }
            if (!String.isBlank(row.get('Country'))) {
                countryNumCodes.add(row.get('Country'));
            }
            if (!String.isBlank(row.get('RecordType'))) {
                recordTypeNames.add(row.get('RecordType'));
            }
        }

        result.totalRows = rows.size();

        Map<String, Account> accByErp = new Map<String, Account>();
        if (!accountErpIds.isEmpty()) {
            for (Account a : [
                SELECT Id, ID_ERP__c
                FROM Account
                WHERE ID_ERP__c IN :accountErpIds
            ]) {
                accByErp.put(a.ID_ERP__c, a);
            }
        }

        Map<String, User> userByErp = new Map<String, User>();
        if (!userErpIds.isEmpty()) {
            for (User u : [
                SELECT Id, ID_ERP__c
                FROM User
                WHERE ID_ERP__c IN :userErpIds
            ]) {
                userByErp.put(u.ID_ERP__c, u);
            }
        }

        Map<String, Country__c> countryByNumCode = new Map<String, Country__c>();
        if (!countryNumCodes.isEmpty()) {
            for (Country__c c : [
                SELECT Id, NumCode__c
                FROM Country__c
                WHERE NumCode__c IN :countryNumCodes
            ]) {
                countryByNumCode.put(c.NumCode__c, c);
            }
        }

        Map<String, Id> rtByDevName = new Map<String, Id>();
        if (!recordTypeNames.isEmpty()) {
            for (RecordType rt : [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Opportunity'
                AND DeveloperName IN :recordTypeNames
                AND IsActive = true
            ]) {
                rtByDevName.put(rt.DeveloperName, rt.Id);
            }
        }

        List<Opportunity> oppsToInsert = new List<Opportunity>();
        List<Integer> sourceRowNums = new List<Integer>();
        List<Map<String, String>> sourceRowsForInsert = new List<Map<String, String>>();

        for (Integer i = 0; i < rows.size(); i++) {
            Integer rowNum = i + 2;
            Map<String, String> row = rows[i];

            try {
                Opportunity opp = new Opportunity();

                String accountErp = row.get('AccountId');
                if (String.isBlank(accountErp) || !accByErp.containsKey(accountErp)) {
                    throw new IllegalArgumentException('Account not found: ' + accountErp);
                }
                opp.AccountId = accByErp.get(accountErp).Id;

                String ownerErp = row.get('Owner');
                if (String.isBlank(ownerErp) || !userByErp.containsKey(ownerErp)) {
                    throw new IllegalArgumentException('Owner not found: ' + ownerErp);
                }
                opp.OwnerId = userByErp.get(ownerErp).Id;

                String bosErp = row.get('AssignedBOS');
                if (!String.isBlank(bosErp)) {
                    if (!userByErp.containsKey(bosErp)) {
                        throw new IllegalArgumentException('AssignedBOS not found: ' + bosErp);
                    }
                    opp.AssignedBOS__c = userByErp.get(bosErp).Id;
                }

                String countryNum = row.get('Country');
                if (!String.isBlank(countryNum)) {
                    if (!countryByNumCode.containsKey(countryNum)) {
                        throw new IllegalArgumentException('Country not found: ' + countryNum);
                    }
                    opp.Country__c = countryByNumCode.get(countryNum).Id;
                }

                String recordTypeDevName = row.get('RecordType');
                if (String.isBlank(recordTypeDevName) || !rtByDevName.containsKey(recordTypeDevName)) {
                    throw new IllegalArgumentException('RecordType not found: ' + recordTypeDevName);
                }
                opp.RecordTypeId = rtByDevName.get(recordTypeDevName);

                if (!String.isBlank(row.get('MarketSegment'))) {
                    opp.MarketSegment__c = row.get('MarketSegment');
                }

                if (!String.isBlank(row.get('Region'))) {
                    opp.Region__c = row.get('Region');
                }

                if (!String.isBlank(row.get('Name'))) {
                    opp.Name = row.get('Name');
                } else {
                    opp.Name = 'Imported Opportunity ' + rowNum;
                }

                if (!String.isBlank(row.get('StageName'))) {
                    opp.StageName = row.get('StageName');
                } else {
                    opp.StageName = 'Prospecting';
                }

                if (!String.isBlank(row.get('CloseDate'))) {
                    opp.CloseDate = Date.valueOf(row.get('CloseDate'));
                } else {
                    opp.CloseDate = Date.today();
                }

                oppsToInsert.add(opp);
                sourceRowNums.add(rowNum);
                sourceRowsForInsert.add(row);

            } catch (Exception e) {
                addError(result, rowNum, row, e.getMessage());
            }
        }

        if (!oppsToInsert.isEmpty()) {
            if (!dryRun) {
                Database.SaveResult[] srList = Database.insert(oppsToInsert, false);

                for (Integer i = 0; i < srList.size(); i++) {
                    if (srList[i].isSuccess()) {
                        result.successCount++;
                    } else {
                        result.errorCount++;
                        Map<String, String> sourceRow = sourceRowsForInsert[i];
                        for (Database.Error err : srList[i].getErrors()) {
                            addError(result, sourceRowNums[i], sourceRow, err.getMessage());
                        }
                    }
                }
            } else {
                System.debug('DRY RUN DATA:');
                System.debug(JSON.serializePretty(oppsToInsert));
                result.successCount = oppsToInsert.size();
            }
        }

        return result;
    }

    public static String buildErrorsCsv(ImportResult result) {
        List<String> lines = new List<String>();

        lines.add('RowNum,AccountId,Owner,AssignedBOS,Country,RecordType,Name,Message');

        if (result == null || result.errors == null || result.errors.isEmpty()) {
            return String.join(lines, '\n');
        }

        for (ImportError err : result.errors) {
            lines.add(
                csvCell(String.valueOf(err.rowNum)) + ',' +
                csvCell(err.accountErp) + ',' +
                csvCell(err.ownerErp) + ',' +
                csvCell(err.assignedBosErp) + ',' +
                csvCell(err.countryNumCode) + ',' +
                csvCell(err.recordTypeDevName) + ',' +
                csvCell(err.opportunityName) + ',' +
                csvCell(err.message)
            );
        }

        return String.join(lines, '\n');
    }

    public static Id saveErrorsCsvAsFile(String fileTitle, ImportResult result) {
        String csv = buildErrorsCsv(result);

        ContentVersion cv = new ContentVersion();
        cv.Title = fileTitle;
        cv.PathOnClient = fileTitle + '.csv';
        cv.VersionData = Blob.valueOf(csv);
        insert cv;

        return cv.Id;
    }

    private static void addError(
        ImportResult result,
        Integer rowNum,
        Map<String, String> row,
        String message
    ) {
        result.errorCount++;
        result.errors.add(new ImportError(
            rowNum,
            getRowValue(row, 'AccountId'),
            getRowValue(row, 'Owner'),
            getRowValue(row, 'AssignedBOS'),
            getRowValue(row, 'Country'),
            getRowValue(row, 'RecordType'),
            getRowValue(row, 'Name'),
            message
        ));
    }

    private static String getRowValue(Map<String, String> row, String key) {
        if (row == null || !row.containsKey(key)) {
            return null;
        }
        return row.get(key);
    }

    private static String csvCell(String value) {
        if (value == null) {
            value = '';
        }

        String escaped = value.replace('"', '""');
        return '"' + escaped + '"';
    }

    private static List<String> parseCsvLine(String line) {
        List<String> result = new List<String>();
        if (line == null) {
            return result;
        }

        String current = '';
        Boolean inQuotes = false;

        for (Integer i = 0; i < line.length(); i++) {
            String ch = line.substring(i, i + 1);

            if (ch == '"') {
                if (inQuotes && i + 1 < line.length() && line.substring(i + 1, i + 2) == '"') {
                    current += '"';
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (ch == ',' && !inQuotes) {
                result.add(current);
                current = '';
            } else {
                current += ch;
            }
        }

        result.add(current);
        return result;
    }
}