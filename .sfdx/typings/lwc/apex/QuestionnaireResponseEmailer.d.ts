declare module "@salesforce/apex/QuestionnaireResponseEmailer.processResponsesForInviteEmail" {
  export default function processResponsesForInviteEmail(param: {questionnaireId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseEmailer.processResponsesForRecallEmail" {
  export default function processResponsesForRecallEmail(param: {questionnaireId: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseEmailer.sendEmailToRespondents" {
  export default function sendEmailToRespondents(param: {questionnaireResponses: any, type: any}): Promise<any>;
}
declare module "@salesforce/apex/QuestionnaireResponseEmailer.sendEmailWithAttachmentToRespondent" {
  export default function sendEmailWithAttachmentToRespondent(param: {base64FileContent: any, fileName: any, respondentEmail: any}): Promise<any>;
}
