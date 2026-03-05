public class AccountResolver {

    public static AccountResolution resolveByErpId(String erpId) {
        if (String.isBlank(erpId)) {
            return AccountResolution.notFound('ERP Account Id is blank');
        }

        Id accId = AccountCache.getOne(erpId);
        if (accId == null) {
            return AccountResolution.notFound(
                'Account not found for ERP Id=' + erpId
            );
        }

        Account acc = [
            SELECT Id, Name, ID_ERP__c
            FROM Account
            WHERE Id = :accId
            LIMIT 1
        ];

        return AccountResolution.found(acc);
    }
}