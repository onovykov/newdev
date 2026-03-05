public class OpportunityLookupImpl implements OpportunityLookup {

    public Id findByIte(String ite) {
        return OpportunityCache.getOneByIte(ite);
    }

    public Id findByErp(String erpId) {
        return OpportunityCache.getOneByErpId(erpId);
    }
}