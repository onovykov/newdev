import { LightningElement, api } from 'lwc';

export default class CustomLookup extends LightningElement {
    @api mainObjectApiName; //Object Api Name displayed in Main Datatable 
    @api targetFieldApiName; //This Object's Lookup Field Api Name
    @api fieldLabel;
    @api disabled = false;
    @api value;
    @api recordId;
    @api required = false;

    handleLookupChange(event) {
        this.value = event.target.value;
        // Creates the event
        const fieldChangedEvent = new CustomEvent('customfieldchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                value: this.value,
                recordId: this.recordId,
                fieldApiName: this.targetFieldApiName
            }
        });
        //dispatching the custom event
        this.dispatchEvent(fieldChangedEvent);
    }

    @api isValid() {
        if (this.required) {
            this.template.querySelector('lightning-input-field').reportValidity();
        }
    }
}