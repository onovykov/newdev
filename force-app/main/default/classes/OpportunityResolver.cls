public class OpportunityResolver {
    @TestVisible
    static OpportunityLookup lookup = new OpportunityLookupImpl();

    public static OpportunityResolutionResult resolve(
        ERPMessageParser.ErpToSfMessage_OpportunityData msg
    ) {
        if (msg == null || msg.data == null || msg.data.header == null) {
            return OpportunityResolutionResult.notFound(
                ExceptionMessageProvider.getByDeveloperName('HEADER_MISSING')
            );
        }

        String ite   = msg.data.header.iteNumber;
        String erpId = String.valueOf(msg.data.header.unDoc);

        // 1️. ITE first
        if (String.isNotBlank(ite)) {
            OpportunityResolutionResult res = resolveByIte(ite);
            if (res.found) {
                return res;
            }
        }

        // 2️. ERP fallback
        if (String.isNotBlank(erpId)) {
            return resolveByErpId(erpId);
        }

        return OpportunityResolutionResult.notFound(
            ExceptionMessageProvider.getByDeveloperName('INVALID_OPP_ID_ERP')
        );
    }
	
    private static OpportunityResolutionResult resolveByIte(String ite) {

        //Id oppId = OpportunityCache.getOneByIte(ite);
        Id oppId = lookup.findByIte(ite);

        if (oppId == null) {
            return OpportunityResolutionResult.notFound(
                ExceptionMessageProvider.buildByDeveloperName(
                    'NOT_FOUND_OPPORTUNITY_ITE',
                    ite
                )
            );
        }

        return loadOpportunity(oppId);
    }
	
    private static OpportunityResolutionResult resolveByErpId(String erpId) {

        //Id oppId = OpportunityCache.getOneByErpId(erpId);
        Id oppId = lookup.findByErp(erpId);

        if (oppId == null) {
            return OpportunityResolutionResult.notFound(
                ExceptionMessageProvider.buildByDeveloperName(
                    'NOT_FOUND_OPPORTUNITY_ERP',
                    erpId
                )
            );
        }

        return loadOpportunity(oppId);
    }
	
    private static OpportunityResolutionResult loadOpportunity(Id oppId) {

        Opportunity opp = [
            SELECT Id, StageName, IsClosed, AccountId
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        return OpportunityResolutionResult.found(opp);
    }
}
