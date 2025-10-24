import { LightningElement,api,wire,track } from 'lwc';
import GetResourceURL from '@salesforce/apex/DisplayImageController.getResourceURL'
import NEWS from '@salesforce/label/c.News';
import READ from '@salesforce/label/c.Read';
import MORE from '@salesforce/label/c.More';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';

export default class SiteNews extends LightningElement {
    finalmainHeader
    finalmainDescription
    finalmainLink
    finalItem1Header
    finalItem1Link
    finalItem2Header
    finalItem2Link
    finalItem3Header
    finalItem3Link
    
    @api Image1 ='';
    @track img1URL;

    @api mainDate;
    @api mainHeader;
    @api mainDescription;
    @api mainLink;
    @api mainHeaderUA;
    @api mainDescriptionUA;
    @api mainLinkUA;
    @api mainHeaderRU;
    @api mainDescriptionRU;
    @api mainLinkRU;
    

    @api Item1Date;
    @api Item1Header;
    @api Item1Link;

    @api Item1HeaderUA;
    @api Item1LinkUA;

    @api Item1HeaderRU;
    @api Item1LinkRU;

    @api Item2Date;
    @api Item2Header;
    @api Item2Link;

    @api Item2HeaderUA;
    @api Item2LinkUA;

    @api Item2HeaderRU;
    @api Item2LinkRU;
    
    @api Item3Date;
    @api Item3Header;
    @api Item3Link;
    
    @api Item3HeaderUA;
    @api Item3LinkUA;

    @api Item3HeaderRU;
    @api Item3LinkRU;

    more = MORE;
    news = NEWS;
    read = READ;
    
    connectedCallback(){
        getUserLanguage().then(result =>{
            console.log('result---------> ' , result);
            if(result == 'uk'){
                console.log('@@@@@@ UKR ');
                this.finalmainHeader = this.mainHeaderUA;
                this.finalmainDescription = this.mainDescriptionUA;
                this.finalmainLink = this.mainLinkUA;

                this.finalItem1Header = this.Item1HeaderUA;
                this.finalItem1Link = this.Item1LinkUA;
                
                this.finalItem2Header = this.Item2HeaderUA;
                this.finalItem2Link = this.Item2LinkUA;
                
                this.finalItem3Header = this.Item3HeaderUA;
                this.finalItem3Link = this.Item3LinkUA;
                
            }else if(result == 'ru'){
                this.finalmainHeader = this.mainHeaderRU;
                this.finalmainDescription = this.mainDescriptionRU;
                this.finalmainLink = this.mainLinkRU;

                this.finalItem1Header = this.Item1HeaderRU;
                this.finalItem1Link = this.Item1LinkRU;
                
                this.finalItem2Header = this.Item2HeaderRU;
                this.finalItem2Link = this.Item2LinkRU;
                
                this.finalItem3Header = this.Item3HeaderRU;
                this.finalItem3Link = this.Item3LinkRU;
            }
            else {
                console.log('@@@@@ ENG ');
                this.finalmainHeader = this.mainHeader;
                this.finalmainDescription = this.mainDescription;
                this.finalmainLink = this.mainLink;

                this.finalItem1Header = this.Item1Header;
                this.finalItem1Link = this.Item1Link;
                
                this.finalItem2Header = this.Item2Header;
                this.finalItem2Link = this.Item2Link;
                
                this.finalItem3Header = this.Item3Header;
                this.finalItem3Link = this.Item3Link;
            }
        })
    }

    @wire(GetResourceURL,{resourceName : '$Image1'}) weire({data,error}){
        if (data) {
            console.log('DATA---------------------------------------------> ', data);
            let slides = [];
            data.forEach(res=>{

                slides.push(
                    {['Image1'] : res}
                );
            });
            console.log(' slides    ', slides);
            this.img1URL = slides[0].Image1;

            console.log(this.img1URL);
            } 
            else if (error) {
                console.log(error);
            }
            }
    }