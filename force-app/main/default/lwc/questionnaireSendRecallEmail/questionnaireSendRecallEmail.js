import { LightningElement, api } from "lwc";
import processResponsesForRecallEmail from "@salesforce/apex/QuestionnaireResponseEmailer.processResponsesForRecallEmail";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class questionnaireSendRecallEmail extends LightningElement {
    @api recordId;

    invoke() {
        console.log("Record Id:", this.recordId);
        processResponsesForRecallEmail({ questionnaireId: this.recordId })
            .then(result => {
                console.log("Apex method called successfully:", result);
                this.showNotification('Success', 'Recall emails has been sent.', 'success');
            })
            .catch(error => {
                console.error("Error calling Apex method:", error);
                this.showNotification('Error', 'Failed to send emails.', 'error');
            });
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,  // success, error, warning, info
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    
}