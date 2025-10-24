import { LightningElement, track, wire } from 'lwc';
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import { updateRecord } from 'lightning/uiRecordApi';
import ENQUIRY from '@salesforce/label/c.Enquiries';
import ORDERS from '@salesforce/label/c.Orders';
import SUPPORT from '@salesforce/label/c.Support';
import CLAIMS from '@salesforce/label/c.Claims';
import FILES from '@salesforce/label/c.Files';
import DEALINGSTATUS from '@salesforce/label/c.Dealing_Status';
import want_to_exit from '@salesforce/label/c.want_to_exit';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import About_Interpipe from '@salesforce/label/c.About_Interpipe';
import Production from '@salesforce/label/c.Production';
import Certificates from '@salesforce/label/c.Certificates';
import Contacts from '@salesforce/label/c.Contacts';
import FINBALANCE from '@salesforce/label/c.Financial_Balance';
import Production_online from '@salesforce/label/c.Production_online';	



import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';
import getBusinessDivision from '@salesforce/apex/UserUtils.getBusinessDivision';
import getUserImg from '@salesforce/apex/UserUtils.getUserImg';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";



export default class SiteHeader extends NavigationMixin(LightningElement) {
    siteLogo;
    siteLogoUA = IMAGES + '/logo.png.png';
    siteLogoEN = IMAGES + '/interpipeLogoEN.png';
    siteLogoRU = IMAGES + '/interpipeLogoRU.png';
    siteLogoKLW = IMAGES + '/LogoKLW.png';
    burgerMenu = IMAGES + '/burger-menu.png';
    EN = IMAGES + '/EN.png';
    FR = IMAGES + '/FR.png';
    DE = IMAGES + '/de.png';
    PL = IMAGES + '/PL.png';
    UA = IMAGES + '/ua.png';
    RU = IMAGES + '/ru.png';
    logout = IMAGES + '/loguot.png'
    showSwitch = false;
    CurrentUserImgUrl;
    CurrentUserLanguage;
    isProdOnlineVisible;

    @track isBurgerMenuActive = false;

    
     
    @track userInfo = {};
    @track modalQuit = false;
    @track modalText;
    @track modalQuitBoolean = false;
    userId = USER_ID;
    userData;
    @track languages = [
        //{name : 'PL', src : this.PL, value : 'pl'},
        {name : 'UA', src : this.UA, value : 'uk'},
        {name : 'EN', src : this.EN, value : 'en_US'},
        {name : 'RU', src : this.RU, value : 'ru'}
    ];
    
    enq = ENQUIRY;
    ord = ORDERS;
    sup = SUPPORT;
    cla = CLAIMS;
    fil = FILES;
    del = DEALINGSTATUS;
    fin = FINBALANCE;
    labels = {
        want_to_exit,
        Yes,
        No,
        About_Interpipe,
        Production,
        Certificates,
        Contacts,
        Production_online
    }
    

    @track selectedLanguage;
    connectedCallback(){
        getUserLanguage().then(result => {
            this.CurrentUserLanguage = result;
            if(result == 'uk'){
                this.siteLogo = this.siteLogoUA; 
            }else if(result =='ru'){
                this.siteLogo = this.siteLogoRU;
            }else{
                this.siteLogo = this.siteLogoEN;
            }
            let langs = this.languages;
            let language = {name : 'EN', src : this.EN, value : 'en_US'};
            let userLang = result;
            langs.forEach(item=>{
                //console.log(item.value,' ' , userLang);
                if(item.value == userLang){
                    language = item;
    
                }
            });
            this.selectedLanguage = language;
            langs = langs.filter(item=>{
                return item.name != this.selectedLanguage.name;
            });
            this.languages = langs;
    
        }).catch(error =>{
            console.log(error);
        })

        getBusinessDivision().then(businessDivision => {
            this.isProdOnlineVisible = businessDivision == 'Railway' ? false : true;
            if(businessDivision == 'Railway') {
                this.siteLogo = this.siteLogoKLW;
            }
        })
    }
   handleCloseSwitch(){
    this.showSwitch = false;
   }


   
    
