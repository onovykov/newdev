@isTest
private with sharing class CopyProductionAmountinQuotasTest {
 
static testmethod void test() {
 
    List<Production_Quota__c> pqList = new List<Production_Quota__c>();
    for (Integer i=0;i<200;i++) {
    Production_Quota__c pq = new Production_Quota__c(Production_Amount_t__c = 1 + i);
    pqList.add(pq);
    }
    insert pqList;
    
    Test.startTest();
    CopyProductionAmountinQuotas c = new CopyProductionAmountinQuotas();
    Database.executeBatch(c);
    Test.stopTest();

    List<Production_Quota__c> pqUpdList= [SELECT Id,Production_Amount_t__c,Quota_Mt__c FROM Production_Quota__c];
    System.assert(pqUpdList[0].Quota_Mt__c != null);
}
}