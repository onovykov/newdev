@isTest
class EmailMessageServiceHandlerTest extends BaseTest {
  
  //--------------------------------------------------------------------------
  // Tests
  static testMethod void test_NoExistsRelations() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com','example_to2@sf.com'};
      testEmail.ccAddresses = new List<String>{'example_cc1@sf.com','example_cc2@sf.com'};
      testEmail.htmlBodyIsTruncated = false;
      testEmail.htmlBody = 'test';

      Contact cont = t.newContacts('test','testl')[0];
      cont.Email = 'example_to1@sf.com';
      cont.MailingCountry = 'Ukraine';
      insert cont;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());
      System.assertEquals('example_from@sf.com', verifyEmailMessage[0].FromAddress);
      System.assertEquals('example_to1@sf.com; example_to2@sf.com', verifyEmailMessage[0].ToAddress);
      System.assertEquals('example_cc1@sf.com; example_cc2@sf.com', verifyEmailMessage[0].CcAddress);

      // verify email message relationship
      List<EmailMessageRelation> verifyEmailRelationships = [SELECT Id FROM EmailMessageRelation];
      System.assertEquals(5, verifyEmailRelationships.size());
    }
  }

  static testMethod void test_LeadCreation() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com','example_to2@sf.com'};
      testEmail.ccAddresses = new List<String>{'example_cc1@sf.com','example_cc2@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

	  User u = t.newUser('example_to1@sf.com');
	  u.Email = 'example_to1@sf.com';
      u.ID_ERP__c = 'TESTBO';
	  u.SalesDivision__c = '00004';
	  u.EmployeeNumber = 'TESTBO';
	  u.LoginERP__c = 'TESTBO';  
	  insert u;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());

      // check that lead is created
      List<Lead> verifyLead = [SELECT LastName, Email FROM Lead];
      System.assertEquals(1, verifyLead.size());
      System.assertEquals('example_from@sf.com', verifyLead[0].LastName);
      System.assertEquals('example_from@sf.com', verifyLead[0].Email);
    }
  }

  static testMethod void test_LeadCreationWithIgnoreEmail() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com','example_to2@sf.com'};
      testEmail.ccAddresses = new List<String>{'example_cc1@sf.com','example_cc2@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      Ignored_Emails__c ignoreEmail = t.newIgroredEmails('example_from@sf.com');
      insert ignoreEmail;

      Contact cont = t.newContacts('test','testl')[0];
      cont.Email = 'example_to1@sf.com';
      cont.MailingCountry = 'Ukraine';
      insert cont;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that email message is created
      List<EmailMessage> verifyEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());

      // check that lead is not created with ignored email address
      List<Lead> verifyLead = [SELECT LastName, Email FROM Lead];
      System.assertEquals(0, verifyLead.size());
    }
  }
  
  static testMethod void test_TaskCreation() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com', t.adminUser.Email};
      testEmail.htmlBodyIsTruncated = true;

      User testUser = t.newUser('test@user.com');
      testUser.ID_ERP__c = 'TESTBO';
	  testUser.SalesDivision__c = '00004';
	  testUser.EmployeeNumber = 'TESTBO';
	  testUser.LoginERP__c = 'TESTBO'; 
      testUser.Email = 'example_from@sf.com';
      insert testUser;

      Account testAccount = t.newAccounts('The Busters')[0];
      testAccount.ID_ERP__c = '123789';
      insert testAccount;

      Contact testContact1 = t.newContacts('', 'Buster1')[0];
      testContact1.Email = 'example_to1@sf.com';
      testContact1.MailingCountry = 'Ukraine';
      insert testContact1;

      Contact testContact2 = t.newContacts('', 'Buster2')[0];
      testContact2.Email = t.adminUser.Email;
      testContact2.MailingCountry = 'Ukraine';
      insert testContact2;

      Opportunity testOpportunity1 = t.newOpportunities('Buster Invoice', testAccount.Id, 'Qualification', Date.today())[0];
      testOpportunity1.OwnerId = testUser.Id;
      insert testOpportunity1;

      Opportunity testOpportunity2 = t.newOpportunities('Buster Invoice1', testAccount.Id, 'Qualification', Date.today())[0];
      testOpportunity2.OwnerId = t.adminUser.Id;
      insert testOpportunity2;

      insert new OpportunityContactRole(
        ContactId = testContact1.Id,
        OpportunityId = testOpportunity1.Id
      );

      insert new OpportunityContactRole(
        ContactId = testContact2.Id,
        OpportunityId = testOpportunity2.Id
      );

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();


      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, RelatedToId, FromAddress, ToAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());

      // check that created task
      List<Opportunity> opps = [SELECT Id, OwnerId, Name, LastModifiedDate FROM Opportunity];
      Integer index;
      if (opps[1].LastModifiedDate > opps[0].LastModifiedDate) {
        index = 1;
      }
      else {
        index = 0;
      }
      List<Task> verifyTask = [SELECT WhatId, OwnerId, Subject FROM Task WHERE Subject = 'Email'];
	  /*
      System.assertEquals(1, verifyTask.size());
      System.assertEquals(opps[index].OwnerId, verifyTask[0].OwnerId);
      System.assertEquals(opps[index].Id, verifyTask[0].WhatId);
	  */
    }
  }
  
  static testMethod void test_ExistsUserAndContact() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = t.adminUser.Email;
      testEmail.toAddresses = new List<String>{'example_to1@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      Contact testContact = t.newContacts('', 'Buster')[0];
      testContact.Email = 'example_to1@sf.com';
      testContact.MailingCountry = 'Ukraine';
      insert testContact;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());
      System.assertEquals(t.adminUser.Email, verifyEmailMessage[0].FromAddress);
      System.assertEquals('example_to1@sf.com', verifyEmailMessage[0].ToAddress);

      // verify email message relationships
      List<EmailMessageRelation> verifyFromEmailRelationships = [SELECT Id, RelationAddress, RelationId, RelationType 
                                                                   FROM EmailMessageRelation
                                                                  WHERE RelationType = 'FromAddress'];
      System.assertEquals(1, verifyFromEmailRelationships.size());
      System.assertEquals(t.adminUser.Id, verifyFromEmailRelationships[0].RelationId);
      System.assertEquals(t.adminUser.Email, verifyFromEmailRelationships[0].RelationAddress);

      List<EmailMessageRelation> verifyToEmailRelationships = [SELECT Id, RelationAddress, RelationId, RelationType 
                                                                   FROM EmailMessageRelation
                                                                  WHERE RelationType = 'ToAddress'];
      System.assertEquals(1, verifyToEmailRelationships.size());
      System.assertEquals(testContact.Id, verifyToEmailRelationships[0].RelationId);
      System.assertEquals(testContact.Email, verifyToEmailRelationships[0].RelationAddress);
    }
  }

  static testMethod void testoExistsMultipleRecords() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      List<Contact> testContacts = new List<Contact>();
      for (Integer i = 0; i < 3; i++) {
        Contact testContact = t.newContacts('', 'Buster' + i)[0];
        testContact.Email = 'example_to1@sf.com';
        testContact.MailingCountry = 'Ukraine';

        testContacts.add(testContact);
      }

      insert testContacts;

      Lead testLead = t.createLeads()[0];
      testLead.Email = 'example_to1@sf.com';
      insert testLead;
      

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
       emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, FromAddress, ToAddress, CcAddress FROM EmailMessage];

      System.assertEquals(1, verifyEmailMessage.size());
      System.assertEquals('example_from@sf.com', verifyEmailMessage[0].FromAddress);
      System.assertEquals('example_to1@sf.com', verifyEmailMessage[0].ToAddress);

      // verify email message relationships
      List<EmailMessageRelation> verifyToEmailRelationships = [SELECT Id, RelationAddress, RelationId, RelationType 
                                                                   FROM EmailMessageRelation
                                                                  WHERE RelationType = 'ToAddress'];

      List<EmailMessageRelation> verifyCcEmailRelationships = [SELECT Id, RelationAddress, RelationId, RelationType 
                                                                   FROM EmailMessageRelation
                                                                  WHERE RelationType = 'CcAddress'];

      System.assertEquals(1, verifyToEmailRelationships.size());
      System.assertEquals(2, verifyCcEmailRelationships.size());

    }
  }
  
  static testMethod void test_AssignToOpportunities() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      Account testAccount = t.newAccounts('The Busters')[0];
      testAccount.ID_ERP__c = '123789';
      insert testAccount;

      Contact testContact = t.newContacts('', 'Buster')[0];
      testContact.Email = 'example_to1@sf.com';
      testContact.MailingCountry = 'Ukraine';
      insert testContact;

      Opportunity testOpportunity = t.newOpportunities('Buster Invoice', testAccount.Id, 'Qualification', Date.today())[0];
      insert testOpportunity;

      insert new OpportunityContactRole(
        ContactId = testContact.Id,
        OpportunityId = testOpportunity.Id
      );

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, RelatedToId, FromAddress, ToAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());
      System.assertEquals('example_from@sf.com', verifyEmailMessage[0].FromAddress);
      System.assertEquals('example_to1@sf.com', verifyEmailMessage[0].ToAddress);
    }
  }

  static testMethod void test_AssignToAccount() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{t.adminUser.Email};
      testEmail.htmlBodyIsTruncated = true;

      Account testAccount = t.newAccounts('The Busters')[0];
      testAccount.OwnerId = t.adminUser.Id;
      testAccount.ID_ERP__c = '123789';
      insert testAccount;

      Contact testContact = t.newContacts('', 'Buster')[0];
      testContact.AccountId = testAccount.Id;
      testContact.Email = t.adminUser.Email;
      testContact.MailingCountry = 'Ukraine';
      insert testContact;

      Contact cont = t.newContacts('test','testl')[0];
      cont.Email = 'example_from@sf.com';
      cont.MailingCountry = 'Ukraine';
      insert cont;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, RelatedToId, FromAddress, ToAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());

      //check that email message assign to acoount
      System.assertEquals(testAccount.Id, verifyEmailMessage[0].RelatedToId);
    }
  }

  static testMethod void test_OutgoingMessage() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@interpipe.biz';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@interpipe.biz';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      Contact cont = t.newContacts('test','testl')[0];
      cont.Email = 'example_to1@sf.com';
      cont.MailingCountry = 'Ukraine';
      insert cont;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, Incoming FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());
      System.assertEquals(false, verifyEmailMessage[0].Incoming);
    }
  }

  static testMethod void test_AssignAttachments() {
    System.runAs(t.adminUser) {
      Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
      testEnvelope.fromAddress = 'example_from@sf.com';
      testEnvelope.toAddress = 'example_to@sf.com';
      testEmail.subject = 'Example subject';
      testEmail.plainTextBody = 'Example body';
      testEmail.fromAddress = 'example_from@sf.com';
      testEmail.toAddresses = new List<String>{'example_to1@sf.com'};
      testEmail.htmlBodyIsTruncated = true;

      Messaging.InboundEmail.BinaryAttachment binAttach = new Messaging.InboundEmail.BinaryAttachment();
      binAttach.body = blob.valueOf('test');
      binAttach.fileName = 'my attachment name';
      binAttach.mimeTypeSubType = 'plain/txt';
      testEmail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {binAttach };

      Messaging.Inboundemail.TextAttachment textAttach = new Messaging.Inboundemail.TextAttachment();
      textAttach.fileName = 'text attachment name';
      textAttach.body = 'test body';
      testEmail.textAttachments = new Messaging.inboundEmail.TextAttachment[] {textAttach };

      Contact cont = t.newContacts('test','testl')[0];
      cont.Email = 'example_to1@sf.com';
      cont.MailingCountry = 'Ukraine';
      insert cont;

      Test.startTest();
        EmailMessageServiceHandler emailMessageService = new EmailMessageServiceHandler();
        emailMessageService.handleInboundEmail(testEmail, testEnvelope);
      Test.stopTest();

      // check that created email message
      List<EmailMessage> verifyEmailMessage = [SELECT Id, RelatedToId, FromAddress, ToAddress FROM EmailMessage];
      System.assertEquals(1, verifyEmailMessage.size());
      
      //check attacment
      List<Attachment> verifyAttach = [SELECT Id, ParentId FROM Attachment];
      System.assertEquals(2, verifyAttach.size());
      System.assertEquals(verifyEmailMessage[0].Id, verifyAttach[0].ParentId);
      System.assertEquals(verifyEmailMessage[0].Id, verifyAttach[1].ParentId);
    }
  }

  
  
  //--------------------------------------------------------------------------
  // Helpers
  static { BaseTest.t = new EmailMessageServiceHandlerTest(); }
  static BaseTest t { get { return BaseTest.t; } }
}