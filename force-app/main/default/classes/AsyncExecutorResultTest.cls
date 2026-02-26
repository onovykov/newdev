@IsTest
public class AsyncExecutorResultTest {
    @IsTest
    static void coverDto() {
        AsyncExecutorResult r = new AsyncExecutorResult();
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 5;
        r.message = 'ok';
        System.assertEquals(5, r.recordCount);
    }

    //--- Coverage boost
    @IsTest
    static void coverIsEmpty() {
        AsyncExecutorResult r = new AsyncExecutorResult();
        r.recordCount = 0;
        System.assertEquals(true, r.isEmpty());
    }    

    @IsTest
    static void coverPojo() {
        AsyncExecutorResult r = new AsyncExecutorResult();
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 5;
        r.message = 'ok';
        r.executedAt = DateTime.now();
        r.configName = 'test';

        System.assertEquals(5, r.recordCount);
    }    
}