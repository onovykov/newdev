// Comparator для сортування подій ERP
public class ErpEventDateComparator
    implements Comparator<DelivServiceDTO.ErpEvent> {

    public Integer compare(
        DelivServiceDTO.ErpEvent a,
        DelivServiceDTO.ErpEvent b
    ) {
        if (a.dt == b.dt) return 0;
        return a.dt < b.dt ? -1 : 1;
    }
}