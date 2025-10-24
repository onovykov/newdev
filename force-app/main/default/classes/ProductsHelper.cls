 public with sharing class ProductsHelper {
    public static final Decimal MM_PER_INCH = 25.4;
    /****************************************************************************
     *              Хелпери та службові методи для ProductsController           *
    *****************************************************************************/
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