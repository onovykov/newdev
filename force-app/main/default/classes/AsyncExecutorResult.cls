public class AsyncExecutorResult {

    public Integer recordCount;
    public AsyncExecutionMode mode;
    public String configName;
    public String message;

    public Id asyncJobId; // Queueable jobId або Batch jobId
    public DateTime executedAt;

    public Boolean isAsync() {
        return mode == AsyncExecutionMode.QUEUEABLE
            || mode == AsyncExecutionMode.BATCH;
    }

    public Boolean isSuccess() {
        return mode != AsyncExecutionMode.NOOP;
    }

    public override String toString() {
        return JSON.serializePretty(this);
    }
}