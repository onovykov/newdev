public class ReclamationTriggerHandler extends TriggerHandler implements ITrigger {
	
	public ReclamationTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
		super(oldMap, newMap, oldList, newList);
	}
    
    public void bulkBefore() {
		System.debug('bulkBefore');
        if(Trigger.isDelete){
            	
        }
    }

	public void bulkAfter() {
		System.debug('bulkAfter');
		
	}

	public void beforeInsert(SObject so) {
		System.debug('beforeInsert');
		
	}

	public void beforeUpdate(SObject oldSo, SObject so) {

		System.debug('beforeUpdate');
		
		
	}

	public void beforeDelete(SObject so) {
	}

	public void afterInsert(SObject so) {

		System.debug('afterInsert');
	
	}

	public void afterUpdate(SObject oldSo, SObject so) {
		System.debug('afterUpdate');
		Reclamation__c oldClaim = (Reclamation__c) oldSo;
		Reclamation__c claim = (Reclamation__c) so;

		if (claim.Status__c =='Sended' && oldClaim.Status__c =='Draft') {
			sendNotificationEmail(claim);
		}
	}

	public void afterDelete(SObject so) {
	}

	public void postProcessing() {
		
	}

	private static void sendNotificationEmail(Reclamation__c claim) {
		List<String> emails = new List<String>();
		List<Reclamation__c> claimInfo = [SELECT Id, Account__r.OwnerId, Owner.Name, AssignedBO_ID__c FROM Reclamation__c WHERE id=:claim.id];
		String ownerName = claimInfo[0].Owner.Name;
		Id assignedBOId = claimInfo[0].AssignedBO_ID__c;
		Id ownerId = claimInfo[0].Account__r.OwnerId;

		User assignedBO = [SELECT Id, Email FROM User WHERE Id = :assignedBOId];
		User salesRep = [SELECT Id, Email FROM User WHERE Id = :ownerId];

		emails.add(assignedBO.Email);
		emails.add(salesRep.Email);
		emails.add('Olga.Napkhanko@m.interpipe.biz');
		emails.add('Aleksandra.Tyshkovskaya@m.interpipe.biz');
		emails.add('Anastasia.Zalata@m.interpipe.biz');
		emails.add('CustomerRoom.Support@m.interpipe.biz');
		// emails.add('v.rybak@polytech.software');

	
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(emails);
		email.setSubject('The New Claim was created in the Customer Room');
	
		// Construct the Salesforce record link
		String recordLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + claim.Id;
		String clientLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + ownerId;

	
		// Include the record link in the email body
		String emailBody = 'New claim created by client: '+ clientLink +'. Click the link below to view the claim record:\n\n' + recordLink;
		email.setPlainTextBody(emailBody);
	
		Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		if (results[0].isSuccess()) {
			System.debug('Emails sent successfully.');
		} else {
			System.debug('Emails failed to send: ' + results[0].getErrors()[0].getMessage());
		}
	}
	

}