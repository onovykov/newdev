public with sharing class ProductsHelper {
   public static final Decimal MM_PER_INCH = 25.4;
   public static final Decimal MM_TO_M = 0.001;
   public static final Decimal INCH_TO_FOOT = 1 / 12;
   public static final Decimal INCHES_PER_FT = 12;
   public static final Decimal PI = 3.141592653589793;

   @TestVisible
    private static ProductMaterialDensity__mdt mockDensity;

   /****************************************************************************
    *              Хелпери та службові методи         *
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

    /**************************************************************************
     *  Методи для розрахунку WeightPPM (вага метру в кг) і 
     *  WeightLPF (вага футу в фунтах) для труб
     **************************************************************************/
    // ===========================
    // Density resolver (MDT)
    // ===========================
    private static ProductMaterialDensity__mdt getDensity(String materialApiName) {
        if (String.isBlank(materialApiName)) {
            throw new IllegalArgumentException('Material API name is required');
        }

        if (Test.isRunningTest() && mockDensity != null) {
            return mockDensity;
        }        
        
        ProductMaterialDensity__mdt density =
            ProductMaterialDensity__mdt.getInstance(materialApiName);

        if (density == null) {
            throw new IllegalArgumentException(
                'No material density defined for: ' + materialApiName
            );
        }
        return density;
    }

    // ===========================
    // Round tube — kg/m (metric)
    // ===========================
    public static Decimal weightPerMeterRoundTubeMM(
        Decimal outerDiameterMM,
        Decimal wallThicknessMM,
        String materialApiName
    ) {
        if (outerDiameterMM <= 0 || wallThicknessMM <= 0) {
            return 0;
        }

        Decimal outerRadiusM =
            (outerDiameterMM / 2) * MM_TO_M;

        Decimal innerRadiusM =
            ((outerDiameterMM - 2 * wallThicknessMM) / 2) * MM_TO_M;

        Decimal crossSectionAreaM2 =
            PI * (outerRadiusM * outerRadiusM - innerRadiusM * innerRadiusM);

        Decimal densityKgM3 =
            getDensity(materialApiName).DencityKGMC__c;

        return (crossSectionAreaM2 * densityKgM3).setScale(3);
    }

    // ===========================
    // Rectangular tube — kg/m
    // ===========================
    public static Decimal weightPerMeterRectTubeMM(
        Decimal heightMM,
        Decimal widthMM,
        Decimal wallThicknessMM,
        String materialApiName
    ) {
        if (heightMM <= 0 || widthMM <= 0 || wallThicknessMM <= 0) {
            return 0;
        }

        Decimal heightM = heightMM * MM_TO_M;
        Decimal widthM  = widthMM  * MM_TO_M;
        Decimal wallM   = wallThicknessMM * MM_TO_M;

        Decimal crossSectionAreaM2 =
            (heightM * widthM) -
            ((heightM - 2 * wallM) * (widthM - 2 * wallM));

        Decimal densityKgM3 =
            getDensity(materialApiName).DencityKGMC__c;

        return (crossSectionAreaM2 * densityKgM3).setScale(3);
    }

    // ===========================
    // Round tube — lb/ft (imperial)
    // ===========================
    public static Decimal weightPerFootRoundTubeInch(
        Decimal outerDiameterIn,
        Decimal wallThicknessIn,
        String materialApiName
    ) {
        if (outerDiameterIn <= 0 || wallThicknessIn <= 0) {
            return 0;
        }

        Decimal outerRadiusIn = outerDiameterIn / 2;
        Decimal innerRadiusIn =
            (outerDiameterIn - 2 * wallThicknessIn) / 2;

        Decimal crossSectionAreaIn2 =
            PI * (outerRadiusIn * outerRadiusIn - innerRadiusIn * innerRadiusIn);

        Decimal densityLbIn3 =
            getDensity(materialApiName).DencityLbInC__c;

        return (crossSectionAreaIn2 * densityLbIn3 * INCHES_PER_FT).setScale(3);
    }

    // ===========================
    // Rectangular tube — lb/ft
    // ===========================
    public static Decimal weightPerFootRectTubeInch(
        Decimal heightIn,
        Decimal widthIn,
        Decimal wallThicknessIn,
        String materialApiName
    ) {
        if (heightIn <= 0 || widthIn <= 0 || wallThicknessIn <= 0) {
            return 0;
        }

        Decimal crossSectionAreaIn2 =
            (heightIn * widthIn) -
            ((heightIn - 2 * wallThicknessIn) *
             (widthIn  - 2 * wallThicknessIn));

        Decimal densityLbIn3 =
            getDensity(materialApiName).DencityLbInC__c;

        return (crossSectionAreaIn2 * densityLbIn3 * INCHES_PER_FT).setScale(3);
    }
}