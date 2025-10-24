public class RouteQuotesHierarchyQueueable implements Queueable {

    private Boolean IsUpdate;
    private static final Date StartDate = Date.today().toStartOfMonth();
    private static final Date EndDate = Date.today().toStartOfMonth().addMonths(6);
    private static final String StartDateString = Date.today().year() + '-' + String.valueOf(Date.today().month()).leftPad(2, '0') + '-01';
    private final static Map<String, String> MarkenSegmentMap = new Map<String, String> {
        '00002' => 'MENA',
        '00001' => 'Americas',
        '00004' => 'Europe',
        '00010' => 'CIS',
        '00011' => 'Ukraine',
        '00006' => 'KLW',
        '00100' => 'Steel',
        '00016' => 'Customs Union',
        '00005' => 'IPS',
        '00020' => 'ETA',
        '00021' => 'Machinery',
        '00008' => 'Передел',
        '00007' => 'Оседание',
        '00012' => 'Сплавы',
        '00013' => 'NMD'
    };

    public RouteQuotesHierarchyQueueable(Boolean isUpdate) {
        this.IsUpdate = isUpdate;
    }

    public void execute(QueueableContext context) {
        Map<String, RouteQuotesH__c> routeQuotesHierarchyMap = checkAndUpdateHierarchy();
        Map<String, List<RouteQuotesRelated__c>> idsToRouteQuoteRelatedMap = upsertRouteQuotesRelated(routeQuotesHierarchyMap);
        createQuoteStructureDetails(idsToRouteQuoteRelatedMap, routeQuotesHierarchyMap);
    }

    private Map<String, RouteQuotesH__c> checkAndUpdateHierarchy() {
        Map<String, RouteQuotesH__c> routeQuotesHierarchyMap = getRouteQuotesHierarchyMap();
        if(routeQuotesHierarchyMap.get('parent') == null) {
            RouteQuotesH__c allRoutesQuotesParent = new RouteQuotesH__c(Name = 'ALL ROUTES QUOTES', Level__c = 0);
            insert allRoutesQuotesParent;
            routeQuotesHierarchyMap.put('parent', allRoutesQuotesParent);
        }

        String queryDatesList = 'SELECT DateBegin__c, DateEnd__c FROM Route_Quota__c';
        queryDatesList += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        queryDatesList += ' GROUP BY DateBegin__c, DateEnd__c';
        List<AggregateResult> routeQuotesDatesList = Database.query(queryDatesList);

        checkDateHierarchy(routeQuotesDatesList, routeQuotesHierarchyMap);

        String querySegmentsList = 'SELECT DateBegin__c, DateEnd__c, MarketSegment__c FROM Route_Quota__c';
        querySegmentsList += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        querySegmentsList += ' GROUP BY DateBegin__c, DateEnd__c, MarketSegment__c';
        List<AggregateResult> routeQuotesSegmentList = Database.query(querySegmentsList);

        checkSegmentHierarchy(routeQuotesSegmentList, routeQuotesHierarchyMap);

        String queryShopsList = 'SELECT DateBegin__c, DateEnd__c, MarketSegment__c, Route__r.Shop__c Shop, Route__r.Shop__r.Name shopName FROM Route_Quota__c';
        queryShopsList += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        queryShopsList += ' GROUP BY DateBegin__c, DateEnd__c, MarketSegment__c, Route__r.Shop__c, Route__r.Shop__r.Name ORDER BY Route__r.Shop__r.Name';
        List<AggregateResult> routeQuotesShopList = Database.query(queryShopsList);

        checkShopHierarchy(routeQuotesShopList, routeQuotesHierarchyMap);

        String queryFamiliesList = 'SELECT DateBegin__c, DateEnd__c, MarketSegment__c, Route__r.Shop__c Shop, Name, SUM(Quote_t__c) SumQuoteT, ' +
                                   'SUM(Quote_pcs__c) SumQuotePcs, SUM(Budget_t__c) SumBudgetT, SUM(Budget_pcs__c) SumBudgetPcs, SUM(Margin__c) SumMargin ' +
                                   'FROM Route_Quota__c';
        queryFamiliesList += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        queryFamiliesList += ' GROUP BY DateBegin__c, DateEnd__c, MarketSegment__c, Route__r.Shop__c, Name ORDER BY Name';
        List<AggregateResult> routeQuotesFamilyList = Database.query(queryFamiliesList);

        upsertFamilyHierarchy(routeQuotesFamilyList, routeQuotesHierarchyMap);

        return routeQuotesHierarchyMap;
    }

    private Map<String, List<RouteQuotesRelated__c>> upsertRouteQuotesRelated(Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        Map<String, Id> routeQuotesRelatedMap = getRouteQuotesRelatedMap();
        Map<String, List<RouteQuotesRelated__c>> idsToRouteQuoteRelatedMap = new Map<String, List<RouteQuotesRelated__c>>();
        List<RouteQuotesRelated__c> routeQuoteRelatedList = new List<RouteQuotesRelated__c>();

        String queryQBAFamilies = 'SELECT Id, QuotesBudgetAll__c, QuotesBudgetAll__r.Budget_pcs__c, QuotesBudgetAll__r.Budget_t__c, QuotesBudgetAll__r.DateBegin__c, ' + 
                                             'QuotesBudgetAll__r.DateEnd__c, QuotesBudgetAll__r.ID_ERP__c, QuotesBudgetAll__r.Margin__c, QuotesBudgetAll__r.MarketSegment__c, ' + 
                                             'QuotesBudgetAll__r.Quote_pcs__c, QuotesBudgetAll__r.Quote_t__c, QuotesBudgetAll__r.Route__c, QuotesBudgetAll__r.Name, ' + 
                                             'Family__r.Name, QuotesBudgetAll__r.Route__r.Shop__c ' + 
                                  'FROM QBA_Families__c';
        queryQBAFamilies += IsUpdate ? ' WHERE QuotesBudgetAll__r.DateBegin__c >= ' + StartDateString : '';
        List<QBA_Families__c> routeQuoteFamilyList = Database.query(queryQBAFamilies);

        for(QBA_Families__c routeQuoteFamily : routeQuoteFamilyList) {
            RouteQuotesRelated__c routeQuoteRelated = new RouteQuotesRelated__c();
            Date dateBegin = routeQuoteFamily.QuotesBudgetAll__r.DateBegin__c;
            String marketSegment = routeQuoteFamily.QuotesBudgetAll__r.MarketSegment__c;
            String shop = routeQuoteFamily.QuotesBudgetAll__r.Route__r.Shop__c;
            String family = routeQuoteFamily.QuotesBudgetAll__r.Name;
            if(routeQuotesRelatedMap.get(routeQuoteFamily.Family__r.Name + '' + routeQuoteFamily.QuotesBudgetAll__r.ID_ERP__c) != null) {
                routeQuoteRelated.Id = routeQuotesRelatedMap.get(routeQuoteFamily.Family__r.Name + '' + routeQuoteFamily.QuotesBudgetAll__r.ID_ERP__c);
            } else {
                routeQuoteRelated.RoutesQuotesH__c = routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shop + '' + family).Id;
            }
            routeQuoteRelated.Name = routeQuoteFamily.Family__r.Name;
            routeQuoteRelated.RouteQuote__c = routeQuoteFamily.QuotesBudgetAll__c;
            routeQuoteRelated.Route_Quote_Name__c = family;
            routeQuoteRelated.Route__c = routeQuoteFamily.QuotesBudgetAll__r.Route__c;
            routeQuoteRelated.DateBegin__c = dateBegin;
            routeQuoteRelated.DateEnd__c = routeQuoteFamily.QuotesBudgetAll__r.DateEnd__c;
            routeQuoteRelated.ID_ERP__c = routeQuoteFamily.QuotesBudgetAll__r.ID_ERP__c;
            routeQuoteRelated.MarketSegment__c = marketSegment;
            routeQuoteRelated.Shop__c = shop;
            routeQuoteRelated.Budget_pcs__c = routeQuoteFamily.QuotesBudgetAll__r.Budget_pcs__c;
            routeQuoteRelated.Budget_t__c = routeQuoteFamily.QuotesBudgetAll__r.Budget_t__c;
            routeQuoteRelated.Quote_pcs__c = routeQuoteFamily.QuotesBudgetAll__r.Quote_pcs__c;
            routeQuoteRelated.Quote_t__c = routeQuoteFamily.QuotesBudgetAll__r.Quote_t__c;
            routeQuoteRelated.Margin__c = routeQuoteFamily.QuotesBudgetAll__r.Margin__c;

            String key = dateBegin.format() + '' + marketSegment + '' + routeQuoteFamily.Family__r.Name;
            if(idsToRouteQuoteRelatedMap.get(key) == null) {
                idsToRouteQuoteRelatedMap.put(key, new List<RouteQuotesRelated__c>());
            }
            idsToRouteQuoteRelatedMap.get(key).add(routeQuoteRelated);
            routeQuoteRelatedList.add(routeQuoteRelated);
        }

        upsert routeQuoteRelatedList;
        return idsToRouteQuoteRelatedMap;
    }

    private void createQuoteStructureDetails(Map<String, List<RouteQuotesRelated__c>> idsToRouteQuoteRelatedMap, Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        Map<String, Id> quoteStructureDetailMap = getQuoteStructureDetailMap();
        List<QuoteStructureDetail__c> quoteStructDetailToUsertList = new List<QuoteStructureDetail__c>();
        Map<String, AggregateResult> quoteRouteSumMap = new Map<String, AggregateResult>();

        String queryquotesStructures = 'SELECT Id, DateBegin__c, DateEnd__c, MarketSegment__c, Family__c, Family__r.Name, Family__r.FamilyType__c, ID_ERP__c, ' + 
                                              'Manager__c, Group3__c, Region__c, Percent__c ' + 
                                       'FROM QuotesStructure__c';
        queryquotesStructures += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        List<QuotesStructure__c> quotesStructureList = Database.query(queryquotesStructures);

        String queryquotesRouteSums = 'SELECT Name, MarketSegment__c, DateBegin__c, SUM(Quote_t__c) SumQuoteT, SUM(Quote_pcs__c) SumQuotePcs, ' + 
                                             'SUM(Budget_t__c) SumBudgetT, SUM(Budget_pcs__c) SumBudgetPcs, SUM(Margin__c) SumMargin ' + 
                                       'FROM RouteQuotesRelated__c';
        queryquotesRouteSums += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        queryquotesRouteSums += ' GROUP BY Name, MarketSegment__c, DateBegin__c';
        List<AggregateResult> quoteRouteSumList = Database.query(queryquotesRouteSums);

        for(AggregateResult quoteRouteSum : quoteRouteSumList) {
            Date dateBegin = (Date)quoteRouteSum.get('DateBegin__c');
            String marketSegment = (String)quoteRouteSum.get('MarketSegment__c');
            String family = (String)quoteRouteSum.get('Name');
            quoteRouteSumMap.put(dateBegin.format() + '' + marketSegment + '' + family, quoteRouteSum);
        }

        for(QuotesStructure__c quotesStructure : quotesStructureList) {
            String key = quotesStructure.DateBegin__c.format() + '' + quotesStructure.MarketSegment__c + '' + quotesStructure.Family__r.Name; 
            List<RouteQuotesRelated__c> idsToRouteQuoteRelatedList = idsToRouteQuoteRelatedMap.get(key);
            AggregateResult quoteRouteSum = quoteRouteSumMap.get(key);
            Set<String> structQuotaAndShop = new Set<String>();

            for(RouteQuotesRelated__c routeQuoteRelated : idsToRouteQuoteRelatedList) {
                if(structQuotaAndShop.contains(routeQuoteRelated.Shop__c + '' + quotesStructure.ID_ERP__c + '' + routeQuoteRelated.Route_Quote_Name__c)) {
                    continue;
                } else {
                    structQuotaAndShop.add(routeQuoteRelated.Shop__c + '' + quotesStructure.ID_ERP__c + '' + routeQuoteRelated.Route_Quote_Name__c);
                }

                String keyForHierarchy = quotesStructure.DateBegin__c.format() + '' + quotesStructure.MarketSegment__c + '' + routeQuoteRelated.Shop__c + '' + routeQuoteRelated.Route_Quote_Name__c;
                QuoteStructureDetail__c quoteStructureDetail = new QuoteStructureDetail__c();
                if(quoteStructureDetailMap.get(quotesStructure.Family__r.Name + '' + quotesStructure.ID_ERP__c) != null) {
                    quoteStructureDetail.Id = quoteStructureDetailMap.get(quotesStructure.Family__r.Name + '' + quotesStructure.ID_ERP__c);
                } else {
                    quoteStructureDetail.RoutesQuotesH__c = routeQuotesHierarchyMap.get(keyForHierarchy).Id;
                }
                quoteStructureDetail.DateBegin__c = quotesStructure.DateBegin__c;
                quoteStructureDetail.DateEnd__c = quotesStructure.DateEnd__c;
                quoteStructureDetail.ID_ERP__c = quotesStructure.ID_ERP__c;
                quoteStructureDetail.MarketSegment__c = quotesStructure.MarketSegment__c;
                quoteStructureDetail.Manager__c = quotesStructure.Manager__c;
                quoteStructureDetail.Family__c = quotesStructure.Family__c;
                quoteStructureDetail.Group3__c = quotesStructure.Group3__c;
                quoteStructureDetail.Region__c = quotesStructure.Region__c;
                quoteStructureDetail.Name  = quotesStructure.Family__r.Name;
                quoteStructureDetail.Percent__c = quotesStructure.Percent__c;
                quoteStructureDetail.FamilyType__c = quotesStructure.Family__r.FamilyType__c;
                quoteStructureDetail.QuoteStruct__c = quotesStructure.Id;
                quoteStructureDetail.Quote_t__c = (Decimal)quoteRouteSum.get('SumQuoteT') * quotesStructure.Percent__c * 0.01;
                quoteStructureDetail.Quote_pcs__c = (Decimal)quoteRouteSum.get('SumQuotePcs') * quotesStructure.Percent__c * 0.01;
                quoteStructureDetail.Budget_t__c = (Decimal)quoteRouteSum.get('SumBudgetT') * quotesStructure.Percent__c * 0.01;
                quoteStructureDetail.Budget_pcs__c = (Decimal)quoteRouteSum.get('SumBudgetPcs') * quotesStructure.Percent__c * 0.01;
                quoteStructureDetail.Margin__c = (Decimal)quoteRouteSum.get('SumMargin') * quotesStructure.Percent__c * 0.01;
                quoteStructDetailToUsertList.add(quoteStructureDetail);
            }
        }

        if(Test.isRunningTest()) {
            upsert quoteStructDetailToUsertList;
        } else {
            ID jobID = System.enqueueJob(new QuoteStructureDetailInsert(quoteStructDetailToUsertList));
        }
    }

    private void checkDateHierarchy(List<AggregateResult> routeQuotesList, Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        List<RouteQuotesH__c> routeQuotesHierarchyToInsertList = new List<RouteQuotesH__c>();

        for(AggregateResult routeQuote : routeQuotesList) {
            Date dateBegin = (Date)routeQuote.get('DateBegin__c');
            if(routeQuotesHierarchyMap.get(dateBegin.format()) == null) {
                Date dateEnd = (Date)routeQuote.get('DateEnd__c');
                DateTime dateTimeBegin = DateTime.newInstance(dateBegin.year(), dateBegin.month(), dateBegin.day(), 0, 0, 0);
    
                RouteQuotesH__c dateHierarchy = new RouteQuotesH__c();
                dateHierarchy.DateBegin__c = dateBegin;
                dateHierarchy.DateEnd__c = dateEnd;
                dateHierarchy.Name = dateTimeBegin.format('MMMM') + ' ' + dateBegin.year();
                dateHierarchy.Level__c = 1;
    
                if(dateBegin >= StartDate && dateEnd <= EndDate) {
                    dateHierarchy.Parent__c = routeQuotesHierarchyMap.get('parent').Id;
                } else {
                    dateHierarchy.ParentId__c = routeQuotesHierarchyMap.get('parent').Id;
                }

                routeQuotesHierarchyMap.put(dateBegin.format(), dateHierarchy);
                routeQuotesHierarchyToInsertList.add(dateHierarchy);
            }
        }
            
        if(!routeQuotesHierarchyToInsertList.isEmpty()) {
            insert routeQuotesHierarchyToInsertList;
        }
    }

    private void checkSegmentHierarchy(List<AggregateResult> routeQuotesList, Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        List<RouteQuotesH__c> routeQuotesHierarchyToInsertList = new List<RouteQuotesH__c>();

        for(AggregateResult routeQuote : routeQuotesList) {
            Date dateBegin = (Date)routeQuote.get('DateBegin__c');
            String marketSegment = (String)routeQuote.get('MarketSegment__c');
            if(routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment) == null) {
                RouteQuotesH__c segmentHierarchy = new RouteQuotesH__c();
                segmentHierarchy.DateBegin__c = dateBegin;
                segmentHierarchy.DateEnd__c = (Date)routeQuote.get('DateEnd__c');
                segmentHierarchy.MarketSegment__c = marketSegment;
                segmentHierarchy.Name = MarkenSegmentMap.get(marketSegment) != null ? MarkenSegmentMap.get(marketSegment) : marketSegment;
                segmentHierarchy.Level__c = 2;
                segmentHierarchy.Parent__c = routeQuotesHierarchyMap.get(dateBegin.format()).Id;

                routeQuotesHierarchyMap.put(dateBegin.format() + '' + marketSegment, segmentHierarchy);
                routeQuotesHierarchyToInsertList.add(segmentHierarchy);
            }
        }

        if(!routeQuotesHierarchyToInsertList.isEmpty()) {
            insert routeQuotesHierarchyToInsertList;
        }
    }

    private void checkShopHierarchy(List<AggregateResult> routeQuotesList, Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        System.debug('routeQuotesHierarchyMap' + routeQuotesHierarchyMap);
        List<RouteQuotesH__c> routeQuotesHierarchyToInsertList = new List<RouteQuotesH__c>();

        for(AggregateResult routeQuote : routeQuotesList) {
            Date dateBegin = (Date)routeQuote.get('DateBegin__c');
            String marketSegment = (String)routeQuote.get('MarketSegment__c');
            String shopId = (String)routeQuote.get('Shop');
            System.debug('key' + dateBegin.format() + '' + marketSegment + '' + shopId);
            System.debug('map result' + routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shopId));
            if(routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shopId) == null) {
                RouteQuotesH__c shopHierarchy = new RouteQuotesH__c();
                shopHierarchy.DateBegin__c = dateBegin;
                shopHierarchy.DateEnd__c = (Date)routeQuote.get('DateEnd__c');
                shopHierarchy.MarketSegment__c = marketSegment;
                shopHierarchy.Name = (String)routeQuote.get('shopName');
                shopHierarchy.Shop__c = shopId;
                shopHierarchy.Level__c = 3;
                shopHierarchy.Parent__c = routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment).Id;

                routeQuotesHierarchyMap.put(dateBegin.format() + '' + marketSegment + '' + shopId, shopHierarchy);
                routeQuotesHierarchyToInsertList.add(shopHierarchy);
            }
        }

        if(!routeQuotesHierarchyToInsertList.isEmpty()) {
            insert routeQuotesHierarchyToInsertList;
        }
    }

    private void upsertFamilyHierarchy(List<AggregateResult> routeQuotesList, Map<String, RouteQuotesH__c> routeQuotesHierarchyMap) {
        List<RouteQuotesH__c> routeQuotesHierarchyToUpsertList = new List<RouteQuotesH__c>();

        for(AggregateResult routeQuote : routeQuotesList) {
            Date dateBegin = (Date)routeQuote.get('DateBegin__c');
            String marketSegment = (String)routeQuote.get('MarketSegment__c');
            String shopId = (String)routeQuote.get('Shop');
            String family = (String)routeQuote.get('Name');
            RouteQuotesH__c familyHierarchy = new RouteQuotesH__c();
            if(routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shopId + '' + family) == null) {
                familyHierarchy.DateBegin__c = dateBegin;
                familyHierarchy.DateEnd__c = (Date)routeQuote.get('DateEnd__c');
                familyHierarchy.MarketSegment__c = marketSegment;
                familyHierarchy.Name = family;
                familyHierarchy.Level__c = 4;
                familyHierarchy.Shop__c = shopId;
                familyHierarchy.Parent__c = routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shopId).Id;
                routeQuotesHierarchyMap.put(dateBegin.format() + '' + marketSegment + '' + shopId + '' + family, familyHierarchy);
            } else {
                familyHierarchy.Id = routeQuotesHierarchyMap.get(dateBegin.format() + '' + marketSegment + '' + shopId + '' + family).Id;
            }

            familyHierarchy.Quote_t__c = (Decimal)routeQuote.get('SumQuoteT');
            familyHierarchy.Quote_pcs__c = (Decimal)routeQuote.get('SumQuotePcs');
            familyHierarchy.Budget_t__c = (Decimal)routeQuote.get('SumBudgetT');
            familyHierarchy.Budget_pcs__c = (Decimal)routeQuote.get('SumBudgetPcs');
            familyHierarchy.Margin__c = (Decimal)routeQuote.get('SumMargin');
            routeQuotesHierarchyToUpsertList.add(familyHierarchy);
        }

        upsert routeQuotesHierarchyToUpsertList;
    }

    private Map<String, RouteQuotesH__c> getRouteQuotesHierarchyMap() {
        Map<String, RouteQuotesH__c> routeQuotesHierarchyMap = new Map<String, RouteQuotesH__c>();
        String query = 'SELECT Id, Name, Level__c, DateBegin__c, MarketSegment__c, Shop__c FROM RouteQuotesH__c';
        query += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString + ' OR Level__c = 0' : '';
        List<RouteQuotesH__c> routeQuotesHList = Database.query(query);

        for(RouteQuotesH__c routeQuotesH : routeQuotesHList) {
            Integer level = Integer.valueOf(routeQuotesH.Level__c);
            switch on level {
                when 0 {
                    routeQuotesHierarchyMap.put('parent', routeQuotesH);
                } when 1 {
                    routeQuotesHierarchyMap.put(routeQuotesH.DateBegin__c.format(), routeQuotesH);
                } when 2 {
                    routeQuotesHierarchyMap.put(routeQuotesH.DateBegin__c.format() + '' + routeQuotesH.MarketSegment__c, routeQuotesH);
                } when 3 {
                    routeQuotesHierarchyMap.put(routeQuotesH.DateBegin__c.format() + '' + routeQuotesH.MarketSegment__c + '' + routeQuotesH.Name, routeQuotesH);
                } when else {
                    routeQuotesHierarchyMap.put(routeQuotesH.DateBegin__c.format() + '' + routeQuotesH.MarketSegment__c + '' + routeQuotesH.Shop__c + '' + routeQuotesH.Name, routeQuotesH);
                }
            }
        }

        return routeQuotesHierarchyMap;
    }

    private Map<String, Id> getRouteQuotesRelatedMap() {
        Map<String, Id> routeQuotesRelatedMap = new Map<String, Id>();
        String query = 'SELECT Id, Name, ID_ERP__c FROM RouteQuotesRelated__c';
        query += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        List<RouteQuotesRelated__c> routeQuotesRelatedList = Database.query(query);

        for(RouteQuotesRelated__c routeQuotesRelated : routeQuotesRelatedList) {
            routeQuotesRelatedMap.put(routeQuotesRelated.name + '' + routeQuotesRelated.ID_ERP__c, routeQuotesRelated.Id);
        }

        return routeQuotesRelatedMap;
    }

    private Map<String, Id> getQuoteStructureDetailMap() {
        Map<String, Id> quoteStructureDetailMap = new Map<String, Id>();
        String query = 'SELECT Id, Name, ID_ERP__c, Family__r.Name FROM QuoteStructureDetail__c';
        query += IsUpdate ? ' WHERE DateBegin__c >= ' + StartDateString : '';
        List<QuoteStructureDetail__c> quoteStructureDetailList = Database.query(query);

        for(QuoteStructureDetail__c quoteStructureDetail : quoteStructureDetailList) {
            String key = quoteStructureDetail.Name + '' + quoteStructureDetail.ID_ERP__c;
            quoteStructureDetailMap.put(key, quoteStructureDetail.Id);
        }

        return quoteStructureDetailMap;
    }
}