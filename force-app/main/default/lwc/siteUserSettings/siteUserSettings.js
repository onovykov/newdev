import { LightningElement ,track,wire,api} from 'lwc';
//import getTimeZone from '@salesforce/apex/UserSettingsController.getTimeZone';
//import getLocale from '@salesforce/apex/UserSettingsController.getLocale';
//import getLanguage from '@salesforce/apex/UserSettingsController.getLanguage';
import getSettingsData from '@salesforce/apex/UserSettingsController.getSettingsData';
import setNewPassword from '@salesforce/apex/UserSettingsController.setNewPassword';
import { getRecord } from 'lightning/uiRecordApi';
import changePassword from '@salesforce/apex/UserUtils.changePassword';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import userId from '@salesforce/user/Id';
import basePath from "@salesforce/community/basePath";

import {NavigationMixin} from 'lightning/navigation';
import Company_name from '@salesforce/label/c.Company_name';
import Mobile_phone from '@salesforce/label/c.Mobile_phone';
import phone from '@salesforce/label/c.Phone';
import About_me	 from '@salesforce/label/c.About_me';
import Email from '@salesforce/label/c.Email';
import Account from '@salesforce/label/c.Account';
import Location from '@salesforce/label/c.Location';

import First_Name from '@salesforce/label/c.First_Name';
import Last_Name from '@salesforce/label/c.Last_Name';
import Time_zone from '@salesforce/label/c.Time_zone';
import Language from '@salesforce/label/c.Language';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import Reset_Password from '@salesforce/label/c.Reset_Password';
import Profile from '@salesforce/label/c.Profile';
import password_change_link from '@salesforce/label/c.password_change_link';
import password_change_link2 from '@salesforce/label/c.password_change_link2';
import Success from '@salesforce/label/c.Success';
import Changes_saved from '@salesforce/label/c.Changes_saved';
import reset_password_question from '@salesforce/label/c.reset_password_question';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import Settings from '@salesforce/label/c.Settings';




export default class SiteUserSettings extends LightningElement {

    @track timeZoneMap;
    @track timeZoneArr = [];

    @track timeLocalMap;
    @track timeLocaleArr = [];

    @track timeLanguageMap;
    @track timeLanguageArr = [];

    @track userData;
    @track userInfo = {};
    userId = userId;
    selectedLanguage;
    selectedLocale;
    selectedTimeZone;
    isLoading = false;
    isChanged = false;
    @track modalText
    @track modalResetPassword

    labels = {
        Company_name,
        Mobile_phone,
        phone,
        About_me,
        Email,
        Account,
        Location,
        First_Name,
        Last_Name,
        Time_zone,
        Language,
        Save,
        Cancel,
        Reset_Password,
        Profile,
        Settings,
        password_change_link,
        password_change_link2,
        Success,
        Changes_saved,
        reset_password_question,
        Yes,
        No
    }

    
    @wire(getRecord,{recordId:'$userId', layoutTypes:['Full']}) handleUser(result){
       
        const {error, data } = result;
        if(data){
            // console.log(data);

            let userValues = {
                firstName : data.fields.FirstName.value,
                lastName : data.fields.LastName.value,
                companyName :  data.fields.CompanyName.value,
                email :  data.fields.Email__c.value,
                phone :  data.fields.Phone__c.value,
                mobilePhone :  data.fields.Mobile_Phone__c.value,
                aboutMe : data.fields.AboutMe.value
            }

            //this.template.querySelectorAll('.user-mail')[0].value = userValues.email;
            this.template.querySelectorAll('.user-fname')[0].value = userValues.firstName;
            this.template.querySelectorAll('.user-lname')[0].value = userValues.lastName;
            this.template.querySelectorAll('.user-phone')[0].value = userValues.phone;
            this.template.querySelectorAll('.user-work-phone')[0].value = userValues.mobilePhone;
            this.template.querySelectorAll('.user-about-me')[0].value = userValues.aboutMe;


            this.userInfo = userValues
            
        }
        if(error){
            console.error(error);
        }
    }

    toggleSubtabs(event) {
        // console.log(event.target.dataset.id);
        this.switchTabName(event.target.dataset.id)                   
    }

    switchTabName(idAtrribute){
        this.template.querySelectorAll('.slds-tabs_default__item').forEach(function(data){
            if(data.querySelectorAll('a')[0].dataset.id == idAtrribute ){
                data.classList.add("slds-is-active")
            } else{
                data.classList.remove("slds-is-active");
            }
        })

        this.template.querySelectorAll('.slds-tabs_default__content').forEach(function(data){  
            // console.log('data', data.dataset.id);
            if(idAtrribute == data.dataset.id){
                try {
                    data.classList.add("slds-show");
                    data.classList.remove("slds-hide");
                } catch (error) {
                    console.log(error)
                }
            } else {
                try {
                    data.classList.remove("slds-show");
                    data.classList.add("slds-hide");
                } catch (error) {
                    console.log(error)
                }
                
            }
        })
    }

