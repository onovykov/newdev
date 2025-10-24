public with sharing class AttachPdfExtension {

	private final sObject mysObject;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public AttachPdfExtension(ApexPages.StandardController stdController) {
        System.debug(((sObject)stdController.getRecord()).Id);
        this.mysObject = (sObject)stdController.getRecord();
    }

    public PageReference attachPDF() {
        //generate and attach the PDF document
        System.debug('attach ');
        PageReference pdfPage = Page.QuotePDFPage;
        pdfPage.getParameters().put('Id', mysObject.Id);

        QuoteDocument qd = new QuoteDocument();
		if (Test.isRunningTest()){
			qd.document = Blob.valueOf('Test is running!');
		} else {
			qd.document = pdfPage.getContentAsPDF();
		}
        
        qd.quoteId = mysObject.Id;
        insert qd;
            
        System.debug('after insert ');

        PageReference pageWhereWeWantToGo = Page.QuotePDFPage;
        pageWhereWeWantToGo.getParameters().put('Id', mysObject.Id);
        pageWhereWeWantToGo.setRedirect(true); 
        return pageWhereWeWantToGo;
    }

}