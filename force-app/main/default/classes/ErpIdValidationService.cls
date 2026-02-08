public with sharing class ErpIdValidationService {

    public class Input {
        @InvocableVariable(required=true)
        public String erpId;
    }

    public class Output {
        @InvocableVariable
        public Boolean isValid;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Validate ERP Id')
    public static List<Output> validate(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input i : inputs) {
            Output o = new Output();
            o.isValid = true;
            o.errorMessage = null;

            // 1️⃣ digits only
            if (!Pattern.matches('^[0-9]+$', i.erpId)) {
                o.isValid = false;
                o.errorMessage = 'ERP ID must contain digits only.';
            }
            // 2️⃣ > 0
            else if (Integer.valueOf(i.erpId) <= 0) {
                o.isValid = false;
                o.errorMessage = 'ERP ID must be greater than 0.';
            }
            // 3️⃣ unique
            else {
                List<Account> acc = [
                    SELECT Id
                    FROM Account
                    WHERE ID_ERP__c = :i.erpId
                    LIMIT 1
                ];
                if (!acc.isEmpty()) {
                    o.isValid = false;
                    o.errorMessage = 'ERP ID already exists for another account.';
                }
            }

            results.add(o);
        }
        return results;
    }
}