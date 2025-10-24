({
	queryData: function (component) {
		this.queryBookedOrderTableData(component);
	},
	queryBookedOrderTableData: function (component) {
		var accountId = component.get("v.recordId");
    	var action = component.get("c.queryBookedOrderTable");
        action.setParams({"accountId": accountId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result.errors === undefined) {
					var current_data = {};
					current_data.BookedOrder = result.ReturnedData;
					current_data.BookedOrder.TileToNumberOfJournalsByQuarters2018 = this.addMergeFields(current_data.BookedOrder.TileToNumberOfJournalsByQuarters2018);
					current_data.BookedOrder.TileToNumberOfJournalsByQuarters2017 = this.addMergeFields(current_data.BookedOrder.TileToNumberOfJournalsByQuarters2017);
					current_data.AccountName = result.AccountName;
					current_data.BookedOrderTableWasReceived = true;
					current_data.CurrentYear = (new Date()).getFullYear();
					component.set("v.Data", current_data);

					this.queryQtyShippedToClientTableData(component);
				}
				else {
					component.set("v.Errors", result.errors);
				}
            } else if (state === "ERROR") {
            	console.log("not fine");
                this.displayToast("Error", "Something went wrong", "error");
                //$A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
	},
	queryQtyShippedToClientTableData: function (component) {
		var accountId = component.get("v.recordId");
		var action = component.get("c.queryQtyShippedToClientTable");
		action.setParams({"accountId": accountId});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result.errors === undefined) {
					var current_data = component.get("v.Data");
					current_data.QTYShippedToClient = result.ReturnedData;
					current_data.QTYShippedToClient.TileToNumberOfJournalsByQuarters2018 = this.addMergeFields(current_data.QTYShippedToClient.TileToNumberOfJournalsByQuarters2018);
					current_data.QTYShippedToClient.TileToNumberOfJournalsByQuarters2017 = this.addMergeFields(current_data.QTYShippedToClient.TileToNumberOfJournalsByQuarters2017);
					current_data.QTYShippedToClientTableWasReceived = true;
					component.set("v.Data", current_data);

					this.queryBalanceForShipmentToClientData(component);
				}
				else {
					component.set("v.Errors", result.errors);
				}
			} else if (state === "ERROR") {
        		console.log("not fine");
				this.displayToast("Error", "Something went wrong", "error");
				//$A.get("e.force:closeQuickAction").fire();
			}
		});
		$A.enqueueAction(action);
	},
	queryBalanceForShipmentToClientData: function (component) {
		var accountId = component.get("v.recordId");
		var action = component.get("c.queryBalanceForShipmentToClient");
		action.setParams({"accountId": accountId});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result.errors === undefined) {
					var current_data = component.get("v.Data");
					current_data.ToTalPendingDeliveries = result.ReturnedData;
					current_data.ToTalPendingDeliveries.PlannedShipmentInNextMonthTitle = this.addMergeFields(current_data.ToTalPendingDeliveries.PlannedShipmentInNextMonthTitle);
					current_data.ToTalPendingDeliveries.PlannedShipmentInThisMonthTitle = this.addMergeFields(current_data.ToTalPendingDeliveries.PlannedShipmentInThisMonthTitle);
					current_data.BalanceForShipmentToClientTableWasReceived = true;

					// Calculate other fields
					current_data.ToTalPendingDeliveries.CurrentBalanceForShipment = current_data.BookedOrder.TotalOfTotals - current_data.QTYShippedToClient.TotalOfTotals;
					current_data.ToTalPendingDeliveries.RemainingQtyForShipment = current_data.ToTalPendingDeliveries.CurrentBalanceForShipment - 
						current_data.ToTalPendingDeliveries.PlannedShipmentInThisMonth - current_data.ToTalPendingDeliveries.PlannedShipmentInNextMonth;
					component.set("v.Data", current_data);

					this.queryDistributionAgreementData(component);
				}
				else {
					component.set("v.Errors", result.errors);
				}
			} else if (state === "ERROR") {
        		console.log("not fine");
				this.displayToast("Error", "Something went wrong", "error");
				//$A.get("e.force:closeQuickAction").fire();
			}
		});
		$A.enqueueAction(action);						
	},
	queryDistributionAgreementData: function (component) {
		var accountId = component.get("v.recordId");
		var action = component.get("c.queryDistributionAgreement");
		action.setParams({"accountId": accountId});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result.errors === undefined) {
					var current_data = component.get("v.Data");
					current_data.DistributionAgreement = result.ReturnedData;
					current_data.DistributionAgreementTableWasReceived = true;
					component.set("v.Data", current_data);

					// ------------ Another call ------------
					// --------------------------------------
				}
				else {
					component.set("v.Errors", result.errors);
				}
			} else if (state === "ERROR") {
        		console.log("not fine");
				this.displayToast("Error", "Something went wrong", "error");
				//$A.get("e.force:closeQuickAction").fire();
			}
		});
		$A.enqueueAction(action);						
	},
	addMergeFields : function (source_string) {
		const monthNames = ["January", "February", "March", "April", "May", "June",
		  "July", "August", "September", "October", "November", "December"
		];

		const currentDate = new Date();
		return source_string.replace("[THIS_YEAR]", currentDate.getFullYear())
							.replace("[LAST_YEAR]", currentDate.getFullYear()-1)
							.replace("[THIS_MONTH]", monthNames[currentDate.getMonth()])
							.replace("[NEXT_MONTH]", monthNames[((currentDate.getMonth()+1) === 12 ? 0 : (currentDate.getMonth()+1))]);
	},
	displayToast : function (title, message, type) {
      // For lightning1 show the toast
      if ($A.get("$Browser.formFactor") !== 'DESKTOP') {
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
      } else { // otherwise throw an alert
          alert(title + ': ' + message);
      }
    }
})