@isTest 
private class InputLookupControllerTest extends BaseTest{

  //--------------------------------------------------------------------------
  // Statics
  private static final String notValidJson = '{"object","TestName"}';
  
  private static final String jsonTemplate = 
    '{"object":"Contact",'+
      '"searchField":"",'+
      '"subtitleField":"",'+
      '"searchTerm":"",'+
      '"filter":"",'+
      '"limit":"",'+
      '"order":""'+
    '}';

  private static final String firstName = 'FirstTest';

  //--------------------------------------------------------------------------
  // Success scenarios

  @isTest
  private static void test_Success_GetRecordLabel() {
    System.runAs(t.adminUser){
      //find label of some custom object to verify logic
      Map<String, Schema.SObjectType> allSobjects = Schema.getGlobalDescribe();
      String customSobjectName = null;
      String customSobjectLabel = null;
      for (Schema.SObjectType sobj : allSobjects.values()){
        if (sobj.getDescribe().isCustom()){
          customSobjectName = sobj.getDescribe().getName();
          customSobjectLabel = sobj.getDescribe().getLabel();
          break;
        }
      }
      if (customSobjectName == null){
        customSobjectName = allSobjects.values()[0].getDescribe().getName();
        customSobjectLabel = allSobjects.values()[0].getDescribe().getLabel();
      }
      String jsonString = '{"object":"' + customSobjectName + '"}';

      t.start();
        String result = InputLookupController.getRecordLabel(jsonString);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'));
      
      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      System.assertEquals(customSobjectLabel, resultsMap.get('objectLabel'));
    }
  }

