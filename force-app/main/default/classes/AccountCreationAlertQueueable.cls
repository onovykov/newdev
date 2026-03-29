public class AccountCreationAlertQueueable implements Queueable {

    private List<String> accountNames;

    public AccountCreationAlertQueueable(List<String> names) {
        this.accountNames = names;
    }

    public void execute(QueueableContext context) {
        try {
            String subject = 'Unauthorized Account Creation Attempt';

            String body = '';
            body += 'User: ' + UserInfo.getUserName() + '\n';
            body += 'UserId: ' + UserInfo.getUserId() + '\n';
            body += 'OrgId: ' + UserInfo.getOrganizationId() + '\n';
            body += 'Time: ' + String.valueOf(System.now()) + '\n\n';

            body += 'Execution flags:\n';
            body += 'IsBatch: ' + System.isBatch() + '\n';
            body += 'IsQueueable: ' + System.isQueueable() + '\n';
            body += 'IsFuture: ' + System.isFuture() + '\n';
            body += 'IsScheduled: ' + System.isScheduled() + '\n\n';

            body += detectExecutionContextStatic() + '\n\n';

            body += 'Accounts attempted: ' + accountNames.size() + '\n';

            for (String name : accountNames) {
                body += '- ' + name + '\n';
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { 'Aleksandr.Novikov@m.interpipe.biz' });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountCreationAlertQueueable failed: ' + e.getMessage());
        }
    }

    // --- Визначення контексту виконання (stack trace)
    private static String detectExecutionContextStatic() {

        String context = 'Execution Context:\n';
        context += 'Batch: ' + System.isBatch() + '\n';
        context += 'Queueable: ' + System.isQueueable() + '\n';
        context += 'Future: ' + System.isFuture() + '\n';
        context += 'Scheduled: ' + System.isScheduled() + '\n\n';

        try {
            throw new AuraHandledException('TRACE');
        } catch (Exception e) {

            List<String> lines = e.getStackTraceString().split('\n');

            List<String> firstLines = new List<String>();
            Integer nlimit = Math.min(10, lines.size());

            for (Integer i = 0; i < nlimit; i++) {
                firstLines.add(lines[i]);
            }

            return context + 'Apex Stack:\n' + String.join(firstLines, '\n');
        }
    }
}