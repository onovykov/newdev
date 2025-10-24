public without sharing class QuestionnaireCloner {

    @AuraEnabled
    public static Id cloneQuestionnaireWithQuestions(Id questionnaireId) {
        // Clone the Questionnaire__c record
        Questionnaire__c originalQuestionnaire = [SELECT Name, StartDate__c, Additional_Information__c,Respondents_List_View_Name__c,LogoFileName__c FROM Questionnaire__c WHERE Id = :questionnaireId];
        Questionnaire__c clonedQuestionnaire = originalQuestionnaire.clone(false, true, false, false);
        clonedQuestionnaire.Name = originalQuestionnaire.Name + ' - Cloned';
        insert clonedQuestionnaire;

        // Clone Section__c records and keep a map of old and new IDs
        Map<Id, Id> sectionIdMap = new Map<Id, Id>();
        List<Section__c> clonedSections = new List<Section__c>();
        Map<String, Section__c> nameToClonedSectionMap = new Map<String, Section__c>();
        List<Section__c> sections = [SELECT Id, Name, Questionnaire__c,Order__c,Additional_Information_English__c,
                                            Additional_Information_Ukrainian__c, Additional_Information_Russian__c ,
                                            Controlling_Question__c, Value__c, Controlling_Question__r.Name
                                     FROM Section__c WHERE Questionnaire__c = :questionnaireId];

        for (Section__c section : sections) {
            Section__c clonedSection = section.clone(false, true, false, false);
            clonedSection.Questionnaire__c = clonedQuestionnaire.Id;
            clonedSection.Controlling_Question__c = null;
            clonedSections.add(clonedSection);
            nameToClonedSectionMap.put(section.Name, clonedSection);
            // Temporary map original ID to cloned section
            sectionIdMap.put(section.Id, null);
        }
        insert clonedSections;

        // Update map with new cloned IDs
        List<Id> originalSectionIds = new List<Id>(sectionIdMap.keySet());
        for (Integer i = 0; i < clonedSections.size(); i++) {
            Id originalSectionId = originalSectionIds[i];
            Id clonedSectionId = clonedSections[i].Id;
            sectionIdMap.put(originalSectionId, clonedSectionId);
        }

        // Clone Question__c records
        Map<String, Question__c> nameToClonedQuestionMap = new Map<String, Question__c>();
        List<Question__c> questions = [SELECT Name, Type__c, Order__c, Question_English__c, Available_Values_English__c,
                                            Question_Ukrainian__c, Question_Russian__c, Questionnaire__c, Section__c,
                                            Available_Values_Ukrainian__c, Available_Values_Russian__c, Required__c,
                                            Controlling_Question__c, Controlling_Question__r.Name, Value__c, Required_Segments__c
                                        FROM Question__c WHERE Questionnaire__c = :questionnaireId];

        for (Question__c question : questions) {
            Question__c clonedQuestion = question.clone(false, true, false, false);
            clonedQuestion.Questionnaire__c = clonedQuestionnaire.Id;
            clonedQuestion.Section__c = sectionIdMap.get(question.Section__c); // Map to cloned Section__c
            clonedQuestion.Controlling_Question__c = null;
            nameToClonedQuestionMap.put(question.Name, clonedQuestion);
        }

        insert nameToClonedQuestionMap.values();

        updateControllingQuestions(nameToClonedQuestionMap, questions);
        updateControllingQuestionsOnSections(nameToClonedQuestionMap, sections, nameToClonedSectionMap);

        return clonedQuestionnaire.Id;
    }

    private static void updateControllingQuestions(Map<String, Question__c> nameToClonedQuestionMap, List<Question__c> questions) {
        List<Question__c> questionsToUpdate = new List<Question__c>();
        for(Question__c question : questions) {
            if(question.Controlling_Question__c != null) { 
                Question__c questionToUpdate = nameToClonedQuestionMap.get(question.Name);
                questionToUpdate.Controlling_Question__c = nameToClonedQuestionMap.get(question.Controlling_Question__r.Name).Id;
                questionsToUpdate.add(questionToUpdate);
            }
        }

        if(!questionsToUpdate.isEmpty()) {
            update questionsToUpdate;
        }
    }

    private static void updateControllingQuestionsOnSections(Map<String, Question__c> nameToClonedQuestionMap, List<Section__c> sections, Map<String, Section__c> nameToClonedSectionMap) {
        List<Section__c> sectionsToUpdate = new List<Section__c>();
        for(Section__c section : sections) {
            if(section.Controlling_Question__c != null) { 
                Section__c sectionToUpdate = nameToClonedSectionMap.get(section.Name);
                sectionToUpdate.Controlling_Question__c = nameToClonedQuestionMap.get(section.Controlling_Question__r.Name).Id;
                sectionsToUpdate.add(sectionToUpdate);
            }
        }

        if(!sectionsToUpdate.isEmpty()) {
            update sectionsToUpdate;
        }
    }   
}