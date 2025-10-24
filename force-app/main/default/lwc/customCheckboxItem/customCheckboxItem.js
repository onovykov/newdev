import { LightningElement, api, track } from 'lwc';

export default class CheckboxItem extends LightningElement {
    @api label;
    @api value;
    @api isChecked = false;

    handleChange(event) {
        this.isChecked = event.target.checked;
        const changeEvent = new CustomEvent('change', {
            detail: {
                value: this.value,
                isChecked: this.isChecked,
            },
        });
        this.dispatchEvent(changeEvent);
    }
}