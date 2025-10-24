public without sharing class EmailMessageController  {
  //--------------------------------------------------------------------------
  // Methods

  @AuraEnabled 
  public static String getRelationToId(String emailMessageId) {
    EmailMessage emailMessage = getMessage(emailMessageId);
    return emailMessage.RelatedToId;
  }

  @AuraEnabled 
  public static String updateRelatedTo(String emailMessageId, String newRelatedToId) {
    EmailMessage emailMessage = getMessage(emailMessageId);

    // Note: this needs to avoid System.StringException: Invalid id: 
    if (String.isBlank(newRelatedToId)) newRelatedToId = null;

    // skip logic if related not changed
    String resultEmailId = emailMessageId;
    if (emailMessage.RelatedToId != newRelatedToId) {
      // query all relations
      List<EmailMessageRelation> relations = [
        SELECT Id, RelationAddress, RelationId, RelationType FROM EmailMessageRelation WHERE EmailMessageId = :emailMessageId
      ];

      EmailMessage newEmailMessage = emailMessage.clone(false);
      newEmailMessage.ActivityId = null;
      newEmailMessage.RelatedToId = newRelatedToId;
      newEmailMessage.ValidatedFromAddress = null;

      delete emailMessage;
      insert newEmailMessage;

      // delete automatically created relationships
      delete [SELECT Id FROM EmailMessageRelation WHERE EmailMessageId = :newEmailMessage.Id];

      List<EmailMessageRelation> newRelations = relations.deepClone(false);
      for (EmailMessageRelation emr : newRelations) {
        emr.EmailMessageId = newEmailMessage.Id;
      }
      insert newRelations;

      resultEmailId = newEmailMessage.Id;
    }

    return resultEmailId;
  }

  //--------------------------------------------------------------------------
  // Helpers
  private static EmailMessage getMessage(String emailMessageId) {
    // grab all email message fields
    List<String> emailFields = new List<String>();
    for (Schema.SObjectField field : EmailMessage.SObjectType.getDescribe().fields.getMap().values()) {
      emailFields.add(field.getDescribe().getName());
    }

    // query email message with all fields
    List<EmailMessage> emailMessages = (EmailMessage[]) Database.query(
      'SELECT ' + String.join(emailFields, ',') + ' FROM EmailMessage WHERE ID = :emailMessageId'
    );
    
    if (emailMessages.isEmpty()) {
      // in theory this should not happen
      throw new AuraHandledException('Not found email message by id: ' + emailMessageId);
    } else {
      return emailMessages[0];
    }
  }
}