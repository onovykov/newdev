public class AccountBisDevTrigger extends TriggerHandler implements ITrigger {

    private final static Map<String, String> BusinessDivisionMap = new Map<String, String> {
        'Pipes' => 'Pipe Products',
        'Railway' => 'Railway Products',
        'Steel' => 'Steel Products',
        'PRD' => 'Product & Resource Dept.',
        'Marketing' => 'Marketing',
        'IT' => 'IT Department',
        'Customer' => 'Customer',
        'TOP' => 'Top Management'
    };

    public AccountBisDevTrigger(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, List<SObject> oldList, List<SObject> newList) {
        super(oldMap, newMap, oldList, newList);
    }

    public void bulkBefore() {
        System.debug('bulkBefore AccountBisDevTrigger');
    }

    public void bulkAfter() {
        System.debug('bulkAfter');
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        System.debug('beforeUpdate');
    }
  
    public void beforeInsert(SObject so) {
        AccountBusinessDivisions__c abd = (AccountBusinessDivisions__c) so;
        abd.Name = BusinessDivisionMap.get(abd.BusinessDivision__c) != null ? BusinessDivisionMap.get(abd.BusinessDivision__c) : abd.BusinessDivision__c;
    } 

    public void beforeDelete(SObject so) {
        System.debug('beforeDelete');
    }

    public void afterInsert(SObject so) {
        System.debug('afterInsert'); 
    }
  
    public void afterUpdate(SObject oldSo, SObject so) {    
    }

    public void afterDelete(SObject so) {
    }

    public override void beforePostProcessing() {
    }

    public void postProcessing() {
    }

/*****************************************************************/
    public void afterInsert(List<AccountBusinessDivisions__c> newRecords) {
        createAccountSalesSegmentation(newRecords);
    }
    
    public static void createAccountSalesSegmentation(List<AccountBusinessDivisions__c> newRecords) {
        List<AccountSalesSegmentation__c> assList = new List<AccountSalesSegmentation__c>();
        Map<Id, Account> accountMap = getAccountMap(newRecords);

        for(AccountBusinessDivisions__c record : newRecords) {
            if (accountMap.get(record.Account__c).Owner.Name != 'IT-Enterprise') {
                AccountSalesSegmentation__c assRec = new AccountSalesSegmentation__c(
                    AccountBusinessDivision__c = record.Id, 
                    Account__c = record.Account__c, 
                    Manager__c = accountMap.get(record.Account__c).OwnerId,
                    MarketSegment__c = accountMap.get(record.Account__c).Owner.SalesDivision__c
                );
                assList.add(assRec);
            }
        }

        insert(assList);
    }

    private static Map<Id, Account> getAccountMap(List<AccountBusinessDivisions__c> abdList) {
        Set<Id> accountIdSet = new Set<Id>();
        for(AccountBusinessDivisions__c abd : abdList) {
            accountIdSet.add(abd.Account__c);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId, Owner.SalesDivision__c, Owner.Name 
                                                            FROM Account 
                                                            WHERE Id IN :accountIdSet]);

        return accountMap;
    }
}