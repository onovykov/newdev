({
	handleClose : function() {
        var homeEvent = $A.get("e.force:navigateToObjectHome");
        // homeEvent.setParams({
        //     "scope": "CustomerEnquiry__c"
        // });
        // homeEvent.fire();
        window.location.reload();  
	},
    attachFiles: function(component,enquiryId){
        let filesIds = component.get("v.fileId");
        let arrFilesIds = [];
        for(let k in filesIds){
            arrFilesIds.push(filesIds[k]);
        }
        let fileIdsString = JSON.stringify(arrFilesIds);
        console.log(fileIdsString);
        console.log(enquiryId);
         var attachFilesToRecord = component.get("c.attachFilesToOpportunity");
        attachFilesToRecord.setParams({
            "filesId": fileIdsString,
            "parentId": enquiryId
        });      
        attachFilesToRecord.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //var res = response.getReturnValue();
                console.log("SUCCESS");               
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(attachFilesToRecord);
    }, 

    getRecordTypeIdByDevName : function(recordTypes, recordTypeDeveloperName) {
        if (recordTypes != undefined && recordTypes.length > 0) {
            let id;
            recordTypes.forEach(element => {
                if (recordTypeDeveloperName == element.developerName) {
                    console.log("element.value: " + element.value);
                    id = element.value;
                }
            });

            return id; 
        }
    }
})