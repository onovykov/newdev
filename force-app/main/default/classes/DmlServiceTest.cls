@IsTest
public class DmlServiceTest {
    @IsTest
    static void coverDml() {
        Account a = new Account(Name='DML Test', Type='Test');
        insert a;
        a.Name = 'Updated';
        DmlService.updateRecords(new List<SObject>{a}, false);
    }
}