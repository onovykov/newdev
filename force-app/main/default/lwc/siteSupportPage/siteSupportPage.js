import { LightningElement,api,track,wire } from 'lwc';
import uploadFile from '@salesforce/apex/FileUploaderTest.uploadFile';
import fetchUserData from '@salesforce/apex/FileUploaderTest.fetchUserData';
import setUserPhone from '@salesforce/apex/FileUploaderTest.setUserPhone';
import SVG_PIPES from '@salesforce/resourceUrl/pipeIcons';
import getCases from '@salesforce/apex/SupportDatatableController.getCases';
import getUserBOSpecId from '@salesforce/apex/UserUtils.getUserBOSpecId';
import getBOSpecEmail from '@salesforce/apex/UserUtils.getBOSpecEmail';
import getUserMarketSegment from '@salesforce/apex/UserUtils.getUserMarketSegment';
import getUserManagerEmail from '@salesforce/apex/UserUtils.getUserManagerEmail';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import Support_contact from '@salesforce/label/c.Support_contact';
import subject from '@salesforce/label/c.subject';
import Creation_date from '@salesforce/label/c.Creation_date';
import Status from '@salesforce/label/c.Status';
import Status_date from '@salesforce/label/c.Status_date';
import Write_to_manager from '@salesforce/label/c.Write_to_manager';
import My_application_history from '@salesforce/label/c.My_application_history';
import Your_name from '@salesforce/label/c.Your_name';
import E_mail from '@salesforce/label/c.E_mail';
import Phone_number from '@salesforce/label/c.Phone_number';
import Problem_description from '@salesforce/label/c.Problem_description';
import Attach_files from '@salesforce/label/c.Attach_files';
import Upload_file from '@salesforce/label/c.Upload_file';
import Send from '@salesforce/label/c.Send';
import supportAccount from '@salesforce/label/c.Support_account';
import supportDescription from '@salesforce/label/c.Support_description';
import supportHeader from '@salesforce/label/c.Support_header';
import supportSubheader from '@salesforce/label/c.Support_subHeader';
import SupportTheme from '@salesforce/label/c.Support_theme';
import Suport_ticket_created from '@salesforce/label/c.Suport_ticket_created';
import theme_for_suport_ticket from '@salesforce/label/c.theme_for_suport_ticket';
import contact_sys_admin from '@salesforce/label/c.contact_sys_admin';
import Processing from '@salesforce/label/c.Processing';
import On_Hold from '@salesforce/label/c.On_Hold';
import New from '@salesforce/label/c.New';
import All_cases from '@salesforce/label/c.All_cases';
import Download_Manual from '@salesforce/label/c.Download_Manual';
import MANUALUA from '@salesforce/resourceUrl/ManualUA';
import MANUALEN from '@salesforce/resourceUrl/ManualEN';
import MANUALRU from '@salesforce/resourceUrl/MANUALRU';




export default class SiteSupportPage extends LightningElement {
    

    labels = {
        My_application_history,
        Support_contact,
        subject,
        Creation_date,
        Status,
        Status_date,
        Write_to_manager,

        Your_name,
        E_mail,
        Phone_number,
        Problem_description,
        Attach_files,
        Upload_file,
        Send,
        SupportTheme,

        supportAccount,
        supportDescription,
        supportHeader,
        supportSubheader,

        Processing,
        On_Hold,
        New,
        All_cases,

        Suport_ticket_created,
        theme_for_suport_ticket,
        contact_sys_admin,
        Download_Manual
        

    }
    @track showSpinner
    @track casesList;
    @track BOspecLastName;
    @track BOspecEmail;
    @track ManagerLastName;
    @track ManagerEmail;

    @track amountAllCases;
    @track amountNewCases;
    @track amountHoldCases;
    @track amountProcessingClaims
    @track dropdownOpen = false;
    @track optionsToDisplay;
    @track options = [
        { id: 'tab-defaultItem-1', label:  this.labels.All_cases, order: 1 },
        { id: 'tab-defaultItem-2', label:  this.labels.New, order: 2 },
        { id: 'tab-defaultItem-3', label:  this.labels.On_Hold, order: 3 },
        { id: 'tab-defaultItem-4', label:  this.labels.Processing, order: 4 },


    ];
    @track selectedOption = this.options[0].label;

