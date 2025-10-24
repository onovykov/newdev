({
	showMessage : function(component, title, severity, msg, timeout) {
		var messageBanner = component.find("messageBanner");
        var errorMessage = component.find("messageHTML");
        errorMessage.set("v.value", msg);
        component.set("v.typeOfMessage", title);
        $A.util.removeClass(messageBanner, 'slds-hide');
        var messageSeverity = component.find("messageSeverity");
        $A.util.addClass(messageSeverity, severity);
        setTimeout(
            $A.getCallback(function() {
                if(component.isValid()){
                    var toastDiv= component.find('messageBanner');
                    $A.util.addClass(toastDiv, "slds-hide");
                } else{
                    console.log('Component is Invalid');
                }
            }), timeout
        );
        // Display the total in a "toast" status message
        /*var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Quick Add: ",
            "message": "The total is: ",
            "duration": 10000,
            "mode" : "pester"
        });
        resultsToast.fire();*/
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


    showSpinner : function (component) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, 'slds-hide');
    },
    hideSpinner : function (component) {
        var spinner = component.find("spinner");
        $A.util.addClass(spinner, 'slds-hide');
    },
    joinErrors : function (errors) {
        var errorText = "";
        if (errors){
            for (var e in errors) {
                errorText += errors[e].message.replace(new RegExp("</br>",'g'),". ")  + " ";
            }
        }
        return errorText;
    }
})