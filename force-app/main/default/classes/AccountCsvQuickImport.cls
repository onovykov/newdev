public with sharing class AccountCsvQuickImport {

    public class ImportError {
        public Integer rowNum;
        public String message;

        public ImportError(Integer rowNum, String message) {
            this.rowNum = rowNum;
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

        List<String> lines = csvText.replace('\r\n', '\n').replace('\r', '\n').split('\n');
        if (lines.isEmpty()) {
            throw new AuraHandledException('CSV is empty');
        }

        List<String> headers = parseCsvLine(lines[0]);
        Map<String, Integer> headerIndex = new Map<String, Integer>();
        for (Integer i = 0; i < headers.size(); i++) {
            headerIndex.put(headers[i].trim(), i);
        }

        List<Map<String, String>> rows = new List<Map<String, String>>();

        Set<String> accountErpIds = new Set<String>();
        Set<String> userErpIds = new Set<String>();
        Set<String> countryCodes = new Set<String>();

        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;

            List<String> cols = parseCsvLine(line);
            Map<String, String> row = new Map<String, String>();

            for (String h : headerIndex.keySet()) {
                Integer idx = headerIndex.get(h);
                row.put(h, idx < cols.size() ? cols[idx].trim() : null);
            }

            rows.add(row);

            if (!String.isBlank(row.get('ORG__c'))) accountErpIds.add(row.get('ORG__c'));
            if (!String.isBlank(row.get('User_ID_ERP__c'))) userErpIds.add(row.get('User_ID_ERP__c'));
            if (!String.isBlank(row.get('CountryCode__c'))) countryCodes.add(row.get('CountryCode__c'));
        }

        result.totalRows = rows.size();

        // --- існуючі акаунти ---
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

        // --- юзери ---
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

        // --- країни ---
        Map<String, Country__c> countryByCode = new Map<String, Country__c>();
        if (!countryCodes.isEmpty()) {
            for (Country__c c : [
                SELECT Id, NumCode__c, A2Code__c, SysName__c
                FROM Country__c
                WHERE NumCode__c IN :countryCodes
            ]) {
                countryByCode.put(c.NumCode__c, c);
            }
        }

        List<Account> accToInsert = new List<Account>();
        List<Integer> sourceRowNums = new List<Integer>();

        for (Integer i = 0; i < rows.size(); i++) {
            Integer rowNum = i + 2;
            Map<String, String> row = rows[i];

            try {
                String erpId = row.get('ORG__c');

                if (String.isBlank(erpId)) {
                    throw new IllegalArgumentException('ORG__c is empty');
                }

                if (accByErp.containsKey(erpId)) {
                    throw new IllegalArgumentException('Account already exists: ' + erpId);
                }

                Account acc = new Account();
                acc.ID_ERP__c = erpId;
                acc.Name = row.get('NORG__c');
                acc.FullName__c = row.get('NORG_S__c');

                // --- країна ---
                String countryCode = row.get('CountryCode__c');
                if (!String.isBlank(countryCode)) {
                    if (!countryByCode.containsKey(countryCode)) {
                        throw new IllegalArgumentException('Country not found: ' + countryCode);
                    }

                    Country__c c = countryByCode.get(countryCode);

                    acc.AccCountry__c = c.Id;
                    acc.BillingCountryCode = c.A2Code__c;
                    acc.BillingCountry = c.SysName__c;
                }

                acc.BillingStreet = row.get('Addr__c');
                acc.BillingCity = row.get('CITY__c');
                acc.Activity_Type__c = 'Active';
                acc.MarketSegment__c = row.get('MarketSegment__c');
                acc.BillingPostalCode = row.get('PostalCode__c');

                // --- owner ---
                String ownerErp = row.get('User_ID_ERP__c');
                if (!String.isBlank(ownerErp)) {
                    if (!userByErp.containsKey(ownerErp)) {
                        throw new IllegalArgumentException('User not found: ' + ownerErp);
                    }
                    acc.OwnerId = userByErp.get(ownerErp).Id;
                }

                accToInsert.add(acc);
                sourceRowNums.add(rowNum);

            } catch (Exception e) {
                result.errorCount++;
                result.errors.add(new ImportError(rowNum, e.getMessage()));
            }
        }

        if (!accToInsert.isEmpty()) {

            Database.SaveResult[] srList = new List<Database.SaveResult>();

            if (!dryRun) {
                srList = Database.insert(accToInsert, false);
            } else {
                System.debug('DRY RUN DATA:');
                System.debug(JSON.serializePretty(accToInsert));
                result.successCount = accToInsert.size();
                return result;
            }

            for (Integer i = 0; i < srList.size(); i++) {
                if (srList[i].isSuccess()) {
                    result.successCount++;
                } else {
                    result.errorCount++;
                    for (Database.Error err : srList[i].getErrors()) {
                        result.errors.add(new ImportError(sourceRowNums[i], err.getMessage()));
                    }
                }
            }
        }

        return result;
    }

    private static List<String> parseCsvLine(String line) {
        List<String> result = new List<String>();
        if (line == null) return result;

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