//=== Вся основна логіка обробника кастомного ліда =====
public with sharing class EnquiryOpportunityResolver {

    public static EnquiryContext resolve(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        EnquiryContext ctx = new EnquiryContext();
 
        OppLookupResult oppRes = findOpportunity(msg);
        ctx.opportunity = oppRes.opportunity;

        if (!oppRes.found) {
            return ctx; // nothing to do
        }

        if (!isEnquiryOpportunity(oppRes.opportunity)) {
            return ctx;
        }

        ctx.isEnquiry = true;
        
        //--- Перевіряємо, чи передано ID_ERP__c нового акаунта
        if (!isValidErpAccount(msg)) {
            ctx.rejectReason = 'Invalid ERP account for enquiry';
            return ctx;
        }
        /*
        //--- Перевіряємо, чи передано сегмент нового акаунта
        if (isSegmentAccount(msg)) {
            return ctx; // allowed, but no conversion
        }
        */
        //--- Перевіряємо, чи вже нема в базі такого акаунта
        if (leadAlreadyConverted(oppRes.opportunity)) {
            return ctx;
        }

        //--- Перевіряємо, чи немає дублікатів
        if (wouldCreateDuplicateAccount(msg)) {
            ctx.rejectReason = 'Lead conversion would create duplicate Account';
            return ctx;
        }

        ctx.shouldConvertLead = true;
        return ctx;
    }

    /* ===== PRIVATE HELPERS ===== */
    //--- Wrapper-результат ("ховаємо" явний null)
    public class OppLookupResult {
        public Boolean found;
        public Opportunity opportunity;
    }

    private static OppLookupResult findOpportunity(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        List<Opportunity> opps = [
            SELECT Id, RecordType.DeveloperName, AccountId
            FROM Opportunity
            WHERE ID_ERP__c = :String.valueOf(msg.data.header.unDoc)
            LIMIT 1
        ];
        OppLookupResult r = new OppLookupResult();
        r.found = !opps.isEmpty();
        r.opportunity = r.found ? opps[0] : null;
        return r;
    } 

    private static Boolean isEnquiryOpportunity(Opportunity opp) {
        return opp.RecordType.DeveloperName == 'Enquiry';
    }

    private static Boolean isValidErpAccount(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        return msg.data.header.account.id != null;
    }
    /*
    private static Boolean isSegmentAccount(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        return msg.data.header. segmentAccount == true;
    }
    */
    private static Boolean leadAlreadyConverted(Opportunity opp) {
        return opp.AccountId != null;
    }

    private static Boolean wouldCreateDuplicateAccount(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        // Якщо знайшли такий ID_ERP__c - це дублікат
        // Дублі по назвах перевіряються під час створення ліда
        return AccountRepository.getByErp(msg.data.header.account.id)!=null;
    }
}