public with sharing class NotificationResultFactory {
    public static NotificationTypes.ChannelResult none(){
        NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
        r.ok = true; r.sentCount = 0;
        return r;
    }

    public static NotificationTypes.ChannelResult fromResults(List<Messaging.SendEmailResult> results){
        NotificationTypes.ChannelResult r = new NotificationTypes.ChannelResult();
        r.ok = true; r.sentCount = 0;
        if (results != null) {
            for (Messaging.SendEmailResult e : results){
                if (!e.isSuccess()){
                    r.ok = false;
                    if (String.isBlank(r.message) && !e.getErrors().isEmpty()) {
                        r.message = e.getErrors()[0].getMessage();
                    }
                } else {
                    r.sentCount = (r.sentCount == null ? 0 : r.sentCount) + 1;
                }
            }
        }
        return r;
    }
}