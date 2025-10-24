public class TubeUtils {
    public static final Decimal MM_PER_INCH = 25.4;
    // === VALIDATION METHODS ===
    public static Boolean isNumber(String s) {
        if (String.isBlank(s)) return false;
        try {
            Decimal.valueOf(s);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static Boolean isDecimalRegex(String s) {
        if (String.isBlank(s)) return false;
        return Pattern.matches('^-?\\d+(\\.\\d+)?$', s);
    }

    public static String formatDecimal(Decimal d) {
        if (d == null) return null;
        return d.stripTrailingZeros().toPlainString();
    }

    // === DENSITY METHODS ===
    public static Decimal getDensity(String material) {
        Map<String, Decimal> m = new Map<String, Decimal>{
            'CARBON_STEEL'    => 7850,
            'STAINLESS_STEEL' => 8000,
            'ALUMINIUM'       => 2700,
            'COPPER'          => 8940,
            'TITANIUM'        => 4500
        };
        return m.containsKey(material) ? m.get(material) : 7850;
    }

    // === ROUND PIPE (CIRCULAR) WEIGHT ===
    public static Decimal calcRoundWeightKPM(Decimal od_mm, Decimal wt_mm, Decimal density) {
        Double od = Double.valueOf(od_mm);
        Double wt = Double.valueOf(wt_mm);
        Double dens = Double.valueOf(density);

        Double area_mm2 = (Math.PI / 4) * (Math.pow(od, 2) - Math.pow(od - 2 * wt, 2));
        Double w = area_mm2 * dens * 0.000001; // мм² → м²
        return Decimal.valueOf(w).setScale(3);
    }

    public static Decimal calcRoundWeightPPF(Decimal od_mm, Decimal wt_mm, Decimal density) {
        Decimal wkgm = calcRoundWeightKPM(od_mm, wt_mm, density);
        return (wkgm * 0.672).setScale(3);
    }

    // === RECTANGULAR PIPE (RHS/SHS) WEIGHT ===
    public static Decimal calcRectWeightKPM(Decimal width_mm, Decimal height_mm, Decimal thickness_mm, Decimal density) {
        if (2 * thickness_mm >= Math.min(width_mm, height_mm)) {
            throw new IllegalArgumentException('Thickness too large for given dimensions.');
        }

        Decimal outerArea = width_mm * height_mm;
        Decimal innerArea = (width_mm - 2 * thickness_mm) * (height_mm - 2 * thickness_mm);
        Decimal area = outerArea - innerArea;
        Decimal w = area * density * 0.000001;
        return w.setScale(3);
    }

    public static Decimal calcRectWeightPPF(Decimal width_mm, Decimal height_mm, Decimal thickness_mm, Decimal density) {
        Decimal wkgm = calcRectWeightKPM(width_mm, height_mm, thickness_mm, density);
        return (wkgm * 0.672).setScale(3);
    }

     //--- Простий конвертор mm->inch ---
    public static Decimal mmToInches(Decimal mm, Integer precision) {
        return (mm==null)? 0.00 : (mm/MM_PER_INCH).setScale(precision);
    }

    /*---------------------------------------------------------------------------
      Конвертор мм у дюйми як змішаний дріб з округленням до 1/denominator дюйма.
      Приклади: 244.48 -> "9 5/8", 168.28 -> "6 5/8", 88.90 -> "3 1/2"
     ---------------------------------------------------------------------------*/
    public static String mmToInchesFraction(Decimal mm, Integer denominator) {
        if (mm == null) return null;
        if (denominator == null || denominator <= 0) denominator = 8;

        // Обробка знаку
        Boolean isNegative = (mm < 0);
        Decimal inchesAbs = (mm.abs() / MM_PER_INCH);

        // Ціла частина
        Integer whole = (Integer)Math.floor(inchesAbs);

        // Дробова частина та округлення до найближчого 1/denominator
        Decimal frac = inchesAbs - whole;
        Integer num = (Integer)Math.round(frac * denominator);

        // Якщо після округлення дробова частина "переповнилась"
        if (num >= denominator) {
            whole += 1;
            num = 0;
        }

        // Спрощення дробу
        if (num != 0) {
            Integer g = gcd(num, denominator);
            num /= g;
            denominator /= g;
        }

        // Формування рядка
        String sign = isNegative && (whole != 0 || num != 0) ? '-' + '' : '';
        if (num == 0) {
            return sign + String.valueOf(whole);
        } else if (whole == 0) {
            return sign + num + '/' + denominator;
        } else {
            return sign + whole + ' ' + num + '/' + denominator;
        }
    }

    // Евклід для НСД
    private static Integer gcd(Integer a, Integer b) {
        a = Math.abs(a);
        b = Math.abs(b);
        while (b != 0) {
            Integer t = Math.mod(a, b);
            a = b;
            b = t;
        }
        return a == 0 ? 1 : a;
    }
    
    // Дефолт-оверлоад: за замовчуванням округляємо до 1/8"
    public static String mmToInchesFraction(Decimal mm) {
        return mmToInchesFraction(mm, 8);
    }   
}