    showToastChangesSaved() {
            const event = new ShowToastEvent({
                title: this.labels.Success,
                message: this.labels.Changes_saved,
                variant: 'success',
                mode: 'sticky'
            });
            this.dispatchEvent(event);
    }
    showToastPasswordReset() {
        const event = new ShowToastEvent({
            title: this.labels.password_change_link,
            message: this.labels.password_change_link2,
            variant: 'success',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
}
    validateEmail(event){      
        let inputData = event.target.value; 
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        // console.log(regExpEmailformat.test(inputData));
        if(!regExpEmailformat.test(inputData)){
            // console.log(this.template.querySelectorAll('.mail')[0].classList)
            this.template.querySelectorAll('.mail')[0].classList.add("bottom-border-red");
        } else{
            this.template.querySelectorAll('.mail')[0].classList.remove("bottom-border-red");
        }
        
    }

    @wire(getSettingsData,{}) handleSettingsData(result){     
        const {error, data } = result;
        if(data){
            this.userData = data.User;
            this.timeLanguageMap = data.Language; 
            // console.log(Object.values(this.timeLanguageMap))        
            //this.timeLanguageArr = Object.keys( this.timeLanguageMap);
            
            Object.keys( this.timeLanguageMap).forEach(element=>{
                    let detail = {};
                    detail.var = element;
                    if(element == this.userData.Language){
                        detail.userValue = true;
                    }else{
                        detail.userValue = false;
                    }
                    this.timeLanguageArr.push(detail);
                });
                
            

            this.timeLocalMap = data.Locale;         
            //this.timeLocaleArr = Object.keys(this.timeLocalMap);

            Object.keys( this.timeLocalMap).forEach(element=>{
                let detail = {};
                detail.var = element;
                if(element == this.userData.Locale){
                    detail.userValue = true;
                }else{
                    detail.userValue = false;
                }
                this.timeLocaleArr.push(detail);
            });

            this.timeZoneMap = data.TimeZone;         
            //this.timeZoneArr = Object.keys( this.timeZoneMap);

            Object.keys( this.timeZoneMap).forEach(element=>{
                let detail = {};
                detail.var = element;
                if(element == this.userData.TimeZone){
                    detail.userValue = true;
                }else{
                    detail.userValue = false;
                }
                this.timeZoneArr.push(detail);
            });

            
        }
        if(error){
            console.error(error);
        }
    }

    handleLanguage(event){
       // console.log(event.currentTarget.value);  
       // console.log(this.timeLanguageMap[event.currentTarget.value]) 
        this.selectedLanguage = this.timeLanguageMap[event.currentTarget.value]
    }
    handleLocale(event){
        // console.log(event.currentTarget.value);  
        // console.log(this.timeLocalMap[event.currentTarget.value]) 
        this.selectedLocale = this.timeLocalMap[event.currentTarget.value]
    }
    handleTimaZone(event){
        // console.log(event.currentTarget.value);  
        // console.log(this.timeZoneMap[event.currentTarget.value]) 
        this.selectedTimeZone = this.timeZoneMap[event.currentTarget.value]
    }


    saveChanges(){
        this.isLoading = true
        let userData = {};
        userData.firstNameInput = this.template.querySelectorAll('.user-fname')[0].value;
        userData.lastNameInput = this.template.querySelectorAll('.user-lname')[0].value;
        //userData.emailInput = this.template.querySelectorAll('.user-mail')[0].value;
        userData.phoneInput = this.template.querySelectorAll('.user-work-phone')[0].value;
        userData.mobilePhoneInput = this.template.querySelectorAll('.user-phone')[0].value;
        userData.aboutMeInput = this.template.querySelectorAll('.user-about-me')[0].value;

        const fields = {};
        fields["Id"] = this.userId;
                
        if(userData.firstNameInput!=this.userInfo.firstName){
            fields["FirstName"] = userData.firstNameInput
            this.isChanged = true;
        }
        if(userData.lastNameInput!=this.userInfo.lastName){
            fields["LastName"] = userData.lastNameInput;
            this.isChanged = true;
        }
        if(userData.mobilePhoneInput!=this.userInfo.mobilePhone){
            fields["Phone"] = userData.mobilePhoneInput;
            this.isChanged = true;
        }
        if(userData.emailInput!=this.userInfo.email){
            fields["Email"] = userData.emailInput;
            this.isChanged = true;
        }
        if(userData.phoneInput!=this.userInfo.phone){
            fields["MobilePhone"] = userData.phoneInput;
            this.isChanged = true;
        }
        if(userData.aboutMeInput!=this.userInfo.aboutMe){
            fields["AboutMe"] = userData.aboutMeInput;
            this.isChanged = true;
        }
        if(this.selectedLanguage != null){
            fields['LanguageLocaleKey'] = this.selectedLanguage;
           // this.isChanged = true;
        }
        if(this.selectedLocale != null){
            fields['LocaleSidKey'] = this.selectedLocale;
            //this.isChanged = true;
        }
        if(this.selectedTimeZone != null){
            fields['TimeZoneSidKey'] = this.selectedTimeZone;
            //this.isChanged = true;
        }

        const recordInput = { fields };
        
        updateRecord(recordInput).then(result=>{
            console.log('RESULT',result);
            this.showToastChangesSaved();
            this.isLoading = false
        }).catch(err=>{
            console.log(err)
        })
        setTimeout(window.location.reload(), 2000);
        
    }
    
    openResetPasswordModal(event){
        try{
            this.modalText = this.labels.reset_password_question;
            this.modalResetPassword = true;
        } catch (e) {
            console.log(e);
        }
    }


    resetPassword(){
        changePassword({}).then(result=>{
            console.log(result);
            //this.showToastPasswordReset();
            const url = this.logoutLink
            window.location = url;
        })

    }
    closeModal(){
        this.modalResetPassword = false;
    }

    refreshComponent(event){
        eval("$A.get('e.force:refreshView').fire();");
    }
    get logoutLink() {
        const sitePrefix = basePath.replace(/\/s$/i, ""); // site prefix is the site base path without the trailing "/s"
        console.log('sitePrefix', sitePrefix)
        return sitePrefix + "/secur/logout.jsp";
        
    }
}