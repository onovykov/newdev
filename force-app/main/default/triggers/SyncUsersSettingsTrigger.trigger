trigger SyncUsersSettingsTrigger on SyncUsersSettings__c (after insert, after update) {
    SyncUsersSettingsTriggerHandler.afterSave();
}