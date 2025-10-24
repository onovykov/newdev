@IsTest
public class SectionTriggerHandlerTest {
    @IsTest
    static void testValidationSuccess() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Draft');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try{
            Section__c section = new Section__c(Name = 'Section Name', Questionnaire__c = questionnaire.Id);
            insert section;

            section.Order__c = 1;
            update section;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isFalse(expectedExceptionThrown, 'Section should be successfully inserted and updated');
    }

    @IsTest
    static void testValidationErrorInsert() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Sent');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            Section__c section = new Section__c(Name = 'Section Name', Questionnaire__c = questionnaire.Id);
            insert section;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isTrue(expectedExceptionThrown, 'Exception should be thrown');
    }

    @IsTest
    static void testValidationErrorUpdate() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Draft');
        insert questionnaire;
        Section__c section = new Section__c(Name = 'Section Name', Questionnaire__c = questionnaire.Id);
        insert section;

        questionnaire.Status__c = 'Sent';
        update questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            section.Order__c = 1;
            update section;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isTrue(expectedExceptionThrown, 'Exception should be thrown');
    }
}