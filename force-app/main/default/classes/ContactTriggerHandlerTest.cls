@isTest
private class ContactTriggerHandlerTest extends BaseTest {
	
	@TestSetup
	private static void testSetup() {
		User TestUser = t.newUser('test@test.com');
		insert TestUser;

		Account TestAccount = t.newAccounts('Test') [0];
		insert TestAccount;

		Contact Testcontact = t.newContacts('Test', 'Birthday') [0];
		Testcontact.AccountId = TestAccount.Id;
		Testcontact.Birthdate = Date.today().addDays(5);
		Testcontact.MailingCountry = 'Ukraine';

		insert Testcontact;
	}

	@isTest
	private static void testInsertTask() {
		Contact TestContact = [SELECT Id, Create_Task__c FROM Contact LIMIT 1];
		User TestUser = [SELECT Id FROM User LIMIT 1];

		t.start();
			TestContact.Create_Task__c = true;
			update TestContact;

		t.stop();

		List<Task> insertedTask = [SELECT Id, Subject, Status, ReminderDateTime FROM Task];
		System.debug ('insertedTask - '+ insertedTask);

		System.assertEquals(2, insertedTask.size());
	}

	static { BaseTest.t = new ContactTriggerHandlerTest(); }
	static BaseTest t { get { return BaseTest.t; } }
}