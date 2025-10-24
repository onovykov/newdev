import { LightningElement,wire,track,api   } from 'lwc';
import getEnquiriyDetail from '@salesforce/apex/EnquiryDatatableController.getEnquiriyDetail';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import uploadFileReclamation from '@salesforce/apex/FileUploaderTest.uploadFileReclamation';
import deleteRelatedFile from '@salesforce/apex/FileUploaderTest.deleteRelatedFile';
import getEnquiryFiles from '@salesforce/apex/EnquiryDatatableController.getEnquiryFiles';
import attachFilesToOpportunity from '@salesforce/apex/EnquiryDatatableController.attachFilesToOpportunity';

import viewFile from '@salesforce/apex/EnquiryDatatableController.viewFile';
import {NavigationMixin} from 'lightning/navigation';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi'; 


import site_th_delete from '@salesforce/label/c.Site_th_delete';
import scf_name from '@salesforce/label/c.scf_name';
import scf_owner from '@salesforce/label/c.scf_owner';
import scf_lastChange from '@salesforce/label/c.scf_lastChange';
import scf_size from '@salesforce/label/c.scf_size';
import card_details from '@salesforce/label/c.card_details';
import card_files from '@salesforce/label/c.card_files';
import Upload_file from '@salesforce/label/c.Upload_file';


import confirm_claim_answer from '@salesforce/label/c.confirm_claim_answer';
import delete_claim_answer from '@salesforce/label/c.delete_claim_answer';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import delete_item_answer from '@salesforce/label/c.delete_item_answer';
import contact_sys_admin from '@salesforce/label/c.contact_sys_admin';

import Enquiry from '@salesforce/label/c.Enquiry';
import Site_orderDetail_TypeOfProducts from '@salesforce/label/c.Site_orderDetail_TypeOfProducts';
import Site_orderDetail_Country from '@salesforce/label/c.Site_orderDetail_Country';
import Site_th_Quantity from '@salesforce/label/c.Site_th_Quantity';
import Site_th_MeasurementUnit from '@salesforce/label/c.Site_th_MeasurementUnit';
import Total_quantity_in_tons from '@salesforce/label/c.Total_quantity_in_tons';
import Support_description from '@salesforce/label/c.Support_description';
import Enquiry_number from '@salesforce/label/c.Enquiry_number';
import Manager from '@salesforce/label/c.Manager';
import Status from '@salesforce/label/c.Status';
import Are_you_sure_to_delete_this_file from '@salesforce/label/c.Are_you_sure_to_delete_this_file';
import File_deleted_successfully from '@salesforce/label/c.File_deleted_successfully';
import Sorry_you_cannot_edit_closed_enquiry from '@salesforce/label/c.Sorry_you_cannot_edit_closed_enquiry';
import Files_uploaded_successfully from '@salesforce/label/c.Files_uploaded_successfully';
import Enquiry_deleted_successfully from '@salesforce/label/c.Enquiry_deleted_successfully';
import Sorry_you_can_not_delete_confirmed_enquiry from '@salesforce/label/c.Sorry_you_can_not_delete_confirmed_enquiry';
import Enquiry_already_confirmed from '@salesforce/label/c.Enquiry_already_confirmed';
import Are_you_sure_you_want_to_delete_this_request from '@salesforce/label/c.Are_you_sure_you_want_to_delete_this_request';
import Are_you_sure_you_want_to_confirm_this_enquiry from '@salesforce/label/c.Are_you_sure_you_want_to_confirm_this_enquiry';
import Site_th_Edit from '@salesforce/label/c.Site_th_Edit';
import Site_th_delete from '@salesforce/label/c.Site_th_delete';
import Confirm from '@salesforce/label/c.Confirm';


import Success from '@salesforce/label/c.Success';
import Changes_saved from '@salesforce/label/c.Changes_saved';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
// import Delete from '@salesforce/label/c.Delete';

import MeasurementUnit from '@salesforce/schema/CustomerEnquiry__c.MeasurementUnit__c';

import SVG_PIPES from '@salesforce/resourceUrl/pipeIcons';
export default class SiteEnquiryDetail extends NavigationMixin(LightningElement) {

	@api getSelectedEnquiry;
	@api objectInfo;

	@track enquiryItemsList;
	@track enquiry;
	@track enqResult
	@track noRefund;
	UA = IMAGES + '/ukraine-twitter.png';

