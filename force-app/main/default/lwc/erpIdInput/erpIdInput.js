import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import validateErpId from '@salesforce/apex/ErpIdValidationApi.validateErpId';

export default class ErpIdInput extends LightningElement {

    @api erpId;
    hasRendered = false;

    // ---------- INITIAL REQUIRED CHECK ----------
    renderedCallback() {
        if (this.hasRendered) {
            return;
        }
        this.hasRendered = true;

        const input = this.template.querySelector('lightning-input');
        if (!this.erpId) {
            input.setCustomValidity('ERP ID is required.');
            input.reportValidity();
        }
    }

    // ---------- ON CHANGE ----------
    handleChange(event) {
        this.erpId = event.target.value;

        // 🔑 ОБОВʼЯЗКОВО: передаємо значення у Flow
        this.dispatchEvent(
            new FlowAttributeChangeEvent('erpId', this.erpId)
        );

        const input = this.template.querySelector('lightning-input');
        input.setCustomValidity('');
        input.reportValidity();
    }

    // ---------- ON BLUR (SERVER VALIDATION) ----------
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

                // 🔑 ДУБЛЮЄМО на всякий випадок після успішної валідації
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