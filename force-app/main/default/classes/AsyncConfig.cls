public class AsyncConfig {
    public Integer syncLimit;
    public Integer queueLimit;
    public Integer batchSize;
    public Integer timeout;

    public AsyncConfig() {
        syncLimit  = 200;
        queueLimit = 2000;
        batchSize  = 200;
        timeout = 120;
    }
}