@IsTest
private class CmdtRuntimeService_Test {

    // =========================
    // SINGLE RECORD TESTS
    // =========================

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

        System.assertNotEquals(null, deployId);
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

    // =========================
    // BULK TESTS
    // =========================

    @IsTest
    static void testBulkInsertCmdtRecords() {
        Map<String, Map<String, String>> records =
            new Map<String, Map<String, String>>{
                'REC_ONE' => new Map<String, String>{
                    'MasterLabel' => 'Record One',
                    'Code__c' => '1'
                },
                'REC_TWO' => new Map<String, String>{
                    'MasterLabel' => 'Record Two',
                    'Code__c' => '2'
                }
            };

        Test.startTest();
        Id deployId = CmdtRuntimeService.insertCmdtRecords(
            'TestCmdt',
            records
        );
        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testBulkUpdateCmdtRecords() {
        Map<String, Map<String, String>> records =
            new Map<String, Map<String, String>>{
                'REC_ONE' => new Map<String, String>{
                    'Name__c' => 'Updated One'
                },
                'REC_TWO' => new Map<String, String>{
                    'Name__c' => 'Updated Two'
                }
            };

        Test.startTest();
        Id deployId = CmdtRuntimeService.updateCmdtRecords(
            'TestCmdt',
            records
        );
        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testBulkUpsertCmdtRecords() {
        Map<String, Map<String, String>> records =
            new Map<String, Map<String, String>>{
                'REC_UPSERT_1' => new Map<String, String>{
                    'MasterLabel' => 'Upsert 1',
                    'Code__c' => '10'
                },
                'REC_UPSERT_2' => new Map<String, String>{
                    'MasterLabel' => 'Upsert 2',
                    'Code__c' => '20'
                }
            };

        Test.startTest();
        Id deployId = CmdtRuntimeService.upsertCmdtRecords(
            'TestCmdt',
            records
        );
        Test.stopTest();

        System.assertNotEquals(null, deployId);
    }

    @IsTest
    static void testBulkDisableCmdtRecords() {
        Test.startTest();

        Id deployId = CmdtRuntimeService.disableCmdtRecords(
            'TestCmdt',
            new List<String>{ 'REC_ONE', 'REC_TWO' }
        );

        Test.stopTest();
        System.assertNotEquals(null, deployId);
    }

    // =========================
    // VALIDATION / NEGATIVE
    // =========================

    @IsTest
    static void testBulkValidationErrors() {
        try {
            CmdtRuntimeService.insertCmdtRecords(
                'TestCmdt',
                new Map<String, Map<String, String>>()
            );
            System.assert(false, 'Exception expected');
        } catch (IllegalArgumentException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void testSingleValidationErrors() {
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