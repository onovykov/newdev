global class EmailMessageServiceHandler implements Messaging.InboundEmailHandler {
	//--------------------------------------------------------------------------
	// Properties
	private static Integer index = 0;

	//--------------------------------------------------------------------------
	// Methods
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		// Create an InboundEmailResult object for returning the result of the Apex Email Service
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

		// get all emails from FromAddress, ToAddresses, CcAddresses
		Set<String> emails = new Set<String> ();
		emails.add(email.fromAddress);
		if (null != email.toAddresses) emails.addAll(email.toAddresses);
		if (null != email.ccAddresses) emails.addAll(email.ccAddresses);
		emails.remove(null);

		// generate EmailMessages
		EmailMessage emailMessage = generateEmailMessage(email);
		
		// get all users
		Map<String, List<Id>> usersMap = getUsersMap(emails);
		Map<String, List<Id>> contactsMap = getContactsMap(emails);
		Map<String, List<Id>> leadsMap = getLeadsMap(emails);
		// create new Lead if there not assosiated Leads and Contacts, and address not in ignor list emails	
		
		System.debug(emailMessage.FromAddress);
		Ignored_Emails__c[] ignoredEmails = [SELECT Email_address__c FROM Ignored_Emails__c WHERE Email_address__c = :emailMessage.FromAddress];
		if (ignoredEmails.size() == 0) {
			List<Opportunity> oppsWithNotEmptyTag = [SELECT Id, Tag__c FROM Opportunity WHERE Tag__c!=null];
			for(Opportunity opp : oppsWithNotEmptyTag){
				if(emailMessage.Subject.contains(opp.Tag__c)){
					emailMessage.RelatedToId = opp.Id;
				}
			}
			if(emailMessage.RelatedToId==null){
				emailMessage.RelatedToId = getRelatedId(emails, emailMessage.Subject);
			}

			// add user to owner
			if (contactsMap.isEmpty() && leadsMap.isEmpty() && !usersMap.isEmpty() && emailMessage.Incoming) {					
				ID userId = usersMap.values().get(0).get(0);
				Lead lead = generateLead(emailMessage.FromAddress, userId);
				insert lead;
				leadsMap.put(lead.Email, new List<Id> { lead.id });
			}
		}
		insert emailMessage;
		System.debug(emailMessage.Id);

		// retrieve all email relationships 
		List<EmailMessageRelation> relationships = getEmailRelationship(emailMessage.Id);


		// assign relation to salesforce records
		Map<String, List<Id>> relatedIdsMap = new Map<String, List<Id>> ();
		relatedIdsMap.putAll(leadsMap);
		relatedIdsMap.putAll(contactsMap);
		relatedIdsMap.putAll(usersMap);
		List<EmailMessageRelation> generatedRelations = generateRelations(relatedIdsMap, relationships);
		upsert generatedRelations;

		for(EmailMessageRelation emr : generatedRelations) {
			System.debug(emr.RelationAddress);
			System.debug(emr.RelationId);
			System.debug(emr.RelationObjectType);
		}

		//Check on filled relations and delete email if there is no any relations except to users	
		
		System.debug(emailMessage.Id);
		EmailMessageRelation[] emrCheck = [Select Id, RelationAddress, RelationId, RelationObjectType FROM EmailMessageRelation WHERE EmailMessageId = :emailMessage.Id];
		for(EmailMessageRelation emr1 : emrCheck) {
			System.debug(emr1.RelationAddress);
			System.debug(emr1.RelationId);
			System.debug(emr1.RelationObjectType);
		}
		EmailMessageRelation[] emr = [Select Id, RelationAddress, RelationId, RelationObjectType FROM EmailMessageRelation WHERE EmailMessageId = :emailMessage.Id AND RelationObjectType != 'User' AND RelationObjectType != null];
		for(EmailMessageRelation emr1 : emr) {
			System.debug(emr1.RelationAddress);
			System.debug(emr1.RelationId);
			System.debug(emr1.RelationObjectType);
		}
		if (emr.size() == 0) {
			delete emailMessage;
			return result;
		}

		// insert attachments assigned to email messages
		List<Attachment> attachments = createAttachments(email);
		for (Attachment a : attachments) {
			a.ParentId = emailMessage.Id;
		}
		insert attachments;

		// update Email Message and set actual message status
		emailMessage.Status = getMessageStatus(emailMessage.Incoming);
		update emailMessage;

		return result;
	}

	//--------------------------------------------------------------------------
	// Helpers
	private static EmailMessage generateEmailMessage(Messaging.InboundEmail email) {
		EmailMessage theEmailMessage = new EmailMessage();

		theEmailMessage.FromName = email.fromName;
		theEmailMessage.FromAddress = email.fromAddress;
		theEmailMessage.ToAddress = joinEmails(email.toAddresses);
		theEmailMessage.CcAddress = joinEmails(email.ccAddresses);
		theEmailMessage.Subject = email.subject;

		if (null != email.plainTextBody) {
			theEmailMessage.TextBody = email.plainTextBody.left(32000);
		}

		if (!email.htmlBodyIsTruncated && null != email.htmlBody) {
			theEmailMessage.HtmlBody = email.htmlBody.left(32000);
		}

		theEmailMessage.Incoming = !email.fromAddress.contains('interpipe.biz');
		theEmailMessage.MessageDate = Datetime.now();
		theEmailMessage.Status = '5'; // temporary set "Draft" status

		return theEmailMessage;
	}

	private Id getRelatedId(Set<String> emails, String subject) {
		// insert email message assigned to opportunity
		System.debug(emails);
		List<Opportunity> opportunitiesList = [
		                                       SELECT Id, Name, OwnerId, Tag__c
		                                       FROM Opportunity
		                                       WHERE ID IN(SELECT OpportunityId FROM OpportunityContactRole WHERE Contact.Email IN :emails)
		                                       AND Owner.Email IN :emails
		                                       AND IsClosed = false
		                                       ORDER BY LastModifiedDate DESC
		                                      ];

		Id resultId = null;
		if (!opportunitiesList.isEmpty()) {
			Opportunity actualOpp = opportunitiesList[0];
			resultId = actualOpp.Id;

			if(actualOpp.Tag__c==null){
				actualOpp.Tag__c = subject;
				update actualOpp;
			}

			if (opportunitiesList.size() > 1) {
				// insert task assign to opportunity owner 
				Task ownerTask = generateTaskForOppOwner(actualOpp.OwnerId, actualOpp.Id, opportunitiesList);
				insert ownerTask;
			}
		} else {
			// if there is no opportunity, assign email to Account
			System.debug(emails);
			List<Account> accountsList = [
			                              SELECT Id FROM Account
			                              WHERE ID IN(SELECT AccountId FROM Contact WHERE Email IN :emails) AND Owner.Email IN :emails
			                              LIMIT 1
			                             ];

			if (!accountsList.isEmpty()) {
				resultId = accountsList[0].Id;
			}
		}

		return resultId;
	}

	private List<EmailMessageRelation> generateRelations(Map<String, List<Id>> relatedIdsMap, List<EmailMessageRelation> existingRelations) {
		List<EmailMessageRelation> relationshipsList = new List<EmailMessageRelation> ();
		for (EmailMessageRelation relationship : existingRelations) {
			String emailAddress = relationship.RelationAddress;
			if (relatedIdsMap.containsKey(emailAddress)) {
				List<Id> emailIds = relatedIdsMap.get(emailAddress);
				for (Integer i = 0; i<emailIds.size(); i++) {
					if (i == 0) {
						relationship.RelationId = emailIds[0];
					} else {
						EmailMessageRelation newRelation = new EmailMessageRelation();
						newRelation.EmailMessageId = relationship.EmailMessageId;
						newRelation.RelationType = 'CcAddress';
						newRelation.RelationAddress = (++ index) + '@tmp.com';
						newRelation.RelationId = emailIds[i];
						relationshipsList.add(newRelation);
					}
				}
			}

			relationshipsList.add(relationship);
		}
		for(EmailMessageRelation emr : relationshipsList) {
			System.debug(emr.RelationAddress);
			System.debug(emr.RelationId);
			System.debug(emr.RelationObjectType);
		}
		return relationshipsList;
	}

	private List<Attachment> createAttachments(Messaging.InboundEmail email) {
		List<Attachment> attachments = new List<Attachment> ();
		if (email.textAttachments != null) {
			for (Messaging.Inboundemail.TextAttachment textAttach : email.textAttachments) {
				Attachment attachment = new Attachment();
				attachment.Name = textAttach.fileName;
				attachment.Body = Blob.valueOf(textAttach.body);
				attachments.add(attachment);
			}
		}

		if (email.binaryAttachments != null) {
			for (Messaging.Inboundemail.BinaryAttachment binaryAttach : email.binaryAttachments) {
				Attachment attachment = new Attachment();
				attachment.Name = binaryAttach.fileName;
				attachment.Body = binaryAttach.body;
				attachments.add(attachment);
			}
		}

		return attachments;
	}

	private static String getMessageStatus(Boolean isIncoming) {
		//'0' = New
		//'1' = Read
		//'2' = Replied
		//'3' = Sent
		//'4' = Forwarded
		//'5' = Draft
		return isIncoming ? '1' : '3';
	}

	private static Task generateTaskForOppOwner(String ownerId, String whatId, List<Opportunity> oppList) {
		Task task = new Task(
		                     OwnerId = ownerId,
		                     Subject = 'Email',
		                     Status = 'Open',
		                     Priority = 'Normal',
		                     WhatId = whatId,
		                     Description = 'Please, choose Opportunity from this list:' + '\n'
		);

		for (Opportunity opp : oppList) {
			task.Description += opp.Name + '\n';
		}

		return task;
	}

	private static Lead generateLead(String email, Id owner) {
		Lead newLead = new Lead(
		                        LastName = email,
		                        Email = email,
		                        Company = 'EmailToLead',
								OwnerId = owner
		);

		return newLead;
	}

	private static string joinEmails(List<String> emails) {
		String joined = '';

		if (emails != null) {
			List<String> emailsTrimed = new List<String> ();
			for (String theEmail : emails) {
				String trimed = theEmail.trim();
				if (!String.isEmpty(trimed)) {
					emailsTrimed.add(trimed);
				}
			}

			joined = String.join(emailsTrimed, ';');
		}

		return joined;
	}

	private List<EmailMessageRelation> getEmailRelationship(Id emailMessageId) {
		System.debug(emailMessageId);
		return[
		SELECT ID, EmailMessageId, RelationAddress, RelationId, RelationType, RelationObjectType
		FROM EmailMessageRelation
		WHERE EmailMessageId = : emailMessageId
		];
	}

	private Map<String, List<Id>> getUsersMap(Set<String> emails) {
		Map<String, List<Id>> result = new Map<String, List<Id>> ();
		System.debug(emails);
		for (User u :[SELECT Id, Email FROM User WHERE Email IN :emails]) {
			result.put(u.Email, new List<Id> ());
			result.get(u.Email).add(u.Id);
		}

		return result;
	}

	private Map<String, List<Id>> getContactsMap(Set<String> emails) {
		Map<String, List<Id>> result = new Map<String, List<Id>> ();
		System.debug(emails);
		for (Contact c :[SELECT Id, Email, OwnerId, Owner.Email FROM Contact WHERE Email IN :emails]) {
			if (!result.containsKey(c.Email)) result.put(c.Email, new List<Id> ());
			result.get(c.Email).add(c.Id);
		}

		return result;
	}

	private Map<String, List<Id>> getLeadsMap(Set<String> emails) {
		Map<String, List<Id>> result = new Map<String, List<Id>> ();
		System.debug(emails);
		for (Lead l :[SELECT Id, Email, OwnerId, Owner.Email FROM Lead WHERE Email IN :emails AND IsConverted != true]) {
			if (!result.containsKey(l.Email)) result.put(l.Email, new List<Id> ());
			result.get(l.Email).add(l.Id);
		}

		return result;
	}
}