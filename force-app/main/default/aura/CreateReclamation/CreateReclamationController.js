({
	init : function(component, event, helper) {
        component.set('v.noReturning', false);                     
        var action = component.get("c.takeInitialInfo");        
        action.setParams({});
        action.setCallback(this, function(response) {
            
            var state = response.getState();           
            if (state === "SUCCESS") {               
                let res = JSON.parse(response.getReturnValue());
                component.set('v.date', res.date);
                component.set('v.client', res.AccountName);
                component.set('v.segment', res.Segment);
                component.set('v.currency', res.Currency);
                res.CurrencyArr = res.CurrencyArr.split(',');
                var currArr = [];
                res.CurrencyArr.pop();
                for(let cur of res.CurrencyArr){
                    currArr.push(cur);
                }
                component.set('v.currencies',currArr);               
            }          
        })
        $A.enqueueAction(action);
        
         // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var objDetails = component.get("v.objDetail");
        // call the helper function
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
    	component.set('v.today', today);
         
    },
    showDetail: function(component, event, helper){
        
        /*
        var validity = component.find("contractNumber").get("v.validity");       
    	var validity2 = component.find("dateContractId").get("v.value");		      
        var validity3 = component.find("reclamationSum").get("v.validity");       
    	*/
        
        
            var contractDate = component.find("dateContractId").get("v.value");
            var dataCurrency = component.find('inputCurrency').get('v.value');
            component.set('v.currency',dataCurrency);
            component.set('v.dateContract',contractDate);       
            component.set('v.showReclamationDetail', false);
                
                            
    },
    changeNoReturning: function(component, event, helper){
        let val = component.get("v.noReturning");        
        component.set('v.reclSum', 0);
        component.set('v.noReturning', !val);
    },
    handleUpdateExpense: function(component, event, helper){
        //console.log('evt');
    },
    catchEvent: function(component, event, helper){
        let updatedExp = event.getParam("order");        
        helper.getOrderItem(component, event, helper,updatedExp);
    },    
    
    //change value in dependent list when control field is selected 
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

    onRender : function(component,event,helper){
    	//debugger;
    	
    	var rootElem = component.find('parent-aura-div-id').getElement();
		var stateElemArray = rootElem.querySelectorAll('select[id$="_state"]');
    	var stateCityMap = component.get('v.stateCityMap');
		var dataArray = component.get('v.dataArray');
		for (var i = 0; i < stateElemArray.length; i++) {
			
			var rowId = stateElemArray[i].id.split('_')[0];
			var citySelElem = rootElem.querySelector('select[id$="' + rowId +'_city"]');
			var cityArray = stateCityMap[stateElemArray[i].value];
			var innerHTMLVar = '';
	    	for (var j = 0; j < cityArray.length; j++) {
	    		if(cityArray[j] == dataArray[rowId-1].city){
	    			innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[j]+ '" selected="true">'+ cityArray[j] +'</option>';  	
	    		}else{
	    			innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[j]+ '">'+ cityArray[j] +'</option>';
    			}
	    	}
	    	citySelElem.innerHTML = innerHTMLVar;			
		}
    },
    claimChanged: function(component,event,helper){
       // alert('qwe');
        var rowId = event.target.id.split('_')[0];
        var noReturning = component.get('v.noReturning');
        var claimEntered = event.target.value;
        var maps = component.get("v.mapOrderItems"); 
        
       
          	
         
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
        
     
        component.set("v.mapOrderItems",maps);
    },
    checkboxSelect: function(component, event, helper) {
        
    var selectedRec = event.getSource().get("v.value");
	var maps = component.get("v.mapOrderItems");
        
    },
    createReclamationAndDetail: function(component, event, helper) {
       helper.createReclamationAndReclamationDetails(component, event, helper);       
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
    closeModal:function(component, event, helper){
            $A.get("e.force:closeQuickAction").fire()            
        },
    
	handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        
        var uploadedFiles = event.getParam("files");
        let dataFiles = cmp.get('v.fileNames');
        //alert("Files uploaded : " + uploadedFiles.length);
		let filesIds = cmp.get("v.fileId");
        let fileNames = cmp.get("v.fileNames");
        // Get the file name
		
		uploadedFiles.forEach(file =>
                             dataFiles.push(file));
        
        //uploadedFiles.forEach(file =>
         //                    fileNames.push(file.name));
        uploadedFiles.forEach(file => filesIds.push(file.documentId));
        
        cmp.set('v.fileId',filesIds);
        
        cmp.set('v.fileNames',dataFiles);             
    }, 
    
    deleteFile: function(cmp, event) {
    	//var btnValue = event.getSource().get("v.value");
    	var btnValue = cmp.get("v.deletedFileId");
        
        let dataFiles = cmp.get('v.fileNames');
        
        let newDataFiles = [];
        let newDataFilesIds = [];
        dataFiles.forEach((file)=>{if(file.documentId != btnValue){
                                   newDataFiles.push(file);
                                  newDataFilesIds.push(file.documentId)}
        });
        
        cmp.set('v.fileNames',newDataFiles);
        
        cmp.set('v.fileId',newDataFilesIds);
        cmp.set("v.isModalOpen", false);
	},
    openModel: function(component, event, helper) {
      // Set isModalOpen attribute to true
      var btnValue = event.getSource().get("v.value");
      component.set("v.deletedFileId",btnValue);  
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
})