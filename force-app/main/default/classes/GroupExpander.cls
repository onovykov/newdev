public with sharing class GroupExpander {
    private static Map<Id, Set<Id>> usersByGroup = new Map<Id, Set<Id>>();
    public static Set<Id> expandUsers(Id groupId) {
        if (groupId == null) return new Set<Id>();
        if (usersByGroup.containsKey(groupId)) return usersByGroup.get(groupId);
        Set<Id> users = new Set<Id>();
        Set<Id> visited = new Set<Id>();
        List<Id> stack = new List<Id>{ groupId };
        while (!stack.isEmpty()) {
            Id gid = stack.remove(stack.size()-1);
            if (visited.contains(gid)) continue;
            visited.add(gid);
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :gid]) {
                String p = String.valueOf(gm.UserOrGroupId).left(3);
                if (p == '005') users.add(gm.UserOrGroupId);
                else if (p == '00G') stack.add(gm.UserOrGroupId);
            }
        }
        usersByGroup.put(groupId, users);
        return users;
    }
}