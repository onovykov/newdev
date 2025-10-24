public class CryptoUtils {

    private static final String CRYPTO_PRIVATE_KEY = 'fg7keo9pvn3ft6dl';
    private static final String CRYPTO_ALGORITHM_NAME = 'AES128';
  
    public static String getCryptoEncodedURLString(String stringToEncode) {
  
      String encoded = EncodingUtil.URLEncode(
        EncodingUtil.base64Encode(
          Crypto.encryptWithManagedIV(
            CRYPTO_ALGORITHM_NAME,
            Blob.valueOf(CRYPTO_PRIVATE_KEY),
            Blob.valueOf(stringToEncode)
          )
        ),
        'UTF-8'
      );
  
      return encoded;
    }
  
    public static String getCryptoDecodedURLString(String stringToDecode) {
  
      String decoded = Crypto.decryptWithManagedIV(
        CRYPTO_ALGORITHM_NAME,
        Blob.valueOf(CRYPTO_PRIVATE_KEY),
        EncodingUtil.base64Decode(
          EncodingUtil.urlDecode(
            stringToDecode,
            'UTF-8'
          )
        )
      ).toString();
  
      return decoded;
    }
  }