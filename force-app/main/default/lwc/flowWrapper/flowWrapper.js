import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class FlowWrapper extends NavigationMixin(LightningElement) {

    handleStatusChange(event) {
        if (event.detail.status !== 'FINISHED') {
            return;
        }

        const outputVars = event.detail.outputVariables || [];

        const createdAccountId = outputVars.find(
            v => v.name === 'CreatedAccount'
        )?.value;

        if (createdAccountId) {
            // 🔁 redirect to created Account
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: createdAccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }

        // 🔒 close modal if Flow opened as Quick Action
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (e) {
            // not a modal → ignore safely
        }
    }
}