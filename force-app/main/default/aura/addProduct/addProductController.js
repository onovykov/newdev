({    
    addOppProduct : function(component, event, helper) {

		
		helper.setlookups(component, event, helper);

        var action = component.get("c.addOppProductQ");
        action.setParams({"oppProduct": component.get("v.oppProduct"), "oppId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                if(response.getReturnValue()==''){
                    $A.get('e.force:refreshView').fire();
                    component.set("v.fifthScreen", false); 
                    component.set("v.finishScreen", true); 
                }
                else{
                    helper.displayToast("Error", response.getReturnValue(), "error");
                }
                     
                                
            }
            else if (response.getState() === "ERROR"){
                console.log(component.get("v.oppProduct.LengthSize__c"));
                console.log(response.getError());
                helper.displayToast("Error", helper.joinErrors(response.getError()), "error");             
            }            
        });
        $A.enqueueAction(action);
        var action = component.get("c.isMobile");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                if(response.getReturnValue()){
    				component.set("v.finishScreenForMobile", true);   
    			}
            }
		});
        $A.enqueueAction(action);
    },
    doInit : function(cmp) {

        var action = cmp.get("c.getCurrencyIsoCode");
        action.setParams({"oppId": cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                var curr = cmp.find("salesPrice");
                curr.set("v.label", 'Price (' + result + ')');   
                curr.set("v.format", '#,###.00');
            }
        });
        $A.enqueueAction(action);

        var action2 = cmp.get("c.getFieldPicklistValues");
        action2.setParams({"picklistField": "InquiryUnit__c"});
        action2.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {				
                var result = response.getReturnValue();
                var opts = [];
                var opts = [{value:"", label:"--None--"}];
                for (var label in result) {
					if (result.hasOwnProperty(label)) {
                        if(result[label]!=0){
                            opts.push({ class: "optionClass", label: label, value: result[label] });
                        }
					}
				}				
                cmp.find("Unit").set("v.options", opts);        
            }
        });
        $A.enqueueAction(action2);

        var action3 = cmp.get("c.getProductNames");
        action3.setParams({"oppId": cmp.get("v.recordId")});
        action3.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {                
                var result = response.getReturnValue();
                var opts = [];
                    var opts = [{value:"", label:"--None--"}];
                    for (var key in result) {
                        var option = {value:key, label:result[key]};
                        opts.push(option);
                    }              
                cmp.find("productName").set("v.options", opts);        
            }
        });
        $A.enqueueAction(action3);
        
        var action4 = cmp.get("c.getShippingPointForCountry");
        action4.setParams({"oppId": cmp.get("v.recordId")});
        action4.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                var opts = [];
                    var opts = [{value:"", label:"--None--"}];
                    for (var key in result) {
                        var option = {value:key, label:result[key]};
                        opts.push(option);
                    }
                cmp.find("shippingPoint").set("v.options", opts);        
            }
        });
        $A.enqueueAction(action4);
    },
    nextTo2 : function(component, event, helper) {
        var productName = component.find("productName");
        var value = productName.get("v.value");

        // Is input numeric?
        if ((value == "") || (value == null)) {
            // Set error
            productName.set("v.errors", [{message:"Fill in Product Group"}]);
        } else {
            // Clear error
            productName.set("v.errors", null);
            component.set("v.firstScreen", false);
            component.set("v.secondScreen", true);
        }
		
	},
	nextTo3 : function(component, event, helper) {
        var a = component.find("Unit");
        console.log(a.get("v.value"));
		component.set("v.secondScreen", false);
		component.set("v.thirdScreen", true);
        if(component.find("sg")!=undefined){
            if(component.find("sg").get("v.value")==''){
                component.set("v.oppProduct.SteelGrade__c", null);
            }
        }
        

               
        
	},
	nextTo4 : function(component, event, helper) {
		
		/*if (component.find(component.get("v.OdId"))!= undefined) {
            component.set("v.oppProduct.TubeOD__c", component.find(component.get("v.OdId")).get("v.value"));
            component.set("v.oppProduct.SteelGrade__c", component.find(component.get("v.SteelGradeId")).get("v.value"));
            component.set("v.oppProduct.TubeWT__c", component.find(component.get("v.WtId")).get("v.value"));
            component.set("v.oppProduct.TubeEnds__c", component.find(component.get("v.EndsId")).get("v.value"));
            component.set("v.oppProduct.Coating__c", component.find(component.get("v.CoatingId")).get("v.value"));
            component.set("v.oppProduct.LengthSize__c", component.find(component.get("v.LengthSizeId")).get("v.value"));
        }*/

        if(component.find("lengthSize")!=undefined){
            if(component.find("lengthSize").get("v.value")==''){
                component.set("v.oppProduct.LengthSize__c", null);
            }
        }

        var inputCmp = component.find("quantity");
        var od;
        var wt;
        var lengthSize;

        if (component.find(component.get("v.OdId"))!= undefined) {
            od = component.find(component.get("v.OdId"));
            wt = component.find(component.get("v.WtId"));        
            lengthSize = component.find(component.get("v.LengthSizeId"));
        } else{
            od = component.find("od");
            wt = component.find("wt");
            lengthSize = component.find("lengthSize");
        }

        
        var valueQ = inputCmp.get("v.value");
        
        var valueOD = od.get("v.value");
        var valueWT = wt.get("v.value");
        var isOKQ = !isNaN(valueQ) && (valueQ != "") && (valueQ != null);
        var isOKOD = (valueOD != "") && (valueOD != null);
        var isOKWT = (valueWT != "") && (valueWT != null);
        var unit = component.find("Unit");
        var valueUnit = unit.get("v.value");
        var isOKUnit = (valueUnit != "") && (valueUnit != null);
        var valueLS = lengthSize.get("v.value");
        console.log(valueUnit);
        var isNotOKLS = (valueUnit == "43") && ((valueLS == null) || (valueLS == ""));
        // Is input numeric?
        if (isOKQ!=true || isOKOD!=true || isOKWT!=true || isNotOKLS ==true || isOKUnit!=true) {
            // Set error
            if(isOKQ!=true){
                inputCmp.set("v.errors", [{message:"Fill in the quantity field"}]);
            }
            if(isOKOD!=true){
                od.set("v.error", true);
                od.set("v.errorMessage", 'Fill in OD field');
            }
            if(isOKOD!=true){
                wt.set("v.error", true);
                wt.set("v.errorMessage", 'Fill in WT field');
            }
            if(isNotOKLS==true){
                lengthSize.set("v.error", true);
                lengthSize.set("v.errorMessage", 'Fill in Length Size field');
            }  
            if(isOKUnit!=true){
                unit.set("v.errors", [{message:"Fill in the quantity field"}]);
            }
      
        } 
        else{
            // Clear error
            unit.set("v.errors", null);
            inputCmp.set("v.errors", null);
            od.set("v.error", false);
            wt.set("v.error", false);
            lengthSize.set("v.error", false);
            component.set("v.thirdScreen", false);
            component.set("v.fourthScreen", true);
        }
        

		/*var inputCmp = component.find("od");
        var value = inputCmp.get("v.value");
        console.log(value);
        // Is input numeric?
        if (value=='') {
            // Set error
            console.log('errrorrrrr');
            inputCmp.set("v.errors", [{message:"Fill in the OD field"}]);
        } else {
            // Clear error
            inputCmp.set("v.errors", null);
            component.set("v.thirdScreen", false);
            component.set("v.fourthScreen", true);
        }*/
	},
    nextTo5 : function(component, event, helper) {
        component.set("v.fourthScreen", false);
        component.set("v.fifthScreen", true);
        var inputCmp = component.find("Unit");
        var value = inputCmp.get("v.value");
        console.log(value);
        component.set("v.oppProduct.InquiryUnit__c", value);
    },
	backTo1 : function(component, event, helper) {
		component.set("v.firstScreen", true);
		component.set("v.secondScreen", false);
	},
	backTo2 : function(component, event, helper) {
		component.set("v.secondScreen", true);
		component.set("v.thirdScreen", false);
		component.set("v.firstScreen", false);
        
	},
	backTo3 : function(component, event, helper) {
		component.set("v.thirdScreen", true);
		component.set("v.secondScreen", false);
		component.set("v.firstScreen", false);
		component.set("v.fourthScreen", false);
        
	},
    backTo4 : function(component, event, helper) {
        component.set("v.fourthScreen", true);
        component.set("v.secondScreen", false);
        component.set("v.firstScreen", false);
        component.set("v.fifthScreen", false);
        component.set("v.thirdScreen", false);
    },
	addAnotherProduct : function(component, event, helper) {
		component.set("v.firstScreen", true);
		component.set("v.thirdScreen", false);
		component.set("v.secondScreen", false);
		component.set("v.fourthScreen", false);
        component.set("v.fifthScreen", false);
		component.set("v.finishScreen", false);
        
        helper.clearValues(component, event, helper);
	},
    cancel : function(component, event, helper) {
        component.set("v.firstScreen", true);
        component.set("v.thirdScreen", false);
        component.set("v.secondScreen", false);
        component.set("v.fourthScreen", false);
        component.set("v.fifthScreen", false);
        component.set("v.finishScreen", false);
        
        helper.clearValues(component, event, helper);
    },
	close : function(component, event, helper) {
		var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	      "recordId": component.get("v.recordId"),
	      "slideDevName": "related"
	    });
	    navEvt.fire();
	}				
})