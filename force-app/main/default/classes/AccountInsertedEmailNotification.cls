public with sharing class AccountInsertedEmailNotification {
    @InvocableMethod
    public static void sendEmail(List<id> ids) {
        try {
            String mailBody = 'New Account has been created. Link: '+ URL.getSalesforceBaseUrl().toExternalForm()+ '/'+ids[0];
            system.debug(ids);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'v.rybak@polytech.software','Violetta.Chernenko@m.interpipe.biz','Aleksandr.Novikov@m.interpipe.biz'};
            email.setToAddresses(toAddresses);
            email.setSubject('New Account has been created');
            email.setPlainTextBody(mailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('An error occurred while sending the email: ' + e.getMessage());
        }
    }
}