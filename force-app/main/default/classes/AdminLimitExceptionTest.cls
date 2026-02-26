@IsTest
public class AdminLimitExceptionTest {
    @IsTest
    static void coverException() {
        try {
            throw new AdminLimitException('limit');
        } catch (AdminLimitException e) {
            System.assertEquals('limit', e.getMessage());
        }
    }
}