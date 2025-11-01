public with sharing class ProdWeeksDTO {

    public Integer W_Year;
    public List<MonthBlock> Data;

    public class MonthBlock {
        public String GODMEC;                 // 'YYYYMM' як рядок
        public List<WeekItem> Weeks;
    }

    public class WeekItem {
        public Integer NWEEK;                 // 1..5
        public Date    DATN;                  // yyyy-MM-dd
        public Date    DATK;                  // yyyy-MM-dd
    }

    // ===== (De)Serialization =====
    public static ProdWeeksDTO fromJson(String payload) {
        if (String.isBlank(payload)) return null;
        return (ProdWeeksDTO) JSON.deserialize(payload, ProdWeeksDTO.class);
    }
    public String toJson(Boolean pretty) {
        return pretty ? JSON.serializePretty(this) : JSON.serialize(this);
    }

    // ===== Helpers =====
    /** Усі тижні у плоскому вигляді. */
    public List<WeekItem> allWeeks() {
        List<WeekItem> out = new List<WeekItem>();
        if (Data == null) return out;
        for (MonthBlock m : Data) {
            if (m != null && m.Weeks != null) out.addAll(m.Weeks);
        }
        return out;
    }

    /** Тижні за конкретним GODMEC ('YYYYMM'). */
    public List<WeekItem> weeksByGODMEC(String godmec) {
        List<WeekItem> res = new List<WeekItem>();
        if (String.isBlank(godmec) || Data == null) return res;
        for (MonthBlock m : Data) {
            if (m != null && m.GODMEC == godmec && m.Weeks != null) {
                res.addAll(m.Weeks);
                break;
            }
        }
        return res;
    }

    /** Map<'YYYYMM', List<WeekItem>> для швидкого доступу по місяцю. */
    public Map<String, List<ProdWeeksDTO.WeekItem>> toMonthMap() {
        Map<String, List<ProdWeeksDTO.WeekItem>> result = new Map<String, List<ProdWeeksDTO.WeekItem>>();
        if (Data == null) return result;
        for (MonthBlock m : Data) {
            if (m == null || String.isBlank(m.GODMEC)) continue; // ✅ пропускаємо null/порожні
            result.put(m.GODMEC, (m.Weeks == null ? new List<ProdWeeksDTO.WeekItem>() : m.Weeks));
        }
        return result;
    }

    // ===== GODMEC utils (рядковий формат 'YYYYMM') =====
    public static Boolean isValidGodmec(String godmec) {
        return !String.isBlank(godmec) && Pattern.matches('^\\d{6}$', godmec);
    }
    public static Integer yearOf(String godmec) {
        return isValidGodmec(godmec) ? Integer.valueOf(godmec.substring(0, 4)) : null;
    }
    public static Integer monthOf(String godmec) {
        return isValidGodmec(godmec) ? Integer.valueOf(godmec.substring(4, 6)) : null;
    }

    // ===== Validation =====
    /**
     * Перевіряємо:
     *  - GODMEC = 'YYYYMM' (6 цифр)
     *  - year(GODMEC) == W_Year
     *  - дати в межах W_Year та DATN <= DATK
     */
    public List<String> validate() {
        List<String> errs = new List<String>();
        if (Data == null) return errs;

        for (MonthBlock m : Data) {
            if (m == null) { errs.add('Null MonthBlock'); continue; }

            if (!isValidGodmec(m.GODMEC)) {
                errs.add('Invalid GODMEC: ' + m.GODMEC + ' (must be YYYYMM digits)');
                continue;
            }
            Integer gy = yearOf(m.GODMEC);
            if (W_Year == null || gy != W_Year) {
                errs.add('GODMEC ' + m.GODMEC + ' year ' + gy + ' != W_Year ' + W_Year);
            }
            if (m.Weeks == null) continue;

            // доведемо порядок до ладу
            m.Weeks.sort(new WeekComparator());

            for (WeekItem w : m.Weeks) {
                if (w == null) { errs.add('Null WeekItem in ' + m.GODMEC); continue; }
                if (w.DATN != null && w.DATN.year() != W_Year)
                    errs.add('DATN not in W_Year for ' + m.GODMEC + ' W' + w.NWEEK);
                if (w.DATK != null && w.DATK.year() != W_Year)
                    errs.add('DATK not in W_Year for ' + m.GODMEC + ' W' + w.NWEEK);
                if (w.DATN != null && w.DATK != null && w.DATN > w.DATK)
                    errs.add('DATN > DATK for ' + m.GODMEC + ' W' + w.NWEEK);
            }
        }
        return errs;
    }

    // ===== Comparator: тижні за номером (без compareTo) =====
    public class WeekComparator implements System.Comparator<ProdWeeksDTO.WeekItem> {
        public Integer compare(ProdWeeksDTO.WeekItem a, ProdWeeksDTO.WeekItem b) {
            Integer x = (a == null || a.NWEEK == null) ? -1 : a.NWEEK;
            Integer y = (b == null || b.NWEEK == null) ? -1 : b.NWEEK;
            if (x == y) return 0;
            return (x < y) ? -1 : 1;
        }
    }
}