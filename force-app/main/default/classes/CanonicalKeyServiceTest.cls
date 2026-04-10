@IsTest
private class CanonicalKeyServiceTest {

    // ========================================
    // ENCODE / DECODE
    // ========================================
    @IsTest
    static void testEncodeDecode() {

        String raw = '0Ш';
        String hex = CanonicalKeyService.encode(raw);

        System.assertEquals('30D0A8', hex);
        System.assertEquals(raw, CanonicalKeyService.decode(hex));
    }

    @IsTest
    static void testEncodeNull() {
        System.assertEquals(null,
            CanonicalKeyService.encode(null));
    }

    // ========================================
    // SPECIAL CHARS
    // ========================================
    @IsTest
    static void testSpecialChars() {
        System.assertEquals('313C',
            CanonicalKeyService.encode('1<'));
    }

    // ========================================
    // VALIDATE HEX
    // ========================================
    @IsTest
    static void testValidateHexValid() {
        System.assertEquals(true,
            CanonicalKeyService.validateHex('30D0A8'));
    }

    @IsTest
    static void testValidateHexOddLength() {
        System.assertEquals(false,
            CanonicalKeyService.validateHex('30D0A'));
    }

    @IsTest
    static void testValidateHexInvalidChars() {
        System.assertEquals(false,
            CanonicalKeyService.validateHex('30D0ZZ'));
    }

    @IsTest
    static void testValidateHexNull() {
        System.assertEquals(false,
            CanonicalKeyService.validateHex(null));
    }

    // ========================================
    // DECODE ERROR
    // ========================================
    @IsTest
    static void testDecodeInvalidThrows() {

        try {
            CanonicalKeyService.decode('ZZZ');
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    // ========================================
    // SAFE DECODE
    // ========================================
    @IsTest
    static void testSafeDecodeInvalid() {
        System.assertEquals(null,
            CanonicalKeyService.safeDecode('ZZZ'));
    }

    @IsTest
    static void testSafeDecodeValid() {
        System.assertEquals('0Ш',
            CanonicalKeyService.safeDecode('30D0A8'));
    }

    // ========================================
    // equalsRawToHex
    // ========================================
    @IsTest
    static void testEqualsRawToHex() {

        System.assertEquals(true,
            CanonicalKeyService.equalsRawToHex('0Ш','30D0A8'));

        System.assertEquals(false,
            CanonicalKeyService.equalsRawToHex('0Ш','30D0A9'));

        System.assertEquals(false,
            CanonicalKeyService.equalsRawToHex(null,'30D0A8'));
    }

    // ========================================
    // BULK
    // ========================================
    @IsTest
    static void testBulkEncode() {

        Set<String> input = new Set<String>{ '0Ш', '1<' };

        Map<String,String> res =
            CanonicalKeyService.bulkEncode(input);

        System.assertEquals(2, res.size());
        System.assertEquals('30D0A8', res.get('0Ш'));
    }

    @IsTest
    static void testBulkSafeDecode() {

        Set<String> input = new Set<String>{
            '30D0A8', 'ZZZ'
        };

        Map<String,String> res =
            CanonicalKeyService.bulkSafeDecode(input);

        System.assertEquals('0Ш', res.get('30D0A8'));
        System.assertEquals(null, res.get('ZZZ'));
    }
}