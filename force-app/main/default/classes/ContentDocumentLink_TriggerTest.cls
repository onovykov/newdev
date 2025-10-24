@isTest
public class ContentDocumentLink_TriggerTest {
   @isTest
    Public static void insertacc(){
        Account acct = new Account(Name='TEST_ACCT');
        insert acct;
    }
    @isTest
    Public static void insertContentVersion(){
    ContentVersion contentVersion = new ContentVersion(
      Title = 'Penguins',
      PathOnClient = 'Penguins.jpg',
      VersionData = Blob.valueOf('Test Content'),
      IsMajorVersion = true
    );
    insert contentVersion;
    }
    
}