	@track mistmatchType = [];
	@track mistmatchSubType;
	@track mapDependetValue;
	@track firstDependentValueArr = [];

	@track picklistData;
	@track enquiryFiles;
	@track wireResult;

	cdl;
	@track modalEnquiry = false;
	@track spinner = false;
	@track idItemToDelete;
	@track idFileToDelete;

	@track deleteFileBoolean = false;
	@track deleteEnquiryBoolean = false;
    @track confirmEnquiryBoolean = false;
	wiresLoaded = false;

	@track modalText;
	@track uploadedFiles = [];
	@track picklist = [];
    @track showMeasUnit;
	selectedMeasUnit;

	labels = {
		Upload_file,

		confirm_claim_answer,
		delete_claim_answer,
		Yes,
		No,
		Sorry_you_cannot_edit_closed_enquiry,
		delete_item_answer,
		contact_sys_admin,
		Enquiry,
		Enquiry_number,
		Site_orderDetail_TypeOfProducts,
		Site_orderDetail_Country,
		Site_th_Quantity,
		Site_th_MeasurementUnit,
		Total_quantity_in_tons,
		Support_description,
		Manager,
		card_details,
		card_files,
		scf_name,
		scf_owner,
		scf_lastChange,
		scf_size,
		Status,
		site_th_delete,
		Are_you_sure_to_delete_this_file,
		File_deleted_successfully,
		Files_uploaded_successfully,
		Success,
		Changes_saved,
        Enquiry_deleted_successfully,
        Sorry_you_can_not_delete_confirmed_enquiry,
        Enquiry_already_confirmed,
        Are_you_sure_you_want_to_delete_this_request,
        Are_you_sure_you_want_to_confirm_this_enquiry,
        Save,
        Cancel,
		Site_th_Edit,
		Site_th_delete,
		Confirm
        // Delete

	}
	attach = `${SVG_PIPES}#attach`;

	@track accData = {};
    @track dropdownOpen = false;
    @track optionsToDisplay;
    @track accData = {};
    @track options = [
        { id: 'tab-defaultItem-2', label:  this.labels.card_details, order: 2 },
        { id: 'tab-defaultItem-3', label:  this.labels.card_files, order: 3 },

    ];
    @track selectedOption = this.options[0].label;

