({	
    init: function(component, event, helper) {
        var action = component.get("c.fetchContactNames");        
        action.setParams({});
        action.setCallback(this, function(response) {            
            var state = response.getState();           
            if (state === "SUCCESS") {               
               
               let res = response.getReturnValue();
                
                let managerEmailFastResponse = 'mailto:' + res[0].email + '?';                
                component.set('v.managerEmailFastAnswer',managerEmailFastResponse);
                
               component.set('v.managersNames',res);                            
               window.setTimeout(
               $A.getCallback( function() {
                    // Now set our preferred value
                    component.find("selectName").set("v.value", res[0].fullName);
                })); 
            }          
        })
        $A.enqueueAction(action);
                
        component.set('v.mycolumns',[
            {label: 'Support Contact',fieldName: 'supportContact',type: 'text',typeAttributes: { linkify:'supportContact'}},
            {label: 'Subject',fieldName: 'subjectUrl',type: 'url',sortable: true,typeAttributes:{ label:{fieldName: 'subject'}}},
            {label: 'Creation Date',fieldName: 'creationDate',type: 'date',sortable: true},
            {label: 'Status',fieldName: 'status',type: 'text',sortable: true},
            {label: 'Status Date',fieldName: 'statusDate',type: 'date',sortable: true},            
        ]);
        
        var action2 = component.get("c.fetchTableInfo");        
        action2.setParams({});
        action2.setCallback(this, function(response) {            
            var state = response.getState();           
            if (state === "SUCCESS") {               
               
               let res = response.getReturnValue();            	           	  
               component.set('v.mydata',res);  
               
            }          
        })
        $A.enqueueAction(action2);
        
      
    },
    createSupportCase: function(component,event,helper){
        helper.createCase(component,event,helper);
        
    },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        
        var uploadedFiles = event.getParam("files");
        
        //alert("Files uploaded : " + uploadedFiles.length);
		let filesIds = cmp.get("v.fileId");
        let fileNames = cmp.get("v.fileNames");
        // Get the file name
		//console.log(fileNames);        
        uploadedFiles.forEach(file =>
                             fileNames.push(file.name));
        uploadedFiles.forEach(file => filesIds.push(file.documentId));
        
        cmp.set('v.fileNames',fileNames);
                     
    },
    // Client-side controller called by the onsort event handler
    handleSort: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})