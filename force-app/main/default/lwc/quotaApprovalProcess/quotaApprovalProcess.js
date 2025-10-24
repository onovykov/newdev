import { LightningElement, wire, track } from 'lwc';
import getQuotaDetails from '@salesforce/apex/QuotaApprovalProcessController.getQuotaDetails';
import getQuoteSegmentStruct from '@salesforce/apex/QuotaApprovalProcessController.getQuoteSegmentStruct';
import approveOrRejectRequest from '@salesforce/apex/QuotaApprovalProcessController.approveOrRejectRequest';
import isApprovalRequestPending from '@salesforce/apex/QuotaApprovalProcessController.isApprovalRequestPending';

export default class QuotaApprovalProcess extends LightningElement {
    quotaData = [];
    quotaHeaderData;
    familyTotals;
    @track groupedData = [];
    @track groupedDataOld = [];
    isManagerVisible = false;
    isRegionVisible = false;
    isGroup3Visible = false;
    urlString = window.location.href;
    message;
    @track showMessage = false;

    connectedCallback() {
        isApprovalRequestPending({ urlString: this.urlString })
        .then((data) => {
            console.log('data: ', data);
            if (data && data == true) {
                getQuotaDetails({ urlString: this.urlString })
                    .then((data) => {
                        console.log('data: ', data);
                        if (data && data.length > 0) {
                            this.quotaData = data;
                            const header = data[0];
                            this.quotaHeaderData = {
                                ...header,
                                formattedDateFrom: this.formatDate(header.dateFrom),
                                formattedDateTo: this.formatDate(header.dateTo),
                                formattedCreatedDate: this.formatDateTime(header.createdDate)
                            };
                            this.getSegmentStruct();
                            this.calculateFamiliesTotals();
                            this.processData();
                        }
                    })
                    .catch(error => {
                        console.error('error =====> ', error);
                    });  
            } else {
                this.message = 'Цей запит вже було оброблено';
                this.showMessage = true
            }
        })
        .catch(error => {
            console.error('error =====> ', error);
        });  
        
    }

    getSegmentStruct() {
        getQuoteSegmentStruct({ marketSegment: this.quotaHeaderData.marketSegment })
            .then((data) => {
                if (data && data.length > 0) {
                    this.isManagerVisible = data[0].ManagerStruct__c;
                    this.isRegionVisible = data[0].RegionStruct__c;
                    this.isGroup3Visible = data[0].Group3Struct__c;
                    console.log('isManagerVisible: ', this.isManagerVisible);
                }
            })
            .catch(error => {
                console.error('error =====> ', error);
            });

    }

    calculateFamiliesTotals() {
        this.familyTotals = [];

        this.quotaData.forEach(item => {
            const existingFamily = this.familyTotals.find(family => family.family === item.family);

            if (!existingFamily) {
                this.familyTotals.push({
                    family: item.family,
                    familyId: item.familyId,
                    familyType: item.familyType,
                    quoteT: parseFloat(item.quoteT) || 0,
                });
            } else {
                existingFamily.quoteT += parseFloat(item.quoteT || 0);
            }
        });

        this.familyTotals = this.familyTotals.map(family => ({
            ...family,
            quoteT: this.formatNumber(family.quoteT),
        }));
    }

