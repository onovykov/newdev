import { LightningElement, api, wire, track } from 'lwc';
import getUserImg from '@salesforce/apex/UserUtils.getUserImg';
import { getRecord } from 'lightning/uiRecordApi';
export default class SiteDealingStatus extends LightningElement {

    @api accountId;
    CurrentUserImgUrl;
    @track accData = {};
    
    connectedCallback(){
        console.log(this.accountId);
    }

    @wire(getRecord,{recordId:'$accountId', layoutTypes:['Full']}) handleAcc(result){
       
        const {error, data } = result;
        if(data){
            console.log(data);
            let accValues = {
                dealingStatus :  data.fields.DealingStatus__c.displayValue,
                balance :  data.fields.Balance__c.value + " " + data.fields.CurrencyIsoCode.value,
                pastDueDebt :  data.fields.PastDueDebt__c.value + " " + data.fields.CurrencyIsoCode.value,
                pastDueDebt15More :  data.fields.PastDueDebt15More__c.value + " " + data.fields.CurrencyIsoCode.value, 
                groupPastDueDebt :  data.fields.GroupPastDueDebt__c.value + " " + data.fields.CurrencyIsoCode.value,
                groupPastDueDebt15More :  data.fields.GroupPastDueDebt15More__c.value + " " + data.fields.CurrencyIsoCode.value,
                currentMonthReceipts :  data.fields.CurrentMonthReceipts__c.value + " " + data.fields.CurrencyIsoCode.value,
                blockDate :  data.fields.BlockDate__c.value,
                permissionDate :  data.fields.PermissionDate__c.value,
                permittedById :  data.fields.PermittedById__c.value,
                permittedProductionAmount :  data.fields.PermittedProductionAmount__c.value,
                permittedShipmentAmount :  data.fields.PermittedShipmentAmount__c.value,
                accountName : data.fields.Name.value,
                //permissionComment :  data.fields.PermissionComment__c.value
            }

            let balance = accValues.balance
            let currentMonthReceipts = accValues.currentMonthReceipts
            let pastDueDebt = accValues.pastDueDebt
            let pastDueDebt15More = accValues.pastDueDebt15More
            let groupPastDueDebt = accValues.groupPastDueDebt
            let groupPastDueDebt15More = accValues.currentMonthReceipts

            accValues.balance = this.numberWithSpaces(balance);
            accValues.currentMonthReceipts = this.numberWithSpaces(currentMonthReceipts);
            accValues.pastDueDebt = this.numberWithSpaces(pastDueDebt);
            accValues.pastDueDebt15More = this.numberWithSpaces(pastDueDebt15More);
            accValues.groupPastDueDebt = this.numberWithSpaces(groupPastDueDebt);
            accValues.groupPastDueDebt15More = this.numberWithSpaces(groupPastDueDebt15More);

            this.accData = accValues;
        }
        if(error){
            console.error(error);
        }
    }

    numberWithSpaces(x) {
        var parts = x.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, " ");
        return parts.join(".");
    }
    @wire(getRecord,{recordId:'$accData.permittedById', layoutTypes:['Full']}) handleUser(result){
        const {error, data } = result;
        if(data){
            this.accData.PermittedByUser = data.fields.FirstName.value + ' ' + data.fields.LastName.value;
        }
        if(error){
            console.error(error);
        }
    }

    @wire(getUserImg,{}) handleUserImg(result){
        const {error, data } = result;
        if(data){
            console.log('1312312312323', data)
            this.CurrentUserImgUrl = data;

        }
        if(error){
            console.error(error);
        }

    }
}