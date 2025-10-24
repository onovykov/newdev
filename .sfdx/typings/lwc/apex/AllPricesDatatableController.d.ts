declare module "@salesforce/apex/AllPricesDatatableController.getPrices" {
  export default function getPrices(): Promise<any>;
}
declare module "@salesforce/apex/AllPricesDatatableController.getFilteredPrices" {
  export default function getFilteredPrices(param: {filters: any, fieldsTypes: any, fieldsMax: any}): Promise<any>;
}
