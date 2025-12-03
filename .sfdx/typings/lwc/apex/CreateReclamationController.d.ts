declare module "@salesforce/apex/CreateReclamationController.takeInitialInfo" {
  export default function takeInitialInfo(): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.getDependentMap" {
  export default function getDependentMap(param: {objDetail: any, contrfieldApiName: any, depfieldApiName: any}): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.getDependentMapLwc" {
  export default function getDependentMapLwc(): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.getOrderItems" {
  export default function getOrderItems(param: {orderId: any}): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.getOrderData" {
  export default function getOrderData(param: {orderId: any}): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.createReclamation" {
  export default function createReclamation(param: {reclamation: any, data: any}): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.addReclamationItems" {
  export default function addReclamationItems(param: {reclamationId: any, data: any}): Promise<any>;
}
declare module "@salesforce/apex/CreateReclamationController.getReclamationStatus" {
  export default function getReclamationStatus(param: {reclamationId: any}): Promise<any>;
}
