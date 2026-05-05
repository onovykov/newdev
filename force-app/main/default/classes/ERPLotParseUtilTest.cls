@IsTest
private class ERPLotParseUtilTest {

    @IsTest
    static void parseDecimal_shouldParseAndScale() {
        System.assertEquals(
            Decimal.valueOf('10.24'),
            ERPLotParseUtil.parseDecimal('10.235', 2)
        );

        System.assertEquals(
            Decimal.valueOf('10.235'),
            ERPLotParseUtil.parseDecimal('10.235', null)
        );
    }

    @IsTest
    static void parseDecimal_shouldReturnZeroForInvalidValues() {
        System.assertEquals(0, ERPLotParseUtil.parseDecimal(null, 2));
        System.assertEquals(0, ERPLotParseUtil.parseDecimal('', 2));
        System.assertEquals(0, ERPLotParseUtil.parseDecimal('bad-value', 2));
    }

    @IsTest
    static void parseDateFromDateTimeString_shouldParseDate() {
        System.assertEquals(
            Date.newInstance(2024, 7, 25),
            ERPLotParseUtil.parseDateFromDateTimeString('2024-07-25T00:00:00')
        );
    }

    @IsTest
    static void parseDateFromDateTimeString_shouldReturnNullForInvalidValues() {
        System.assertEquals(null, ERPLotParseUtil.parseDateFromDateTimeString(null));
        System.assertEquals(null, ERPLotParseUtil.parseDateFromDateTimeString(''));
        System.assertEquals(null, ERPLotParseUtil.parseDateFromDateTimeString('bad'));
        System.assertEquals(null, ERPLotParseUtil.parseDateFromDateTimeString('bad-value-123'));
    }
}