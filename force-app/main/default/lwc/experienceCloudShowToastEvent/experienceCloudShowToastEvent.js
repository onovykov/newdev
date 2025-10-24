import { LightningElement, wire, api, track } from 'lwc';
import getCustomerComunityUserAccount from '@salesforce/apex/ExperienceCloudShowToastEventController.getCustomerComunityUserAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import 	dueDebt from '@salesforce/label/c.due_debt';
import 	cantOrderProducts from '@salesforce/label/c.cant_order_any_products';
import 	wontPlaceAnOrder from '@salesforce/label/c.will_not_be_able_to_place_an_order';


export default class ExperienceCloudShowToastEvent extends LightningElement {
    CurrencyIsoCode;
    PastDueDebt;
    DealingStatus;
    BlockDate;
    @wire(getCustomerComunityUserAccount)
    wiredAccounts({ data, error }) {
        if (data) {
            console.log(data);
            this.CurrencyIsoCode = data[0].CurrencyIsoCode;
            this.PastDueDebt = data[0].PastDueDebt__c;
            this.DealingStatus = data[0].DealingStatus__c;
            this.BlockDate = data[0].BlockDate__c;
            this.showToast();
        } else if (error) {
            console.log(error);
        }
    }
    showToast() {
        console.log(this.DealingStatus);
        if (this.DealingStatus == 40) {
            const event = new ShowToastEvent({
                title: dueDebt + ' ' + this.PastDueDebt + this.CurrencyIsoCode,
                message:
                wontPlaceAnOrder + ' ' + this.BlockDate,
                mode: 'sticky',
                variant: 'error'
            });
            this.dispatchEvent(event);
        } if (this.DealingStatus == 10) {
            const event = new ShowToastEvent({
                title: dueDebt + ' ' + this.PastDueDebt + this.CurrencyIsoCode,
                message: cantOrderProducts,
                mode: 'sticky',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }

    }

}