public without sharing class SiteNewsController {

    @AuraEnabled
    public static NewsWrapper getNews() {
        NewsWrapper newsWrapper = new NewsWrapper();
        String language = UserUtils.getUserLanguage();

        List<News__c> mainNews = [SELECT Id, Date__c, Description_EN__c, Description_RU__c, Description_UA__c,
                                         Header_EN__c, Header_RU__c, Header_UA__c,
                                         Link_EN__c, Link_RU__c, Link_UA__c, Image__c
                                  FROM News__c 
                                  WHERE Main_News__c = true
                                  ORDER BY Date__c DESC LIMIT 1
        ];

        String query = 'SELECT Id, Date__c, Description_EN__c, Description_RU__c, Description_UA__c, ' +
                              'Header_EN__c, Header_RU__c, Header_UA__c, ' +
                              'Link_EN__c, Link_RU__c, Link_UA__c, Image__c ' +
                       'FROM News__c ';

        if(!mainNews.isEmpty()) {
            query += 'WHERE Id != \'' + mainNews.get(0).Id + '\' ORDER BY Date__c DESC LIMIT 3';
        } else {
            query += 'ORDER BY Date__c DESC LIMIT 4';
        }

        List<News__c> newsList = Database.query(query);
        Integer i = 0;
        Datetime dt;

        if(!mainNews.isEmpty()) {
            dt = mainNews.get(0).Date__c;
            newsWrapper.mainId = mainNews.get(0).Id;
            newsWrapper.mainDate = DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd.MM.yyyy');
            newsWrapper.mainHeader = language == 'uk' ? mainNews.get(0).Header_UA__c : language == 'ru' ? mainNews.get(0).Header_RU__c : mainNews.get(0).Header_EN__c;
            newsWrapper.mainDescription = language == 'uk' ? mainNews.get(0).Description_UA__c : language == 'ru' ? mainNews.get(0).Description_RU__c : mainNews.get(0).Description_EN__c;
            newsWrapper.mainLink = language == 'uk' ? mainNews.get(0).Link_UA__c : language == 'ru' ? mainNews.get(0).Link_RU__c : mainNews.get(0).Link_EN__c;
            newsWrapper.mainImage = mainNews.get(0).Image__c;
            // Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher(mainNews.get(0).Image__c);
            // String img = '';
            // while (imgMatcher.find()){                
            //     String imageTag = imgMatcher.group();
            //     img = imageTag.substringBetween(' src="', '"' );
            // }
            // newsWrapper.mainImage = img.unescapeHtml4();
        } else {
            dt = newsList.get(0).Date__c;
            newsWrapper.mainId = newsList.get(0).Id;
            newsWrapper.mainDate = DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd.MM.yyyy');
            newsWrapper.mainHeader = language == 'uk' ? newsList.get(0).Header_UA__c : language == 'ru' ? newsList.get(0).Header_RU__c : newsList.get(0).Header_EN__c;
            newsWrapper.mainDescription = language == 'uk' ? newsList.get(0).Description_UA__c : language == 'ru' ? newsList.get(0).Description_RU__c : newsList.get(0).Description_EN__c;
            newsWrapper.mainLink = language == 'uk' ? newsList.get(0).Link_UA__c : language == 'ru' ? newsList.get(0).Link_RU__c : newsList.get(0).Link_EN__c;
            newsWrapper.mainImage = newsList.get(0).Image__c;
            i++;
        }

        dt = newsList.get(i).Date__c;
        newsWrapper.Item1Date = DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd.MM.yyyy');
        newsWrapper.Item1Header = language == 'uk' ? newsList.get(i).Header_UA__c : language == 'ru' ? newsList.get(i).Header_RU__c : newsList.get(i).Header_EN__c;
        newsWrapper.Item1Link = language == 'uk' ? newsList.get(i).Link_UA__c : language == 'ru' ? newsList.get(i).Link_RU__c : newsList.get(i).Link_EN__c;
        i++;

        dt = newsList.get(i).Date__c;
        newsWrapper.Item2Date = DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd.MM.yyyy');
        newsWrapper.Item2Header = language == 'uk' ? newsList.get(i).Header_UA__c : language == 'ru' ? newsList.get(i).Header_RU__c : newsList.get(i).Header_EN__c;
        newsWrapper.Item2Link = language == 'uk' ? newsList.get(i).Link_UA__c : language == 'ru' ? newsList.get(i).Link_RU__c : newsList.get(i).Link_EN__c;
        i++;

        dt = newsList.get(i).Date__c;
        newsWrapper.Item3Date = DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd.MM.yyyy');
        newsWrapper.Item3Header = language == 'uk' ? newsList.get(i).Header_UA__c : language == 'ru' ? newsList.get(i).Header_RU__c : newsList.get(i).Header_EN__c;
        newsWrapper.Item3Link = language == 'uk' ? newsList.get(i).Link_UA__c : language == 'ru' ? newsList.get(i).Link_RU__c : newsList.get(i).Link_EN__c; 

        return newsWrapper;
    }

    public class NewsWrapper {
        @AuraEnabled public String mainId;
        @AuraEnabled public String mainDate;
        @AuraEnabled public String mainHeader;
        @AuraEnabled public String mainDescription;
        @AuraEnabled public String mainLink;
        @AuraEnabled public String Item1Date;
        @AuraEnabled public String Item1Header;
        @AuraEnabled public String Item1Link;
        @AuraEnabled public String Item2Date;
        @AuraEnabled public String Item2Header;
        @AuraEnabled public String Item2Link;
        @AuraEnabled public String Item3Date;
        @AuraEnabled public String Item3Header;
        @AuraEnabled public String Item3Link;
        @AuraEnabled public String mainImage;
    }
}