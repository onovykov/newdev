/*
    Legacy Gateway
    Тут іде bulk-обробка списку Opportunity, одна точка для post-callout update LastSyncERP__c,
    і update робиться через Database.update(..., false), щоб один поганий запис не валив увесь пакет.
*/
public with sharing class LegacyOpportunityStageSyncGateway implements IOpportunityStageSyncGateway {
    public void sync(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        List<Opportunity> opportunities = [
            SELECT Id,
                   LastSyncERP__c,
                   ID_ERP__c,
                   StageName,
                   LastModifiedDate,
                   ExpectedDelivDate__c,
                   RecordTypeId,
                   Lead__c,
                   Status__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
              AND Id_ERP__c != null
        ];

        if (opportunities.isEmpty()) {
            return;
        }

        List<Opportunity> updates = new List<Opportunity>();

        for (Opportunity opp : opportunities) {
            //LegacyOpportunityStageSyncService.SyncResult result =
            //    LegacyOpportunityStageSyncService.send(opp);

            LegacyOpportunityStageSyncService.SyncResult result =
                LegacyOpportunityStageSyncServiceFacade.send(opp);
                
            if (result != null && result.success == true) {
                updates.add(new Opportunity(
                    Id = opp.Id,
                    LastSyncERP__c = System.now()
                ));
            }
        }

        if (!updates.isEmpty()) {
            Database.update(updates, false);
        }
    }
}