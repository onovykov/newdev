({
	helperMethod : function() {
		
	},
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.mydata");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.mydata", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    createCase: function(component,event,helper){
        let info = {};        
        let idManager= '';
        let fullname = component.find('selectName').get('v.value');
        let arrManagerInfo = component.get('v.managersNames');
            
            for(let i in arrManagerInfo){
            	let obj = arrManagerInfo[i];
                      if(obj.fullName == fullname){
            
            idManager = obj.id;
        }
            }
        let name = component.find('selectName').get('v.value').split(' ');
        let subject = component.find('subject').get('v.value');
        let description = component.find('description').get('v.value');
        let filesIds = component.get("v.fileId");
        let arrFilesIds = [];
        for(let k in filesIds){
            arrFilesIds.push(filesIds[k]);
        }
        
 		info.idManager = idManager;
        info.firstName = name[0];
        info.lastName = name[1];
        info.subject = subject;
        info.description = description;
        info.files = arrFilesIds;
                       
        var action = component.get("c.createCase");        
        action.setParams({'data':JSON.stringify(info)});
        action.setCallback(this, function(response) {
            var state = response.getState();           
            if (state === "SUCCESS") {               
              
               var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": 'SUCCESS',
                        "message": 'Ticket was created',
                        "type":'SUCCESS'
                    });
            toastEvent.fire();
                let res = response.getReturnValue();
                component.find("navService").navigate({
                    "type": "standard__recordPage",
                    "attributes": {
                        "recordId": res,
                        "objectApiName": "CustomerEnquiry__c",
                        "actionName": "view"
                    }
                    });
            }      
        });
        $A.enqueueAction(action);
    }
})