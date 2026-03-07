declare module "@salesforce/apex/ScrapDecadesController.getHierarchy" {
  export default function getHierarchy(param: {yearFilter: any, limitSize: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getDetails" {
  export default function getDetails(param: {decadeId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getDayLimits" {
  export default function getDayLimits(param: {dayDecadeId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getDayLimitsByDate" {
  export default function getDayLimitsByDate(param: {targetDate: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.saveDayLimitsByDate" {
  export default function saveDayLimitsByDate(param: {targetDate: any, dayDecadeId: any, items: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.saveDayLimitsForDay" {
  export default function saveDayLimitsForDay(param: {dayDecadeId: any, items: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getDecadeTotalsByDecade" {
  export default function getDecadeTotalsByDecade(param: {decadeId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getMonthTotalsByMonth" {
  export default function getMonthTotalsByMonth(param: {monthId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.getYearTotalsByYear" {
  export default function getYearTotalsByYear(param: {yearId: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.copyDayLimits" {
  export default function copyDayLimits(param: {sourceDayDecadeId: any, targetDayDecadeIds: any, items: any, skipZeros: any, onlyTypeIds: any}): Promise<any>;
}
declare module "@salesforce/apex/ScrapDecadesController.listSiblingDays" {
  export default function listSiblingDays(param: {sourceDayDecadeId: any}): Promise<any>;
}
