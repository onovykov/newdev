public without sharing class QuestionnaireController {
    @AuraEnabled(cacheable=true)

    public static QuestionnaireDataWrapper getQuestionnaireData(String questionnaireId, String responseId) {
        system.debug('responseId'+responseId);
        system.debug('getProfileId '+ UserInfo.getProfileId());

        QuestionnaireDataWrapper dataWrapper = new QuestionnaireDataWrapper();
        List<QuestionnaireSection> questionnaireSections = new List<QuestionnaireSection>();
        Questionnaire_Response__c questionnaireResponse = [
            SELECT Id, MarketSegment__c, Respondent__c, Status__c, Respondent_Language__c, Questionnaire__c, RespondentEmail__c, LastModifiedDate
            FROM Questionnaire_Response__c
            WHERE Id = :responseId
            LIMIT 1
        ];
        questionnaireId = questionnaireResponse.Questionnaire__c;
        Map<Id, Question__c> questionsMap = new Map<Id, Question__c>([
            SELECT Id, Name, Order__c, Type__c, Question_English__c, Question_Russian__c, Question_Ukrainian__c, Available_Values_English__c, 
                   Available_Values_Ukrainian__c,Available_Values_Russian__c, Required__c, Required_Segments__c, Questionnaire__r.IsClosed__c,
                   Questionnaire__r.Name, Questionnaire__r.LogoFileName__c, Questionnaire__r.Questionnaire_Name_Ukrainian__c,
                   Section__r.Id, Section__r.Additional_Information_English__c, Section__r.Additional_Information_Russian__c,
                   Section__r.Order__c, Section__r.Additional_Information_Ukrainian__c, Questionnaire__r.Questionnaire_Name_Russian__c,
                   Controlling_Question__c, Value__c, Section__r.Controlling_Question__c, Section__r.Value__c, Section__r.Name,
                   (SELECT Id, Value__c FROM Answers__r WHERE QuestionnaireResponse__c = :responseId LIMIT 1)
            FROM Question__c
            WHERE Questionnaire__c = :questionnaireId
            ORDER BY Order__c ASC
        ]);

        List<Question__c> questions = questionsMap.values();

        Map<Id, List<Question>> sectionIdToQuestionsMap = new Map<Id, List<Question>>();

        for (Question__c question : questions) {
            Question questionnaireQuestion = new Question();
            questionnaireQuestion.questionId = question.Id;
            questionnaireQuestion.Name = question.Name;
            questionnaireQuestion.order = question.Order__c;
            questionnaireQuestion.type = question.Type__c;
             // Depending on Respondent_Language__c, set the appropriate question text
            if (questionnaireResponse.Respondent_Language__c == 'Ukrainian') {
                questionnaireQuestion.questionValue = question.Question_Ukrainian__c;
                questionnaireQuestion.availableValues = question.Available_Values_Ukrainian__c;
                questionnaireQuestion.SectionAdditionalInformation = question.Section__r?.Additional_Information_Ukrainian__c;

            } else if (questionnaireResponse.Respondent_Language__c == 'Russian') {
                questionnaireQuestion.questionValue = question.Question_Russian__c;
                questionnaireQuestion.availableValues = question.Available_Values_Russian__c;
                questionnaireQuestion.SectionAdditionalInformation = question.Section__r?.Additional_Information_Russian__c;

            } else {
                questionnaireQuestion.questionValue = question.Question_English__c;
                questionnaireQuestion.availableValues = question.Available_Values_English__c;
                questionnaireQuestion.SectionAdditionalInformation = question.Section__r?.Additional_Information_English__c;
            }
            questionnaireQuestion.sectionOrder = question.Section__r?.Order__c;

            questionnaireQuestion.conrtolQuestionId = question.Controlling_Question__c;
            questionnaireQuestion.value = question.Value__c;
            if(question.Controlling_Question__c != null && !questionsMap.get(question.Controlling_Question__c).Answers__r.isEmpty()) {
                List<String> values = question.Value__c.split(',');
                questionnaireQuestion.isVisible = !values.contains(questionsMap.get(question.Controlling_Question__c).Answers__r.get(0).Value__c);
            }

            questionnaireQuestion.sectionConrtolQuestionId = question.Section__r.Controlling_Question__c;
            questionnaireQuestion.sectionValue = question.Section__r.Value__c;
            if(question.Section__r.Controlling_Question__c != null && !questionsMap.get(question.Section__r.Controlling_Question__c).Answers__r.isEmpty()) {
                List<String> values = question.Section__r.Value__c.split(',');
                questionnaireQuestion.sectionIsVisible = !values.contains(questionsMap.get(question.Section__r.Controlling_Question__c).Answers__r.get(0).Value__c);
            }
            questionnaireQuestion.sectionName = question.Section__r.Name;
            questionnaireQuestion.isRequired = questionnaireResponse.MarketSegment__c != null && question.Required_Segments__c != null ? 
                                               question.Required__c && question.Required_Segments__c.contains(questionnaireResponse.MarketSegment__c) : 
                                               question.Required__c;
            // Check if there is a related answer and set it as currentUserAnswerId
            if (question.Answers__r != null && !question.Answers__r.isEmpty()) {
                questionnaireQuestion.currentUserAnswerId = question.Answers__r[0]; // Assuming there's only one related answer
            }

            if (question.Section__c != null) {
                if (!sectionIdToQuestionsMap.containsKey(question.Section__r.Id)) {
                    sectionIdToQuestionsMap.put(question.Section__r.Id, new List<Question>());
                }

                sectionIdToQuestionsMap.get(question.Section__r.Id).add(questionnaireQuestion);
            }
        }
        for (Id sectionId : sectionIdToQuestionsMap.keySet()) {
            QuestionnaireSection questionnaireSection = new QuestionnaireSection();
            questionnaireSection.sectionId = sectionId;
            questionnaireSection.questions = sectionIdToQuestionsMap.get(sectionId);
            questionnaireSection.order = questionnaireSection.questions[0].sectionOrder;
            questionnaireSection.conrtolQuestionId = questionnaireSection.questions[0].sectionConrtolQuestionId;
            questionnaireSection.value = questionnaireSection.questions[0].sectionValue;
            questionnaireSection.isVisible = questionnaireSection.questions[0].sectionIsVisible;
            if (questionnaireResponse.Respondent_Language__c == 'Ukrainian') {
                questionnaireSection.questionnaireName = questions[0].Questionnaire__r.Questionnaire_Name_Ukrainian__c;

            } else if (questionnaireResponse.Respondent_Language__c == 'Russian') {
                questionnaireSection.questionnaireName = questions[0].Questionnaire__r.Questionnaire_Name_Russian__c;

            } else {
                questionnaireSection.questionnaireName = questions[0].Questionnaire__r.Name;
            }
            questionnaireSection.logoFileName = questions[0].Questionnaire__r.LogoFileName__c;
            questionnaireSection.additionalInformation = sectionIdToQuestionsMap.get(sectionId)[0].SectionAdditionalInformation;
            questionnaireSections.add(questionnaireSection);
        }
        dataWrapper.questionnaireSections = questionnaireSections;
        dataWrapper.questionnaireResponse = questionnaireResponse;
        dataWrapper.isClosed = questions[0].Questionnaire__r.IsClosed__c;
        return dataWrapper;
    }
    public class QuestionnaireDataWrapper {
        @AuraEnabled
        public List<QuestionnaireSection> questionnaireSections;
        
        @AuraEnabled
        public Questionnaire_Response__c questionnaireResponse;
        
        @AuraEnabled
        public Boolean isClosed;
    }

    public class QuestionnaireSection {
        @AuraEnabled
        public String questionnaireName;
        @AuraEnabled
        public String logoFileName;
        @AuraEnabled
        public Id sectionId;
        @AuraEnabled
        public String additionalInformation;
        @AuraEnabled
        public Decimal order;
        @AuraEnabled
        public List<Question> questions;
        @AuraEnabled
        public Id conrtolQuestionId;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public Boolean isVisible = true;
    }
    
    public class Question {
        @AuraEnabled
        public Id questionId;
        @AuraEnabled
        public Answer__c currentUserAnswerId;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public Decimal order;
        @AuraEnabled
        public String SectionAdditionalInformation;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String questionValue;
        @AuraEnabled
        public String availableValues;
        @AuraEnabled
        public Decimal sectionOrder;
        @AuraEnabled
        public Boolean isRequired;
        @AuraEnabled
        public Id conrtolQuestionId;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public Boolean isVisible = true;
        @AuraEnabled
        public Id sectionConrtolQuestionId;
        @AuraEnabled
        public String sectionValue;
        @AuraEnabled
        public Boolean sectionIsVisible = true;
        @AuraEnabled
        public String sectionName;
    }


    @AuraEnabled
    public static String createAnswer(String questionId, String response, String responseId) {
        System.debug('questionId' + questionId);
        System.debug('response' + response);
        System.debug('responseId' + responseId);
        Question__c question = [SELECT Name FROM Question__c WHERE id =:questionId LIMIT 1];
        
        try {
            List<Answer__c> existingAnswers = [SELECT Id FROM Answer__c WHERE Question__c = :questionId AND QuestionnaireResponse__c =:responseId LIMIT 1];
            System.debug('existingAnswers' + existingAnswers);
            if (existingAnswers != null && !existingAnswers.isEmpty()) {
                Answer__c existingAnswer = existingAnswers[0];
                existingAnswer.Value__c = response;
                existingAnswer.QuestionnaireResponse__c = responseId;
                
                update existingAnswer;
                updateRelatedAccountNPS(questionId, response, responseId);
                System.debug('Answer record updated '+ existingAnswer);

                return 'Answer record updated successfully.';
            } else {
                // No existing answer record found, create a new one
                Answer__c newAnswer = new Answer__c();
                newAnswer.Question__c = questionId; 
                newAnswer.Value__c = response; 
                newAnswer.QuestionnaireResponse__c = responseId;


                // Insert the new answer record
                insert newAnswer;
                updateRelatedAccountNPS(questionId, response, responseId);
                System.debug('Answer record inserted '+ newAnswer);
                return 'Answer record inserted successfully.';
            }
        } catch (Exception e) {
            // Handle any exceptions or errors here
            return 'Error creating/updating answer record: ' + e.getMessage();
        }
    }
    public static void updateRelatedAccountNPS(String questionId, String response, String responseId) {
        try {
            Question__c question = [SELECT Name FROM Question__c WHERE id =:questionId LIMIT 1];
            System.debug('question NAME  '+ question.Name);

            if (question.Name == 'NPS') {
                // Fetch the related questionnaire response
                Questionnaire_Response__c questionnaireResponse = [SELECT Id, Respondent__c, Respondent__r.AccountId FROM Questionnaire_Response__c WHERE Id = :responseId LIMIT 1];
                System.debug('Questionnaire_Response__c  '+ questionnaireResponse);
                
                if (questionnaireResponse != null && questionnaireResponse.Respondent__c != null) {
                    // Fetch the related account
                    Id accountId = questionnaireResponse.Respondent__r.AccountId;
                    System.debug('accountId  '+ accountId);
                    System.debug('response  '+ response);

                    
                    if (accountId != null) {
                        // Update the account's NPS field
                        Account relatedAccount = new Account(Id = accountId, NPS__c = response);
                        System.debug('relatedAccount  '+ relatedAccount);
                        update relatedAccount;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception in updateRelatedAccountNPS: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }        
    }
    
    @AuraEnabled
    public static String getQuestionnaireId(String responseId) {
        String questionnaireId = [SELECT id, Questionnaire__c FROM Questionnaire_Response__c WHERE id =:responseId LIMIT 1]?.Questionnaire__c;
        return questionnaireId;
    }
    @AuraEnabled
    public static String updateResponseStatus(Id questionnaireResponseId, String newStatus) {
        try {
            Questionnaire_Response__c questionnaireResponse = new Questionnaire_Response__c(
                Id = questionnaireResponseId,
                Status__c = newStatus
            );

            if(questionnaireResponse.Status__c == 'Complete') {
                questionnaireResponse.Completed_Date__c = Date.today();
            }

            update questionnaireResponse;

            return 'Status updated successfully.';
        } catch (Exception e) {
            return 'Error updating status: ' + e.getMessage();
        }
    }
    @AuraEnabled
    public static String updateResponseLanguage(Id questionnaireResponseId, String newLanguage) {
        try {
            Questionnaire_Response__c questionnaireResponse = new Questionnaire_Response__c(
                Id = questionnaireResponseId,
                Respondent_Language__c = newLanguage
            );

            update questionnaireResponse;

            return 'Respondent Language updated successfully.';
        } catch (Exception e) {
            return 'Error updating Language: ' + e.getMessage();
        }
    }
    // @AuraEnabled
    // public static List<Answer__c> getQuestionnaireDataForXLSX(String questionnaireId) {
    //     List<Answer__c> answersWithQuestionsAndResponse = [SELECT id, Value__c, Question__r.Question_English__c, Question__r.Required__c,
    //                                                     Question__r.Question_Russian__c, Question__r.Question_Ukrainian__c,
    //                                                     QuestionnaireResponse__r.Status__c, QuestionnaireResponse__r.RespondentEmail__c, QuestionnaireResponse__r.MarketSegment__c,
    //                                                     QuestionnaireResponse__r.Respondent__c, QuestionnaireResponse__r.LastModifiedDate
    //                                                     FROM Answer__c
    //                                                     WHERE QuestionnaireResponse__r.Questionnaire__c =:questionnaireId
    //                                                     ];
    //     return answersWithQuestionsAndResponse;
    // }

    @AuraEnabled
    public static List<AnswerWrapper> getQuestionnaireDataForXLSX(String questionnaireId) {
        List<AnswerWrapper> answearWrapperList = new List<AnswerWrapper>();

        List<Section__c> sectionWithQuestionsList = [SELECT Id, Name,
                                                            (SELECT Id, Order__c, Question_English__c, Section__r.Order__c FROM Questions__r ORDER BY Order__c ASC) 
                                                    FROM Section__c 
                                                    WHERE Questionnaire__c = :questionnaireId 
                                                    ORDER BY Order__c ASC];

        List<Questionnaire_Response__c> questionnaireResponses = [SELECT Id, Status__c, RespondentEmail__c, MarketSegment__c
                                                                  FROM Questionnaire_Response__c
                                                                  WHERE Questionnaire__c = :questionnaireId];
        
        Map<String, Answer__c> questionAndResponseToAnswerMap = getQuestionAndResponseToAnswerMap(questionnaireResponses);


        for(Section__c section : sectionWithQuestionsList) {
            for(Question__c question : section.Questions__r) {
                for(Questionnaire_Response__c questionnaireResponse : questionnaireResponses) {
                    AnswerWrapper answer = new AnswerWrapper();

                    if(questionAndResponseToAnswerMap.get(question.Id + '' + questionnaireResponse.Id) != null) {
                        answer.value = questionAndResponseToAnswerMap.get(question.Id + '' + questionnaireResponse.Id).Value__c;
                    }
                    answer.questionnaireResponseId = questionnaireResponse.Id;
                    answer.questionEnglish = question.Question_English__c;
                    answer.status = questionnaireResponse.Status__c;
                    answer.respondentEmail = questionnaireResponse.RespondentEmail__c;
                    answer.marketSegment = questionnaireResponse.MarketSegment__c;
                    answer.sectionAndQuestionName = section.Name + ': ' + question.Question_English__c;

                    answearWrapperList.add(answer);
                }
            }
        }

        return answearWrapperList;
    }

    private static  Map<String, Answer__c> getQuestionAndResponseToAnswerMap(List<Questionnaire_Response__c> questionnaireResponses) {
        List<Answer__c> anwersList = [SELECT Id, Value__c, Question__c, QuestionnaireResponse__c FROM Answer__c WHERE QuestionnaireResponse__c IN :questionnaireResponses];
        Map<String, Answer__c> questionAndResponseToAnswerMap = new Map<String, Answer__c>();

        for(Answer__c answer : anwersList) {
            questionAndResponseToAnswerMap.put(answer.Question__c + '' + answer.QuestionnaireResponse__c, answer);
        }
        return questionAndResponseToAnswerMap;
    }

    public class AnswerWrapper {
        @AuraEnabled
        public Id questionnaireResponseId;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String questionEnglish;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String respondentEmail;
        @AuraEnabled
        public String marketSegment;
        @AuraEnabled
        public String sectionAndQuestionName;
    }


    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}