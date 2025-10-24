import { LightningElement, api } from "lwc";
import processResponsesForInviteEmail from "@salesforce/apex/QuestionnaireResponseEmailer.processResponsesForInviteEmail";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class questionnaireSendInviteEmail extends LightningElement {
    @api recordId;

    invoke() {
        console.log("Record Id: ", this.recordId);
        processResponsesForInviteEmail({ questionnaireId: this.recordId })
            .then(result => {
                setTimeout(() => {
                    window.location.reload();
                }, 3000); // 3000 milliseconds = 3 seconds
                console.log("Apex method called successfully:", result);
                this.showNotification('Success', 'The survey has started successfully. Reloading...', 'success');
            })
            .catch(error => {
                console.error("Error calling Apex method:", error);
                this.showNotification('Error', 'Failed to start the survey.', 'error');
            });
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showNotification(title, message, variant) {
        console.log('notif')
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,  // success, error, warning, info
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    
}