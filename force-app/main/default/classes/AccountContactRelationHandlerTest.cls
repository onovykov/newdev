@isTest
public with sharing class AccountContactRelationHandlerTest {

    @isTest
    static void test_Non_KLW_Segment_Assignment() {
        Account acc = new Account(Name = 'Other Account', MarketSegment__c = '00004'); // Europe
        insert acc;

        Contact con = new Contact(
                LastName = 'Test Contact',
                MailingCountry = 'Ukraine',
                AccountId = acc.Id
        );

        insert con;

        AccountContactRelation acrResult = [
                SELECT BusinessDivision__c, MarketSegment__c
                FROM AccountContactRelation
                WHERE AccountId = :acc.Id AND ContactId = :con.Id
        ];

        System.assertEquals('Pipes', acrResult.BusinessDivision__c);
        System.assertEquals('00004', acrResult.MarketSegment__c);
    }

    @isTest
    static void test_KLW_Segment_Assignment() {
        Account acc = new Account(Name = 'KLW Account', MarketSegment__c = '00006'); // KLW
        insert acc;

        Contact con = new Contact(
                LastName = 'KLW Contact',
                MailingCountry = 'Ukraine',
                AccountId = acc.Id
        );
        insert con;

        AccountContactRelation acrResult = [
                SELECT BusinessDivision__c, MarketSegment__c
                FROM AccountContactRelation
                WHERE AccountId = :acc.Id AND ContactId = :con.Id
        ];

        System.assertEquals('Railway', acrResult.BusinessDivision__c);
        System.assertEquals('00006', acrResult.MarketSegment__c);
    }
}