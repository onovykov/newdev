({
	myAction : function(component, event, helper) {
		
	},
    
    closeMethodInAuraController : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
    
})