    handleClick() {
        this.showSwitch = !this.showSwitch;
        
    }
    handleLangSelect(event){
        event.stopPropagation();
        let langs = this.languages;
        langs.push(this.selectedLanguage);
        this.selectedLanguage = {name : event.currentTarget.dataset.langName, src : event.currentTarget.dataset.langSrc, value : event.currentTarget.dataset.langValue}
        langs = langs.filter(item=>{
            return item.name != this.selectedLanguage.name;
        }) 
        this.languages = langs;
        this.showSwitch = false; 
        const fields = {};
            fields['Id'] = USER_ID;
            fields['LanguageLocaleKey'] = this.selectedLanguage.value;
            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    window.location.reload();
                })
                .catch(error => {console.error(error)});
    }

    @wire(getRecord,{recordId:'$userId', layoutTypes:['Full']}) handleAcc(result){
        const {error, data } = result;
        if(data){
            //console.log(data);
            let userValues = {
                firstName : data.fields.FirstName.value,
                lastName : data.fields.LastName.value
            }
            this.userInfo = userValues
        }
        if(error){
            console.error(error);
        }
    }

    @wire(getUserImg,{}) handleUserImg(result){
        const {error, data } = result;
        if(data){
            this.CurrentUserImgUrl = data;

        }
        if(error){
            console.error(error);
        }
    }


    openExitModal(event){
        //console.log('!@#!@#!@##!@#' , this.labels)
        try{
            this.modalText = this.labels.want_to_exit;
            this.modalQuit = true;
            this.modalQuitBoolean = true;
        } catch (e) {
            console.log(e);
        //console.log(event.target.dataset.id);
        }
    }



    cleanModalBoolean(){
        this.modalDeleteFile = false;
        this.modalQuitBoolean = false;
    }   

    closeModal(){
        this.modalQuit = false;
    }
    confirmModal(){
        const url = this.logoutLink
        window.location = url;
    }
    
    get logoutLink() {
        const sitePrefix = basePath.replace(/\/s$/i, ""); // site prefix is the site base path without the trailing "/s"
        //console.log('sitePrefix', sitePrefix)
        return sitePrefix + "/secur/logout.jsp";
        
    }



    handleMenuSelect(event){

        var selectedVal = event.detail.value;
        //console.log( 'Selected button is ',  this.CurrentUserLanguage );
        if(this.CurrentUserLanguage == 'uk'){
            if(selectedVal == 'About Interpipe'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/'
                    }
                });
             }
             if(selectedVal == 'Production'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/production/'
                    }
                });
             }
             if(selectedVal == 'Certificates'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/clients/certificates'
                    }
                });
             }
             if(selectedVal == 'Contacts'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/contacts/contacts/#s9'
                    }
                });
             }
        }else{
            if(selectedVal == 'About Interpipe'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/en/'
                    }
                });
             }
             if(selectedVal == 'Production'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/en/production/'
                    }
                });
             }
             if(selectedVal == 'Certificates'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/en/clients/certificates'
                    }
                });
             }
             if(selectedVal == 'Contacts'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'https://interpipe.biz/en/contacts/contacts/#s9'
                    }
                });
             }
        }
        if(selectedVal == 'IP-Cameras'){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/NewCustomerRoom/s/ip-cameras'
                }
            });
         }

    }
    handleBurgerMenuClick() {
        this.isBurgerMenuActive = !this.isBurgerMenuActive;
        const burgerMenu = this.template.querySelector('.burger-menu');
        const burgerMenuButton = this.template.querySelector('.burger-menu-button');
        const burgerMenuContent = this.template.querySelector('.burger-menu-content');
        burgerMenu.classList.toggle('active');
        burgerMenuButton.classList.toggle('active');
        burgerMenuContent.classList.toggle('active');
      }

}