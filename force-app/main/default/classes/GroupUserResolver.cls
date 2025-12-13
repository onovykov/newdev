public with sharing class GroupUserResolver {

    /** Кеш: група → сет юзерів */
    private static Map<Id, Set<Id>> groupUsersCache = new Map<Id, Set<Id>>();

    /**
     * Отримати Id групи за DeveloperName
     */
    public static Id getGroupIdByDeveloperName(String developerName) {
        Group g = [
            SELECT Id 
            FROM Group 
            WHERE DeveloperName = :developerName 
            LIMIT 1
        ];
        return g.Id;
    }

    /**
     * Головний метод: повертає усіх юзерів групи (враховуючи вкладені групи/ролі)
     */
    public static Set<Id> getAllUsersFromGroup(Id groupId) {

        if (groupUsersCache.containsKey(groupId)) {
            return groupUsersCache.get(groupId);
        }

        // Витягуємо ВСІ зв'язки GroupMember одним запитом
        List<GroupMember> allLinks = [
            SELECT GroupId, UserOrGroupId
            FROM GroupMember
        ];

        // Індекс за GroupId → GroupMember
        Map<Id, List<GroupMember>> byGroup = new Map<Id, List<GroupMember>>();
        for (GroupMember gm : allLinks) {
            if (!byGroup.containsKey(gm.GroupId)) {
                byGroup.put(gm.GroupId, new List<GroupMember>());
            }
            byGroup.get(gm.GroupId).add(gm);
        }

        // BFS: розгортаємо всі вкладені групи
        Set<Id> allGroups = new Set<Id>{ groupId };
        Set<Id> toProcess = new Set<Id>{ groupId };

        while (!toProcess.isEmpty()) {
            Set<Id> next = new Set<Id>();
            for (Id gId : toProcess) {
                if (byGroup.containsKey(gId)) {
                    for (GroupMember m : byGroup.get(gId)) {

                        if (isGroupId(m.UserOrGroupId) && !allGroups.contains(m.UserOrGroupId)) {
                            allGroups.add(m.UserOrGroupId);
                            next.add(m.UserOrGroupId);
                        }
                    }
                }
            }
            toProcess = next;
        }

        // Тепер отримуємо ВСІ member-и всіх знайдених груп
        List<GroupMember> members = [
            SELECT GroupId, UserOrGroupId
            FROM GroupMember
            WHERE GroupId IN :allGroups
        ];

        // Категоризація: Users, Roles, Roles+Subordinates
        Set<Id> resultUsers = new Set<Id>();
        Set<Id> roleIds = new Set<Id>();
        Set<Id> roleSubIds = new Set<Id>();

        for (GroupMember m : members) {

            String prefix = String.valueOf(m.UserOrGroupId).substring(0, 3);

            if (prefix == '005') {                    // User
                resultUsers.add(m.UserOrGroupId);

            } else if (prefix == '00E') {             // Role
                roleIds.add(m.UserOrGroupId);

            } else if (prefix == '00D') {             // RoleAndSubordinates
                roleSubIds.add(m.UserOrGroupId);
            }
        }

        // Users за Role
        if (!roleIds.isEmpty()) {
            for (User u : [
                SELECT Id FROM User WHERE UserRoleId IN :roleIds
            ]) {
                resultUsers.add(u.Id);
            }
        }

        // Users за Role+Subordinates
        if (!roleSubIds.isEmpty()) {
            Set<Id> allRelevantRoles = new Set<Id>();

            // Отримаємо Role + Subordinates одним запитом
            List<UserRole> roles = [
                SELECT Id, ParentRoleId
                FROM UserRole
            ];

            // будуємо дерево ролей
            Map<Id, List<Id>> children = new Map<Id, List<Id>>();
            for (UserRole r : roles) {
                if (r.ParentRoleId != null) {
                    if (!children.containsKey(r.ParentRoleId)) {
                        children.put(r.ParentRoleId, new List<Id>());
                    }
                    children.get(r.ParentRoleId).add(r.Id);
                }
            }

            // BFS по ролях
            Set<Id> queue = new Set<Id>(roleSubIds);
            allRelevantRoles.addAll(roleSubIds);

            while (!queue.isEmpty()) {
                Set<Id> next = new Set<Id>();
                for (Id rId : queue) {
                    if (children.containsKey(rId)) {
                        for (Id child : children.get(rId)) {
                            if (!allRelevantRoles.contains(child)) {
                                allRelevantRoles.add(child);
                                next.add(child);
                            }
                        }
                    }
                }
                queue = next;
            }

            // Users з урахуванням усіх підлеглих ролей
            for (User u : [
                SELECT Id 
                FROM User 
                WHERE UserRoleId IN :allRelevantRoles
            ]) {
                resultUsers.add(u.Id);
            }
        }

        groupUsersCache.put(groupId, resultUsers);
        return resultUsers;
    }

    private static Boolean isGroupId(Id anyId) {
        return String.valueOf(anyId).startsWith('00G');
    }
}