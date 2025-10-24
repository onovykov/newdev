@IsTest
public class QuestionnaireHandlerTest {
    
    @IsTest
    static void testValidationSuccess() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Draft');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            questionnaire.StartDate__c = Date.today();
            update questionnaire;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isFalse(expectedExceptionThrown, 'Questionnaire should be successfully updated');
    }

    @IsTest
    static void testValidationError() {
        Questionnaire__c questionnaire = new Questionnaire__c(Name = 'Test Name', Status__c = 'Sent');
        insert questionnaire;

        Boolean expectedExceptionThrown = false;
        try {
            questionnaire.StartDate__c = Date.today();
            update questionnaire;
        } catch(Exception e) {
            expectedExceptionThrown = true;
        }

        Assert.isTrue(expectedExceptionThrown, 'Exception should be thrown');
    }
}