import { LightningElement, api, wire } from 'lwc';
import getUsersForRole from '@salesforce/apex/AccountTeamUserSelector.getUsersForRole';

export default class AccountTeamUserLookup extends LightningElement {

    @api recordId;
    @api mode; // 'MANAGER' or 'BOS'
    @api label = 'Select User';
    @api value;

    users = [];

    @wire(getUsersForRole, { accountId: '$recordId', roleType: '$mode' })
    wiredUsers({ data, error }) {
        if (data) {
            this.users = data.map(u => ({
                label: u.Name,
                value: u.Id
            }));
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: { value: this.value }
            })
        );
    }
}