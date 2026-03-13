public with sharing class PARDeadNotificationService {

    public static void notify(
        PriceApprovalRequest__c par
    ) {

        Messaging.SingleEmailMessage mail =
            new Messaging.SingleEmailMessage();

        mail.setToAddresses(
            new String[] { 'it-support@company.com' }
        );

        mail.setSubject(
            'PAR Dead: ' + par.Name
        );

        mail.setPlainTextBody(
            'Document: ' + par.Name +
            '\nERP ID: ' + par.ID_ERP__c +
            '\nRetryCount: ' + par.RetryCount__c +
            '\nError: ' + par.LastErrorMessage__c
        );

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail }
        );
    }
}