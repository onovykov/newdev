@IsTest
private class StageEngineConfigurationExceptionTest {

    @IsTest
    static void testException() {
        try {
            throw new StageEngineConfigurationException('test');
        } catch (StageEngineConfigurationException e) {
            System.assertEquals('test', e.getMessage());
        }
    }
}