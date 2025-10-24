import { LightningElement, wire, track } from 'lwc';
import getApprovalRequests from '@salesforce/apex/ApprovalRequestController.getApprovalRequests';
import approveRequests from '@salesforce/apex/ApprovalRequestController.approveRequests';
import rejectRequests from '@salesforce/apex/ApprovalRequestController.rejectRequests';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalManager extends LightningElement {
    @track approvalRequestsData;
    @track approvalRequests = [];
    @track selectedRequests = [];
    @track isLoading = false;

    columns = [
        // { label: 'Step ID', fieldName: 'stepId' },
        { 
            label: 'Opportunity Name', 
            fieldName: 'oppLink', 
            type: 'url',
            typeAttributes: { label: { fieldName: 'oppName' }, target: '_blank' }
        },
        { 
            label: 'Product Name', 
            fieldName: 'oppProductLink', 
            type: 'url',
            typeAttributes: { label: { fieldName: 'oppProductName' }, target: '_blank' }
        },
        { label: 'Expiration Date', fieldName: 'expirationDate' },
        { label: 'KDO', fieldName: 'targetObjectKDO' },
        { 
            label: 'Comment', 
            fieldName: 'comment', 
            type: 'text',
            editable: true
        }
    ];

    @wire(getApprovalRequests)
    wiredRequests(response) {
        this.approvalRequestsData = response; // Store the response
        const { data, error } = response;
        if (data) {
            console.log('data', data);
            this.approvalRequests = data;
        } else if (error) {
            // Handle error
            console.error('Error fetching approval requests:', error);
        }
    }
    
    handleSave(event) {
        const draftValues = event.detail.draftValues;
    
        // Create a new array to hold the updated records for approvalRequests
        const updatedApprovalRequests = [...this.approvalRequests];
        let updatedSelectedRequests = [...this.selectedRequests];
    
        // Process each draftValue item
        draftValues.forEach(draftValue => {
            // Find the index of the current item in approvalRequests
            const index = updatedApprovalRequests.findIndex(item => item.stepId === draftValue.stepId);
            if (index !== -1) {
                // Create a copy of the object and update it
                updatedApprovalRequests[index] = {...updatedApprovalRequests[index], ...draftValue};
    
                // Update selectedRequests if the changed record is in selectedRequests
                const selectedIndex = updatedSelectedRequests.findIndex(item => item.stepId === draftValue.stepId);
                if (selectedIndex !== -1) {
                    updatedSelectedRequests[selectedIndex] = {...updatedSelectedRequests[selectedIndex], ...draftValue};
                }
            }
        });
    
        // Update the state arrays
        this.approvalRequests = updatedApprovalRequests;
        this.selectedRequests = updatedSelectedRequests;
    
        // Clear draft values after processing
        this.template.querySelector('lightning-datatable').draftValues = [];
    
        // Optionally, update the records in Salesforce or another database
        // ... your code to update Salesforce records ...
    }
    
    
    
    
    handleRowSelection(event) {
        this.selectedRequests = event.detail.selectedRows;
        console.log('selectedRequests   ', this.selectedRequests);
    }

    approveSelected() {
        this.isLoading = true;
        console.log('approveSelected', this.selectedRequests);
    
        approveRequests({ workItems: this.selectedRequests })
            .then(() => {
                this.refreshData('Approve');
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    rejectSelected() {
        this.isLoading = true;
        console.log('rejectSelected', this.selectedRequests);
    
        rejectRequests({ workItems: this.selectedRequests })
            .then(() => {
                this.refreshData('Reject');
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    

    refreshData(type) {
        // Show spinner while refreshing
        this.isLoading = true;
        
        refreshApex(this.approvalRequestsData)
            .finally(() => {
                // Hide spinner after refresh
                if(type === 'Approve'){
                    this.showToast('Success', 'Selected requests APPROVED successfully', 'success');
                }else if (type === 'Reject'){
                    this.showToast('Success', 'Selected requests REJECTED successfully', 'success');
                }
                this.isLoading = false;
            });
    }
    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }),
    );
}
    get hasApprovalRequests() {
        return this.approvalRequests && this.approvalRequests.length > 0;
    }

}