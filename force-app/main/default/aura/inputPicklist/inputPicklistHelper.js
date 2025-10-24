({
	 getFieldPicklistValues : function(component, objName) {
		console.log("start " + objName);
        var action = component.get("c.getNames");
        action.setParams({
            "objectApiName": objName
        });
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === "SUCCESS") {
                if(response.getReturnValue()) {

                    var result = response.getReturnValue();
                    var opts = [];
                    var opts = [{value:"", label:"--None--"}];
                    for (var key in result) {
                        var option = {value:key, label:result[key]};
                        opts.push(option);
                    }
                    
                    const inputCmp = component.find("inputSelect");
                    inputCmp.set("v.options", opts);
                    x = component.get("v.sObject");
					y = component.get("v.objName");
					z = component.get("v.sObject")[component.get("v.objName")]
					console.log("gg " + x);
					console.log("gg " + y);
					console.log("gg " + z);
					
					console.log("ff" + component.get("v.sObject")[component.get("v.objName")]);
                    inputCmp.set("v.value", component.get("v.sObject")[component.get("v.objName")]);
					console.log("finish " + objName);
                }
            }
        });		
        $A.enqueueAction(action);
    }
})