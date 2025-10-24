import { LightningElement,api,wire,track } from 'lwc';
import GetResourceURL from '@salesforce/apex/DisplayImageController.getResourceURL'
import DIVISIONS from '@salesforce/label/c.Divisions';
import MORE from '@salesforce/label/c.More';
import getUserLanguage from '@salesforce/apex/UserUtils.getUserLanguage';

export default class SiteDivision extends LightningElement {
    FinalLabel1;
    FinalLabel2;
    FinalLabel3;
    
    FinalText1;
    FinalText2;
    FinalText3;

    FinalLink1;
    FinalLink2;
    FinalLink3;

    @api Label1;
    @api Label2;
    @api Label3;

    @api Label1UA;
    @api Label2UA;
    @api Label3UA;

    
    @api Label1RU;
    @api Label2RU;
    @api Label3RU;

    @api Text1;
    @api Text2;
    @api Text3;

    @api Text1UA;
    @api Text2UA;
    @api Text3UA;

    @api Text1RU;
    @api Text2RU;
    @api Text3RU;

    @api Item1LinkUA
    @api Item2LinkUA
    @api Item3LinkUA

    @api Item1LinkRU
    @api Item2LinkRU
    @api Item3LinkRU
    
    @api Item1Link
    @api Item2Link
    @api Item3Link

    @api Image1 ='';
    @track img1URL;
    @track img2URL;
    @track img3URL;
    div = DIVISIONS;
    mor = MORE;
    @track streamUrl = 'https://youtu.be/aR_VAGEnnjA'

    connectedCallback(){
        getUserLanguage().then(result =>{
            if(result == 'uk'){
                this.FinalLabel1 = this.Label1UA;
                this.FinalLabel2 = this.Label2UA;
                this.FinalLabel3 = this.Label3UA;
                this.FinalText1 = this.Text1UA;
                this.FinalText2 = this.Text2UA;
                this.FinalText3 = this.Text3UA;
                this.FinalLink1 = this.Item1LinkUA;
                this.FinalLink2 = this.Item2LinkUA;
                this.FinalLink3 = this.Item3LinkUA;
            }else if(result == 'ru'){
                this.FinalLabel1 = this.Label1RU;
                this.FinalLabel2 = this.Label2RU;
                this.FinalLabel3 = this.Label3RU;
                this.FinalText1 = this.Text1RU;
                this.FinalText2 = this.Text2RU;
                this.FinalText3 = this.Text3RU;
                this.FinalLink1 = this.Item1LinkRU;
                this.FinalLink2 = this.Item2LinkRU;
                this.FinalLink3 = this.Item3LinkRU;
            }else{
                this.FinalLabel1 = this.Label1;
                this.FinalLabel2 = this.Label2;
                this.FinalLabel3 = this.Label3;
                this.FinalText1 = this.Text1;
                this.FinalText2 = this.Text2;
                this.FinalText3 = this.Text3;
                this.FinalLink1 = this.Item1Link;
                this.FinalLink2 = this.Item2Link;
                this.FinalLink3 = this.Item3Link;
            }
        })
    }
    

    // renderedCallback() {
    //     Promise.all([
    //       // Import the necessary libraries or scripts provided by your live streaming platform
    //       // Example: importScript('/resource/yourLiveStreamingLibraries')
    //     ])
    //       .then(() => {
    //         // Initialize the live video player
    //         // Replace 'yourPlayerInitializationFunction' with the actual function or method for initializing the player
    //         yourPlayerInitializationFunction(this.template.querySelector('.live-video-player'), this.streamUrl);
    //       })
    //       .catch(error => {
    //         console.error('Error loading live video player libraries:', error);
    //       });
    //   }

    @wire(GetResourceURL,{resourceName : '$Image1'}) weire({data,error}){
        if (data) {
            let slides = [];
            data.forEach(res=>{

                slides.push(
                    {['Image1'] : res}
                );
            });
            // console.log(' slides    ', slides);
            this.img1URL = slides[0].Image1;
            this.img2URL =  slides[1].Image1;
            this.img3URL = slides[2].Image1;
            } 
            else if (error) {
                console.log(error);
            }
            }
    
    
}