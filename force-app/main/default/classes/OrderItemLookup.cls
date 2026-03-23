public interface OrderItemLookup {
    Id findByIte(String ite);
    Map<String, Id> findByItes(Set<String> ites);

    OrderItem findEntityByIte(String ite);
    Map<String, OrderItem> findEntitiesByItes(Set<String> ites);
}