    casesResult;
    BOspecid;
    sortIcon = IMAGES + '/filterIcon.png';
    chatImg = IMAGES + '/chat-btn.png';
    manualImg = IMAGES + '/manual.png';

    dateSortToggled = false;
    stageSortToggled = false;
    isModalOpen = false;
    @track selectedCaseid;

    allCases;
    newCases;
    onHoldcases;
    escalatedCases;
    @track filteredCasesList;

    @api
    myRecordId;
    @track fileData;
    @api recordId = '5000E00000HpupjQAB';
    @track fileName;
    @track uploadedFiles = [];
    arrayOfUploadedFiles = [];
    userData;
    isAmericanUser = false;
    userLanguage;
    manualUA = MANUALUA;
    manualEN = MANUALEN;
    manualRU = MANUALRU;


    attach = `${SVG_PIPES}#attach`;

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }


    connectedCallback() {
        this.optionsToDisplay = this.options.filter((option) => option.label !== this.selectedOption);
        getUserLanguage().then(result => {
            console.log(result);
            if(result == 'uk'){
                this.userLanguage = 'uk'
            }else if(result =='ru'){
                this.userLanguage = 'ru'
            }else{
                this.userLanguage = 'en_US'
            }

            }).catch(error =>{
                console.log(error);
            })
            
        getUserMarketSegment().then(response=>{
            // console.log('response ---->', response)
            if(response == '00001'){
                this.isAmericanUser = true;
            }
        })

        getUserManagerEmail().then(response=>{
            if(this.isAmericanUser){
                this.ManagerEmail ='mailto:'+ response[0].Manager.Email;
                this.ManagerLastName = response[0].Manager.LastName;
            }
        })
        
    }
    renderedCallback(){
        let styleDropdownBtn = window.getComputedStyle(this.refs.dropdownBtn);
        if(this.refs.dropdownList?.style){
            this.refs.dropdownList.style.width = styleDropdownBtn.width;
        }
    }
    @wire(getCases,{}) handleCases(result){
        this.casesResult = result;
        const {error, data } = result;
        if(data){
            // console.log(data);
            
            let dataCopy = data.map(item=>{
                return Object.assign({},item);
            })
            dataCopy.forEach(item => {
              if(item.Status == 'Escalated') {
                //console.log(item.Status)
                item.Status = 'Processing';
              }
            });
            this.casesList = dataCopy;
            this.filteredCasesList = dataCopy;

            this.filteredCasesList = dataCopy;

            let all = this.filteredCasesList.filter((item=>{
                return item;
            }))
            let newCase = this.filteredCasesList.filter((item=>{
                return item.Status == 'New';
            }))
            let onHold = this.filteredCasesList.filter((item=>{
                return item.Status == 'On Hold';
            }))
            let processing = this.filteredCasesList.filter((item=>{
                return item.Status == 'Processing';
            }))


            this.amountAllCases = all.length;
            this.amountNewCases = newCase.length;
            this.amountHoldCases = onHold.length;
            this.amountProcessingClaims = processing.length;
        }
        if(error){
            console.error(error);
        }

    }
    @wire(getUserBOSpecId,{}) handleUser(result){
        const {error, data } = result;
        if(data){
            this.BOspecid = data;
        }
        if(error){
            console.error(error);
        }

    }
    @wire(getBOSpecEmail,{BOid : '$BOspecid'}) handleBOUser(result){
        const {error, data } = result;
        if(data){
            this.BOspecLastName = data[0].LastName;
            this.BOspecEmail ='mailto:'+ data[0].Email__c;

        }
        if(error){
            console.error(error);
        }

    }



    downloadFile() {
       console.log('this.userLanguage', this.userLanguage)
        const link = document.createElement('a');
        if(this.userLanguage == 'uk'){
            link.href = this.manualUA;
        }else if(this.userLanguage =='ru'){
            link.href = this.manualRU;
        }else {
            link.href = this.manualEN;
        }
        link.download = "Interpipe Manual";
        document.body.appendChild(link);
        console.log(link)

        link.click();
    }
    searchBy(){
        this.filteredCasesList = this.casesList;

        if(this.allCases){
            this.filteredCasesList = this.filteredCasesList.filter(caseItem=>{
                return caseItem;
            })
        }
        if(this.newCases){
            this.filteredCasesList = this.filteredCasesList.filter(caseItem=>{
                return caseItem.Status == 'New';
            })
        }
        if(this.onHoldcases){
            this.filteredCasesList = this.filteredCasesList.filter(caseItem=>{
                return caseItem.Status == 'On Hold';
            })
        }
        if(this.escalatedCases){
            this.filteredCasesList = this.filteredCasesList.filter(caseItem=>{
                return caseItem.Status == 'Processing';
            })
        }
       
    }
    
    toggleSubtabs(event) {
        this.switchTabName(event.target.dataset.id)                   
    }
    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }
	handleOptionClick(event) {
        const selectedOptionId = event.target.dataset.id;
        console.log('selectedOptionId ',selectedOptionId)
        this.switchTabName(selectedOptionId)    
        const selectedOption = this.options.find((option) => option.id === selectedOptionId);
        if (selectedOption) {   
            this.selectedOption = selectedOption.label;
            this.optionsToDisplay = this.options.filter((option) => option.label !== selectedOption.label);
            this.optionsToDisplay.sort((a, b) => a.order - b.order);
            console.log()
        }
        this.dropdownOpen = false;
    }

    switchTabName(idAtrribute){
        try {
            this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
               
                if(data.querySelectorAll('a')[0].dataset.id == idAtrribute ){
                    data.classList.add("slds-is-active")
                } else{
                    data.classList.remove("slds-is-active");
                }
            })
            
            if(idAtrribute == 'tab-defaultItem-1'){
                this.allCases = true
                this.newCases = false;
                this.onHoldcases = false;
                this.escalatedCases = false;
                this.searchBy();
            }
            if(idAtrribute == 'tab-defaultItem-2'){
                this.allCases = false
                this.newCases = true;
                this.onHoldcases = false;
                this.escalatedCases = false;
                this.searchBy();
            }
            if(idAtrribute == 'tab-defaultItem-3'){
                this.allCases = false
                this.newCases = false;
                this.onHoldcases = true;
                this.escalatedCases = false;
                this.searchBy();
            }
            if(idAtrribute == 'tab-defaultItem-4'){
                this.allCases = false;
                this.newCases = false;
                this.onHoldcases = false;
                this.escalatedCases = true;
                this.searchBy();
            }            
        } catch (error) {
            console.log(error);
        }
    }

    filterByDate(){
        if(!this.dateSortToggled ){
            this.dateSortToggled = !this.dateSortToggled;
            this.stageSortToggled = false;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        }else{
            this.dateSortToggled = !this.dateSortToggled;
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
        } 
        try {
            var self = this;
            let arrayForSort = [...this.filteredCasesList];
            arrayForSort.sort(function(a, b) {
                if(self.sortBydateAsc){
                    return new Date(b.CreatedDate)-new Date(a.CreatedDate);
                } else {
                    return new Date(a.CreatedDate)-new Date(b.CreatedDate);
                }
            });
            this.filteredCasesList = arrayForSort;
            this.sortBydateAsc = !this.sortBydateAsc;
        } catch (error) {
            console.log(error)
        }
    }
    filterByStage(){
        if(!this.stageSortToggled ){
            this.stageSortToggled = !this.stageSortToggled;
            this.dateSortToggled = false;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.add('sort-icon-rotate');
            this.template.querySelector('[data-id="dateSortIcon"]').classList.remove('sort-icon-rotate')
        }else{
            this.stageSortToggled = !this.stageSortToggled;
            this.template.querySelector('[data-id="stageSortIcon"]').classList.remove('sort-icon-rotate')
        } 
        try {
            var self = this;
            let arrayForSort = [...this.filteredCasesList];
            arrayForSort.sort(function(a, b) {
                if(self.sortByStageAsc){
                    return  new String(b.Status).localeCompare(new String(a.Status));
                } else {
                    return new String(a.Status).localeCompare(new String(b.Status));
                }
            });
            this.filteredCasesList = arrayForSort;
            this.sortByStageAsc = !this.sortByStageAsc;
        } catch (error) {
            console.log(error)
        }
    }

    @wire(fetchUserData,{}) handleUserData(result){
        const {error, data } = result;
        if(data){
            this.userData = data;
            // console.log(this.template.querySelectorAll('.user-mail'))
            // this.template.querySelectorAll('.user-mail')[0].value = data.Email;
            // this.template.querySelectorAll('.user-name')[0].value = data.Name;
            // this.template.querySelectorAll('.user-phone')[0].value = data.Phone?data.Phone: ' ';
            
        }
        if(error){
            console.error(error);
        }

    }

    handleFileSelect(event) {
        try {
            var files = event.target.files;
            event.target.disabled = true;
            var file = files[0];
            this.template.querySelectorAll('.input-file')[0].disabled= false;
        } catch (error) {
            console.log(error)
        }
        
        if(event.target.files.length > 0) {
            try {
                
            
            var base64changed =this.fileListToBase64(event.target.files);
            let self = this;   
            base64changed.then(function(result) {
                   // self.uploadedFiles = result;
                    for(let i = 0;i<result.length;i++){
                        let file = {};
                        
                        file.name = result[i].split(',')[0]
                        file.base64 = result[i].split(',')[1]
                        self.uploadedFiles.push(file);
                    }
               
            });
            
        } catch (error) {
                console.log(error)
        }
    }
    }

    async fileListToBase64(fileList) {
        // create function which return resolved promise
        // with data:base64 string
        try {
            
       
        function getBase64(file) {
          const reader = new FileReader()
          return new Promise(resolve => {
            reader.onload = ev => {
              resolve(file.name+','+ev.target.result.split(',')[1])
            }
            reader.readAsDataURL(file)
          })
        }
        // here will be array of promisified functions
        const promises = []
      
        // loop through fileList with for loop
        for (let i = 0; i < fileList.length; i++) {
          promises.push(getBase64(fileList[i]))
        }
      
        // array with base64 strings
        return await Promise.all(promises)
    } catch (error) {
         console.log(error)   
    }
    }

    submitHelp(){
        this.showSpinner = true;
        this.template.querySelectorAll('.user-name')[0].value;
        let userData ={};
        userData.userName = this.template.querySelectorAll('.user-name')[0].value;
        userData.theme = this.template.querySelectorAll('.user-theme')[0].value;
        userData.description = this.template.querySelectorAll('.user-description')[0].value;
        userData.phoneNumber = this.template.querySelectorAll('.user-phone')[0].value;
        userData.email = this.template.querySelectorAll('.user-mail')[0].value;

        this.checkUserPhoneNumber(userData.phoneNumber);
        if(this.validateTheme(userData.theme)){  
            try {
                uploadFile({ files:JSON.stringify(this.uploadedFiles), recordId:'5000E00000HpupjQAB',caseData:JSON.stringify(userData) }).then(result=>{
                    this.fileData = null
                    this.template.querySelector('c-custom-toast-lwc').showToast('success', this.labels.Suport_ticket_created);
                    this.showSpinner = false;
                }).catch(err=>{
                    console.log(err)
                    this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.contact_sys_admin);
                    this.showSpinner = false;
                }).finally(() => {
                    
                })
            } catch (error2) {
                console.log(error2)
                this.showSpinner = false;
            }
        } else {
            this.showSpinner = false;
            this.template.querySelector('c-custom-toast-lwc').showToast('warning', this.labels.theme_for_suport_ticket);    
        }
        window.location.reload();
    }

    checkUserPhoneNumber(phoneInput){
        if(phoneInput!=this.userData.Phone){
            try {
                setUserPhone({phone:phoneInput }).then(result=>{
                }).catch(err=>{
                    console.log(err)
                }).finally(() => {
                    
                })
            } catch (error2) {
                console.log(error2)
            }
        }
    }

    validateTheme(theme){
        if(theme){
            return true;
        } else {
            return false;
        }
    }

    deleteFromList(event){
        let indexValue = event.target.value
        this.uploadedFiles.splice(indexValue,1)
    }

    validateInputs(event){
    }

    validateEmail(event){      
        let inputData = event.target.value; 
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        
        if(!regExpEmailformat.test(inputData)){
            this.template.querySelectorAll('.mail')[0].classList.add("bottom-border-red");
        } else{
            this.template.querySelectorAll('.mail')[0].classList.remove("bottom-border-red");
        }
        
    }

    closeModal() {
        this.isModalOpen = false;
        
    }

    @api
    modalContainer;

    openModal(event) {
        this.isModalOpen = true;       
        this.selectedCaseid = event.target.dataset.id
        setTimeout(() => {
            this.modalContainer = this.template.querySelector('.slds-modal__container');
        }, 2000)
    }
}