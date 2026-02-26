@IsTest
public class AsyncConfigExceptionTest {
    @IsTest
    static void coverException() {
        try {
            throw new AsyncConfigException('test');
        } catch (AsyncConfigException e) {
            System.assertEquals('test', e.getMessage());
        }
    }
}