import { LightningElement, api } from "lwc";
import processQuestionnaireResponses from "@salesforce/apex/QuestionnaireResponseCreator.processQuestionnaireResponses";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
export default class createQuestionnaireResponses extends LightningElement {
    @api recordId;

    @api invoke() {
        console.log("Record Id:", this.recordId);
        processQuestionnaireResponses({ questionnaireId: this.recordId })
            .then(result => {
                console.log("Apex method called successfully:");
                setTimeout(() => {
                    window.location.reload();
                }, 3000); // 3000 milliseconds = 3 seconds
                this.showNotification('Success', 'Questionnaire response records create successfully. Reloading...', 'success');
            })
            .catch(error => {
                console.error("Error calling Apex method:", error);
                this.showNotification('Error', 'Failed to create records. ' + error, 'error');
            });
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