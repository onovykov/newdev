public with sharing class ProdWeeksImportService {

    public static ProdWeeksImportResult importProdWeeks(String jsonString) {
        if (String.isBlank(jsonString)) {
            return ProdWeeksImportResult.fail('Empty JSON payload');
        }

        ProdWeeksDTO dto;
        try {
            dto = ProdWeeksDTO.fromJson(jsonString);
        } catch (Exception e) {
            return ProdWeeksImportResult.fail('JSON parse error: ' + e.getMessage());
        }
        if (dto == null) return ProdWeeksImportResult.fail('DTO is null after parsing');

        List<String> issues = dto.validate();
        if (!issues.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'ProdWeeksDTO validation issues: ' + String.join(issues, ' | '));
        }

        Id mainId = ensureMain();

        Set<String> allItemIds = new Set<String>();
        List<ProdWeeksH__c> toUpsert = new List<ProdWeeksH__c>();

        String yearStr = String.valueOf(dto.W_Year); // String для ItemId/ParentId

        // Year (Level=1)
        allItemIds.add(yearStr);
        toUpsert.add(makeYearRow(yearStr));

        if (dto.Data != null) {
            for (ProdWeeksDTO.MonthBlock m : dto.Data) {
                if (m == null || String.isBlank(m.GODMEC)) continue;

                String monthItemId = m.GODMEC;           // 'YYYYMM'
                allItemIds.add(monthItemId);
                toUpsert.add(makeMonthRow(yearStr, monthItemId));

                if (m.Weeks != null) {
                    for (ProdWeeksDTO.WeekItem w : m.Weeks) {
                        if (w == null || w.NWEEK == null) continue;
                        String weekItemId = monthItemId + '_' + String.valueOf(w.NWEEK);
                        allItemIds.add(weekItemId);
                        toUpsert.add(makeWeekRow(dto.W_Year, monthItemId, w, weekItemId));
                    }
                }
            }
        }

        Map<String, ProdWeeksH__c> existingByItem = loadExistingByItemId(allItemIds);

        List<ProdWeeksH__c> toInsert = new List<ProdWeeksH__c>();
        List<ProdWeeksH__c> toUpdate = new List<ProdWeeksH__c>();

        for (ProdWeeksH__c rec : toUpsert) {
            ProdWeeksH__c found = existingByItem.get((String) rec.ItemId__c);
            if (found == null) {
                toInsert.add(rec);
            } else {
                rec.Id = found.Id;
                toUpdate.add(rec);
            }
        }

        Database.SaveResult[] insRes, updRes;
        try {
            if (!toInsert.isEmpty()) insRes = Database.insert(toInsert, false);
            if (!toUpdate.isEmpty()) updRes = Database.update(toUpdate, false);
        } catch (Exception e) {
            return ProdWeeksImportResult.fail('DML error: ' + e.getMessage());
        }

        try {
            SysUtils.updateHierarchy('ProdWeeksH__c', 'ItemId__c', 'ParentId__c', 'Parent__c');
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'updateHierarchy failed: ' + e.getMessage());
        }

        ProdWeeksImportResult res = new ProdWeeksImportResult();
        res.inserted = (insRes == null ? 0 : countSuccess(insRes));
        res.updated  = (updRes == null ? 0 : countSuccess(updRes));
        res.errors   = collectErrors(insRes, updRes);
        res.warnings = issues;
        return res;
    }

    // -------- record builders (динамічна установка чисел або рядків) --------

    private static ProdWeeksH__c makeYearRow(String yearStr) {
        ProdWeeksH__c r = new ProdWeeksH__c();
        r.ItemId__c   = yearStr;
        r.Name        = yearStr;
        r.Level__c    = 1;
        r.ParentId__c = 'MAIN'; // текстовий foreign key
        setNumberOrText(r, 'Year__c', Integer.valueOf(yearStr));
        return r;
    }

    private static ProdWeeksH__c makeMonthRow(String yearStr, String godmec) {
        Integer y = Integer.valueOf(godmec.substring(0, 4));
        Integer m = Integer.valueOf(godmec.substring(4, 6));

        String monthApi   = String.valueOf(m); // '1'..'12' для Month__c
        String monthLabel = getPicklistLabel(ProdWeeksH__c.SObjectType, 'Month__c', monthApi);
        String monthName  = (monthLabel == null ? monthApi : monthLabel).toUpperCase(); // 'JANUARY'

        ProdWeeksH__c r = new ProdWeeksH__c();
        r.ItemId__c   = godmec;       // 'YYYYMM'
        r.Name        = monthName;    // 'JANUARY'
        r.Level__c    = 2;
        r.ParentId__c = yearStr;      // текстовий foreign key
        // Поля року/місяця (Month__c – picklist, ставимо API value як String)
        setNumberOrText(r, 'Year__c',  y);
        r.put('Month__c', monthApi);
        return r;
    }

    private static ProdWeeksH__c makeWeekRow(Integer wYear, String godmec, ProdWeeksDTO.WeekItem w, String weekItemId) {
        Integer month = Integer.valueOf(godmec.substring(4, 6));

        ProdWeeksH__c r = new ProdWeeksH__c();
        r.ItemId__c   = weekItemId;               // 'YYYYMM_N'
        r.Name        = 'Week ' + String.valueOf(w.NWEEK);
        r.Level__c    = 3;
        r.ParentId__c = godmec;                   // текстовий foreign key
        r.DateFrom__c = w.DATN;
        r.DateTo__c   = w.DATK;

        // Year/Month/WeekNum: підтримуємо будь-які типи (Number/Text)
        setNumberOrText(r, 'Year__c',    wYear);
        setNumberOrText(r, 'Month__c',   month);  // якщо Month__c — picklist, setNumberOrText поставить '1'..'12'
        setNumberOrText(r, 'WeekNum__c', w.NWEEK);

        return r;
    }

    // -------- dynamic setters: ставимо Integer або String залежно від типу поля --------

    private static void setNumberOrText(SObject rec, String fieldApi, Integer value) {
        Schema.DescribeSObjectResult sobj = ProdWeeksH__c.SObjectType.getDescribe();
        Schema.DescribeFieldResult dfr = sobj.fields.getMap().get(fieldApi).getDescribe();
        Schema.DisplayType dt = dfr.getType();

        if (dt == Schema.DisplayType.Integer ||
            dt == Schema.DisplayType.Double  ||
            dt == Schema.DisplayType.Long    ||
            dt == Schema.DisplayType.Currency ||
            dt == Schema.DisplayType.Percent) {
            rec.put(fieldApi, value);
        } else {
            rec.put(fieldApi, (value == null ? null : String.valueOf(value)));
        }
    }

    // -------- infra helpers --------
    // Повертає label для picklist-значення (apiValue) або сам apiValue, якщо не знайдено.
    public static String getPicklistLabel(Schema.SObjectType sType, String fieldApi, String apiValue) {
        if (String.isBlank(apiValue)) return apiValue;
        Schema.DescribeFieldResult dfr = sType.getDescribe().fields.getMap().get(fieldApi).getDescribe();
        if (dfr.getType() != Schema.DisplayType.Picklist) return apiValue;
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.getValue() == apiValue) {
                return pe.getLabel();
            }
        }
        return apiValue;
    }

    private static Id ensureMain() {
        List<ProdWeeksH__c> pwMain = [
            SELECT Id FROM ProdWeeksH__c
            WHERE ItemId__c = 'MAIN' AND Level__c = 0
            LIMIT 1
        ];
        if (!pwMain.isEmpty()) return pwMain[0].Id;

        ProdWeeksH__c mainRec = new ProdWeeksH__c(
            ItemId__c   = 'MAIN',
            Name        = 'PRODUCTION WEEKS',
            Level__c    = 0,
            ParentId__c = null
        );
        insert mainRec;
        return mainRec.Id;
    }

    private static Map<String, ProdWeeksH__c> loadExistingByItemId(Set<String> itemIds) {
        Map<String, ProdWeeksH__c> mapByItem = new Map<String, ProdWeeksH__c>();
        if (itemIds.isEmpty()) return mapByItem;

        for (ProdWeeksH__c r : [
            SELECT Id, ItemId__c
            FROM ProdWeeksH__c
            WHERE ItemId__c IN :itemIds
        ]) {
            mapByItem.put(r.ItemId__c, r);
        }
        return mapByItem;
    }

    private static Integer countSuccess(Database.SaveResult[] results) {
        Integer ok = 0;
        if (results == null) return ok;
        for (Database.SaveResult sr : results) if (sr.isSuccess()) ok++;
        return ok;
    }

    private static List<String> collectErrors(Database.SaveResult[] insRes, Database.SaveResult[] updRes) {
        List<String> errs = new List<String>();
        for (Database.SaveResult sr : (insRes == null ? new List<Database.SaveResult>() : insRes)) {
            if (!sr.isSuccess()) for (Database.Error e : sr.getErrors()) errs.add('Insert: ' + e.getMessage());
        }
        for (Database.SaveResult sr : (updRes == null ? new List<Database.SaveResult>() : updRes)) {
            if (!sr.isSuccess()) for (Database.Error e : sr.getErrors()) errs.add('Update: ' + e.getMessage());
        }
        return errs;
    }

    private static Boolean isFourDigitYear(String s) {
        if (String.isBlank(s)) return false;
        s = s.trim();
        if (s.length() != 4) return false;
        // перевіряємо, що всі символи — цифри
        for (Integer i = 0; i < 4; i++) {
            String ch = s.substring(i, i + 1);
            if (ch < '0' || ch > '9') return false;
        }
        return true;
    }

    /****** Clean-up - якщо треба прибити якийсь рік з календаря тижнів *****/ 
    // Підсумок клінапу
    public class DeleteSummary {
        public String year;
        public Integer weeksFound = 0, weeksDeleted = 0;
        public Integer monthsFound = 0, monthsDeleted = 0;
        public Integer yearsFound = 0, yearsDeleted = 0;
        public Boolean dryRun = true;
        public List<String> errors = new List<String>();
    }

    // Видалення ієрархії за роком (спершу Level=3 → потім 2 → потім 1).
    // yearStr очікуємо як "YYYY" (рядок, бо ParentId__c у нас текстовий foreign key).
    public static DeleteSummary deleteYear(String yearStr, Boolean dryRun) {
        DeleteSummary sum = new DeleteSummary();
        sum.year = yearStr;
        sum.dryRun = (dryRun == null ? true : dryRun);

        yearStr = (yearStr == null) ? null : yearStr.trim();
        if (!isFourDigitYear(yearStr)) {
            sum.errors.add('yearStr must be a 4-digit string like "2025". Got: ' + yearStr);
            return sum;
        }

        try {
            // Weeks (Level=3) — діти місяців формату YYYYMM, тому ParentId__c LIKE 'YYYY%'
            List<ProdWeeksH__c> weeks = [
                SELECT Id
                FROM ProdWeeksH__c
                WHERE Level__c = 3 AND ParentId__c LIKE : (yearStr + '%')
            ];
            sum.weeksFound = weeks.size();
            if (!sum.dryRun && !weeks.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(weeks, false);
                for (Database.DeleteResult r : dr) {
                    if (r.isSuccess()) sum.weeksDeleted++;
                    else for (Database.Error e : r.getErrors()) sum.errors.add('Week delete: ' + e.getMessage());
                }
            }

            // Months (Level=2) — батько це сам рік за ParentId__c='YYYY'
            List<ProdWeeksH__c> months = [
                SELECT Id
                FROM ProdWeeksH__c
                WHERE Level__c = 2 AND ParentId__c = :yearStr
            ];
            sum.monthsFound = months.size();
            if (!sum.dryRun && !months.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(months, false);
                for (Database.DeleteResult r : dr) {
                    if (r.isSuccess()) sum.monthsDeleted++;
                    else for (Database.Error e : r.getErrors()) sum.errors.add('Month delete: ' + e.getMessage());
                }
            }

            // Year (Level=1) — сам вузол року
            List<ProdWeeksH__c> years = [
                SELECT Id
                FROM ProdWeeksH__c
                WHERE Level__c = 1 AND ItemId__c = :yearStr
            ];
            sum.yearsFound = years.size();
            if (!sum.dryRun && !years.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(years, false);
                for (Database.DeleteResult r : dr) {
                    if (r.isSuccess()) sum.yearsDeleted++;
                    else for (Database.Error e : r.getErrors()) sum.errors.add('Year delete: ' + e.getMessage());
                }
            }
        } catch (Exception ex) {
            sum.errors.add('Cleanup fatal: ' + ex.getMessage());
        }
        return sum;
    }
}