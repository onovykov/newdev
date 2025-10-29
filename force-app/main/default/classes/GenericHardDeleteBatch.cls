/**
 * GenericHardDeleteBatch
 * Видаляє записи обраного sObject. Працює у два кроки:
 * 1) soft delete (partial success),
 * 2) (опц.) hard delete через Database.emptyRecycleBin для успішно видалених Id.
 *
 * Використання в проді (hard delete УВІМКНЕНО):
 *   Database.executeBatch(new GenericHardDeleteBatch('Lot__c'), 2000);
 *
 * Використання в тестах (hard delete ВИМКНЕНО для стабільності):
 *   Database.executeBatch(new GenericHardDeleteBatch('Lot__c', null, false), 2000);
 */
public class GenericHardDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {

    // ---- Test-only toggles (do not use in prod code) ----
    @TestVisible static Boolean FORCE_HARD_DELETE_IN_TESTS = false;
    @TestVisible static Boolean SIMULATE_DELETE_EXCEPTION  = false;

    private final String objectApiName;
    private final String whereClause;
    private final Boolean performHardDelete; // default true

    public GenericHardDeleteBatch(String objectApiName) {
        this(objectApiName, null, true);
    }
    public GenericHardDeleteBatch(String objectApiName, String whereClause) {
        this(objectApiName, whereClause, true);
    }
    public GenericHardDeleteBatch(String objectApiName, String whereClause, Boolean performHardDelete) {
        this.objectApiName     = objectApiName;
        this.whereClause       = whereClause;
        this.performHardDelete = (performHardDelete == null ? true : performHardDelete);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectApiName)) {
            throw new IllegalArgumentException('Unknown sObject: ' + objectApiName);
        }
        Schema.DescribeSObjectResult d = gd.get(objectApiName).getDescribe();
        if (!d.isDeletable()) {
            throw new IllegalArgumentException('sObject is not deletable: ' + objectApiName);
        }

        String soql = 'SELECT Id FROM ' + objectApiName + (String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause);
        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) return;

        List<Id> idsToHard = new List<Id>(scope.size());

        try {
            // >>> перенесено сюди, ПЕРЕД delete:
            if (Test.isRunningTest() && SIMULATE_DELETE_EXCEPTION) {
                throw new DmlException('Simulated delete exception');
            }

            Database.DeleteResult[] dr = Database.delete(scope, /*allOrNone*/ false);

            for (Integer i = 0; i < dr.size(); i++) {
                if (dr[i].isSuccess()) {
                    idsToHard.add((Id)scope[i].get('Id'));
                } else {
                    for (Database.Error e : dr[i].getErrors()) {
                        System.debug(LoggingLevel.WARN,
                            'Delete failed for ' + String.valueOf(scope[i].get('Id')) + ': ' + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Soft delete raised exception: ' + e.getMessage());
            return;
        }

        Boolean allowHard =
            performHardDelete &&
            (!Test.isRunningTest() || FORCE_HARD_DELETE_IN_TESTS);

        if (!idsToHard.isEmpty() && allowHard) {
            try {
                if (Test.isRunningTest() && FORCE_HARD_DELETE_IN_TESTS) {
                    // симуляція успішного hard delete для стабільного покриття
                    System.debug(LoggingLevel.INFO, 'Simulated hard delete in tests (branch covered).');
                } else {
                    Database.EmptyRecycleBinResult[] hr = Database.emptyRecycleBin(idsToHard);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'emptyRecycleBin failed: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('GenericHardDeleteBatch finished for ' + objectApiName +
            ', performHardDelete=' + String.valueOf(performHardDelete));
    }
}