    processData() {
        const grouped = new Map();

        this.quotaData.forEach((item) => {
            if (!grouped.has(item.familyType)) {
                grouped.set(item.familyType, []);
            }

            grouped.get(item.familyType).push({
                manager: item.manager,
                group3: item.group3,
                region: item.region,
                quoteT: parseFloat(item.quoteT) || 0,
                percent: parseFloat(item.percent) || 0,
                addQty: parseFloat(item.addQty) || 0,
                quoteTClass: item.isQuoteTEquals ? 'slds-text-align_right' : 'highlight-cell slds-text-align_right',
                percentClass: item.isPercentEquals ? 'slds-text-align_right' : 'highlight-cell slds-text-align_right',
                addQtyClass: item.isAddQtyEquals ? 'slds-text-align_right' : 'highlight-cell slds-text-align_right',
                percentOld: parseFloat(item.percentOld) || 0,
                quoteTOld: parseFloat(item.quoteTOld) || 0,
                addQtyOld: parseFloat(item.addQtyOld) || 0,
                quoteTOldClass: 'slds-text-align_right',
                percentOldClass: 'slds-text-align_right',
                addQtyOldClass: 'slds-text-align_right',
            });
        });

        this.groupedData = Array.from(grouped.entries()).map(([familyType, rows]) => {
            const totals = rows.reduce(
                (acc, row) => {
                    acc.quoteT += row.quoteT;
                    acc.percent += row.percent;
                    acc.addQty += row.addQty;
                    acc.quoteTOld += row.quoteTOld;
                    acc.percentOld += row.percentOld;
                    acc.addQtyOld += row.addQtyOld;
                    return acc;
                },
                { quoteT: 0, percent: 0, addQty: 0, quoteTOld: 0, percentOld: 0, addQtyOld: 0 }
            );

            rows.push({
                manager: 'Загалом: ', 
                group3: '',
                region: '',
                quoteT: totals.quoteT,
                percent: totals.percent,
                addQty: totals.addQty,
                quoteTClass: 'highlight-cell bold-cell slds-text-align_right',
                percentClass: 'highlight-cell bold-cell slds-text-align_right',
                addQtyClass: 'highlight-cell bold-cell slds-text-align_right',
                quoteTOld: totals.quoteTOld,
                percentOld: totals.percentOld,
                addQtyOld: totals.addQtyOld,
                quoteTOldClass: 'bold-cell slds-text-align_right',
                percentOldClass: 'bold-cell slds-text-align_right',
                addQtyOldClass: 'bold-cell slds-text-align_right',
                managerClass: 'bold-cell',
            });

            rows.forEach((row) => {
                row.quoteT = this.formatNumber(row.quoteT);
                row.percent = this.formatNumber(row.percent);
                row.addQty = this.formatNumber(row.addQty);
                row.quoteTOld = this.formatNumber(row.quoteTOld);
                row.percentOld = this.formatNumber(row.percentOld);
                row.addQtyOld = this.formatNumber(row.addQtyOld);
            });

            return {
                familyType,
                rowspan: rows.length + 1,
                rows,
            };
        });

        //console.log('this.groupedData: ', JSON.stringify(this.groupedData, null, 2));
    }
    
    formatNumber(value) {
        const number = parseFloat(value);
        return isNaN(number) ? '0.00' : number.toFixed(2);
    }

    get quotaNumber() {
        return this.quotaData.length > 0 ? this.quotaData[0].requestNumber : '';
    }
        
    get marketSegmentName() {
        return this.quotaData.length > 0 ? this.quotaData[0].marketSegmentName : '';
    }
    
    get formattedDate() {
        if (this.quotaData.length > 0 && this.quotaData[0].dateFrom) {
            const dateFrom = new Date(this.quotaData[0].dateFrom);
            const year = dateFrom.getFullYear();
            const month = String(dateFrom.getMonth() + 1).padStart(2, '0');
            return year.toString() + '/' + month.toString();
        }
        return '';
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const [year, month, day] = dateString.split('-');
        return `${day}.${month}.${year}`;
    }
    
    formatDateTime(dateTimeString) {
        if (!dateTimeString) return '';
        const date = new Date(dateTimeString);
        const options = {
            timeZone: 'Europe/Kyiv',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        };
        const formatted = new Intl.DateTimeFormat('uk-UA', options).format(date);
        return formatted.replace(/\//g, '.');
    }

    handleApproveRequest() {
        console.log('tut ');
        approveOrRejectRequest({ urlString: this.urlString, isApproved: true })
            .then((data) => {
                console.log('data: ', data);
                if (data) {
                    this.message = data;
                    this.showMessage = true;
                }
            })
            .catch(error => {
                console.error('error =====> ', error);
            });
    }

    handleRejectRequest() {
        approveOrRejectRequest({ urlString: this.urlString, isApproved: false })
            .then((data) => {
                console.log('data: ', data);
                if (data) {
                    this.message = data;
                    this.showMessage = true;
                }
            })
            .catch(error => {
                console.error('error =====> ', error);
            });
    }
}