declare module "@salesforce/apex/QuestionnaireController.getQuestionnaireData" {
  export default function getQuestionnaireData(param: {questionnaireId: any, responseId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireController.createAnswer" {
  export default function createAnswer(param: {questionId: any, response: any, responseId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireController.getQuestionnaireId" {
  export default function getQuestionnaireId(param: {responseId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireController.updateResponseStatus" {
  export default function updateResponseStatus(param: {questionnaireResponseId: any, newStatus: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireController.updateResponseLanguage" {
  export default function updateResponseLanguage(param: {questionnaireResponseId: any, newLanguage: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireController.getQuestionnaireDataForXLSX" {
  export default function getQuestionnaireDataForXLSX(param: {questionnaireId: any}): Promise<any>;
}
