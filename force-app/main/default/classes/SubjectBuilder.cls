public with sharing class SubjectBuilder {
    public static String build(NotificationTypes.NotificationPayload p, User u, Contact c){
        if (p == null) return 'Notification';
        if (p.eventKey == 'OPP_CLOSED_WON_USERS') {
            String name = (p.context != null && p.context.getSObjectType() == Opportunity.SObjectType) ? String.valueOf(p.context.get('Name')) : '';
            return 'Closed Won: ' + name;
        } else if (p.eventKey == 'AR_OVERDUE_7D_USERS') {
            String accName = (p.context != null) ? String.valueOf(p.context.get('Name')) : '';
            return '[AR 7d] ' + accName;
        } else if (p.eventKey != null && p.eventKey.startsWith('ERR_')) {
            return '[SF ERROR] ' + p.eventKey;
        }
        return 'Notification: ' + p.eventKey;
    }
}