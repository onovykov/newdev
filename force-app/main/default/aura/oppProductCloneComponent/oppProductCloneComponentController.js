({
	doInit : function(cmp, event, helper) {
        var action = cmp.get("c.getSaveRecord");
        action.setParams({"oppId": "00k26000005x8lCAAQ"});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				var editRecordEvent = $A.get("e.force:editRecord");
				console.log(response.getReturnValue());
			    editRecordEvent.setParams({
			         "recordId": response.getReturnValue()
			   	});
			    editRecordEvent.fire();
            }
            else{
            	var errors = response.getError();                
                console.log(errors);                
            }            
        });
        $A.enqueueAction(action);
    }
})