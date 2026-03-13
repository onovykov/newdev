public with sharing class NotificationTypes {

    public class NotificationPayload {
        public String eventKey;
        public SObject context;
        public Map<String, Object> vars;

        /** Створює payload події: ключ, контекст, змінні */
        public NotificationPayload(String e, SObject c, Map<String, Object> v) {
            eventKey = e;
            context = c;
            vars = (v == null) ? new Map<String, Object>() : v;
        }

        public NotificationPayload() {}
    }

    public class NotificationEventCfg {
        public String eventKey;
        public Boolean active;
        public String channel;
        public List<String> recipientGroupKeys = new List<String>();
        public String templateApiName;
        public Boolean saveAsActivity;
        public Integer throttleMinutes;
        public Integer batchSize;
    }

    public class RecipientBundle {
        public Set<Id> userIds = new Set<Id>();
        public Set<Id> contactIds = new Set<Id>();
        public Set<String> emails = new Set<String>();
        public String resolverTrace;

        /** true — якщо немає жодного отримувача */
        public Boolean isEmpty() {
            return userIds.isEmpty() && contactIds.isEmpty() && emails.isEmpty();
        }

        /** Загальна кількість отримувачів */
        public Integer totalCount() {
            return userIds.size() + contactIds.size() + emails.size();
        }
    }

    public class ChannelResult {
        public Boolean ok;
        public String message;
        public Integer sentCount;
    }
}