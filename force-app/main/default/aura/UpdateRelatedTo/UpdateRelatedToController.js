({
    doInit : function(component, event, helper) {
		var action = component.get("c.getRelationToId");
        action.setParams({ 
            emailMessageId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var relatedToId = response.getReturnValue();
				component.set("v.relatedToId", relatedToId);
                
                component.set("v.selectedType", "");
                if (relatedToId) {
                    var prefix = relatedToId.substring(0, 3);
                    if (prefix === '001') component.set("v.selectedType", "Account");
                    if (prefix === '006') component.set("v.selectedType", "Opportunity");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    changeType : function(component, event, helper) {
		component.set("v.relatedToId", "");
    },
    
	saveClick : function(component, event, helper) {
        var action = component.get("c.updateRelatedTo");
        action.setParams({ 
            emailMessageId : component.get("v.recordId"),
            newRelatedToId : component.get("v.relatedToId")
        });
        
        helper.toggleSpinner(component);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.toggleSpinner(component);
				var emailMessageId = response.getReturnValue();

                if (component.get("v.recordId") != emailMessageId) {
                    // navigate to newly created email
                    $A.get("e.force:navigateToSObject")
                    .setParams({
                        "recordId": emailMessageId,
                        "slideDevName": "detail"
                    })
                    .fire();     
                } else {
                    // Close the action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction").fire();
                }
            }
            else if (state === "ERROR") {
                helper.toggleSpinner(component);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.displayToast('Error message', errors[0].message, 'error');
                    }
                } else {
                    helper.displayToast("Unknown error", '', 'error');
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    
    cancelClick : function(component, event, helper) {
		// Close the action panel
        var dismissActionPanel = $A.get("e.force:closeQuickAction").fire();
	},
})