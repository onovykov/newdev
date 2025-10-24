({
	handleRecordClick: function(component, event, helper) {

        var focusIndex = event.currentTarget.dataset.index;


        var records = component.get('v.records');		
		
        
            component.set('v.rec', records[focusIndex]);
        
console.log(records[focusIndex]);
        var appEvent = $A.get("e.c:setRecord");
appEvent.setParams({ "label" : records[focusIndex].label });
appEvent.setParams({ "value" : records[focusIndex].value });
appEvent.setParams({ "sourceId" : component.get('v.sourceId') });
appEvent.fire();

    }
})