({
	helperMethod : function() {
		
	},
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField) {
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                
                
                var listOfkeys = []; // for store all map keys (controller picklist values)
                // play a for loop on Return map 
                // and fill the all map key on listOfkeys variable.
                for (var singlekey in StoreResponse) {
                    listOfkeys.push(singlekey);
                }
                
                StoreResponse['--- None ---'] = ['none'];
               
                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set("v.depnedentFieldMap",StoreResponse);
                
                // create a empty array for store map keys(@@--->which is controller picklist values) 
                
                var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                
                
                
                //set the controller field value for lightning:select
                if (listOfkeys != undefined && listOfkeys.length > 0) {
                    ControllerField.push('--- None ---');
                }
                
                for (var i = 0; i < listOfkeys.length; i++) {
                    ControllerField.push(listOfkeys[i]);
                }  
                // set the ControllerField variable values to country(controller picklist field)
                component.set("v.listControllingValues", ControllerField);
                
            }else{
                alert('Something went wrong..');
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchDepValues: function(component, ListOfDependentFields,name) {
        // create a empty array var for store dependent picklist values for controller field        
        var citySelElem = component.find(name);      
        var dependentFields = [];
       // dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
       // component.find(name).set("v.items",dependentFields);
        component.set("v.listDependingValues", dependentFields);
        //component.find("1dep").set("v.value",  dependentFields);
    },
    getOrderItem: function(component, event, helper,orderId){
        var action = component.get("c.getOrderData");              
        action.setParams({'orderId': orderId});
        action.setCallback(this, function(response) {
            console.log(response.getState());
            console.log(response.getError());
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = JSON.parse(response.getReturnValue());                
                console.log('response val');
                console.log(StoreResponse);
                 //debugger
				var arrayMapKeys = component.get("v.mapOrderItems");
                if(arrayMapKeys == null || Object.keys(arrayMapKeys).length === 0){
                    arrayMapKeys = [];
                }
        		                                           
                for(var key in StoreResponse){
                    let duplicateFound = false;                    
                    for(var kk in arrayMapKeys){
                      
                        if(arrayMapKeys[kk].key.toString() == key.toString()){
                            alert('duplicate found!');
                            duplicateFounr = true
                        }
                	}
                    if(!duplicateFound){
                        StoreResponse[key].forEach(data=>data.selected = false);
                        arrayMapKeys.push({key: key, value: StoreResponse[key]});
                    
                    }
										                    
                }
                
                component.set("v.mapOrderItems",arrayMapKeys);
                var qwer = component.get("v.mapOrderItems");                
                //qwer[orderId.toString()] =StoreResponse;
        		                          
            }});
        $A.enqueueAction(action);      

    },
    createReclamationAndReclamationDetails: function (component, event, helper){
        function showToast(title,message,type){
        	var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": title,
                        "message": message,
                        "type":type
                    });
            toastEvent.fire()};
        var contractDate = component.get('v.dateContract') != ''? component.get('v.dateContract') : 'none' ;       
        var validated = true;
        var maps = component.get("v.mapOrderItems");
        var selectedItems = [];
       
        for(var key in maps){
           let oneColl = maps[key];
            
            oneColl.value.forEach(data=> {
                if(data.selected){
                
                let obj = Object.assign({},data);
                
                //console.log(data);
                var claimPrice = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimSum"]').value;
                //console.log(claimPrice);
                var claimQuaintity = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimQ"]').value;
                //console.log(claimQuaintity);
                var mismatchType = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_state"]').value;
               // console.log(mismatchType);
                var mismatchSubType = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_city"]').value;
               // console.log(mismatchSubType);
                var mismatchSubDate = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_date"]').value;
               // console.log(mismatchSubDate);    
                var commentItem = component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_comment"]').value;
               // console.log(mismatchSubDate);             
                obj.claimPrice = claimPrice;
                obj.claimQuaintity = claimQuaintity;
                obj.mismatchType = mismatchType;
                obj.mismatchSubType = mismatchSubType;
                obj.mismatchSubDate = mismatchSubDate;
            	obj.iteNumber = data['ITENumber'];   
            	obj.idErp = data['IdinERP']; 
            	obj.commentItem = commentItem;
            
            if(claimPrice==''){
                component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimSum"]').style.backgroundColor = "#ffcccb";
                validated = false;
            } else {
                component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimSum"]').style.backgroundColor = "white";
            } ;
            if(claimQuaintity==''){
                 component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimQ"]').style.backgroundColor = "#ffcccb";
                validated = false;
            } else{
                component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_claimQ"]').style.backgroundColor = "white";
            } ;
            if(mismatchType==''){
                 component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_state"]').style.backgroundColor = "#ffcccb";
                validated = false;
            } else{
				component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_state"]').style.backgroundColor = "white";                
            } ;
            if(mismatchSubType==''){
                 component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_city"]').style.backgroundColor = "#ffcccb";
                validated = false;
            } else {
                component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_city"]').style.backgroundColor = "white"; 
            } ;
            if(mismatchSubDate==''){
                 component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_date"]').style.backgroundColor = "#ffcccb";
                validated = false;
            } else{
                 component.find('parent-aura-div-id').getElement().querySelector('[id="'+data.Id + '_date"]').style.backgroundColor = "white";
            }            	               
            	selectedItems.push(obj);            	                                       
            }
            });
}
 if(selectedItems.length != 0){
    if(validated){
        
        let filesIds = component.get("v.fileId");
        let arrFilesIds = [];
        for(let k in filesIds){
            arrFilesIds.push(filesIds[k]);
        }
    
    	var reclDetail = {};
            reclDetail.orderNumber = component.get("v.orderNumber");
            reclDetail.reclSum = component.get("v.reclSum");
            reclDetail.reclCurrency = component.get('v.currency');
            reclDetail.contractDate = contractDate;
        	reclDetail.marketSegment = component.get('v.segment');
        	reclDetail.noRefund = component.get('v.noReturning');
        	reclDetail.files = arrFilesIds;

    
            var action = component.get("c.createReclamation");
        	action.setParams({
            'reclamation' : JSON.stringify(reclDetail),   
            'data' : JSON.stringify(selectedItems),            
        });
         action.setCallback(this, function(response) {
             if (response.getState() == "SUCCESS") {
                 showToast("Success!","The record has been created successfully.","success");
                 let res = response.getReturnValue();                
                 window.location.reload(); 
             } else {
                 showToast("Something went wrong!","The record has not been created","error");             
             }
         });
        $A.enqueueAction(action);
	}else {        
        showToast("Something went wrong!","All fields must be filled","error");      	    
}
} else{    
    showToast("Something went wrong!","Order item is not selected","error");    	
}
    }
})