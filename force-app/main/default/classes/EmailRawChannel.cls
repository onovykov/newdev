public with sharing class EmailRawChannel implements NotificationChannel {
    public NotificationTypes.ChannelResult send(NotificationTypes.NotificationPayload p, NotificationTypes.RecipientBundle r, NotificationTypes.NotificationEventCfg cfg) {
        if (r.emails.isEmpty()) return NotificationResultFactory.none();
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>(r.emails));
        m.setSubject(SubjectBuilder.build(p, null, null));
        m.setPlainTextBody(BodyBuilder.build(p, null, null));
		List<Messaging.SendEmailResult> res = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ m });
		return NotificationResultFactory.fromResults(res);
    }
}