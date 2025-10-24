declare module "@salesforce/apex/ReclamationDatatableController.getReclamations" {
  export default function getReclamations(): Promise<any>;
}
declare module "@salesforce/apex/ReclamationDatatableController.getReclamationFiles" {
  export default function getReclamationFiles(param: {reclamationId: any}): Promise<any>;
}
declare module "@salesforce/apex/ReclamationDatatableController.viewFile" {
  export default function viewFile(param: {cdl: any}): Promise<any>;
}
declare module "@salesforce/apex/ReclamationDatatableController.generatePdf" {
  export default function generatePdf(param: {selectedReclamations: any}): Promise<any>;
}
