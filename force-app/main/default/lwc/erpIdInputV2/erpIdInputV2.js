import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import validateErpId from '@salesforce/apex/ErpIdValidationApi.validateErpId';

export default class ErpIdInputV2 extends LightningElement {

    @api erpId;
    hasRendered = false;

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        const input = this.template.querySelector('lightning-input');
        if (!this.erpId) {
            input.setCustomValidity('ERP ID is required.');
            input.reportValidity();
        }
    }

    handleChange(event) {
        this.erpId = event.target.value;

        // 🔑 ЄДИНИЙ МЕХАНІЗМ ПЕРЕДАЧІ У FLOW
        this.dispatchEvent(
            new FlowAttributeChangeEvent('erpId', this.erpId)
        );

        const input = this.template.querySelector('lightning-input');
        input.setCustomValidity('');
        input.reportValidity();
    }

    async handleBlur() {
        const input = this.template.querySelector('lightning-input');

        if (!this.erpId) {
            input.setCustomValidity('ERP ID is required.');
            input.reportValidity();
            return;
        }

        try {
            const result = await validateErpId({ erpId: this.erpId });

            if (!result.isValid) {
                input.setCustomValidity(result.errorMessage);
            } else {
                input.setCustomValidity('');

                // 🔁 дублюємо на всякий випадок
                this.dispatchEvent(
                    new FlowAttributeChangeEvent('erpId', this.erpId)
                );
            }

            input.reportValidity();
        } catch (e) {
            input.setCustomValidity('Validation error. Please try again.');
            input.reportValidity();
        }
    }
}