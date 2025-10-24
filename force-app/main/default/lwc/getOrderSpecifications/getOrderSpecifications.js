import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import requestForOrderSpecList from '@salesforce/apex/GetOrderSpecificationsController.requestForOrderSpecList';
import requestForOrderSpec from '@salesforce/apex/GetOrderSpecificationsController.requestForOrderSpec';

export default class GetOrderSpecifications extends LightningElement {
    showSpinner = true;
    showError = false;
    showOrderConfirm = false;
    showOrderConfirmDisabled = true;
    b64 = 'data:application/pdf;base64, ';
    nameFile = 'Order_Confirmation.pdf';
    @api recordId;

    @wire(requestForOrderSpecList, {recId: '$recordId'})
    getResponse({data, error}) {
        if (data) {
            if(data.Success == true) {
                this.requestOrderSpecHandle(this.recordId, data.Specifications[0].FileInfo.Id);
            } else {
                this.showSpinner = false;
                this.showError = true;
            }
        } else if (error) {
            this.showSpinner = false;
            this.showError = true;

            console.error(error);
        }
    }

    requestOrderSpecHandle(recId1, fieldId1) {
        requestForOrderSpec({recId: recId1, fieldId: fieldId1})
            .then((result) => {
                if (result.Success == true) {
                    this.b64 += result.FileContent.Content;
                    this.nameFile = result.FileContent.FileName;
                    this.showSpinner = false;
                    this.showOrderConfirm = true;
                    this.showOrderConfirmDisabled = false;
                    console.log('b64 : ', this.b64);
                } else {
                    this.showSpinner = false;
                    this.showError = true;
                }
            })
            .catch((error) => {
                console.error(error);
                this.showSpinner = false;
                this.showError = true;
            });
    }

    closeModal(){
        this.dispatchEvent(new CloseActionScreenEvent());           
    }

    downloadFile() {
        if (this.b64.length > 0) {
            const link = document.createElement('a');
            
            link.href = this.b64;
            link.download = this.nameFile;
            this.template.querySelector('.container').appendChild(link);
            link.click();
        }
    }
}