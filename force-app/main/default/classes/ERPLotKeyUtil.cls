public class ERPLotKeyUtil {

    public static String buildExtKey(Id orderItemId, Id prodWeekId, String lotType) {
        if (orderItemId == null || prodWeekId == null || String.isBlank(lotType)) {
            return null;
        }

        return String.valueOf(orderItemId) + '#' +
               String.valueOf(prodWeekId) + '#' +
               lotType;
    }

    public static Set<String> collectExtKeys(List<ERPLotAggregate> aggregates) {
        Set<String> result = new Set<String>();

        if (aggregates == null) {
            return result;
        }

        for (ERPLotAggregate agg : aggregates) {
            if (!String.isBlank(agg.extKey)) {
                result.add(agg.extKey);
            }
        }

        return result;
    }
}