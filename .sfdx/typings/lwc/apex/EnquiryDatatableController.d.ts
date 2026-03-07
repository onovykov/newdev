declare module "@salesforce/apex/EnquiryDatatableController.getEnquiries" {
  export default function getEnquiries(): Promise<any>;
}
declare module "@salesforce/apex/EnquiryDatatableController.getEnquiriyDetail" {
  export default function getEnquiriyDetail(param: {enqId: any}): Promise<any>;
}
declare module "@salesforce/apex/EnquiryDatatableController.getEnquiryFiles" {
  export default function getEnquiryFiles(param: {enqId: any}): Promise<any>;
}
declare module "@salesforce/apex/EnquiryDatatableController.viewFile" {
  export default function viewFile(param: {cdl: any}): Promise<any>;
}
declare module "@salesforce/apex/EnquiryDatatableController.generatePdf" {
  export default function generatePdf(param: {selectedEnquiries: any}): Promise<any>;
}
declare module "@salesforce/apex/EnquiryDatatableController.attachFilesToOpportunity" {
  export default function attachFilesToOpportunity(param: {enqId: any}): Promise<any>;
}
