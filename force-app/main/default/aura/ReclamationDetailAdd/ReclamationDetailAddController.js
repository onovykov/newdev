({
	init : function(component, event, helper) {        
         // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var objDetails = component.get("v.objDetail");
        helper.getStatusReclamation(component, event, helper);
        // call the helper function
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI); 
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
    	component.set('v.today', today);
        console.log(component.get('v.recordId'));
    },

    getEvents : function(component, event, helper) {
        var evtValue = event.getParam("recordId");
        component.set("v.recordId",evtValue);
	},
    
    catchEvent: function(component, event, helper){
        let updatedExp = event.getParam("order");        
        helper.getOrderItem(component, event, helper,updatedExp);
    },
    checkboxSelect: function(component, event, helper) {
        
    var selectedRec = event.getSource().get("v.value");
	var maps = component.get("v.mapOrderItems");
        
    },
    closeModal:function(component, event, helper){
            $A.get("e.force:closeQuickAction").fire()            
    },
    createReclamationAndDetail: function(component, event, helper) {
       helper.createReclamationAndReclamationDetails(component, event, helper);       
	},
    controlFieldChanged: function(component,event,helper){
    	var rowId = event.target.id.split('_')[0];
    	var stateSelected = event.target.value;       
    	var citySelElem = component.find('parent-aura-div-id').getElement().querySelector('[id="'+rowId + '_city"]');
    	var stateCityMap = component.get('v.depnedentFieldMap');
    	var cityArray = stateCityMap[stateSelected];
    	var innerHTMLVar = '';
    	for (var i = 0; i < cityArray.length; i++) {
    		//innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[i]+ '">' +cityArray[i] +'</option>';  
            innerHTMLVar = innerHTMLVar + '<option text="' + cityArray[i]+ '"  selected="{!dataVar.subtype == '+cityArray[i]+ '}" >' +cityArray[i] +'</option>';  
    	}
    	citySelElem.innerHTML = innerHTMLVar;
        //new 05 12
        var maps = component.get("v.mapOrderItems");
        maps.forEach(function(data) {
            let newArr = data.value;
            newArr.map(function(dat){if(dat.Id == rowId){
                dat.type = stateSelected;
                dat.subtype = cityArray[0];
            }})
        }
         );
        
        component.set("v.mapOrderItems",maps);
    },
    claimChanged: function(component,event,helper){
       
        var rowId = event.target.id.split('_')[0];
        
        var claimEntered = event.target.value;
        var maps = component.get("v.mapOrderItems"); 
        
        
        //if(!noReturning){   	
         
        var orderPrice = component.find('parent-aura-div-id').getElement().querySelector('[id="'+rowId + '_uniPrice"]');
        var claimPrice = component.find('parent-aura-div-id').getElement().querySelector('[id="'+rowId + '_claimSum"]');
        claimPrice.value = orderPrice.innerText * claimEntered;
        maps.forEach(function(data) {
            let newArr = data.value;
            newArr.map(function(dat){if(dat.Id == rowId){
                dat.claimQty = claimEntered;
                dat.claimSum = claimPrice.value;
            }})
        }
         );
        
       // } else{
        //  claimEntered = 0;  
       // }
        
        component.set("v.mapOrderItems",maps);
    },
    	deleteOrder: function (component, event, helper){
    var claimEntered = event.getSource().get("v.value");
    var maps = component.get("v.mapOrderItems"); 
    
    let newMap =[];
    for(var key in maps){
        if(key!=claimEntered){
            newMap.push({key: key, value: maps[key].value});
        }
    }   
    component.set("v.mapOrderItems",newMap);
        
}, 
})