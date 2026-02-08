public with sharing class ErpIdValidationApi {

    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled(cacheable=true)
    public static ValidationResult validateErpId(String erpId) {
        ValidationResult r = new ValidationResult();
        r.isValid = true;
        r.errorMessage = null;

        if (String.isBlank(erpId)) {
            r.isValid = false;
            r.errorMessage = 'ERP ID is required.';
            return r;
        }

        if (!Pattern.matches('^[0-9]+$', erpId)) {
            r.isValid = false;
            r.errorMessage = 'ERP ID must contain digits only.';
            return r;
        }

        if (Integer.valueOf(erpId) <= 0) {
            r.isValid = false;
            r.errorMessage = 'ERP ID must be greater than 0.';
            return r;
        }

        List<Account> acc = [
            SELECT Id
            FROM Account
            WHERE ID_ERP__c = :erpId
            LIMIT 1
        ];

        if (!acc.isEmpty()) {
            r.isValid = false;
            r.errorMessage = 'ERP ID already exists.';
        }

        return r;
    }
}