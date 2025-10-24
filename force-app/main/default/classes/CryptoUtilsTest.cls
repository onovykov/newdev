@isTest
public class CryptoUtilsTest {

  @isTest
  public static void getCryptoEncodedURLString_nullString_Exception() {
    String stringToEncode;

    Test.startTest();
    try {
      String encoded = CryptoUtils.getCryptoEncodedURLString(stringToEncode);
      Assert.fail('There should be an exception');
    } catch (Exception e) {
      String errorMessage = e.getMessage();

      Assert.isTrue(true, 'An exception should be caught');
      Assert.isNotNull(errorMessage, 'The error message should not be null');
    }
    Test.stopTest();
  }

  @isTest
  public static void getCryptoEncodedURLString_Success() {
    String stringToEncode = 'Test';

    Test.startTest();
    String encoded = CryptoUtils.getCryptoEncodedURLString(stringToEncode);
    Test.stopTest();

    Assert.isNotNull(encoded, 'There should be encoded string');
    Assert.areNotEqual(stringToEncode, encoded, 'The initial string and encoded string should not be the same');
  }

  @isTest
  public static void getCryptoDecodedURLString_nullString_Exception() {
    String stringToDecode;

    Test.startTest();
    try {
      String decoded = CryptoUtils.getCryptoDecodedURLString(stringToDecode);
      Assert.fail('There should be an exception');
    } catch (Exception e) {
      String errorMessage = e.getMessage();

      Assert.isTrue(true, 'An exception should be caught');
      Assert.isNotNull(errorMessage, 'The error message should not be null');
    }
    Test.stopTest();
  }

  @isTest
  public static void getCryptoDecodedURLString_Success() {
    String initialString = 'Test';
    String encoded = CryptoUtils.getCryptoEncodedURLString(initialString);

    Test.startTest();
    String decoded = CryptoUtils.getCryptoDecodedURLString(encoded);
    Test.stopTest();

    Assert.isNotNull(decoded, 'There should be decoded string');
    Assert.areEqual(initialString, decoded, 'The initial string and decoded string should be the same');
  }
}