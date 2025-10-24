declare module "@salesforce/apex/PreviewPdfController.attachPDfLight" {
  export default function attachPDfLight(param: {quoteId: any, pageName: any, quantity: any, selectedMeasure: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.getTemplate" {
  export default function getTemplate(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.getAllTemplates" {
  export default function getAllTemplates(): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.getMarketSegment" {
  export default function getMarketSegment(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.getAllLanguages" {
  export default function getAllLanguages(param: {quoteId: any, curTemplate: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.getAllMetrics" {
  export default function getAllMetrics(): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.validateQuoteTerms" {
  export default function validateQuoteTerms(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.fetchQuoteLineItems" {
  export default function fetchQuoteLineItems(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.changeShowInPdfToTrue" {
  export default function changeShowInPdfToTrue(param: {selectedQuoteLineItems: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.changeShowInPdfToFalse" {
  export default function changeShowInPdfToFalse(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.fetchPicklistMeasureUnit" {
  export default function fetchPicklistMeasureUnit(): Promise<any>;
}
declare module "@salesforce/apex/PreviewPdfController.fetchMeasureUnitsProducts" {
  export default function fetchMeasureUnitsProducts(param: {quoteId: any}): Promise<any>;
}
