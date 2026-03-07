declare module "@salesforce/apex/ScrapTypeService.getByBranchAndGroup" {
  export default function getByBranchAndGroup(): Promise<any>;
}
declare module "@salesforce/apex/ScrapTypeService.getScrapDetails" {
  export default function getScrapDetails(param: {scrapTypeId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapTypeService.setActive" {
  export default function setActive(param: {scrapTypeId: any, newIsActive: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapTypeService.updateDescription" {
  export default function updateDescription(param: {scrapTypeId: any, newDescription: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapTypeService.getRemainingSummary" {
  export default function getRemainingSummary(param: {scrapTypeId: any}): Promise<any>;
}
