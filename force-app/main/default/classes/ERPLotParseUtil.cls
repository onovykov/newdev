public class ERPLotParseUtil {

    public static Decimal parseDecimal(String src, Integer scale) {
        if (String.isBlank(src)) {
            return 0;
        }

        try {
            Decimal value = Decimal.valueOf(src);

            if (scale != null) {
                value = value.setScale(scale);
            }

            return value;
        } catch (Exception e) {
            return 0;
        }
    }

    public static Date parseDateFromDateTimeString(String dtString) {
        if (String.isBlank(dtString) || dtString.length() < 10) {
            return null;
        }

        try {
            return Date.valueOf(dtString.substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }
}