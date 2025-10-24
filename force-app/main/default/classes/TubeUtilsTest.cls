@IsTest
private class TubeUtilsTest {

    // Допоміжний метод для приблизної рівності десяткових чисел
    private static void assertApprox(Decimal actual, Decimal expected, Decimal tol, String msg) {
        System.assert( (actual - expected).abs() <= tol, msg + ' Expected: ' + expected + ', actual: ' + actual);
    }

    @IsTest
    static void testValidatorsAndFormatting() {
        // isNumber
        System.assertEquals(true,  TubeUtils.isNumber('123'));
        System.assertEquals(true,  TubeUtils.isNumber('123.45'));
        System.assertEquals(true,  TubeUtils.isNumber('-0.5'));
        System.assertEquals(false, TubeUtils.isNumber(''));
        System.assertEquals(false, TubeUtils.isNumber(null));
        System.assertEquals(false, TubeUtils.isNumber('12.3.4'));
        System.assertEquals(false, TubeUtils.isNumber('abc'));

        // isDecimalRegex
        System.assertEquals(true,  TubeUtils.isDecimalRegex('0'));
        System.assertEquals(true,  TubeUtils.isDecimalRegex('-12'));
        System.assertEquals(true,  TubeUtils.isDecimalRegex('3.1415'));
        System.assertEquals(false, TubeUtils.isDecimalRegex(''));
        System.assertEquals(false, TubeUtils.isDecimalRegex(null));
        System.assertEquals(false, TubeUtils.isDecimalRegex('1.'));
        System.assertEquals(false, TubeUtils.isDecimalRegex('.25'));
        System.assertEquals(false, TubeUtils.isDecimalRegex('1,25'));

        // formatDecimal
        System.assertEquals('12.34', TubeUtils.formatDecimal(12.3400));
        System.assertEquals('10',    TubeUtils.formatDecimal(10.000));
        System.assertEquals(null,    TubeUtils.formatDecimal(null));
    }

    @IsTest
    static void testGetDensity() {
        System.assertEquals(7850, TubeUtils.getDensity('CARBON_STEEL'));
        System.assertEquals(8000, TubeUtils.getDensity('STAINLESS_STEEL'));
        System.assertEquals(2700, TubeUtils.getDensity('ALUMINIUM'));
        System.assertEquals(8940, TubeUtils.getDensity('COPPER'));
        System.assertEquals(4500, TubeUtils.getDensity('TITANIUM'));
        // Невідомий матеріал -> дефолт 7850
        System.assertEquals(7850, TubeUtils.getDensity('SOMETHING_ELSE'));
        System.assertEquals(7850, TubeUtils.getDensity(null));
    }

    @IsTest
    static void testRoundPipeWeight() {
        // Тест-кейс (мм): OD=168.28, WT=7.11, density=7850 → ~28.260 кг/м; PPF ~18.991
        Decimal od = 168.28, wt = 7.11, dens = 7850;
        Decimal wkgm = TubeUtils.calcRoundWeightKPM(od, wt, dens);
        Decimal wppf = TubeUtils.calcRoundWeightPPF(od, wt, dens);
        System.assertEquals(3, wkgm.scale(), 'Scale must be 3 for kg/m');
        System.assertEquals(3, wppf.scale(), 'Scale must be 3 for PPF');
        System.assertEquals(28.260, wkgm, 'Unexpected kg/m for round pipe');
        System.assertEquals(18.991, wppf, 'Unexpected PPF for round pipe');
    }

    @IsTest
    static void testRectPipeWeight() {
        // Прямокутна труба: 100x50x5 мм, 7850 кг/м3 → площа стінки = 5000 - 3600 = 1400 мм2
        // Вага = 1400 * 7850 * 1e-6 = 10.99 кг/м; PPF ≈ 7.385
        Decimal w = TubeUtils.calcRectWeightKPM(100, 50, 5, 7850);
        System.assertEquals(10.990, w.setScale(3), 'Unexpected kg/m for rect pipe');
        Decimal wppf = TubeUtils.calcRectWeightPPF(100, 50, 5, 7850);
        System.assertEquals(7.385, wppf.setScale(3), 'Unexpected PPF for rect pipe');

        // Негативний кейс: товщина занадто велика (2*t >= min(width,height)) → IllegalArgumentException
        Boolean thrown = false;
        try {
            TubeUtils.calcRectWeightKPM(10, 8, 4, 7850); // 2*4 = 8 = min(10,8)
        } catch (IllegalArgumentException e) {
            thrown = true;
        }
        System.assert(thrown, 'Expected IllegalArgumentException for too large thickness');
    }

    @IsTest
    static void testMmToInches() {
        // mm->inch з точністю
        // 50.8 мм = 2.0"
        Decimal inches = TubeUtils.mmToInches(50.8, 3);
        System.assertEquals(2.000, inches, '50.8 mm must be exactly 2.000"');

        // null -> 0.00
        System.assertEquals(0.00, TubeUtils.mmToInches(null, 2));
    }

    @IsTest
    static void testMmToInchesFraction_PositiveTypical() {
        // Типові приклади з опису:
        System.assertEquals('9 5/8', TubeUtils.mmToInchesFraction(244.48, 8));
        System.assertEquals('6 5/8', TubeUtils.mmToInchesFraction(168.28, 8));
        System.assertEquals('3 1/2', TubeUtils.mmToInchesFraction(88.90, 8));

        // Скорочення дробу через gcd: 6.35 мм = 0.25" => "1/4" (з denominator=8 дає 2/8 -> 1/4)
        System.assertEquals('1/4', TubeUtils.mmToInchesFraction(6.35, 8));

        // Ціла частина 0 + дріб ≠ 0
        System.assertEquals('1/8', TubeUtils.mmToInchesFraction(3.175, 8));

        // Рівно ціле значення
        System.assertEquals('2', TubeUtils.mmToInchesFraction(50.8, 8)); // 2"
    }

    @IsTest
    static void testMmToInchesFraction_NegativeAndRoundingCarry() {
        // Негативне значення, тільки дріб
        System.assertEquals('-1/2', TubeUtils.mmToInchesFraction(-12.7, 8)); // -0.5" => "-1/2"

        // Негативне значення з цілою частиною і дробом (перевірка знаку)
        // 30.1625 мм = 1.1875" = 1 3/16
        System.assertEquals('-1 3/16', TubeUtils.mmToInchesFraction(-30.1625, 16));

        // Переповнення після округлення дробу: 5.999" ≈ 152.3946 мм, за 1/8" повинно округлитись до "6"
        Decimal mm = 5.999 * 25.4;
        System.assertEquals('6', TubeUtils.mmToInchesFraction(mm, 8));

        // null -> null
        System.assertEquals(null, TubeUtils.mmToInchesFraction(null, 8));

        // Нуль → "0"
        System.assertEquals('0', TubeUtils.mmToInchesFraction(0, 8));
    }

    @IsTest
    static void testMmToInchesFraction_DefaultOverloadAndBadDenominator() {
        // Оверлоад із дефолтним denominator=8
        System.assertEquals('9 5/8', TubeUtils.mmToInchesFraction(244.48));

        // Неправильний denominator -> за замовчуванням 8
        System.assertEquals('9 5/8', TubeUtils.mmToInchesFraction(244.48, 0));
        System.assertEquals('9 5/8', TubeUtils.mmToInchesFraction(244.48, -5));
        System.assertEquals('9 5/8', TubeUtils.mmToInchesFraction(244.48, null));
    }
}