	@wire(getPicklistValues, {recordTypeId: '$objectInfo.data.defaultRecordTypeId',fieldApiName: MeasurementUnit
	})
	wiredPicklistValues(result) {
    // console.log('enquiryObjectInfo ' , this.enquiryObjectInfo)
    // console.log('getSelectedEnquiry ' , this.getSelectedEnquiry)
		this.wireResult = result;
		const {error, data} = result;
		if (data) {
			this.picklistData = data;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getEnquiriyDetail, {enqId: '$getSelectedEnquiry'})
	handleEnqResult(result) {
		this.enqResult = result;
		const {error, data} = result;

		if (data && this.picklistData) {
			let dataCopy = {...data};
			if(data.Description__c == undefined){
				dataCopy.Description__c = '';
			}
			
			if (data.OpportunityId__r) {
				if (data.OpportunityId__r.StageName == 'Qualification') {
					dataCopy.Status__c = 'Sent';
				}
				if (data.OpportunityId__r.StageName == 'Preparation' || data.OpportunityId__r.StageName == 'Analysis' ||
					data.OpportunityId__r.StageName == 'Proposal' || data.OpportunityId__r.StageName == 'Negotiation') {
					dataCopy.Status__c = 'Processing';
				}
				if (data.OpportunityId__r.StageName == 'Cancelled') {
					dataCopy.Status__c = 'Cancelled';
				}
				if (data.OpportunityId__r.StageName == 'Closed Won' || data.OpportunityId__r.StageName == 'Closed Lost') {
					dataCopy.Status__c = 'Closed';
				}
			} else {
				dataCopy.Status__c = 'Draft';
			}
			this.enquiry = dataCopy;
			
			let values = [];
			Object.values(this.picklistData.values).forEach(element => {
				let detail = {};
				detail.label = element.label;
				detail.value = element.value;
				if (this.enquiry) {
					if (this.enquiry.MeasurementUnit__c == element.label) {
						detail.userValue = true;
					} else {
						detail.userValue = false
					}
				}
				values.push(detail);
				//console.log(detail)
			});
			this.picklist = values;

		
			if(this.enquiry){
				this.showMeasUnit = true;
				this.wiresLoaded = true;
				// console.log('2', JSON.parse(JSON.stringify(this.enquiry)))
			}
		}
	}




	connectedCallback() {
		this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
		getEnquiryFiles({
			enqId: this.getSelectedEnquiry
		}).then(result => {

			if (result) {
				// console.log(result);
				let dataCopy = result.map(item => {
					return Object.assign({}, item);
				})
				dataCopy.forEach(element => {
					element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
				});
				this.enquiryFiles = dataCopy;
			}

		});
	}
	renderedCallback(){
        // let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        // if(this.refs.dropdownList?.style){
        //     this.refs.dropdownList.style.width = styleDropdownBtn.width;
        // }
    }
	toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }
	handleOptionClick(event) {
		
        const selectedOptionId = event.target.dataset.id;
        console.log('selectedOptionId ',selectedOptionId)
        this.switchTabName(selectedOptionId)    
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        if (selectedOption) {   
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);
            console.log()
        }
        this.dropdownOpen = false;
    }
	toggleSubtabs(event) {
		// console.log(event.target.id);
		this.switchTabName(event.target.dataset.id)
	}

	switchTabName(idAtrribute) {
		// console.log('in function', idAtrribute)
		this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data) {
			if (data.querySelectorAll('a')[0].dataset.id == idAtrribute) {
				data.classList.add("slds-is-active")
			} else {
				data.classList.remove("slds-is-active");
			}
		})

		let idAttributeContent = idAtrribute
		// console.log(idAttributeContent);
		this.template.querySelectorAll('.slds-tabs_default__content').forEach(function(data) {
			// console.log(data.id) ;

			let currentId = data.dataset.id
			// console.log(currentId == idAttributeContent) ;
			if (idAttributeContent == currentId) {
				data.classList.add("slds-show");
				data.classList.remove("slds-hide");
			} else {
				try {
					data.classList.remove("slds-show");
					data.classList.add("slds-hide");
				} catch (error) {
					console.log(error)
				}

			}
		})
	}

	get ownerFullName() {
		Z ``
		return this.reclamation.Owner.FirstName + ' ' + this.reclamation.Owner.LastName;
	}

	formatBytes(bytes, decimals = 2) {
		if (!+bytes) return '0 Bytes'
		const k = 1024
		const dm = decimals < 0 ? 0 : decimals
		const sizes = ['Bytes', 'KB', 'MB', 'GB']
		const i = Math.floor(Math.log(bytes) / Math.log(k))
		return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`
	}

	openFile(event) {

		// console.log(event.target.dataset.id);
		this.cdl = event.target.dataset.id;
		viewFile({
			cdl: this.cdl
		}).then(result => {
			// console.log('file url  result ', result);

			this[NavigationMixin.Navigate]({
				type: 'standard__webPage',
				attributes: {
					url: result
				}
			});

		})
	}

	deleteFile() {
		this.spinner = true;
		deleteRelatedFile({
			docId: this.idFileToDelete
		}).then(response => {

			//console.log(response);
			if (response == 'Success') {
				this.template.querySelector('c-custom-toast-lwc').showToast('success', this.labels.File_deleted_successfully);

			} else {
				this.template.querySelector('c-custom-toast-lwc').showToast('error', this.labels.contact_sys_admin);

			}

			getEnquiryFiles({
				enqId: this.getSelectedEnquiry
			}).then(result => {

				if (result) {
					// console.log(result);
					let dataCopy = result.map(item => {
						return Object.assign({}, item);
					})
					dataCopy.forEach(element => {
						element.fileSize = this.formatBytes(element.ContentDocument.ContentSize, 2);
					});
					this.enquiryFiles = dataCopy;
					this.closeModal();
					this.cleanModalBoolean();
				}

			});
		}).catch(err => {
			console.log(err)
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
		}).finally(() => {

		})
		this.spinner = false;
	}


	//file loader for reclamation
	handleFileSelect(event) {

		// console.log(event.target.files)
		if (this.enquiry.Status__c == 'Draft') {
			this.spinner = true;
			if (event.target.files.length > 0) {

				try {
					let self = this;
					self.spinner = true;

					var base64changed = this.fileListToBase64(event.target.files);
					self.spinner = true;
					base64changed.then(function(result) {
						for (let i = 0; i < result.length; i++) {
							self.spinner = true;
							let file = {};
							file.name = result[i].split(',')[0];
							file.base64 = result[i].split(',')[1];
							self.uploadedFiles.push(file);
						}
						// console.log(self.uploadedFiles);
						uploadFileReclamation({
							files: JSON.stringify(self.uploadedFiles),
							recordId: self.getSelectedEnquiry
						}).then(result => {
							self.spinner = false;

							// console.log(result);
							self.template.querySelector('c-custom-toast-lwc').showToast('success', self.labels.Files_uploaded_successfully);
							getEnquiryFiles({
								enqId: self.getSelectedEnquiry
							}).then(result => {

								if (result) {
									// console.log(result);
									let dataCopy = result.map(item => {
										return Object.assign({}, item);
									})
									dataCopy.forEach(element => {
										element.fileSize = self.formatBytes(element.ContentDocument.ContentSize, 2);
									});
									self.enquiryFiles = dataCopy;
								}
								self.uploadedFiles = [];
							});
						}).catch(err => {
							console.log(err)
							self.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
						}).finally(() => {

						})
					});
				} catch (error) {
					console.log(error)
				}
				// console.log( this.uploadedFiles);  
				this.spinner = false;
			}

		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Sorry_you_cannot_edit_closed_enquiry);
		}

	}

	async fileListToBase64(fileList) {
		try {
			function getBase64(file) {
				const reader = new FileReader()
				return new Promise(resolve => {
					reader.onload = ev => {
						resolve(file.name + ',' + ev.target.result.split(',')[1])
						// console.log(file.name)
					}
					reader.readAsDataURL(file)
				})
			}
			const promises = []
			for (let i = 0; i < fileList.length; i++) {
				promises.push(getBase64(fileList[i]))
			}
			return await Promise.all(promises)
		} catch (error) {
			console.log(error)
		}
	}


	editEnquiry() {
		if (this.enquiry.Status__c == 'Draft') {
			let allNotEditableInputs = this.template.querySelectorAll('.non-editable');
			allNotEditableInputs.forEach(item => {
				item.classList.add('opacity-low')
			})


			let allInputs = this.template.querySelectorAll('.input-field');

			allInputs.forEach(item => {
				item.disabled = false;
				item.classList.add('input-field-edit')
			})

			this.template.querySelectorAll('.save')[0].classList.remove('display-none')
			this.template.querySelectorAll('.cancel')[0].classList.remove('display-none')
		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Sorry_you_cannot_edit_closed_enquiry);
		}
	}

	handleMeasUnit(event) {
		this.selectedMeasUnit = event.currentTarget.value
		//console.log(this.selectedMeasUnit);
	}


	saveChanges() {
		this.spinner = true
		let enqData = {};
		enqData.totalQuantityInput = this.template.querySelectorAll('.total-quantity')[0].value;
		enqData.descriptionInput = this.template.querySelectorAll('.description')[0].value;
		enqData.TotalQuantityTonsInput = this.template.querySelectorAll('.total-quantity-tons')[0].value;
		enqData.MeasurementUnitInput = this.selectedMeasUnit;
		const fields = {};
		fields["Id"] = this.getSelectedEnquiry;
		fields["TotalQuantity__c"] = enqData.totalQuantityInput;
		fields["Description__c"] = enqData.descriptionInput;
		fields["TotalQuantity_t__c"] = enqData.TotalQuantityTonsInput;
		fields["MeasurementUnit__c"] = enqData.MeasurementUnitInput;

		const recordInput = {
			fields
		};

		//console.log(recordInput);

		updateRecord(recordInput).then(result => {
			console.log('RESULT', result);		
			
			refreshApex(this.enqResult);
			this.showToastChangesSaved();
			this.disableEdit();
			this.spinner = false;

			this.dispatchEvent(new CustomEvent('childrefresh'))
			
		})
		.catch(err => {
			console.log(err);
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);

		})

		//setTimeout(window.location.reload(), 3000);

	}
	cancelChanges() {
		this.template.querySelectorAll('.total-quantity')[0].value = this.enquiry.TotalQuantity__c;
		this.template.querySelectorAll('.description')[0].value = this.enquiry.Description__c;
		this.template.querySelectorAll('.total-quantity-tons')[0].value = this.enquiry.TotalQuantity_t__c;
		this.template.querySelectorAll('.total-quantity-tons')[0].value = this.enquiry.TotalQuantity_t__c;
		this.template.querySelectorAll('.measUnit')[0].selected = this.enquiry.MeasurementUnit__c;


		this.disableEdit();
	}
	disableEdit() {
		let allNotEditableInputs = this.template.querySelectorAll('.non-editable');
		allNotEditableInputs.forEach(item => {
			item.classList.remove('opacity-low')
		})
		let allInputs = this.template.querySelectorAll('.input-field');
		allInputs.forEach(item => {
			item.disabled = true;
			item.classList.remove('input-field-edit')
		})
		this.template.querySelectorAll('.save')[0].classList.add('display-none')
		this.template.querySelectorAll('.cancel')[0].classList.add('display-none')
	}

	showToastChangesSaved() {
		const event = new ShowToastEvent({
			title: this.labels.Success,
			message: this.labels.Changes_saved,
			variant: 'success',
			mode: 'sticky'
		});
		this.dispatchEvent(event);
	}

    // modals -----------------------------------------------------------------------------------------------------------------------------
    openDeleteFileModal(event) {
		// console.log(this.enquiry.Status__c)
		if (this.enquiry.Status__c == 'Draft') {
			try {
				this.modalText = this.labels.Are_you_sure_to_delete_this_file;
				this.deleteFileBoolean = true;
				this.modalEnquiry = true;
				this.idFileToDelete = event.target.dataset.id;
			} catch (e) {
				console.log(e);
			}
		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Sorry_you_cannot_edit_closed_enquiry);
		}
		// console.log(event.target.dataset.id);
	}

    openDeleteEnquiryModal(event) {
		if (this.enquiry.Status__c == 'Draft') {
			try {
				this.modalText = this.labels.Are_you_sure_you_want_to_delete_this_request;
                this.deleteEnquiryBoolean = true;
				this.modalEnquiry = true;
			} catch (e) {
				console.log(e);
			}
		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Sorry_you_can_not_delete_confirmed_enquiry);
		}
		// console.log(event.target.dataset.id);
	}

    openConfirmEnquiryModal(event) {
		// console.log(this.enquiry.Status__c)
		if (this.enquiry.Status__c == 'Draft') {
			try {
				this.modalText = this.labels.Are_you_sure_you_want_to_confirm_this_enquiry;
                this.confirmEnquiryBoolean = true;
				this.modalEnquiry = true;
			} catch (e) {
				console.log(e);
			}
		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Enquiry_already_confirmed);
		}
		// console.log(event.target.dataset.id);
	}

	confirmEnquiryModal() {
		if (this.deleteFileBoolean) {
			this.deleteFile();
		}
        if (this.deleteEnquiryBoolean) {
			this.deleteEnquiry();
		}
        if (this.confirmEnquiryBoolean) {
			this.confirmEnquiry();
		}
	}
	deleteEnquiry() {
		
			deleteRecord(this.getSelectedEnquiry)
				.then(() => {
					this.template.querySelector('c-custom-toast-lwc').showToast('success', this.labels.Enquiry_deleted_successfully);
                    this.closeModal();
					this.cleanModalBoolean();
					window.location.reload();

				})
				.catch(error => {
					console.error(error);
					this.template.querySelector('c-custom-toast-lwc').showToast('error', 'Error');
				});
		
			
	}

    confirmEnquiry() {
		if (this.enquiry.Status__c == 'Draft') {
			this.spinner = true
			let fields = {};
			fields["Id"] = this.getSelectedEnquiry;
			fields["Status__c"] = "Sent";
			let recordInput = {fields};
			//console.log(recordInput);
			updateRecord(recordInput).then(result => {
				console.log('CONFIRM RESULT', result);
				
				refreshApex(this.enqResult);
				this.showToastChangesSaved();
				// refreshApex(this.enqResult)
				this.disableEdit();
				attachFilesToOpportunity({enqId: this.getSelectedEnquiry})
				this.spinner = false;
                this.closeModal();
				this.cleanModalBoolean();
					// refreshApex(this.enquiryObjectInfo);
					this.dispatchEvent(new CustomEvent('childrefresh'))
				

			}).catch(err => {
				console.log(err)
			})
		} else {
			this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.Enquiry_already_confirmed);
		}
    }


    
	cleanModalBoolean() {
		this.deleteEnquiryBoolean = false;
		this.deleteFileBoolean = false;
        this.confirmEnquiryBoolean = false;
	}

    closeModal() {
		this.modalEnquiry = false;
	}



}