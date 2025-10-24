import { LightningElement, wire, api, track } from 'lwc';
import cloneQuestionnaireWithQuestions from '@salesforce/apex/QuestionnaireCloner.cloneQuestionnaireWithQuestions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class QuestionnaireCloner extends NavigationMixin(LightningElement) {
    @api recordId; // If the component is placed on a record page, it gets the record Id automatically.

    cloneQuestionnaire() {
        cloneQuestionnaireWithQuestions({ questionnaireId: this.recordId })
            .then(clonedRecordId => {
                // Navigate to the new record page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: clonedRecordId,
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error('Error cloning questionnaire:', error);
            });
    }
}