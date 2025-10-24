({
	createLookup : function(component, event, helper, randNum, label, object) {
        $A.createComponent(
            "c:inputLookup",
            {
                "aura:id": randNum,

                "label": label,
                "object": object,
                "searchField": "Name",
                "placeholder": "Select an option",
                "order": "Name",
                "limit": "5",
                "loadingMessage": "Loading...",
                "errorMessage": "Invalid input",
                "value": "",
                "showRecentRecords": "true"
            },
            function(newInputLookup, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newInputLookup);
                    component.set("v.body", body);
                }
            });
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
    joinErrors : function (errors) {
        var errorText = "";
        if (errors){
            for (var e in errors) {
                errorText += errors[e].message + " ";
                if(errors[e].pageErrors){
                  errorText += errors[e].pageErrors[0].message + " ";
                }
            }
        }
        return errorText;
    },
    setlookups : function(component, event, helper){
      if (component.find(component.get("v.OdId"))!= undefined) {
            component.set("v.oppProduct.TubeOD__c", (component.find(component.get("v.OdId")).get("v.value")!='') ? component.find(component.get("v.OdId")).get("v.value") : null);
            component.set("v.oppProduct.SteelGrade__c", (component.find(component.get("v.SteelGradeId")).get("v.value")!='') ? component.find(component.get("v.SteelGradeId")).get("v.value") : null);
            component.set("v.oppProduct.TubeWT__c", (component.find(component.get("v.WtId")).get("v.value")!='') ? component.find(component.get("v.WtId")).get("v.value") : null);
            component.set("v.oppProduct.TubeEnds__c", (component.find(component.get("v.EndsId")).get("v.value")!='') ? component.find(component.get("v.EndsId")).get("v.value") : null);
            component.set("v.oppProduct.Coating__c", (component.find(component.get("v.CoatingId")).get("v.value")!='') ? component.find(component.get("v.CoatingId")).get("v.value") : null);
            component.set("v.oppProduct.LengthSize__c", (component.find(component.get("v.LengthSizeId")).get("v.value")!='') ? component.find(component.get("v.LengthSizeId")).get("v.value") : null);
            component.set("v.oppProduct.QuotaType__c", (component.find(component.get("v.QuotaTypeId")).get("v.value")!='') ? component.find(component.get("v.QuotaTypeId")).get("v.value") : null);
            component.set("v.oppProduct.ProductStandard__c", (component.find(component.get("v.StandardId")).get("v.value")!='') ? component.find(component.get("v.StandardId")).get("v.value") : null);
        }
    },
    clearValues : function(component, event, helper){
      var action = component.get("c.getNewOppProduct");        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.oppProduct", result);
                var a = component.find("Unit");
                a.set("v.value", null);
            }
        });
        $A.enqueueAction(action);

        var od = component.find('od');
        if(od!=undefined){od.destroy();}
        else{component.find(component.get("v.OdId")).destroy();}
        var wt = component.find('wt');
        if(wt!=undefined){wt.destroy();}
        else{component.find(component.get("v.WtId")).destroy();}
        var sg = component.find('sg');
        if(sg!=undefined){sg.destroy();}
        else{component.find(component.get("v.SteelGradeId")).destroy();}
        var ends = component.find('ends');
        if(ends!=undefined){ends.destroy();}
        else{component.find(component.get("v.EndsId")).destroy();}
        var coating = component.find('coating');
        if(coating!=undefined){coating.destroy();}
        else{component.find(component.get("v.CoatingId")).destroy();}
        var lengthSize = component.find('lengthSize');
        if(lengthSize!=undefined){lengthSize.destroy();}
        else{component.find(component.get("v.LengthSizeId")).destroy();}
        var quotaType = component.find('quotaType');
        if(quotaType!=undefined){quotaType.destroy();}
        else{component.find(component.get("v.QuotaTypeId")).destroy();}        
        var standard = component.find('standard');
        if(standard!=undefined){standard.destroy();}
        else{component.find(component.get("v.StandardId")).destroy();}

        var randomNumber = Math.floor(1000 + Math.random() * 9000);
        component.set("v.OdId", randomNumber);
        var randomNumber2 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.SteelGradeId", randomNumber2);
        var randomNumber3 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.WtId", randomNumber3);
        var randomNumber4 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.EndsId", randomNumber4);
        var randomNumber5 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.CoatingId", randomNumber5);
        var randomNumber6 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.LengthSizeId", randomNumber6);
        var randomNumber7 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.QuotaTypeId", randomNumber7);
        var randomNumber8 = Math.floor(1000 + Math.random() * 9000);
        component.set("v.StandardId", randomNumber8);

        component.set("v.body", []);

        helper.createLookup(component, event, helper, randomNumber, "OD", "TubeOD__c");
        helper.createLookup(component, event, helper, randomNumber2, "Steel Grade", "SteelGrade__c");
        helper.createLookup(component, event, helper, randomNumber3, "WT", "TubeWT__c");
        helper.createLookup(component, event, helper, randomNumber4, "Ends", "TubeEnds__c");
        helper.createLookup(component, event, helper, randomNumber5, "Coating", "CoatingType__c");
        helper.createLookup(component, event, helper, randomNumber6, "Length Size", "TubeLengthSize__c");
        helper.createLookup(component, event, helper, randomNumber7, "Quota Type", "QuotaType__c");
        helper.createLookup(component, event, helper, randomNumber8, "Standard", "ProductStandard__c");
    }
	
})