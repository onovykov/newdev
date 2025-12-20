public class HistoryItemDateComparator
    implements Comparator<DelivServiceDTO.HistoryItemDto> {

    public Integer compare(
        DelivServiceDTO.HistoryItemDto a,
        DelivServiceDTO.HistoryItemDto b
    ) {
        if (a.dt == b.dt) return 0;
        return a.dt < b.dt ? -1 : 1;
    }
}