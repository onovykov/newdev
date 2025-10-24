import { LightningElement} from 'lwc';
import NEWS from '@salesforce/label/c.News';
import READ from '@salesforce/label/c.Read';
import MORE from '@salesforce/label/c.More';
import getNews from '@salesforce/apex/SiteNewsController.getNews';

export default class SiteNewsUpdated extends LightningElement {
    finalmainHeader
    finalmainDescription
    finalmainLink
    finalItem1Header
    finalItem1Link
    finalItem2Header
    finalItem2Link
    finalItem3Header
    finalItem3Link
    mainDate
    Item1Date
    Item2Date
    Item3Date
    img1URL;

    more = MORE;
    news = NEWS;
    read = READ;
    
    connectedCallback() {
        getNews().then(result => {
            console.log('result---------> ', JSON.stringify(result, null, 2));
            if (result) {
                this.img1URL = result.mainImage;
                this.mainDate = result.mainDate;
                this.finalmainHeader = result.mainHeader;
                this.finalmainDescription = result.mainDescription;
                this.finalmainLink = result.mainLink;
    
                this.Item1Date = result.Item1Date;
                this.finalItem1Header = result.Item1Header;
                this.finalItem1Link = result.Item1Link;
    
                this.Item2Date = result.Item2Date;
                this.finalItem2Header = result.Item2Header;
                this.finalItem2Link = result.Item2Link;
    
                this.Item3Date = result.Item3Date;
                this.finalItem3Header = result.Item3Header;
                this.finalItem3Link = result.Item3Link;
            }
        });
    }
}