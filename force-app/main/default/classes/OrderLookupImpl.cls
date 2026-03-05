public class OrderLookupImpl implements OrderLookup {

    public Id findByIte(String ite) {
        return OrderCache.getOneByIte(ite);
    }

    public Id findByErp(String erpId) {
        return OrderCache.getOneByErpId(erpId);
    }
}