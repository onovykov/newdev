({
    doInit  : function(component, event, helper) {
        component.set('v.isMobile', $A.get('$Browser.formFactor') === 'DESKTOP' ? false : true);

        var messageBanner = component.find("messageBanner");
        $A.util.addClass(messageBanner, "slds-hide");
        var content = component.find("main-content");
        $A.util.addClass(content, "slds-scrollable");
        helper.showSpinner(component);

        var action = component.get("c.getOpportunity");
        action.setParams({"oppId": component.get("v.recordId")});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                console.log(response.getReturnValue());
                helper.hideSpinner(component);
                component.set("v.oppWrapper", response.getReturnValue());
                var assignedBO = component.get("v.oppWrapper.oppo.AssignedBOS__r.id");
                //var additionalBO = component.get("v.oppWrapper.oppo.AdditionalBOS__c.id");
                var oppoIdERP = component.get("v.oppWrapper.oppo.ID_ERP__c");
                var ownerIdERP = component.get("v.oppWrapper.oppo.Owner.ID_ERP__c");
                var attachements = component.get("v.oppWrapper.attachements");
                
                console.log("grgr" + attachements);
              
                if (attachements.length == 0) {
                    component.set("v.attachementsExist", false);
                }
                var emails = component.get("v.oppWrapper.emails");
                if (emails.length == 0) {
                    component.set("v.emailsExist", false);
                }
                /*if (assignedBO == null) {
                    helper.displayToast("Warning", $A.get("$Label.c.NoAssignedBO"), "warning");
                   //helper.showMessage(component, "Warning", "slds-theme_warning", $A.get("$Label.c.NoAssignedBO"), 3000);
                } else */if (assignedBO != null && assignedBO.Email == null){
                    helper.displayToast("Warning", $A.get("$Label.c.NoEmailOnAssignedBO"), "warning");
                   //helper.showMessage(component, "Warning", "slds-theme_warning", $A.get("$Label.c.NoEmailOnAssignedBO"), 3000);
                }
                if (ownerIdERP == null){
                    helper.displayToast("Warning", $A.get("$Label.c.NoOwnerIdERP"), "warning");
                }
                /*if (oppoIdERP != null) {
                    helper.displayToast("Warning", $A.get("$Label.c.OppAlreadySent"), "warning");
                }*/
            } else if (state === "INCOMPLETE") {
                helper.showSpinner(component);
            } else if (state === "ERROR") {
                helper.hideSpinner(component);
                helper.displayToast("Error", helper.joinErrors(response.getError()), "error");
                //helper.showMessage(component, "Error", "slds-theme_error", helper.joinErrors(response.getError()),3000);
            }
        });
        $A.enqueueAction(action);
       
        
    },
    submit : function(component, event, helper) {
        helper.showSpinner(component);
        var action = component.get("c.sendJSONData");
        action.setParams({"jsonedWrapper": JSON.stringify(component.get("v.oppWrapper"))});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                helper.hideSpinner(component);
                helper.displayToast("Confirm", "Opportunity info has been successfully sent.", "success");
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "INCOMPLETE") {
                helper.showSpinner(component);
            } else if (state === "ERROR") {
                helper.hideSpinner(component);
                /*var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "type" : "error",
                    "message": "fff"
                });
                toastEvent.fire();*/
                console.log(response.getError()[0].message);
                helper.displayToast("Error", helper.joinErrors(response.getError()), "error");
                //helper.showMessage(component, "Error", "slds-theme_error", helper.joinErrors(response.getError()),5000);
            }
        });
        $A.enqueueAction(action);
    },
    cancel : function (component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
    
})