public class RecordTypeRegistry {
    // 🔹 Константи RecordTypeId
    public static final Id RT_OPP_NEW_CLIENT_ENQUIRY    = '012S8000003CKzEIAW';
    public static final Id RT_OPP_TUBES_SIMPLE_RFP      = '0120Y0000015nlnQAA';
    public static final Id RT_OPP_TUBES_TENDER          = '0120Y0000015nlmQAA';
    public static final Id RT_OPP_WHEELS_SIMPLE_RFP     = '0121n000000FrcGAAS';
    public static final Id RT_OPP_WHEELS_TENDER         = '0121n000000FrcLAAS';

    public static final Id RT_CONTACT_INTERNAL          = '0120Y000000WrG4QAK';
    public static final Id RT_CONTACT_EXTERNAL          = '0120Y000000WrG3QAK';

    public static final Id RT_SPF_ACTUAL_BUDGET         = '0121n000000WwrbAAC';
    public static final Id RT_SPF_CORRECTED_BUDGET      = '0120Y000000WwJtQAK';
    public static final Id RT_SPF_FACT                  = '0120Y000000WwJuQAK';
    public static final Id RT_SPF_INITIAL_BUDGET        = '0120Y000000WWJWQAK';
    public static final Id RT_SPF_OPPORTUNITY           = '0120Y000000WwJvQAK';
    public static final Id RT_SPF_ORDER                 = '0120Y000000Wwc7QAC';
    public static final Id RT_SPF_PLAN                  = '0120Y000000WwJxQAK';

    public static final Id RT_SBR_PLAN_MONTH            = '0120Y000000FjsSQAS';
    public static final Id RT_SBR_PLAN_QUARTER          = '0120Y000000FjsTQAS';

    // 🔹 Map: ObjectName:RecordTypeName → Id
    public static final Map<String, Id> NameToId = new Map<String, Id>{
        'Opportunity:New Client`s Enquiry' => RT_OPP_NEW_CLIENT_ENQUIRY,
        'Opportunity:Tubes: Simple RFP'    => RT_OPP_TUBES_SIMPLE_RFP,
        'Opportunity:Tubes: Tender'        => RT_OPP_TUBES_TENDER,
        'Opportunity:Wheels: Simple RFP'   => RT_OPP_WHEELS_SIMPLE_RFP,
        'Opportunity:Wheels: Tender'       => RT_OPP_WHEELS_TENDER,

        'Contact:Internal'                 => RT_CONTACT_INTERNAL,
        'Contact:External'                 => RT_CONTACT_EXTERNAL,

        'SalesPlanFact:Actual Budget'     => RT_SPF_ACTUAL_BUDGET,
        'SalesPlanFact:Corrected Budget'  => RT_SPF_CORRECTED_BUDGET,
        'SalesPlanFact:Fact'              => RT_SPF_FACT,
        'SalesPlanFact:Initial Budget'    => RT_SPF_INITIAL_BUDGET,
        'SalesPlanFact:Opportunity'       => RT_SPF_OPPORTUNITY,
        'SalesPlanFact:Order'             => RT_SPF_ORDER,
        'SalesPlanFact:Plan'              => RT_SPF_PLAN,

        'SalesBudgetRecord:Plan Month'    => RT_SBR_PLAN_MONTH,
        'SalesBudgetRecord:Plan Quarter'  => RT_SBR_PLAN_QUARTER
    };

    // 🔹 Map: Id → ObjectName:RecordTypeName
    public static final Map<Id, String> IdToName = new Map<Id, String>{
        RT_OPP_NEW_CLIENT_ENQUIRY   => 'Opportunity:New Client`s Enquiry',
        RT_OPP_TUBES_SIMPLE_RFP     => 'Opportunity:Tubes: Simple RFP',
        RT_OPP_TUBES_TENDER         => 'Opportunity:Tubes: Tender',
        RT_OPP_WHEELS_SIMPLE_RFP    => 'Opportunity:Wheels: Simple RFP',
        RT_OPP_WHEELS_TENDER        => 'Opportunity:Wheels: Tender',

        RT_CONTACT_INTERNAL         => 'Contact:Internal',
        RT_CONTACT_EXTERNAL         => 'Contact:External',

        RT_SPF_ACTUAL_BUDGET        => 'SalesPlanFact:Actual Budget',
        RT_SPF_CORRECTED_BUDGET     => 'SalesPlanFact:Corrected Budget',
        RT_SPF_FACT                 => 'SalesPlanFact:Fact',
        RT_SPF_INITIAL_BUDGET       => 'SalesPlanFact:Initial Budget',
        RT_SPF_OPPORTUNITY          => 'SalesPlanFact:Opportunity',
        RT_SPF_ORDER                => 'SalesPlanFact:Order',
        RT_SPF_PLAN                 => 'SalesPlanFact:Plan',

        RT_SBR_PLAN_MONTH           => 'SalesBudgetRecord:Plan Month',
        RT_SBR_PLAN_QUARTER         => 'SalesBudgetRecord:Plan Quarter'
    };

    // 🔹 Перевірка типу запису за ID
    public static Boolean isRecordType(SObject record, Id expectedRecordTypeId) {
        return record != null && record.get('RecordTypeId') == expectedRecordTypeId;
    }

    // 🔹 Перевірка типу запису за іменем
    public static Boolean isRecordType(SObject record, String objectApiName, String recordTypeName) {
        Id expectedId = NameToId.get(objectApiName + ':' + recordTypeName);
        return expectedId != null && record.get('RecordTypeId') == expectedId;
    }
}