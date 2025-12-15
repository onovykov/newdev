@IsTest
private class CmdtRuntimeService_Test {

    @IsTest
    static void testInsertCmdtRecord() {
        Test.startTest();

        Id deployId = CmdtRuntimeService.insertCmdtRecord(
            'TestCmdt',
            'TEST_RECORD',
            new Map<String, String>{
                'Name__c' => 'Test Name',
                'MasterLabel' => 'Test Label'
            }
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            deployId,
            'DeployId should not be null'
        );
    }

    @IsTest
    static void testUpdateCmdtRecord() {
        Test.startTest();

        Id deployId = CmdtRuntimeService.updateCmdtRecord(
            'TestCmdt',
            'TEST_RECORD',
            new Map<String, String>{
                'Name__c' => 'Updated Name'
            }
        );

        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testUpsertCmdtRecord() {
        Test.startTest();

        Id deployId = CmdtRuntimeService.upsertCmdtRecord(
            'TestCmdt',
            'TEST_RECORD',
            new Map<String, String>{
                'Name__c' => 'Upsert Name',
                'MasterLabel' => 'Upsert Label'
            }
        );

        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testDisableCmdtRecord() {
        Test.startTest();

        Id deployId = CmdtRuntimeService.disableCmdtRecord(
            'TestCmdt',
            'TEST_RECORD'
        );

        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testValidationErrors() {
        try {
            CmdtRuntimeService.insertCmdtRecord(
                null,
                'REC',
                new Map<String, String>()
            );
            System.assert(false, 'Exception expected');
        } catch (IllegalArgumentException e) {
            System.assert(true);
        }
    }
}