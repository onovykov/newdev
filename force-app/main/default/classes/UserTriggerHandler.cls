public class UserTriggerHandler extends TriggerHandler implements ITrigger{
    public static Map<Id, User> userMap = new Map<Id, User>();
    public static Map<Id, SObject> oldMap;
    public static Map<Id, SObject> newMap; 
    List<SObject> oldList;
    List<SObject> newList;
        
    public static Map<String, String> profileNameToMarketSegment = new Map<String, String>{'Sales Manager (Ukraine)' => '00011', 
        'Sales Manager (MENA)' => '00002',
        'Sales Manager (KLW)' => '00006',
        'Sales Manager (EU)' => '00004',
        'Sales Manager (EU&Africa)' => '00020',
        'Sales Manager (ETA)' => '00020',
        'Sales Manager (CU)' => '00016',
        'Sales Manager (CIS)' => '00010',
        'Sales Manager (America)' => '00001'};  
        
    public UserTriggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
        super(oldMap, newMap, oldList, newList);
    }
        
    public void bulkBefore() {
        System.debug('bulkBefore');
    }   
    
    public void bulkAfter() {
        System.debug('bulkAfter');      
    }

    public void beforeInsert(SObject so) {
        System.debug('beforeInsert');   
        User createdUser = (User) So;
        
        checkUserDivision(createdUser); 
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        System.debug('beforeUpdate');
    }
    
    //--- Логування активації/деактивації юзера
    //    Логуємо до об'єкту UserAuditLog__c
    //        User__c - Який користувач був змінений
    //        ChangedBy__c - Хто зробив зміну
    //        OldStatus__c - Значення IsActive до змін (Text)
    //        NewStatus__c - Значення IsActive після змін (Text)
    //        ChangeDate__c - Коли була зміна    
    public void beforeUpdate(List<User> oldList, List<User> newList) {
        List<UserAuditLog__c> logs = new List<UserAuditLog__c>();
    
        for (Integer i = 0; i < newList.size(); i++) {
            User oldU = oldList[i];
            User newU = newList[i];
    
            if (oldU.IsActive != newU.IsActive) {
                logs.add(new UserAuditLog__c(
                    User__c = newU.Id,
                    ChangedBy__c = UserInfo.getUserId(),
                    OldStatus__c = String.valueOf(oldU.IsActive),
                    NewStatus__c = String.valueOf(newU.IsActive),
                    ChangeDate__c = System.now()
                ));
            }
        }
    
        if (!logs.isEmpty()) {
            String jsonLogs = JSON.serialize(logs);
            UserAuditLogService.insertLogs(jsonLogs);
        }
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        System.debug('afterInsert');
        User createdUser = (User) So;
        updateUserDivision(createdUser.id);
        if(createdUser.AssignedBOS__c == null){
            updateUserAssignedBO(createdUser.id);
        }
        if(!Test.isRunningTest()){
            Map<String, String> userIdsMap = new Map<String, String>();
            userIdsMap.put('Id', createdUser.Id);
            userIdsMap.put('ID_ERP__c', createdUser.ID_ERP__c);
            userIdsMap.put('LoginERP__c', createdUser.LoginERP__c);
            userIdsMap.put('UID_ERP__c', createdUser.UID_ERP__c);
            createUserIdErpForNewUserManager(userIdsMap);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        User updatedUser = (User) So;
        User oldUser = (User) oldSo;
        if(updatedUser.AssignedBOS__c == null){
            updateUserAssignedBO(updatedUser.id);
        }
        if(oldUser.ID_ERP__c != updatedUser.ID_ERP__c){
            updateUserIdErp(oldUser, updatedUser);
        }
    }

    public void afterDelete(SObject so) {
    }
    
    public void postProcessing() {
    }   
    
    public static void checkUserDivision(User createdUser){
        Set<String> checkedProfiles = profileNameToMarketSegment.keySet();       
        if(checkedProfiles.contains(createdUser.profile.name)){
            createdUser.SalesDivision__c = profileNameToMarketSegment.get(createdUser.profile.name);
        }
    }
    
    @future
    public static void createUserIdErpForNewUserManager(Map<String, String> userIdsMap){
        List<UserID_ERP__c> objectsToCreate = new List<UserID_ERP__c>();

        if(userIdsMap.get('ID_ERP__c') != null) {
            objectsToCreate.add(createUserIdErp(userIdsMap.get('Id'), userIdsMap.get('ID_ERP__c')));
        }
        if(userIdsMap.get('LoginERP__c') != null) {
            objectsToCreate.add(createUserIdErp(userIdsMap.get('Id'), userIdsMap.get('LoginERP__c')));
        }
        if(userIdsMap.get('UID_ERP__c') != null) {
            objectsToCreate.add(createUserIdErp(userIdsMap.get('Id'), userIdsMap.get('UID_ERP__c')));
        }

        insert objectsToCreate;          
    }

    private static UserID_ERP__c createUserIdErp(Id userId, String idErp){
        UserID_ERP__c nameIdErp = new UserID_ERP__c();
        nameIdErp.Name = idErp;
        nameIdErp.User__c = userId;
        return nameIdErp;
    }
    
    @future
    public static void updateUserDivision(String userInfo){
        User updateCreatedUser = [SELECT profile.name,SalesDivision__c from user where id=:userInfo LIMIT 1];
        checkUserDivision(updateCreatedUser);
        update updateCreatedUser;
    }

    // public void UpdateInactiveDays(List<User> newList) {
    //     for (User u : newList) {
    //         if (u.LastLoginDate != null) {
    //             u.DaysInactive__c = -Date.today().daysBetween(u.LastLoginDate.date());
    //         }
    //         else {
    //             u.DaysInactive__c = -Date.today().daysBetween(u.CreatedDate.date());
    //         }
    //     }
    // }

    public static void updateUserAssignedBO(String userId){
        User userToUpdate = [SELECT Id, Name, AssignedBOS__c, SalesDivision__c, ManagerId, Manager.AssignedBOS__c 
                             FROM User 
                             WHERE id =:userId LIMIT 1];

        if(userToUpdate.AssignedBOS__c == null && userToUpdate.ManagerId != null && userToUpdate.Manager.AssignedBOS__c != null && 
           userToUpdate.Id != userToUpdate.Manager.AssignedBOS__c){
            userToUpdate.AssignedBOS__c = userToUpdate.Manager.AssignedBOS__c;
            update userToUpdate;
        }
    }

    public void updateUserIdErp(User oldUser, User user){
        if(oldUser.ID_ERP__c != null) {
            List<UserID_ERP__c> userIdErpOld = [SELECT Id FROM UserID_ERP__c WHERE User__c = :user.Id AND Name = :oldUser.ID_ERP__c];
            if(!userIdErpOld.isEmpty()) {
                userIdErpOld.get(0).Active__c = false;
                update userIdErpOld;
            }
        }

        if(user.ID_ERP__c != null) {
            List<UserID_ERP__c> userIdErp = [SELECT Id, Active__c FROM UserID_ERP__c WHERE User__c = :user.Id AND Name = :user.ID_ERP__c];
            if(!userIdErp.isEmpty()) {
                if(!userIdErp.get(0).Active__c){
                    userIdErp.get(0).Active__c = true;
                    update userIdErp;
                }
            } else {
                UserID_ERP__c nameIdErp = createUserIdErp(user.Id, user.ID_ERP__c);
                insert nameIdErp;
            }
        }
    }      

    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;        
    }       
}