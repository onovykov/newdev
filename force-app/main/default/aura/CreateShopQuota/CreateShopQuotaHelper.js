({
	helperMethod : function() {
		
	},
     handleSearch: function( component, searchTerm ) {
        var action = component.get( "c.searchShopQuota" );
        action.setParams({
            searchTerm: searchTerm
        });
        action.setCallback( this, function( response ) {
            var event = $A.get( "e.c:ShopQuotaLoaded" );
            event.setParams({
                "shopQuotas": response.getReturnValue()
            });
            event.fire();
        });
        $A.enqueueAction( action );
    }
})