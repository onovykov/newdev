@IsTest
public class AsyncConfigTest {
    @IsTest
    static void coverDefaults() {
        AsyncConfig c = new AsyncConfig();
        System.assertEquals(200, c.syncLimit);
        System.assertEquals(2000, c.queueLimit);
        System.assertEquals(200, c.batchSize);
    }
}