public with sharing class CreateSupplierService {

    // =============================
    // INPUT DTO
    // =============================
    public class Request {

        // --- Required ---
        @InvocableVariable(required=true)
        public String erpId;

        @InvocableVariable(required=true)
        public String accountName;

        @InvocableVariable(required=true)
        public Id recordTypeId;

        @InvocableVariable(required=true)
        public Id ownerId;

        // --- Contact / Communication ---
        @InvocableVariable
        public String phone;

        @InvocableVariable
        public String mobile;

        @InvocableVariable
        public String email;

        @InvocableVariable
        public String website;

        // --- Billing Address ---
        @InvocableVariable
        public String billingStreet;

        @InvocableVariable
        public String billingPostalCode;

        @InvocableVariable
        public String billingCountry;

        @InvocableVariable
        public String billingCountryCode;

        // --- Shipping Address ---
        @InvocableVariable
        public String shippingStreet;

        @InvocableVariable
        public String shippingPostalCode;

        @InvocableVariable
        public String shippingCountry;

        @InvocableVariable
        public String shippingCountryCode;

        @InvocableVariable
        public String accountCity;

        // --- Business Attributes ---
        @InvocableVariable
        public String accountCurrency;

        @InvocableVariable
        public String marketSegment;

        @InvocableVariable
        public String activityType;

        // --- Hierarchy / Defaults ---
        @InvocableVariable
        public Id parentId;
    }

    // =============================
    // OUTPUT DTO
    // =============================
    public class Response {
        @InvocableVariable
        public Id accountId;
    }

    // =============================
    // INVOCABLE METHOD
    // =============================
    @InvocableMethod(label='Create Supplier Account (Full)')
    public static List<Response> create(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request req : requests) {

            // =============================
            // FINAL VALIDATION
            // =============================
            if (String.isBlank(req.erpId)) {
                throw new AuraHandledException('ERP ID is required');
            }
            if (!Pattern.matches('\\d+', req.erpId)) {
                throw new AuraHandledException('ERP ID must contain digits only');
            }
            if (Integer.valueOf(req.erpId) <= 0) {
                throw new AuraHandledException('ERP ID must be greater than zero');
            }

            if (![
                SELECT Id
                FROM Account
                WHERE ID_ERP__c = :req.erpId
                LIMIT 1
            ].isEmpty()) {
                throw new AuraHandledException(
                    'Account with this ERP ID already exists'
                );
            }

            // =============================
            // ACCOUNT CREATION
            // =============================
            Account acc = new Account();

            // --- Identity ---
            acc.Name = req.accountName;
            acc.ID_ERP__c = req.erpId;
            acc.RecordTypeId = req.recordTypeId;
            acc.OwnerId = req.ownerId;
            acc.ParentId = req.parentId;

            // --- Communication ---
            acc.Phone = req.phone;
            acc.Mobile__c = req.mobile;
            acc.Email__c = req.email;
            acc.Website = req.website;

            // --- Billing ---
            acc.BillingStreet = req.billingStreet;
            acc.BillingPostalCode = req.billingPostalCode;
            acc.BillingCountry = req.billingCountry;
            acc.BillingCountryCode = req.billingCountryCode;
            acc.BillingCity = req.accountCity;

            // --- Shipping ---
            acc.ShippingStreet = req.shippingStreet;
            acc.ShippingPostalCode = req.shippingPostalCode;
            acc.ShippingCountry = req.shippingCountry;
            acc.ShippingCountryCode = req.shippingCountryCode;
            acc.ShippingCity = req.accountCity;

            // --- Business fields ---
            acc.CurrencyIsoCode = req.accountCurrency;
            acc.MarketSegment__c = req.marketSegment;
            acc.Activity_Type__c = req.activityType;

            // --- Defaults ---
            acc.Level__c = 2;
            acc.Under_Sanctions__c = false;

            insert acc;

            Response r = new Response();
            r.accountId = acc.Id;
            responses.add(r);
        }

        return responses;
    }
}