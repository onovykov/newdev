public with sharing class RecipientResolver {

    /** Розв'язує отримувачів для події: бере Recipient Groups з cfg, читає їх конфіги з CMDT і збирає userIds/contactIds/emails. */
    public static NotificationTypes.RecipientBundle resolve(
            NotificationTypes.NotificationEventCfg cfg,
            SObject context
    ) {
        NotificationTypes.RecipientBundle out = new NotificationTypes.RecipientBundle();
        if (cfg == null || cfg.recipientGroupKeys == null || cfg.recipientGroupKeys.isEmpty()) {
            out.resolverTrace = 'No recipient groups in event cfg';
            return out;
        }

        RecipientGroupRepo.prime(new Set<String>(cfg.recipientGroupKeys));

        ContextInfo ctx = buildContext(context);

        List<String> trace = new List<String>();
        for (String groupKey : cfg.recipientGroupKeys) {
            RecipientGroupRepo.RecipientGroupCfg g = RecipientGroupRepo.getGroupCfg(groupKey);

            if (g == null) {
                trace.add(groupKey + ': group not found');
                continue;
            }

            String kind = safeTrim(g.kind);
            String def  = safeTrim(g.definition);

            if (String.isBlank(kind) || String.isBlank(def)) {
                trace.add(g.key + ': kind/definition is blank');
                continue;
            }

            if (kind == 'Users') {
                Integer before = out.userIds.size();
                resolveUsers(def, ctx, out.userIds);
                trace.add(g.key + ': Users ' + def + ' +' + String.valueOf(out.userIds.size() - before));
            } else if (kind == 'Contacts') {
                Integer before = out.contactIds.size();
                resolveContacts(def, ctx, out.contactIds);
                trace.add(g.key + ': Contacts ' + def + ' +' + String.valueOf(out.contactIds.size() - before));
            } else if (kind == 'Emails') {
                Integer before = out.emails.size();
                resolveEmails(def, out.emails);
                trace.add(g.key + ': Emails +' + String.valueOf(out.emails.size() - before));
            } else {
                trace.add(g.key + ': unsupported kind=' + kind);
            }
        }

        out.resolverTrace = String.join(trace, ' | ');
        return out;
    }

    /** Готує “контекст” для резолвінгу: Opportunity/Account і потрібні поля (OwnerId, MarketSegment__c тощо). */
    private static ContextInfo buildContext(SObject context) {
        ContextInfo ctx = new ContextInfo();
        if (context == null) {
            return ctx;
        }

        if (context.getSObjectType() == Opportunity.SObjectType) {
            ctx.opp = (Opportunity) context;
            if (ctx.opp.AccountId != null) {
                ctx.acc = loadAccount(ctx.opp.AccountId);
            }
        } else if (context.getSObjectType() == Account.SObjectType) {
            Account a = (Account) context;
            ctx.acc = ensureAccountFields(a);
        }

        return ctx;
    }

    /** Резолвить Users по “definition token”: OPP_OWNER, ACCOUNT_OWNER, SYSADMINS, BACKOFFICE_BY_SEGMENT. */
    private static void resolveUsers(String definition, ContextInfo ctx, Set<Id> outUserIds) {
        if (definition == 'OPP_OWNER') {
            if (ctx.opp != null && ctx.opp.OwnerId != null) {
                outUserIds.add(ctx.opp.OwnerId);
            }
            return;
        }

        if (definition == 'ACCOUNT_OWNER') {
            if (ctx.acc != null && ctx.acc.OwnerId != null) {
                outUserIds.add(ctx.acc.OwnerId);
            }
            return;
        }

        if (definition == 'SYSADMINS') {
            for (User u : querySysAdmins()) {
                outUserIds.add(u.Id);
            }
            return;
        }

        if (definition == 'BACKOFFICE_BY_SEGMENT') {
            String seg = (ctx.acc == null) ? null : (String) ctx.acc.get('MarketSegment__c');
            if (String.isBlank(seg)) {
                return;
            }

            String devName = 'BACKOFFICE_' + seg;
            Id groupId = findPublicGroupIdByDeveloperName(devName);
            if (groupId != null) {
                outUserIds.addAll(expandUsersFromGroup(groupId));
            }
            return;
        }

        if (definition == 'HELPDESK_ADMIN') {
            for (User u : queryHelpdeskAdmins()) {
                outUserIds.add(u.Id);
            }
            return;
        }

        if (definition == 'SEGMENT_CHIEF') {
            String seg = (ctx.acc == null) ? null : (String) ctx.acc.get('MarketSegment__c');
            if (String.isBlank(seg)) {
                return;
            }
            for (User u : querySegmentChiefs(seg)) {
                outUserIds.add(u.Id);
            }
            return;
        }
    }

    /** Резолвить Contacts по "definition token": IT_ADMIN_INTERPIPE_UA, ORDERS_ADMIN_INTERPIPE_UA, INTEGRATION_PRIMARY_ADMIN, HELPDESK_ADMIN або CSV правил (див. нижче). */
    private static void resolveContacts(String definition, ContextInfo ctx, Set<Id> outContactIds) {
        if (definition == 'IT_ADMIN_INTERPIPE_UA') {
            Id accId = NotificationConstants.getInterpipeUkraineAccountId();
            List<Contact> itAdmins = ContactRepository.getByAccountAndType(accId, 'IT-Admin');
            for (Contact c : itAdmins) {
                outContactIds.add(c.Id);
            }
            return;
        }

        if (definition == 'ORDERS_ADMIN_INTERPIPE_UA') {
            Id accId = NotificationConstants.getInterpipeUkraineAccountId();
            List<Contact> ordersAdmins = ContactRepository.getByAccountAndType(accId, 'OrdersAdmin');
            for (Contact c : ordersAdmins) {
                outContactIds.add(c.Id);
            }
            return;
        }

        if (definition == 'INTEGRATION_PRIMARY_ADMIN') {
            System.debug('============= INTEGRATION_PRIMARY_ADMIN =================');

            List<Contact> integrationAdmins = ContactRepository.getByType('Integration Primary Admin');
            System.debug('integrationAdmins: ' + integrationAdmins);
            for (Contact c : integrationAdmins) {
                outContactIds.add(c.Id);
            }
            return;
        }

        if (definition == 'HELPDESK_ADMIN') {
            List<Contact> helpdeskAdmins = ContactRepository.getByType('Helpdesk Admin');
            for (Contact c : helpdeskAdmins) {
                outContactIds.add(c.Id);
            }
            return;
        }
    }

    /** Додає “raw emails” із definition (CSV). */
    private static void resolveEmails(String definition, Set<String> outEmails) {
        if (String.isBlank(definition)) {
            return;
        }
        for (String part : definition.split(',')) {
            String e = safeTrim(part);
            if (!String.isBlank(e)) {
                outEmails.add(e);
            }
        }
    }

    /** Повертає активних користувачів з профілем System Administrator (кеш на транзакцію). */
    private static List<User> querySysAdmins() {
        if (sysAdminsCache != null) {
            return sysAdminsCache;
        }
        sysAdminsCache = [
                SELECT Id
                FROM User
                WHERE IsActive = true AND Profile.Name = 'System Administrator'
        ];
        return sysAdminsCache;
    }

    /** Повертає активних користувачів з UserRole.Name = 'Help Desk Admin'. */
    private static List<User> queryHelpdeskAdmins() {
        return [
                SELECT Id
                FROM User
                WHERE IsActive = true AND UserRole.Name = 'Help Desk Admin'
        ];
    }

    /** Повертає Chiefs of Market Segment або Senior Sales Managers для заданого сегмента. */
    private static List<User> querySegmentChiefs(String segment) {
        // Шукаємо користувачів де UserRole.Name містить назву сегмента
        // Або UserRole.Name = 'Senior Sales Manager'
        String rolePattern = '%' + segment + '%';
        return [
                SELECT Id
                FROM User
                WHERE IsActive = true
                AND (UserRole.Name LIKE :rolePattern OR UserRole.Name = 'Senior Sales Manager')
        ];
    }

    /** Знаходить Public Group (Regular) по DeveloperName і повертає його Id. */
    private static Id findPublicGroupIdByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Group> grps = [
                SELECT Id
                FROM Group
                WHERE Type = 'Regular' AND DeveloperName = :developerName
                LIMIT 1
        ];
        return grps.isEmpty() ? null : grps[0].Id;
    }

    /** Розгортає Group → UserIds (підтримує вкладені групи), без рекурсії і з захистом від циклів. */
    private static Set<Id> expandUsersFromGroup(Id rootGroupId) {
        Set<Id> users = new Set<Id>();
        if (rootGroupId == null) {
            return users;
        }

        Set<Id> visitedGroups = new Set<Id>();
        Set<Id> pendingGroups = new Set<Id>{ rootGroupId };

        while (!pendingGroups.isEmpty()) {
            Set<Id> current = new Set<Id>();
            current.addAll(pendingGroups);
            pendingGroups.clear();

            visitedGroups.addAll(current);

            for (GroupMember gm : [
                    SELECT GroupId, UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId IN :current
            ]) {
                String prefix = String.valueOf(gm.UserOrGroupId).substring(0, 3);
                if (prefix == '005') {
                    users.add(gm.UserOrGroupId);
                } else if (prefix == '00G') {
                    if (!visitedGroups.contains(gm.UserOrGroupId)) {
                        pendingGroups.add(gm.UserOrGroupId);
                    }
                }
            }
        }

        return users;
    }

    /** Підтягує Account з потрібними полями, якщо в контексті був тільки Id. */
    private static Account loadAccount(Id accountId) {
        if (accountId == null) {
            return null;
        }
        return [
                SELECT Id, OwnerId, MarketSegment__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
    }

    /** Гарантує, що в Account є поля OwnerId/MarketSegment__c; якщо ні — підтягує з БД. */
    private static Account ensureAccountFields(Account a) {
        if (a == null) {
            return null;
        }

        // Безпечна перевірка чи поля queried і заповнені (без SObjectException)
        Map<String, Object> fields = a.getPopulatedFieldsAsMap();
        Boolean hasOwnerId = fields.containsKey('OwnerId') && fields.get('OwnerId') != null;
        Boolean hasMarketSegment = fields.containsKey('MarketSegment__c') && fields.get('MarketSegment__c') != null;

        if (hasOwnerId && hasMarketSegment) {
            return a;
        }
        return loadAccount(a.Id);
    }

    /** Безпечний trim для String. */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }

    private class ContextInfo {
        public Opportunity opp;
        public Account acc;
    }

    private static List<User> sysAdminsCache;
}