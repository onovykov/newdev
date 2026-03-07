declare module "@salesforce/apex/OrderDatatableController.getOrders" {
  export default function getOrders(): Promise<any>;
}
declare module "@salesforce/apex/OrderDatatableController.getOrderContext" {
  export default function getOrderContext(param: {isPortal: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/OrderDatatableController.getStructuredProdPlan" {
  export default function getStructuredProdPlan(param: {isPortal: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/OrderDatatableController.generatePdf" {
  export default function generatePdf(param: {selectedOrders: any}): Promise<any>;
}
