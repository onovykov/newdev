({
    doInit: function(component, event, helper) {
        var customerUserId = $A.get("$SObjectType.CurrentUser.Id");
        
        var actionRecTypes = component.get("c.getCustomerEnquiryRecTypes");
        actionRecTypes.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var sortedRecordTypes = response.getReturnValue().sort(function(a,b){
                    if(a.developerName > b.developerName){
                        return 1;
                    } if(a.developerName < b.developerName){
                        return -1;
                    }
                });
                
                component.set("v.recordTypes",sortedRecordTypes);
                                
                var defaultRecType = response.getReturnValue().find(x => x !== undefined);
                //component.set("v.selectedRecordTypeId", defaultRecType.value);
                
            } else {
                console.log("Failed with state: " + state);
            }
        });

        var actionBusinessDivision = component.get("c.getBusinessDivision");
                actionBusinessDivision.setParams({
                    "customerUserId": customerUserId
                });
                
                actionBusinessDivision.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var businessDivisionValues = response.getReturnValue();
                        var businessDivision = businessDivisionValues.businessDivision;
                        var allDivisions = businessDivisionValues.allDivisions;
                        console.log("businessDivision: " + businessDivision);
                        console.log("allDivisions: " + allDivisions);
        
                        if(!allDivisions) {
                            if(businessDivision == 'Railway') {
                                component.set("v.selectedRecordTypeId", helper.getRecordTypeIdByDevName(component.get('v.recordTypes'), 'Wheels'));
                            } else {
                                component.set("v.selectedRecordTypeId", helper.getRecordTypeIdByDevName(component.get('v.recordTypes'), 'Tubes'));
                            }
                            component.set("v.isRecordEditFormVisible", true);
                        } else {
                            component.set("v.isRecordTypeSelectionVisible", true);
                        }
                        
                    } else {
                        console.log("Failed with state: " + state);
                    }
                });
        
        var actionPrepolulate = component.get("c.getContactMailingCountry");
        actionPrepolulate.setParams({
            "customerUserId": customerUserId
        });
        
        actionPrepolulate.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var prepopulatedValues = response.getReturnValue();
                //console.log(prepopulatedValues);
                var countryId = prepopulatedValues.mailingCountryId;
                var managerId = prepopulatedValues.managerId;
                var contactAccId = prepopulatedValues.contactAccId;
                component.set("v.contactMailingCountryId", countryId);
                component.set("v.managerId", managerId);
                component.set("v.contactAccId", contactAccId);
                
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(actionRecTypes);
        $A.enqueueAction(actionBusinessDivision);
        $A.enqueueAction(actionPrepolulate);
    },

    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        
        var uploadedFiles = event.getParam("files");
        let dataFiles = cmp.get('v.fileNames');
        //alert("Files uploaded : " + uploadedFiles.length);
		let filesIds = cmp.get("v.fileId");
        let fileNames = cmp.get("v.fileNames");
        // Get the file name
		
		uploadedFiles.forEach(file =>
                             dataFiles.push(file));
        
        //uploadedFiles.forEach(file =>
         //                    fileNames.push(file.name));
        uploadedFiles.forEach(file => filesIds.push(file.documentId));
        
        cmp.set('v.fileId',filesIds);
        
        cmp.set('v.fileNames',dataFiles);    
        console.log(uploadedFiles);
    }, 
    
    deleteFile: function(cmp, event) {
    	//var btnValue = event.getSource().get("v.value");
    	var btnValue = cmp.get("v.deletedFileId");
        
        let dataFiles = cmp.get('v.fileNames');
        
        let newDataFiles = [];
        let newDataFilesIds = [];
        dataFiles.forEach((file)=>{if(file.documentId != btnValue){
                                   newDataFiles.push(file);
                                  newDataFilesIds.push(file.documentId)}
        });
        
        cmp.set('v.fileNames',newDataFiles);
        
        cmp.set('v.fileId',newDataFilesIds);
        cmp.set("v.isModalOpen", false);
	},

    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        var btnValue = event.getSource().get("v.value");
        component.set("v.deletedFileId",btnValue);  
        component.set("v.isModalOpen", true);
     },
    
     closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
     },

     
    
    handleChange: function(component, event, helper) {
        component.set("v.selectedRecordTypeId", event.getParam("value"));
    },
    
    handleCancel: function(component, event, helper) {
        component.set("v.isRecordTypeSelectionVisible", false);
        helper.handleClose(component, event, helper);
    },
    
    handleNext: function(component, event, helper){
        component.set("v.isRecordEditFormVisible", true);
        component.set("v.isRecordTypeSelectionVisible", false);
    },
    
    handleSave: function(component, event, helper) {
        //component.set("v.isRecordTypeSelectionVisible", false);   
        //component.set("v.isRecordEditFormVisible", false);        
        //helper.handleClose(component, event, helper);\

        event.preventDefault();
        var fields = event.getParam('fields');
        console.log('fields ', fields);
        var isSaveAndSubmit = component.get('v.isSaveAndSubmit');

        if (isSaveAndSubmit) {
            fields['Status__c'] = 'Sent';
            component.set('v.isSaveAndSubmit', false);
            console.log('is save and submit after clear ', component.get('v.isSaveAndSubmit'));
        }

        component.find('recordEditForm').submit(fields);
    },
    
    handleEditFormCancel: function(component, event, helper) {
        component.set("v.isRecordTypeSelectionVisible", false);
        component.set("v.isRecordEditFormVisible", false);
        helper.handleClose(component, event, helper);
        
    },
    
    handleSaveAndNew: function(component, event, helper) {
    },

    handeSaveAndSubmit: function(component, event, helper) {
        console.log('save and submit clicked ');
        component.set('v.isSaveAndSubmit', true);
        console.log('is save and submit ', component.get('v.isSaveAndSubmit'));

        document.getElementById('submitButton').click();
        console.log('btn ', btn);

    },
    
    callSuccess: function(component, event, helper) {
		var params = event.getParams(); //get event params
        var recordId = params.response.id; //get record id  
        console.log(recordId);
        try{
            helper.attachFiles(component,recordId);
        }
        catch(err){
            console.log(err)
        }        
        window.location.reload();  
        // component.find("navService").navigate({
        // "type": "standard__recordPage",
        // "attributes": {
        //     "recordId": params.response.id,
        //     "objectApiName": "CustomerEnquiry__c",
        //     "actionName": "view"
        // }
    	// });
        //helper.handleClose(component, event, helper);
        
    },
    
    onTotalQtyChange: function(component, event, helper) {
        let measurementUnit = component.get("v.measurementUnit");
        //34 is API value for tons
        if(measurementUnit === '34'){
			let totalQty = component.get("v.totalQty");
			component.set("v.totalQty_t", totalQty);
        }
    },   
    
    
})