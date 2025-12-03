declare module "@salesforce/apex/QuestionnaireResponseCreator.processQuestionnaireResponses" {
  export default function processQuestionnaireResponses(param: {questionnaireId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseCreator.deleteExistingResponsesWithAnswers" {
  export default function deleteExistingResponsesWithAnswers(param: {questionnaireId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseCreator.queryContactsFromListView" {
  export default function queryContactsFromListView(param: {listViewName: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseCreator.createQuestionnaireResponsesForContacts" {
  export default function createQuestionnaireResponsesForContacts(param: {questionnaireId: any, contactsFromListView: any, language: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseCreator.sendNotificationEmail" {
  export default function sendNotificationEmail(param: {contactWithEmailSize: any, contactWithoutEmailSize: any, responseSize: any, contactsWithoutEmail: any}): Promise<any>;
}
