({
	myAction : function(component, event, helper) {
		
	},
       doInit : function( component, event, helper ) {
        
        let pageRef = component.get("v.pageReference");
        
        let state = pageRef.state; // state holds any query params
        let base64Context = state.inContextOfRef;
        if ( base64Context.startsWith("1\.") ) {
            base64Context = base64Context.substring( 2 );
        }
        let addressableContext = JSON.parse( window.atob( base64Context ) );
        component.set( "v.recordId", addressableContext.attributes.recordId );
        
    },
    onInit: function( component, event, helper ) {
        // proactively search on component initialization
        var searchTerm = component.get( "v.searchTerm" );
        helper.handleSearch( component, searchTerm );
        
        let pageRef = component.get("v.pageReference");
        
        let state = pageRef.state; // state holds any query params
        let base64Context = state.inContextOfRef;
        if ( base64Context.startsWith("1\.") ) {
            base64Context = base64Context.substring( 2 );
        }
        let addressableContext = JSON.parse( window.atob( base64Context ) );
        component.set( "v.recordId", addressableContext.attributes.recordId );
    },
    onSearchTermChange: function( component, event, helper ) {
        // search anytime the term changes
        var searchTerm = component.get( "v.searchTerm" );
        // to improve performance, particularly for fast typers,
        // we wait a small delay to check when user is done typing
        var delayMillis = 500;
        // get timeout id of pending search action
        var timeoutId = component.get( "v.searchTimeoutId" );
        // cancel pending search action and reset timer
        clearTimeout( timeoutId );
        // delay doing search until user stops typing
        // this improves client-side and server-side performance
        timeoutId = setTimeout( $A.getCallback( function() {
            helper.handleSearch( component, searchTerm );
        }), delayMillis );
        component.set( "v.searchTimeoutId", timeoutId );
    },
    handleComponentEvent : function(component, event, helper) {
        var valueFromChild = event.getParam("message");
        
        component.set("v.quotaType", valueFromChild);
    },
    handleSubmit: function(component, event, helper) {
            event.preventDefault();       // stop the form from submitting
        	var quotaType = component.get("v.quotaType");
            var fields = event.getParam('fields');
            fields.Quota_Type__c = quotaType;       	
            component.find('recordEditForm').submit(fields);
        },
    
    handleSuccess: function(component, event) {
            var payload = event.getParams().response;      	
         	var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId":payload.id,
                  "slideDevName": "Detail"
                });
    	 	navEvt.fire();
        },
    
    handleClick: function(component, event) {
            var payload = event.getParams().response;      	
         	var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": component.get( "v.recordId"),
                  "slideDevName": "Detail"
                });
    	 	navEvt.fire();
        },
    
    handleError: function(component, event) {
        var errors = event.getParams();
        
        let errMessage = errors.error.body.output.fieldErrors.Quota_Type__c[0].message;
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "mode": 'sticky',
            "title": "Error!",
            "message": errMessage
        });
        toastEvent.fire();
    }

})