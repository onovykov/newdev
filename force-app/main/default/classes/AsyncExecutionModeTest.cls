@IsTest
public class AsyncExecutionModeTest {
    @IsTest
    static void coverEnum() {
        System.assertNotEquals(null, AsyncExecutionMode.SYNC);
        System.assertNotEquals(null, AsyncExecutionMode.BATCH);
    }
}