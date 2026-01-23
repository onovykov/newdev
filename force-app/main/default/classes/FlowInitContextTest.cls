@IsTest(seeAllData=true)
public class FlowInitContextTest {

    @IsTest
    static void testInit() {
        // GIVEN
        List<String> dummy = new List<String>{ 'init' };

        // WHEN
        Test.startTest();
        List<FlowInitContext.Output> result = FlowInitContext.init(dummy);
        Test.stopTest();

        // THEN
        System.assertEquals(1, result.size(), 'One Output object expected');

        FlowInitContext.Output o = result[0];

        System.assertNotEquals(
            null,
            o.recordTypeId,
            'Account RecordTypeId should be resolved'
        );

        System.assertNotEquals(
            null,
            o.recordTypeContactId,
            'Contact RecordTypeId should be resolved'
        );

        System.assertNotEquals(
            null,
            o.ownerId,
            'OwnerId should be resolved via UserRepository'
        );

        // ParentHierId is optional
        // Either null or valid Account Id
        if (o.ParentHierId != null) {
            System.assert(
                o.ParentHierId.getSObjectType() == Account.SObjectType,
                'ParentHierId must reference Account'
            );
        }
    }
}