  @isTest
  private static void test_Success_GetRecords() {
    System.runAs(t.adminUser){
      Contact newCont = t.newContacts(firstName, 'LastTest')[0];
      newCont.MailingCountry = 'Ukraine';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",' , '"searchField":"FirstName",')
        .replace('"searchTerm":"",'  , '"searchTerm":"' + firstName + '",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      Map<String,Object> dataElement = (Map<String,Object>) dataList[0];
      System.assertEquals(newCont.FirstName, dataElement.get('label'));
      System.assertEquals(newCont.Id, dataElement.get('value'));
      System.assertEquals(null, dataElement.get('sublabel'));
    }
  }

  @isTest
  private static void test_Success_GetRecords_Subtitle() {
    System.runAs(t.adminUser){
      Account newAcc = t.newAccounts('TestAcc')[0];
      newAcc.ID_ERP__c = '12379';
      insert newAcc;

      Contact newCont = t.newContacts(firstName, 'LastTest')[0];
      newCont.AccountId = newAcc.Id;
      newCont.MailingCountry = 'Ukraine';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",')
        .replace('"subtitleField":"",', '"subtitleField":"Account.Name",')
        .replace('"searchTerm":"",'   , '"searchTerm":"' + firstName + '",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      //System.assertEquals('', result);

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      Map<String,Object> dataElement = (Map<String,Object>) dataList[0];

      System.assertEquals(newCont.FirstName, dataElement.get('label'));
      System.assertEquals(newCont.Id, dataElement.get('value'));
      System.assertEquals(newAcc.Name, dataElement.get('sublabel'));
    }
  }

  @isTest
  private static void test_Success_GetRecords_Order() {
    System.runAs(t.adminUser){
      Account newAcc = t.newAccounts('TestAcc')[0];
      newAcc.ID_ERP__c = '12379';
      insert newAcc;

      List<Contact> newConts = t.newContacts('FirstTest', 'LastTest');
      List<Contact> insertedConts = new List<Contact>();
      for (Integer i = 0; i < 10; i++){
        newConts[i].AccountId = newAcc.Id;
        newConts[i].MailingCountry = 'Ukraine';
        insertedConts.add(newConts[i]);
      }
      insert insertedConts;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",')
        .replace('"subtitleField":"",', '"subtitleField":"Account.Name",')
        .replace('"searchTerm":"",'   , '"searchTerm":"' + firstName + '",')
        .replace('"order":""'         , '"order":"FirstName"');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');

      for (Integer i = 0; i < dataList.size(); i++){
        Map<String,Object> dataElement = (Map<String,Object>) dataList[i];
        System.assertEquals(insertedConts[i].FirstName, dataElement.get('label'));
        System.assertEquals(insertedConts[i].Id, dataElement.get('value'));
        System.assertEquals(newAcc.Name, dataElement.get('sublabel'));
      } 
      
    }
  }

  @isTest
  private static void test_Success_GetRecords_Limit() {
    System.runAs(t.adminUser){
      Account newAcc = t.newAccounts('TestAcc')[0];
      newAcc.ID_ERP__c = '12379';
      insert newAcc;

      List<Contact> newConts = t.newContacts('FirstTest', 'LastTest');
      List<Contact> insertedConts = new List<Contact>();
      for (Integer i = 0; i < 20; i++){
        newConts[i].AccountId = newAcc.Id;
        newConts[i].MailingCountry = 'Ukraine';
        insertedConts.add(newConts[i]);
      }
      insert insertedConts;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",')
        .replace('"subtitleField":"",', '"subtitleField":"Account.Name",')
        .replace('"searchTerm":"",'   , '"searchTerm":"' + firstName + '",')
        .replace('"limit":"",'        , '"limit":"10",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      System.assertEquals(10, dataList.size());
      
    }
  }

  @isTest
  private static void test_Success_GetRecords_Filter() {
    System.runAs(t.adminUser){
      Account newAcc = t.newAccounts('TestAcc')[0];
      newAcc.ID_ERP__c = '12379';
      insert newAcc;

      List<Opportunity> newOpps = t.newOpportunities('TestOpp',newAcc.Id,'New',Date.today());
      List<Opportunity> insertedOpps = new List<Opportunity>();
      for (Integer i = 0; i < 10; i++){
        newOpps[i].CloseDate = Date.today().addDays(10);
        insertedOpps.add(newOpps[i]);
        insertedOpps.add(newOpps[i+10]);
      }
      insert insertedOpps;

      String jsonString = jsonTemplate
        .replace('"object":"Contact"' , '"object":"Opportunity"')
        .replace('"searchField":"",'  , '"searchField":"Name",')
        .replace('"subtitleField":"",', '"subtitleField":"Account.Name",')
        .replace('"filter":"",'       , '"filter":"CloseDate > TODAY",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      //System.assertEquals('', result);

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      System.assertEquals(10, dataList.size());
      
    }
  }

  @isTest
  private static void test_Success_GetRecentRecords() {
    System.runAs(t.adminUser){
      Contact newCont = t.newContacts('FirstTest', 'LastTest')[0];
      newCont.MailingCountry = 'Ukraine';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",');

      t.start();
        String result = InputLookupController.getRecentRecords(jsonString);
      t.stop();

      //System.assertEquals('', result);
	  /*
      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      Map<String,Object> dataElement = (Map<String,Object>) dataList[0];

      System.assertEquals(newCont.FirstName, dataElement.get('label'));
      System.assertEquals(newCont.Id, dataElement.get('value'));
      System.assertEquals(null, dataElement.get('sublabel'));
	  */
    }
  }

  @isTest
  private static void test_Success_GetRecentRecordsNoRecords() {
    System.runAs(t.adminUser){
      t.start();
        String result = InputLookupController.getRecentRecords(jsonTemplate);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      System.assertEquals(0, dataList.size());
    }
  }

  @isTest
  private static void test_Success_GetRecords_Address() {
    System.runAs(t.adminUser){
      Contact newCont = t.newContacts('FirstTest', 'LastTest')[0];
      newCont.MailingCity = 'City';
      newCont.MailingCountry = 'Ukraine';
      newCont.MailingPostalCode = '12345';
      newCont.MailingStreet = 'Street';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",','"searchField":"MailingAddress",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(true, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals(null, responceMap.get('errMsg'));

      Map<String, Object> resultsMap = (Map<String, Object>) responceMap.get('results');
      List<Object> dataList = (List<Object>) resultsMap.get('data');
      Map<String,Object> dataElement = (Map<String,Object>) dataList[0];

      String expectedAddress = newCont.MailingStreet + ', ' + 
                               newCont.MailingCity + ', ' + 
                               newCont.MailingCountry + ', ' +
                               newCont.MailingPostalCode;
      System.assertEquals(expectedAddress, dataElement.get('label'));
      System.assertEquals(newCont.Id, dataElement.get('value'));
      System.assertEquals(null, dataElement.get('sublabel'));
    }
  }

  //--------------------------------------------------------------------------
  // Error scenarios

  @isTest
  private static void test_Error_GetRecords() {
    System.runAs(t.adminUser){
      String firstName = 'FirstTest';
      Contact newCont = t.newContacts(firstName, 'LastTest')[0];
      newCont.MailingCountry = 'Ukraine';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",')
        .replace('"searchTerm":"",'   , '"searchTerm":"' + firstName + '",')
        .replace('"filter":"",'       , '"filter":"FirstName == \'Test\'",');

      t.start();
        String result = InputLookupController.getRecords(jsonString);
      t.stop();

      //System.assertEquals('', result);

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(false, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals('unexpected token: \'=\'', responceMap.get('errMsg'));
    }
  }

  @isTest
  private static void test_Error_GetRecentRecords() {
    System.runAs(t.adminUser){
      Contact newCont = t.newContacts('FirstTest', 'LastTest')[0];
      newCont.MailingCountry = 'Ukraine';
      insert newCont;

      String jsonString = jsonTemplate
        .replace('"searchField":"",'  , '"searchField":"FirstName",')
        .replace('"filter":"",'       , '"filter":"FirstName == \'Test\'",');

      t.start();
        String result = InputLookupController.getRecentRecords(jsonString);
      t.stop();
	  /*
      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(false, (Boolean) responceMap.get('isSuccess'), result);
      System.assertEquals('unexpected token: \'==\'', responceMap.get('errMsg'));
	  */
    }
  }

  @isTest
  private static void test_Error_GetRecordLabel() {
    System.runAs(t.adminUser){
      t.start();
        String result = InputLookupController.getRecordLabel(notValidJson);
      t.stop();

      Map<String, Object> responceMap = (Map<String, Object>) JSON.deserializeUntyped(result);
      System.assertEquals(false, (Boolean) responceMap.get('isSuccess'));
      System.assert( ((String) responceMap.get('errMsg')).contains('Unexpected character'));
    }
  }

  //--------------------------------------------------------------------------
  // Helpers
  static { BaseTest.t = new InputLookupControllerTest(); }
  static BaseTest t { get { return BaseTest.t; } }
}