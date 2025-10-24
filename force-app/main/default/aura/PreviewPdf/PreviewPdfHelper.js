({
    getValidatedQuoteTerms : function(component, event, helper) {
        var action = component.get("c.validateQuoteTerms");
        action.setParams({ quoteId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.validatedQuoteTerms', result);
                if(result == true){
                    let button = component.find('generatePDFButton');
                    button.set('v.disabled',false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    getTemplates : function(component, event, helper) {
        var action = component.get("c.getAllTemplates");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.templateOptions', result);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getTemplate : function(component, event, helper) {
        var action = component.get("c.getTemplate");
        action.setParams({ quoteId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.template', result);
                helper.getLanguages(component, event, helper);
                if(component.get('v.template') == 'Wheels') {
                    component.set('v.selectedMetric', 'Quantity');
                    component.set('v.showMetrics', false);
                } else if(component.get('v.template') == 'Pipes') {
                    helper.getMetrics(component, event, helper);
                    component.set('v.showMetrics', true);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getLanguages : function(component, event, helper) {
        var action = component.get("c.getAllLanguages");
        
        action.setParams({ quoteId : component.get("v.recordId"), curTemplate : component.get("v.template") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result != 'undefined') {
                    component.find('languageId').set('v.disabled', false);
                    component.set('v.languageOptions', result);
                    component.find('languageId').set('v.value', result[0]);
                } else {
                    component.find('languageId').set('v.disabled', true);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);		
    },
    
    getMarketSegment : function(component, event, helper) {
        var action = component.get("c.getMarketSegment");
        action.setParams({ quoteId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.marketSegment', result);
                if(result == 'KLW') {
                    component.set('v.template', 'Wheels');
                    helper.getLanguages(component, event, helper);
                    component.set('v.selectedMetric', 'Quantity');
                    component.set('v.showMetrics', false);
                } else helper.getTemplate(component, event, helper);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getMetrics : function(component, event, helper) {
        var action = component.get("c.getAllMetrics");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.metricOptionsMap', JSON.parse(result));
                component.set('v.metricOptions', Object.keys(component.get('v.metricOptionsMap')));
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    displayToast : function (title, message, type) {
        var toast = $A.get("e.force:showToast");
        
        // For lightning1 show the toast
        if (toast) {
            //fire the toast event in Salesforce1
            if(type=='success'){
                toast.setParams({
                    "title": title,
                    "message": message,
                    "type": type || "other",                
                    "duration" : 3000
                });
            }
            else{
                toast.setParams({
                    "title": title,
                    "message": message,
                    "type": type || "other",
                    "mode": "sticky"
                    
                });
            }
            
            toast.fire();
            //var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
            //dismissActionPanel.fire(); 
        } else { // otherwise throw an alert
            alert(title + ': ' + message);
        }
    },
    fetchQuoteLineItemsHelper: function(component, event, helper){
        component.set('v.mycolumns', [
            {label: 'Product', fieldName: 'Product2Name', type: 'text',initialWidth: 140},
            {label: 'Product Name', fieldName: 'Name__c', type: 'text',initialWidth: 140},
            {label: 'Quantity (units)', fieldName: 'InquiryQuantity__c', type: 'text',initialWidth: 140},
            {label: 'Sales Price (per unit)', fieldName: 'InquiryUnitPrice__c', type: 'text',initialWidth: 140},
            {label: 'Quantity (t)', fieldName: 'Quantity', type: 'text',initialWidth: 140},
            {label: 'Sales Price (per t)', fieldName: 'UnitPrice', type: 'text',initialWidth: 160},
            {label: 'Sales Price (per ft)', fieldName: 'Sales_Price_ft__c', type: 'text',initialWidth: 160},
            {label: 'Sales Price (per lb)', fieldName: 'Sales_Price_lb__c', type: 'text',initialWidth: 160},
            {label: 'Sales Price (per m)', fieldName: 'Sales_Price_m__c', type: 'text', initialWidth: 160},
            {label: 'Sales Price (per pcs)', fieldName: 'Sales_Price_pcs__c', type: 'text', initialWidth: 170}
            ]);
        
        var action = component.get("c.fetchQuoteLineItems");
        action.setParams({ quoteId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log(response.getReturnValue());
                var rows = response.getReturnValue();
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i];
                if (row.Product2) row.Product2Name = row.Product2.Name;
            }
                
                component.set("v.quoteLineItemList", response.getReturnValue());
                
                var rowss =[];
                var data = response.getReturnValue();
                data.forEach(function(d){
                    rowss.push(d.Id);
                    //console.log(d.Id)
                })
                //console.log(rowss);
                component.set('v.selectedQuoteItemIds',rowss);
                component = component.find("partnerTable");                
        		component.set('v.selectedRows', rowss);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }});
        $A.enqueueAction(action);
    },
 	setToTrueShowInPdfField: function(component, event, helper,idArr){
	
    //console.log(idArr);
    var action = component.get("c.changeShowInPdfToTrue");
	action.setParams({ selectedQuoteLineItems : idArr
        });
    action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('settinf');
                
            }
    else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
    }});
    $A.enqueueAction(action);    
    },
    
    changeValueShowInPdfToFalse: function(component, event, helper){
        var action = component.get("c.changeShowInPdfToFalse");
        action.setParams({ quoteId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('values success changed')
            } 
        else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
        }});
        $A.enqueueAction(action);  
        },
    
    fetchMeasureUnitValues: function(component, event, helper){
         	var action = component.get("c.fetchPicklistMeasureUnit");
        
            action.setParams({});        
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    //console.log(response.getReturnValue());
                    let res = response.getReturnValue();
                    let dataForCheckBoxGroup = [];
                    for(let key in res){
                        let data = {};
                        //data[key] = res[key];
                        data['label'] = res[key];
                        data['value'] = key;
                        dataForCheckBoxGroup.push(data);
                    }
                    //console.log(dataForCheckBoxGroup);
                    //component.set('v.options',dataForCheckBoxGroup);
                    //component.set('v.options',dataForCheckBoxGroup);
                } 
            else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
            }});
            $A.enqueueAction(action);  
        
    },
    fetchMeasureUnits: function(component, event, helper){
        var action = component.get("c.fetchMeasureUnitsProducts");
        action.setParams({ quoteId : component.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('measure unites');
                //console.log(response.getReturnValue());
                let res = response.getReturnValue();
                component.set('v.defaultMeasureValues',res);
            } 
        });
        $A.enqueueAction(action);  
        }
                        
})