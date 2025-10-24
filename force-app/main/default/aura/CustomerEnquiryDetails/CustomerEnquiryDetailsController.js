({	
    init : function(component, event, helper) {          
        
        function showToast(title,message,type){
        	var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": title,
                        "message": message,
                        "type":type
                    });
            toastEvent.fire()};
        
        component.set('v.mycolumns',[
            {label: 'Product',fieldName: 'product',type: 'text', sortable: true},
            {label: 'Product Name',fieldName: 'productName',type: 'text',sortable: true},
            {label: 'Measurement Unit',fieldName: 'measurementUnit',type: 'text',sortable: true},
            {label: 'Quantity',fieldName: 'quantity',type: 'number',sortable: true},
            {label: 'Quantity (t)',fieldName: 'quantityT',type: 'number',sortable: true},
            {label: 'ITE Number',fieldName: 'iteNumber',type: 'text',sortable: true}
        ]);
        
        var action = component.get("c.takeInitialInfo");        
        action.setParams({'recordId':component.get('v.recordId')});
        action.setCallback(this, function(response) {
            
            var state = response.getState();           
            if (state === "SUCCESS") {               
                let res = response.getReturnValue(); 
                //console.log(res);
                if(res.length){
                    component.set('v.showTable',true);
                }
                component.set('v.mydata',res);             
            }   else {
                 showToast("Something went wrong!","The record has not been fetched","error");             
             }       
        })
        $A.enqueueAction(action); 
                
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