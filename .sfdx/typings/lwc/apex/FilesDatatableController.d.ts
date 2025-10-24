declare module "@salesforce/apex/FilesDatatableController.getFiles" {
  export default function getFiles(): Promise<any>;
}
declare module "@salesforce/apex/FilesDatatableController.viewFile" {
  export default function viewFile(param: {cdl: any}): Promise<any>;
}
declare module "@salesforce/apex/FilesDatatableController.deleteRelatedFile" {
  export default function deleteRelatedFile(param: {docId: any}): Promise<any>;
}
declare module "@salesforce/apex/FilesDatatableController.uploadFile" {
  export default function uploadFile(param: {files: any}): Promise<any>;
}
