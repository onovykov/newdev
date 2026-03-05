public interface OrderLookup {
    Id findByIte(String ite);
    Id findByErp(String erpId);
}