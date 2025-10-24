@IsTest
public class DeleteRecordsBatchTest {

    @IsTest
    static void testLastActivityDate() {
        List<Task> taskList = new List<Task>();
        for(Integer i = 0; i < 200; i++) {
            if (Math.mod(i, 2) == 0) {
                taskList.add(new Task(Subject = 'Test', ActivityDate = date.newInstance(2024, 01, 01)));
            } else {
                taskList.add(new Task(Subject = 'Test', ActivityDate = date.newInstance(2023, 01, 01)));
            } 
        }
        insert taskList;

        Test.startTest();
        DeleteRecordsBatch batch = new DeleteRecordsBatch('SELECT Id FROM Task WHERE ActivityDate < 2024-01-01');
        Id batchJobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Task> tasksAfterBatchList = [SELECT Id FROM Task];

        Assert.areEqual(100, tasksAfterBatchList.size());
    }
}