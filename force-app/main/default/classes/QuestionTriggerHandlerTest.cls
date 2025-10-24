@IsTest
public class QuestionTriggerHandlerTest {

    @IsTest
    static void testValidationSuccess() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Draft');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try{
            Question__c question = new Question__c(Name = 'Question Name', Questionnaire__c = questionnaire.Id);
            insert question;

            question.Required__c = true;
            update question;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isFalse(expectedExceptionThrown, 'Question should be successfully inserted and updated');
    }

    @IsTest
    static void testValidationErrorInsert() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Sent');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            Question__c question = new Question__c(Name = 'Question Name', Questionnaire__c = questionnaire.Id);
            insert question;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isTrue(expectedExceptionThrown, 'Exception should be thrown');
    }

    @IsTest
    static void testValidationErrorUpdate() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Draft');
        insert questionnaire;
        Question__c question = new Question__c(Name = 'Question Name', Questionnaire__c = questionnaire.Id);
        insert question;

        questionnaire.Status__c = 'Sent';
        update questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            question.Required__c = true;
            update question;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isTrue(expectedExceptionThrown, 'Exception should be thrown');
    }
}