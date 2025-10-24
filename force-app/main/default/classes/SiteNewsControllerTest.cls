@isTest
private class SiteNewsControllerTest {
    @testSetup
    static void setupTestData() {
        News__c mainNews = new News__c(
            Date__c = Date.today(),
            Description_EN__c = 'Main News Description EN',
            Description_RU__c = 'Main News Description RU',
            Description_UA__c = 'Main News Description UA',
            Header_EN__c = 'Main News Header EN',
            Header_RU__c = 'Main News Header RU',
            Header_UA__c = 'Main News Header UA',
            Link_EN__c = 'https://mainnews.com/en',
            Link_RU__c = 'https://mainnews.com/ru',
            Link_UA__c = 'https://mainnews.com/ua',
            Main_News__c = true
        );
        insert mainNews;

        List<News__c> newsList = new List<News__c>();
        for (Integer i = 1; i <= 4; i++) {
            newsList.add(new News__c(
                Date__c = Date.today().addDays(-i),
                Description_EN__c = 'News ' + i + ' Description EN',
                Description_RU__c = 'News ' + i + ' Description RU',
                Description_UA__c = 'News ' + i + ' Description UA',
                Header_EN__c = 'News ' + i + ' Header EN',
                Header_RU__c = 'News ' + i + ' Header RU',
                Header_UA__c = 'News ' + i + ' Header UA',
                Link_EN__c = 'https://news' + i + '.com/en',
                Link_RU__c = 'https://news' + i + '.com/ru',
                Link_UA__c = 'https://news' + i + '.com/ua',
                Main_News__c = false
            ));
        }
        insert newsList;
    }

    @isTest
    static void testGetNewsWithMainNews() {
        Test.startTest();
        SiteNewsController.NewsWrapper result = SiteNewsController.getNews();
        Test.stopTest();

        System.assertEquals('Main News Header EN', result.mainHeader);
        System.assertEquals('Main News Description EN', result.mainDescription);
        System.assertEquals('https://mainnews.com/en', result.mainLink);
        System.assertEquals('News 1 Header EN', result.Item1Header);
        System.assertEquals('https://news1.com/en', result.Item1Link);
        System.assertEquals('News 2 Header EN', result.Item2Header);
        System.assertEquals('https://news2.com/en', result.Item2Link);
        System.assertEquals('News 3 Header EN', result.Item3Header);
        System.assertEquals('https://news3.com/en', result.Item3Link);
    }

    @isTest
    static void testGetNewsWithoutMainNews() {
        delete [SELECT Id FROM News__c WHERE Main_News__c = true];

        Test.startTest();
        SiteNewsController.NewsWrapper result = SiteNewsController.getNews();
        Test.stopTest();

        System.assertEquals('News 1 Header EN', result.mainHeader);
        System.assertEquals('News 1 Description EN', result.mainDescription);
        System.assertEquals('https://news1.com/en', result.mainLink);
        System.assertEquals('News 2 Header EN', result.Item1Header);
        System.assertEquals('https://news2.com/en', result.Item1Link);
        System.assertEquals('News 3 Header EN', result.Item2Header);
        System.assertEquals('https://news3.com/en', result.Item2Link);
        System.assertEquals('News 4 Header EN', result.Item3Header);
        System.assertEquals('https://news4.com/en', result.Item3Link);
    }
}