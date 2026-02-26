@IsTest
public class AsyncExecutorResultCoverageTest {
    @IsTest
    static void cover() {
        AsyncExecutorResult r = new AsyncExecutorResult();
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 1;
        System.assertNotEquals(null, r.toDebugString());
    }

    @IsTest
    static void coverAllFields() {

        AsyncExecutorResult r = new AsyncExecutorResult();
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 5;
        r.message = 'ok';
        r.asyncJobId = UserInfo.getUserId();
        r.configName = 'Default';
        r.executedAt = System.now();

        String s = r.toDebugString();
        System.assert(s.contains('SYNC'));
    }  
    
    @IsTest
    static void coverPojoAndToString() {
        AsyncExecutorResult r = new AsyncExecutorResult();
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 3;
        r.message = 'ok';
        r.executedAt = DateTime.now();
        r.configName = 'Default_Setting';

        System.assertEquals(3, r.recordCount);

        // якщо в класі є toString() — це підніме coverage
        String s = String.valueOf(r);
        System.assertNotEquals(null, s);
    }
    
    @IsTest
    static void coverAllFields2() {
        AsyncExecutorResult r = new AsyncExecutorResult();

        r.mode        = AsyncExecutionMode.SYNC;
        r.recordCount = 123;
        r.message     = 'ok';
        r.asyncJobId  = '707000000000AAA';
        r.executedAt  = DateTime.now();
        r.configName  = 'CFG_TEST';

        System.assertEquals(AsyncExecutionMode.SYNC, r.mode);
        System.assertEquals(123, r.recordCount);
        System.assertEquals('ok', r.message);
        System.assertEquals('CFG_TEST', r.configName);
    } 
    
    @IsTest
    static void coverDto() {
        AsyncExecutorResult r = new AsyncExecutorResult();

        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 5;
        r.message = 'ok';
        r.asyncJobId = '707000000000001';
        r.executedAt = System.now();
        r.configName = 'Default';

        System.assertEquals(5, r.recordCount);
        System.assertEquals('ok', r.message);
        System.assertEquals(
            AsyncExecutionMode.SYNC,
            r.mode
        );
    }    
}