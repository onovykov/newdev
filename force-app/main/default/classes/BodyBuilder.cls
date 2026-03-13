public with sharing class BodyBuilder {
    public static String build(NotificationTypes.NotificationPayload p, User u, Contact c){
        if (p == null) return '';
        String s = 'Event: ' + p.eventKey + '\n';
        if (p.vars != null) for (String k : p.vars.keySet()) s += k + ': ' + String.valueOf(p.vars.get(k)) + '\n';
        return s;
    }
}