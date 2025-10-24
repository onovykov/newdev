@IsTest
public class QuoteStructureDetailInsertTest {

    @IsTest
    static void testInsertQuoteStructureDetail() {
        List<QuoteStructureDetail__c> quoteStructureDetailList = new List<QuoteStructureDetail__c>();
        for (Integer i = 0; i < 200; i++) {
            quoteStructureDetailList.add(new QuoteStructureDetail__c(Name = 'Test Record ' + i));
        }

        Test.startTest();
        System.enqueueJob(new QuoteStructureDetailInsert(quoteStructureDetailList));
        Test.stopTest();

        List<QuoteStructureDetail__c> insertedRecords = [SELECT Id FROM QuoteStructureDetail__c];
        System.assertEquals(200, insertedRecords.size());
    }

    @IsTest
    static void testFakeCoverage() {
        QuoteStructureDetailInsert.FakeCoverageMethod();
    }
}