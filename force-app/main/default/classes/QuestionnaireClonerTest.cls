@isTest
public class QuestionnaireClonerTest {

    @isTest static void testCloneQuestionnaireWithQuestions() {
        // Create and insert a test Questionnaire__c record
        Questionnaire__c testQuestionnaire = new Questionnaire__c(
            Name = 'Test Questionnaire'
            // Set other necessary fields
        );
        insert testQuestionnaire;

        // Create and insert test Section__c records
        Section__c testSection = new Section__c(
            Name = 'Test Section',
            Questionnaire__c = testQuestionnaire.Id
            // Set other necessary fields
        );
        insert testSection;

        // Create and insert test Question__c records
        Question__c testQuestion = new Question__c(
            Name = 'Test Question',
            Questionnaire__c = testQuestionnaire.Id,
            Section__c = testSection.Id
            // Set other necessary fields
        );
        insert testQuestion;

        Question__c secondQuestion = new Question__c(
            Name = 'Second Question',
            Questionnaire__c = testQuestionnaire.Id,
            Section__c = testSection.Id,
            Controlling_Question__c = testQuestion.Id,
            Value__c = 'Test Value'
        );
        insert secondQuestion;

        Test.startTest();
        // Call the method to test
        Id clonedQuestionnaireId = QuestionnaireCloner.cloneQuestionnaireWithQuestions(testQuestionnaire.Id);
        Test.stopTest();

        // Assert that the Questionnaire__c was cloned
        Questionnaire__c clonedQuestionnaire = [SELECT Id, Name FROM Questionnaire__c WHERE Id = :clonedQuestionnaireId];
        System.assertNotEquals(null, clonedQuestionnaire, 'The cloned questionnaire should not be null.');
        System.assertEquals('Test Questionnaire - Cloned', clonedQuestionnaire.Name, 'The name of the cloned questionnaire is incorrect.');

        // Assert that related Section__c and Question__c records were cloned
        List<Section__c> clonedSections = [SELECT Id, Questionnaire__c FROM Section__c WHERE Questionnaire__c = :clonedQuestionnaireId];
        System.assertNotEquals(0, clonedSections.size(), 'Cloned sections should exist.');

        List<Question__c> clonedQuestions = [SELECT Id, Questionnaire__c FROM Question__c WHERE Questionnaire__c = :clonedQuestionnaireId];
        System.assertNotEquals(0, clonedQuestions.size(), 'Cloned questions should exist.');
    }
}