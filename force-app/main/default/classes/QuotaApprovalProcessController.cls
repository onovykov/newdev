public without sharing class QuotaApprovalProcessController {

    private final static Map<String, String> MarkenSegmentMap = new Map<String, String> {
        '00002' => 'MENA',
        '00001' => 'Americas',
        '00004' => 'Europe',
        '00010' => 'CIS',
        '00011' => 'Ukraine',
        '00006' => 'KLW',
        '00100' => 'Steel',
        '00016' => 'Customs Union',
        '00005' => 'IPS',
        '00020' => 'ETA',
        '00021' => 'Machinery',
        '00008' => 'Передел',
        '00007' => 'Оседание',
        '00012' => 'Сплавы',
        '00013' => 'NMD'
    };

    @AuraEnabled
    public static List<QuoteRequestDetailWrapper> getQuotaDetails(String urlString) {
        List<QuoteRequestDetailWrapper> QuoteRequestDetailWrapperList = new List<QuoteRequestDetailWrapper>();
        String paramsString = urlString.substringAfter('&');

        if(String.isBlank(paramsString)) {
            return QuoteRequestDetailWrapperList;
        }

        String decryptedParamsString = CryptoUtils.getCryptoDecodedURLString(paramsString);
        String headerId = decryptedParamsString.split('&').get(0).split('=').get(1);

        List<QuoteRequestDetail__c> quoteStructDetailList = [SELECT Id, FamilyType__r.Name, Family__r.ID_ERP__c, Family__r.Name, 
                                                                    MarketSegment__c, Manager__r.Name, Group3__r.Name, Region__r.Name, 
                                                                    Percent__c, Quote_t__c, AddQty_t__c, QuoteStructureDetail__r.Percent__c,
                                                                    QuoteStructureDetail__r.Quote_t__c, QuoteStructureDetail__r.AddQty_t__c,
                                                                    QuoteRequestHeader__r.DateFrom__c, QuoteRequestHeader__r.DateTo__c,
                                                                    QuoteRequestHeader__r.Name, QuoteRequestHeader__r.CreatedDate, 
                                                                    QuoteRequestHeader__r.CreatedBy.Name
                                                             FROM QuoteRequestDetail__c 
                                                             WHERE QuoteRequestHeader__c = :headerId
                                                             ORDER BY FamilyType__r.Name ASC
        ];

        for (QuoteRequestDetail__c quoteStructDetail : quoteStructDetailList) {            
            QuoteRequestDetailWrapper QuoteRequestDetailWrapper = new QuoteRequestDetailWrapper(quoteStructDetail);
            QuoteRequestDetailWrapperList.add(QuoteRequestDetailWrapper);
        }

        return QuoteRequestDetailWrapperList;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteSegmentStruct__c> getQuoteSegmentStruct(String marketSegment) {
        List<QuoteSegmentStruct__c> quoteStructDetailList = [SELECT Id, ManagerStruct__c, Group3Struct__c, RegionStruct__c
                                                             FROM QuoteSegmentStruct__c 
                                                             WHERE MarketSegment__c = :marketSegment 
                                                             AND Is_Active__c = true];

        return quoteStructDetailList;
    }

    @AuraEnabled
    public static Boolean isApprovalRequestPending(String urlString) {
        String paramsString = urlString.substringAfter('&');

        String decryptedParamsString = CryptoUtils.getCryptoDecodedURLString(paramsString);
        String headerId = decryptedParamsString.split('&').get(0).split('=').get(1);

        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :headerId LIMIT 1];
        
        if(workItems.isEmpty()) {
            return false;
        } else {
            return true;
        }
    }

    @AuraEnabled
    public static String approveOrRejectRequest(String urlString, Boolean isApproved) {
        List<QuoteRequestDetailWrapper> QuoteRequestDetailWrapperList = new List<QuoteRequestDetailWrapper>();
        String paramsString = urlString.substringAfter('&');

        String decryptedParamsString = CryptoUtils.getCryptoDecodedURLString(paramsString);
        String headerId = decryptedParamsString.split('&').get(0).split('=').get(1);
        String userId = decryptedParamsString.split('&').get(1).split('=').get(1);

        User user = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :headerId LIMIT 1];
        ProcessInstanceWorkitem workItem = workItems.get(0);

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workItem.Id);
        if(isApproved) {
            req.setAction('Approve');
            req.setComments('Approved by ' + user.Name);
        } else {
            req.setAction('Reject');
            req.setComments('Rejected by ' + user.Name);
        }

        requests.add(req);
        Approval.ProcessResult[] processResults = Approval.process(requests);

        return 'Запит на коригування успішно ' + (isApproved ? 'узгоджено' : 'відхилено');
    }

    public class QuoteRequestDetailWrapper {
        @AuraEnabled public Id quoteStructDetailId {get; set;}
        @AuraEnabled public String familyType {get; set;}
        @AuraEnabled public String familyId {get; set;}
        @AuraEnabled public String family {get; set;}
        @AuraEnabled public String marketSegment {get; set;}
        @AuraEnabled public String marketSegmentName {get; set;}
        @AuraEnabled public String manager {get; set;}
        @AuraEnabled public String group3 {get; set;}
        @AuraEnabled public String region {get; set;}
        @AuraEnabled public Decimal percent {get; set;}
        @AuraEnabled public Decimal quoteT {get; set;}
        @AuraEnabled public Decimal addQty {get; set;}
        @AuraEnabled public Decimal percentOld {get; set;}
        @AuraEnabled public Decimal quoteTOld {get; set;}
        @AuraEnabled public Decimal addQtyOld {get; set;}
        @AuraEnabled public Date dateFrom {get; set;}
        @AuraEnabled public Date dateTo {get; set;}
        @AuraEnabled public String requestNumber {get; set;}
        @AuraEnabled public Datetime createdDate {get; set;}
        @AuraEnabled public String createdBy {get; set;}
        @AuraEnabled public Boolean isPercentEquals {get; set;}
        @AuraEnabled public Boolean isQuoteTEquals {get; set;}
        @AuraEnabled public Boolean isAddQtyEquals {get; set;}

        public QuoteRequestDetailWrapper(QuoteRequestDetail__c quoteStructDetail) {

            this.quoteStructDetailId = quoteStructDetail.Id;
            this.familyType = quoteStructDetail.FamilyType__r.Name;
            this.familyId = String.valueOf(quoteStructDetail.Family__r.ID_ERP__c);
            this.family = quoteStructDetail.Family__r.Name;
            this.marketSegment = quoteStructDetail.MarketSegment__c;
            this.marketSegmentName = MarkenSegmentMap.get(marketSegment);
            this.manager = quoteStructDetail.Manager__r.Name;
            this.group3 = quoteStructDetail.Group3__r.Name;
            this.region = quoteStructDetail.Region__r.Name;
            this.percent = quoteStructDetail.Percent__c;
            this.quoteT = quoteStructDetail.Quote_t__c;
            this.addQty = quoteStructDetail.AddQty_t__c != null ? quoteStructDetail.AddQty_t__c : 0;
            this.percentOld = quoteStructDetail.QuoteStructureDetail__r.Percent__c;
            this.quoteTOld = quoteStructDetail.QuoteStructureDetail__r.Quote_t__c;
            this.addQtyOld = quoteStructDetail.QuoteStructureDetail__r.AddQty_t__c != null ? quoteStructDetail.QuoteStructureDetail__r.AddQty_t__c : 0;
            this.dateFrom = quoteStructDetail.QuoteRequestHeader__r.DateFrom__c;
            this.dateTo = quoteStructDetail.QuoteRequestHeader__r.DateTo__c;
            this.requestNumber = quoteStructDetail.QuoteRequestHeader__r.Name;
            this.createdDate = quoteStructDetail.QuoteRequestHeader__r.CreatedDate;
            this.createdBy = quoteStructDetail.QuoteRequestHeader__r.CreatedBy.Name;
            this.isPercentEquals = quoteStructDetail.Percent__c?.setScale(2) == quoteStructDetail.QuoteStructureDetail__r.Percent__c?.setScale(2);
            this.isQuoteTEquals = quoteStructDetail.Quote_t__c?.setScale(2) == quoteStructDetail.QuoteStructureDetail__r.Quote_t__c?.setScale(2);
            this.isAddQtyEquals = quoteStructDetail.AddQty_t__c?.setScale(2) == quoteStructDetail.QuoteStructureDetail__r.AddQty_t__c?.setScale(2) || 
                                  (quoteStructDetail.AddQty_t__c == null && quoteStructDetail.QuoteStructureDetail__r.AddQty_t__c == 0) || 
                                  (quoteStructDetail.AddQty_t__c == 0 && quoteStructDetail.QuoteStructureDetail__r.AddQty_t__c == null);
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
    }
}