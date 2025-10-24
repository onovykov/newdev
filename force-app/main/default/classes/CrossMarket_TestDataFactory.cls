@IsTest
public class CrossMarket_TestDataFactory {

    // --- JobTitle helper через SysUtils ---
    private static String jobTitleApi(String jobTitleLabel) {
        Map<String,String> labelToValue = SysUtils.getPicklistFieldMap('User', 'JobTitle__c', false);
        return labelToValue.get(jobTitleLabel);
    }

    // ========= Picklist helpers (АКТИВНІ значення на КОНКРЕТНОМУ полі) =========

    // 1) Перше АКТИВНЕ API-значення контролюючого поля User.BusinesDivision__c
    public static String firstActiveUserBusinessDivisionApi() {
        Schema.DescribeFieldResult dfr =
            Schema.getGlobalDescribe().get('User')
                  .getDescribe().fields.getMap().get('BusinesDivision__c').getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) return pe.getValue();
        }
        return null;
    }

    // 2) Перше АКТИВНЕ API-значення залежного поля User.SalesDivision__c
    public static String firstActiveUserSalesDivisionApi() {
        Schema.DescribeFieldResult dfr =
            Schema.getGlobalDescribe().get('User')
                  .getDescribe().fields.getMap().get('SalesDivision__c').getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) return pe.getValue(); // напр., '00002'
        }
        return null;
    }

    // 3) Перше АКТИВНЕ API зі списку Opp.CrossMarketSegment__c, яке НЕ дорівнює avoidApi
    public static String firstActiveOppSegmentApiNotEqual(String avoidApi) {
        Schema.DescribeFieldResult dfr =
            Schema.getGlobalDescribe().get('Opportunity')
                  .getDescribe().fields.getMap().get('CrossMarketSegment__c').getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive() && pe.getValue() != avoidApi) {
                return pe.getValue();
            }
        }
        return null;
    }

    // ========= Profiles =========
    private static Id profileId(Boolean isAdmin){
        return [
            SELECT Id FROM Profile
            WHERE Name = : (isAdmin ? 'System Administrator' : 'Standard User')
            LIMIT 1
        ].Id;
    }

    // ========= Users =========
    // ВАЖЛИВО: спочатку ставимо BusinesDivision__c (контролер), потім SalesDivision__c (dependent)
    public static User makeUser(String alias, String email, String jobTitleLabel, String salesDivisionApi, Boolean isAdmin) {
        String jtApi  = jobTitleApi(jobTitleLabel);
        String bdApi  = firstActiveUserBusinessDivisionApi();
        System.assertNotEquals(null, bdApi, 'User.BusinesDivision__c має мати хоч одне активне значення');

        User u = new User(
            FirstName='T', LastName=alias, Alias=alias.left(8),
            Email=email,
            Username=email + '.' + System.currentTimeMillis() + '@test.org',
            TimeZoneSidKey='Europe/Warsaw', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            ProfileId=profileId(isAdmin),
            IsActive=true,
            JobTitle__c         = jtApi,   // picklist API (User)
            BusinesDivision__c = bdApi,   // 🔸 контрольне поле — СПОЧАТКУ!
            SalesDivision__c    = salesDivisionApi // 🔸 dependent picklist — ПІСЛЯ контролера
        );
        insert u;
        return u;
    }

    // ========= Opportunities =========
    public static Opportunity makeOpp(
        User owner,
        String name,
        Date closeDt,
        String stage,
        Id crossMgrId,
        String mainMarketSegApi,   // Opp.MarketSegment__c (API)
        String crossMarketSegApi,  // Opp.CrossMarketSegment__c (API)
        Decimal crossShare
    ) {
        Opportunity o = new Opportunity(
            Name = name,
            CloseDate = closeDt,
            StageName = stage,
            OwnerId = owner.Id,
            MarketSegment__c      = mainMarketSegApi,   // головний сегмент
            CrossMarketSegment__c = crossMarketSegApi,  // крос-сегмент (інший)
            CrossMarketManager__c = crossMgrId,
            CrossMarketShare__c   = crossShare
        );
        insert o;
        return o;
    }
}