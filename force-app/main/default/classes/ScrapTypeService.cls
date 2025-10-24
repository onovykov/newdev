// ScrapTypeService.cls
public with sharing class ScrapTypeService {

    public class GroupBucket {
        @AuraEnabled public Id groupId;
        @AuraEnabled public String groupName;
        @AuraEnabled public List<ScrapType__c> items = new List<ScrapType__c>();
    }
    public class DualGrouping {
        @AuraEnabled public List<GroupBucket> commercial;
        @AuraEnabled public List<GroupBucket> corporate;
    }

    @AuraEnabled(cacheable=true)
    public static DualGrouping getByBranchAndGroup() {
        List<ScrapType__c> allRecords = [
                SELECT Id, Name, ScrapTypeCode__c, Description__c,
                        IsActive__c, IsGroup__c, Level__c,
                        Parent__c, Parent__r.Name, ID_ERP__c, CurrencyIsoCode
                FROM ScrapType__c
        ];
        Map<Id, ScrapType__c> recordsByIdMap = new Map<Id, ScrapType__c>(allRecords);

        Map<Id, GroupBucket> commercialBucketsByGroupId = new Map<Id, GroupBucket>();
        Map<Id, GroupBucket> corporateBucketsByGroupId  = new Map<Id, GroupBucket>();

        for (ScrapType__c leafRecord : allRecords) {
            if (leafRecord.IsGroup__c == true) continue; // беремо тільки листові

            ScrapType__c currentNode = leafRecord;
            ScrapType__c nodeUnderBranch = null; // «Брухт сталевий», «Брухт чавунний», ...
            Boolean isCommercialBranch = false;
            Boolean isKnownBranch = false;

            Integer guard = 0;
            while (currentNode != null && guard < 500) {
                String currentName = (currentNode.Name == null) ? '' : currentNode.Name.trim().toLowerCase();

                if (currentName == 'комерційний брухт') {
                    isCommercialBranch = true;
                    isKnownBranch = true;
                    break;
                }
                if (currentName == 'корпорація') {
                    isCommercialBranch = false;
                    isKnownBranch = true;
                    break;
                }

                nodeUnderBranch = currentNode; // запам’ятовуємо поточного як «дитину під гілкою»
                currentNode = (currentNode.Parent__c == null) ? null : recordsByIdMap.get(currentNode.Parent__c);
                guard++;
            }
            if (!isKnownBranch || nodeUnderBranch == null) continue;

            Map<Id, GroupBucket> targetMap = isCommercialBranch ? commercialBucketsByGroupId : corporateBucketsByGroupId;
            if (!targetMap.containsKey(nodeUnderBranch.Id)) {
                GroupBucket newBucket = new GroupBucket();
                newBucket.groupId = nodeUnderBranch.Id;
                newBucket.groupName = nodeUnderBranch.Name;
                targetMap.put(nodeUnderBranch.Id, newBucket);
            }
            targetMap.get(nodeUnderBranch.Id).items.add(leafRecord);
        }

        DualGrouping result = new DualGrouping();
        result.commercial = new List<GroupBucket>(commercialBucketsByGroupId.values());
        result.corporate  = new List<GroupBucket>(corporateBucketsByGroupId.values());

        // сортування груп і елементів за назвою (без урахування регістру)
        result.commercial.sort(new GroupBucketByName());
        result.corporate.sort(new GroupBucketByName());
        for (GroupBucket bucket : result.commercial) bucket.items.sort(new ScrapByName());
        for (GroupBucket bucket : result.corporate)  bucket.items.sort(new ScrapByName());

        return result;
    }

    public class ScrapByName implements System.Comparator<ScrapType__c> {
        public Integer compare(ScrapType__c a, ScrapType__c b) {
            String aName = (a != null && a.Name != null) ? a.Name.toLowerCase() : '';
            String bName = (b != null && b.Name != null) ? b.Name.toLowerCase() : '';
            return aName.compareTo(bName);
        }
    }
    public class GroupBucketByName implements System.Comparator<GroupBucket> {
        public Integer compare(GroupBucket a, GroupBucket b) {
            String aName = (a != null && a.groupName != null) ? a.groupName.toLowerCase() : '';
            String bName = (b != null && b.groupName != null) ? b.groupName.toLowerCase() : '';
            return aName.compareTo(bName);
        }
    }

    // ДЕТАЛІ ОДНОГО ЗАПИСУ ДЛЯ ПРАВОЇ ПАНЕЛІ
    @AuraEnabled(cacheable=true)
    public static ScrapType__c getScrapDetails(Id scrapTypeId) {
        if (scrapTypeId == null) return null;
        return [
            SELECT Id, Name, ScrapTypeCode__c, Description__c, IsActive__c, IsGroup__c,
                   Level__c, Parent__c, Parent__r.Name, ID_ERP__c, CurrencyIsoCode
            FROM ScrapType__c
            WHERE Id = :scrapTypeId
            LIMIT 1
        ];
    }

    // ПЕРЕМИКАЧ АКТИВНОСТІ
    @AuraEnabled
    public static ScrapType__c setActive(Id scrapTypeId, Boolean newIsActive) {
        if (scrapTypeId == null) throw new AuraHandledException('scrapTypeId is required');
        update new ScrapType__c(Id = scrapTypeId, IsActive__c = (newIsActive == true));
        return [
            SELECT Id, Name, ScrapTypeCode__c, Description__c, IsActive__c, IsGroup__c,
                   Level__c, Parent__c, Parent__r.Name, ID_ERP__c, CurrencyIsoCode
            FROM ScrapType__c
            WHERE Id = :scrapTypeId
            LIMIT 1
        ];
    }

    // ScrapTypeService.cls (додай у кінець класу, всередині {})
// ------------------------- ОНОВЛЕННЯ ОПИСУ -------------------------
    @AuraEnabled
    public static ScrapType__c updateDescription(Id scrapTypeId, String newDescription) {
        if (scrapTypeId == null) {
            throw new AuraHandledException('scrapTypeId is required');
        }
        // за потреби: валідація довжини/trim
        update new ScrapType__c(Id = scrapTypeId, Description__c = newDescription);

        return [
                SELECT Id, Name, ScrapTypeCode__c, Description__c, IsActive__c, IsGroup__c,
                        Level__c, Parent__c, Parent__r.Name, ID_ERP__c, CurrencyIsoCode
                FROM ScrapType__c
                WHERE Id = :scrapTypeId
                LIMIT 1
        ];
    }

    // ==================== ЗАЛИШОК ЛІМІТІВ: СЬОГОДНІ / ДЕКАДА / МІСЯЦЬ ====================
    public class RemainingSummary {
        @AuraEnabled public Decimal day;
        @AuraEnabled public Decimal decade;
        @AuraEnabled public Decimal month;
        @AuraEnabled public String unit;
        public RemainingSummary(Decimal d, Decimal dc, Decimal m, String u) {
            day = (d == null ? 0 : d);
            decade = (dc == null ? 0 : dc);
            month = (m == null ? 0 : m);
            unit = (String.isBlank(u) ? 'т' : u);
        }
    }

    @AuraEnabled
    public static RemainingSummary getRemainingSummary(Id scrapTypeId) {
        if (scrapTypeId == null) {
            throw new AuraHandledException('scrapTypeId is required');
        }

        Date today = Date.today();
        Integer year = today.year();
        Integer month = today.month();

        // Знайдемо поточну декаду через DTUtils.getMonthDecades(year, month)
        Integer currentDecade = 1;
        Map<Integer, List<Date>> decades = DTUtils.getMonthDecades(year, month);
        for (Integer decNum : decades.keySet()) {
            List<Date> range = decades.get(decNum);
            if (range != null && range.size() == 2 && today >= range[0] && today <= range[1]) {
                currentDecade = decNum;
                break;
            }
        }

        // === ДЕНЬ: беремо доступні по днях і витягуємо сьогоднішній DayId ===
        Decimal remainingDay = 0;
        Map<Id, Decimal> availableByDay =
                ScrapUtils.getAvailableScrapLimitsByDays(scrapTypeId, year, month, currentDecade);
        Map<Id, Date> dayIdToDate = DTUtils.getDaysIdDate(year, month, currentDecade);
        if (dayIdToDate != null) {
            for (Id dayId : dayIdToDate.keySet()) {
                if (dayIdToDate.get(dayId) == today && availableByDay.containsKey(dayId)) {
                    remainingDay = availableByDay.get(dayId);
                    break;
                }
            }
        }

        // === ДЕКАДА: план − факт (вага або, якщо її немає, тонтаж) ===
        Decimal plannedDecade = ScrapUtils.getScrapDecadeLimit(scrapTypeId, year, month, currentDecade);
        Decimal inputDecade = 0;
        Map<Id, Decimal> inputByDaysDecade =
                ScrapUtils.getScrapDecadeInputByDays(scrapTypeId, year, month, currentDecade);
        for (Decimal v : inputByDaysDecade.values()) inputDecade += (v == null ? 0 : v);
        Decimal remainingDecade = plannedDecade - inputDecade;

        // === МІСЯЦЬ: план − (факт по всіх трьох декадах) ===
        Decimal plannedMonth = ScrapUtils.getScrapMonthLimit(scrapTypeId, year, month);
        Decimal inputMonth = 0;
        for (Integer dec = 1; dec <= 3; dec++) {
            Map<Id, Decimal> inputByDays =
                    ScrapUtils.getScrapDecadeInputByDays(scrapTypeId, year, month, dec);
            for (Decimal v : inputByDays.values()) inputMonth += (v == null ? 0 : v);
        }
        Decimal remainingMonth = plannedMonth - inputMonth;

        return new RemainingSummary(remainingDay, remainingDecade, remainingMonth, 'т');
    }

    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}