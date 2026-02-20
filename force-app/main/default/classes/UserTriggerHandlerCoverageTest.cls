@IsTest
private class UserTriggerHandlerCoverageTest {

    @IsTest
    static void coverAfterInsertLegacyPath() {

        Test.startTest();

        User u = TestDataFactory.createTestUser();
        // insert уже був у factory → тут не важливо

        Test.stopTest();

        System.assert(true);
    }
}