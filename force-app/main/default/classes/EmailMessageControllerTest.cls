@isTest 
class EmailMessageControllerTest extends BaseTest{

  @isTest
  static void test_Error_NotFoundEmail() {
    System.runAs(t.adminUser){
      String notValidId = '02s26000000mKKfAAM';
      Boolean isError = false;

      t.start();
        try {
          EmailMessageController.getRelationToId(notValidId);
        } catch (AuraHandledException ahe) {
          isError = true;
        }
      t.stop();

      System.assertEquals(true, isError);
    }
  }

  @isTest
  static void test_Success_GetRelationTo() {
    System.runAs(t.adminUser){
      Account newAcc = t.newAccounts('TestAcc')[0];
      insert newAcc;

      EmailMessage newEmail = t.newEmailMessages()[0];
      newEmail.RelatedToId = newAcc.Id;
      insert newEmail;

      t.start();
        String accId = EmailMessageController.getRelationToId(newEmail.Id);
      t.stop();

      System.assertEquals(newAcc.Id, accId);
    }
  }

  @isTest
  static void test_Success_UpdateRelatedTo() {
    System.runAs(t.adminUser){
      List<Account> newAccs = t.newAccounts('TestAcc');
      newAccs[0].Name = 'TestBefore';
      newAccs[1].Name = 'TestAfter';
      List<Account> accsToInsert = new List<Account>();
      accsToInsert.add(newAccs[0]);
      accsToInsert.add(newAccs[1]);
      insert accsToInsert;

      EmailMessage oldEmail = t.newEmailMessages()[0];
      oldEmail.RelatedToId = accsToInsert[0].Id;
      insert oldEmail;

      t.start();
        String newEmailId = EmailMessageController.updateRelatedTo(oldEmail.Id, accsToInsert[1].Id);
      t.stop();

      List<EmailMessage> verifyEmails = [SELECT Id, RelatedToId, ValidatedFromAddress, ActivityId 
                                         FROM EmailMessage];

      System.assertEquals(1, verifyEmails.size());
      System.assertEquals(newEmailId, verifyEmails[0].Id);
      System.assertEquals(accsToInsert[1].Id, verifyEmails[0].RelatedToId);

    }
  }
  //--------------------------------------------------------------------------
  // Helpers
  static { BaseTest.t = new EmailMessageControllerTest(); }
  static BaseTest t { get { return BaseTest.t; } }
}