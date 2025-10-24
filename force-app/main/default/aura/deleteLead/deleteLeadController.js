({
	delete : function(component, event, helper) {
		var action = component.get("c.deleteLead");
        action.setParams({"leadId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
            	console.log('hhh');
				var homeEvent = $A.get("e.force:navigateToObjectHome");
			    homeEvent.setParams({
			        "scope": "Lead"
			    });
			    homeEvent.fire();
            }
            else{
            	console.log('hhhkk');
            	var errors = response.getError();                
                console.log(errors);                
            }            
        });
        $A.enqueueAction(action);
	},
	cancel : function(component, event, helper) {
		
		var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	      "recordId": component.get("v.recordId")
	    });
	    navEvt.fire();
	}

})