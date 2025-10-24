public class ContactTriggerHandler extends TriggerHandler implements ITrigger {

	public ContactTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}

	public static List<Task> tasksToInsert = new List<Task> ();
	public static List<User> userList = new List<User> ();

	public void bulkBefore() {
		if (userList.isEmpty()) {
			userList = [SELECT Id, TimeZoneSidKey FROM USER];
		}
	}

	public void bulkAfter() {
		System.debug('bulkAfter');

	}

	public void beforeInsert(SObject so) { }

	public void beforeUpdate(SObject oldSo, SObject so) {
		System.debug('AfterUpdate');

		Contact contactFromTrigger = (Contact) so;
		if (contactFromTrigger.Create_Task__c) {
			
			tasksToInsert.add(createUpcomingBirthdayTask(contactFromTrigger));
			tasksToInsert.add(createTodayBirthdayTask(contactFromTrigger));

			System.debug('Tasks To Insert - ' + tasksToInsert);
			contactFromTrigger.Create_Task__c = false;
		}
	}

	private Task createUpcomingBirthdayTask(Contact contactFromTrigger) {

			Task birthdayTask = new Task();
			birthdayTask.ActivityDate = contactFromTrigger.Next_Birthday__c;
			birthdayTask.Subject = 'Upcoming Birthday';
			birthdayTask.Status = 'Open';
			birthdayTask.Contact__c = contactFromTrigger.Id;
			birthdayTask.Description = 'Upcoming birthday of ' + contactFromTrigger.LastName + ' in 5 days - '+ contactFromTrigger.Next_Birthday__c.format() +'.';
			birthdayTask.OwnerId = contactFromTrigger.OwnerId;
			birthdayTask.IsReminderSet = true;
			birthdayTask.ReminderDateTime = DateTime.newInstance(contactFromTrigger.Next_Birthday__c.addDays(- 5), Time.newInstance(9, 00, 0, 0));

			return birthdayTask;
	}

	private Task createTodayBirthdayTask(Contact contactFromTrigger) {

			Task birthdayTask = new Task();
			birthdayTask.ActivityDate = contactFromTrigger.Next_Birthday__c;
			birthdayTask.Subject = 'Birthday Reminder';
			birthdayTask.Status = 'Open';
			birthdayTask.Contact__c = contactFromTrigger.Id;
			birthdayTask.Description = 'Today is a Birthday of ' + contactFromTrigger.LastName + ' .';
			birthdayTask.OwnerId = contactFromTrigger.OwnerId;
			birthdayTask.IsReminderSet = true;
			birthdayTask.ReminderDateTime = DateTime.newInstance(contactFromTrigger.Next_Birthday__c, Time.newInstance(9, 00, 0, 0));

			return birthdayTask;
	}


	public void beforeDelete(SObject so) { }
	public void afterInsert(SObject so) { }
	public void afterUpdate(SObject oldSo, SObject so) {}

	public void afterDelete(SObject so) { }
	public void postProcessing() {

		if (!tasksToInsert.isEmpty()) {
			insert tasksToInsert;
		}
		System.debug('tasksToInsert' + tasksToInsert);

	}


}