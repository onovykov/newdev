public with sharing class CanonicalKeyService {
    // ========================================
    // ENCODE
    // ========================================
    /**
     * Encode raw string to HEX (UTF-8, UPPERCASE)
     */

    public static String encode(String input) {
        if (String.isBlank(input)) return null;

        return EncodingUtil.convertToHex(
            Blob.valueOf(input.trim())
        ).toUpperCase();
    }    
    /**
     * Alias for encode (semantic)
     */
    public static String normalize(String input) {
        return encode(input);
    }

    // ========================================
    // DECODE
    // ========================================
    /**
     * Decode HEX back to original string (throws on invalid HEX)
     */
    public static String decode(String hex) {
        if (String.isBlank(hex)) {
            return null;
        }

        if (!validateHex(hex)) {
            throw new CanonicalKeyException(
                'Invalid HEX string: ' + hex
            );
        }

        Blob b = EncodingUtil.convertFromHex(hex);
        return b.toString();
    }

    /**
     * Safe decode (never throws)
     */
    public static String safeDecode(String hex) {
        try {
            return decode(hex);
        } catch (Exception e) {
            return null;
        }
    }

    // ========================================
    // VALIDATION
    // ========================================
    /**
     * Validate HEX string (even length, valid chars)
     */
    public static Boolean validateHex(String hex) {
        if (String.isBlank(hex)) {
            return false;
        }

        String h = hex.trim();

        // must be even length
        if (Math.mod(h.length(), 2) != 0) {
            return false;
        }

        // check HEX chars
        for (Integer i = 0; i < h.length(); i++) {
            String c = h.substring(i, i+1).toUpperCase();

            Boolean isHex =
                (c >= '0' && c <= '9') ||
                (c >= 'A' && c <= 'F');

            if (!isHex) {
                return false;
            }
        }

        return true;
    }

    // ========================================
    // UTILS (OPTIONAL BUT USEFUL)
    // ========================================
    /**
     * Compare raw value to HEX
     */
    public static Boolean equalsRawToHex(String raw, String hex) {
        if (String.isBlank(raw) || String.isBlank(hex)) {
            return false;
        }

        return encode(raw) == hex;
    }

    /**
     * Bulk encode
     */
    public static Map<String, String> bulkEncode(Set<String> inputs) {
        Map<String, String> res = new Map<String, String>();

        if (inputs == null) return res;

        for (String s : inputs) {
            res.put(s, encode(s));
        }

        return res;
    }

    /**
     * Bulk safe decode
     */
    public static Map<String, String> bulkSafeDecode(Set<String> hexValues) {
        Map<String, String> res = new Map<String, String>();

        if (hexValues == null) return res;

        for (String h : hexValues) {
            res.put(h, safeDecode(h));
        }

        return res;
    }

    // ========================================
    // EXCEPTION
    // ========================================
    public class CanonicalKeyException extends Exception {}
}