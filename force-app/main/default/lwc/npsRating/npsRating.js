import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NPS_FIELD from '@salesforce/schema/Account.NPS__c';

export default class npsRating extends LightningElement {
    @api recordId; // Record ID of the account

    @wire(getRecord, { recordId: '$recordId', fields: [NPS_FIELD] })
    account;

    get npsValue() {
        return getFieldValue(this.account.data, NPS_FIELD);
    }

    get npsClass() {
        const nps = this.npsValue;
        if (nps >= 1 && nps <= 4) {
            return 'red';
        } else if (nps >= 5 && nps <= 8) {
            return 'orange';
        } else if (nps >= 9 && nps <= 10) {
            return 'green';
        }
        return '';
    }
}