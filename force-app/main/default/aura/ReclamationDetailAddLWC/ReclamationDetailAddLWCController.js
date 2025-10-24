({
    onInit : function(component, event, helper) {
        console.log('init');
        window.addEventListener('clickButton', (e) => {
            console.log('test');
        }, false);
    },

    handleAddedProduct : function(component, event) {
        console.log('add product6' + event.getParams());
        console.log( event.getParams());
        console.log(event.detail);
        console.log(component);
        //component.set("v.isModalOpen", true);
        console.log('add product5' + event.getParam('detail'));
        console.log( event.getParam('detail'));
        console.log(event);
        
    },

    handleMessage: function (component, event) {
        console.log('subscription')
        if (event) {
            console.log(JSON.stringify(event));
            console.log(event._params.reclamationId);
        }
        try {
            component.set("v.parentValueReclamation",event._params.reclamationId);
        } catch (error) {
            console.log(error);
        }
        
        component.set("v.isModalOpen", true);

    },


    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
     },
    
     closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
     },
    
     submitDetails: function(component, event, helper) {
        // Set isModalOpen attribute to false
        //Add your code to call apex method or do some processing
        component.set("v.isModalOpen", false);
     },
    
    reloadItemPage: function(component, event, helper) {
        console.log('reload page of items2');
        component.set("v.isModalOpen", false);
        console.log('reload page of items3');
        try {
            component.find('lWCComponent').LWCreloadProducts(); 
        } catch (error) {
            console.log(error)
        }
        
        
     },
})