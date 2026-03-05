public interface OpportunityLookup {
    Id findByIte(String ite);
    Id findByErp(String erpId);
}