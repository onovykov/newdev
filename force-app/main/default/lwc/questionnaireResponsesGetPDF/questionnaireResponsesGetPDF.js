import { LightningElement, api } from "lwc";
import getQuestionnaireId from '@salesforce/apex/QuestionnaireController.getQuestionnaireId';
import getQuestionnaireData from '@salesforce/apex/QuestionnaireController.getQuestionnaireData';
import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import GOLOS_FONT from '@salesforce/resourceUrl/Golos';

export default class getQuestionnaireResponsesPDF extends LightningElement {
    @api recordId; // This property will store the record Id
    questionnaireId;
    questionnaireSection;
    questionnaireName;
    questionnaireLogo;
    questionnaireResponse = {};
    jsPDFLoaded = false;
    jsPDFInstance = null;
    autoTableInstance = null;
    // renderedCallback(){
    //     this.invoker();
    // }

    renderedCallback() {
        if (this.jsPDFLoaded) {
            return;
        }
        this.jsPDFLoaded = true;
    
        Promise.all([
            loadScript(this, JSPDF),
            loadScript(this, autoTable),
        ]).then(() => {
            if (window.jspdf && window.jspdf.jsPDF) {
                const { jsPDF } = window.jspdf;
                const testDoc = new jsPDF();
                if (typeof testDoc.autoTable !== 'function') {
                    console.warn('autoTable not initialized. Trying manual assignment.');
                    if (window.autoTable && typeof window.autoTable === 'function') {
                        jsPDF.API.autoTable = window.autoTable;
                    }
                }
            }
        }).catch(error => {
            console.error('Error loading jsPDF or autoTable:', error);
        });
    }
    
    @api invoke() {
        getQuestionnaireId({ responseId: this.recordId })
            .then(result => {
                this.questionnaireId = result;
    
                getQuestionnaireData({ questionnaireId: this.questionnaireId, responseId: this.recordId })
                    .then(result => {
                        if (result) {
                            let newData = JSON.parse(JSON.stringify(result));
                            console.log('newData',newData);
                            this.questionnaireSections = [...newData.questionnaireSections].sort((a, b) => a.order - b.order);
                            this.questionnaireName = this.questionnaireSections[0].questionnaireName;
                            this.questionnaireResponse = newData.questionnaireResponse;
                            this.questionnaireLogo = IMAGES + '/' + this.questionnaireSections[0].logoFileName;
                            this.questionnaireSections = this.questionnaireSections.map(section => {
                                section.questions = section.questions.map(question => ({
                                    ...question,
                                    Id: question.questionId,
                                    options: question.availableValues
                                        ? question.availableValues.split(',').map(value => ({ label: value, value: value }))
                                        : [],
                                    isPicklist: question.type === 'Picklist',
                                    isText: question.type === 'Text',
                                    isTextArea: question.type === 'TextArea',
                                    isCheckboxGroup: question.type === 'Checkbox Group',
                                    isRadioGroup: question.type === 'Radio',
                                    initialValue: question.currentUserAnswerId && question.currentUserAnswerId.Value__c ? question.currentUserAnswerId.Value__c : null,
                                }));
                                // console.log('section', section)
                
                                return section;
                            });
                            this.downloadPDF();
                        }
                    })
                    .catch(error => {
                        console.error("Error calling getQuestionnaireData:", error);
                    });
            })
            .catch(error => {
                console.error("Error calling getQuestionnaireId:", error);
            });
    }    
    
    async downloadPDF() {
        try {
            if (!window.jspdf || !window.jspdf.jsPDF) {
                return;
            }

            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();
            doc.addFont(GOLOS_FONT, "Golos", "normal");
            doc.setFont("Golos");
            doc.setFontSize(9);
    
            // Fetch the logo image as a Blob
            const response = await fetch(this.questionnaireLogo);
            const blob = await response.blob();
    
            // Create a URL from the blob for image loading
            const imageUrl = URL.createObjectURL(blob);
    
            // Load the image for conversion to JPEG
            const image = new Image();
            image.onload = async () => {
                // Create canvas and draw image on it to convert to JPEG
                const canvas = document.createElement('canvas');
                canvas.width = image.width;
                canvas.height = image.height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(image, 0, 0);
    
                // Convert canvas to JPEG URL
                const jpegUrl = canvas.toDataURL('image/jpeg');
                if(this.questionnaireSections[0].logoFileName == 'QuestionnaiteInterpipeSteel.png'){
                    doc.addImage(jpegUrl, 'JPEG', 10, 10, 30, 26);
                }else if(this.questionnaireSections[0].logoFileName == 'QuestionnaireKLWLogo.jpeg'){
                    doc.addImage(jpegUrl, 'JPEG', 10, 10, 18, 26.4);
                }else {
                    doc.addImage(jpegUrl, 'JPEG', 10, 10, 23.4, 26);
                }

                if (this.questionnaireName) {
                    // doc.text(this.questionnaireName, 140, 32);
                    const splitQuestionnaireName = doc.splitTextToSize(this.questionnaireName, 70);
                    if(splitQuestionnaireName.length === 1){
                        doc.text(130, 32, splitQuestionnaireName);
                    }else if(splitQuestionnaireName.length === 2){
                        doc.text(130, 30, splitQuestionnaireName);
                    }else {
                        doc.text(130, 26, splitQuestionnaireName);
                    }
                }
                doc.setLineWidth(0.5);
                doc.line(10, 35, 200, 35);
                const columns = ['Section', 'Questions', 'Answers'];
                const rows = [];
                this.questionnaireSections.forEach(section => {
                    if(section.isVisible) {
                        section.questions.forEach(question => {
                            if(question.isVisible){
                                let response = question.initialValue || '';
                                if (question.isCheckboxGroup) {
                                    response = response.split(',').join('\n');
                                }
                                rows.push([question.sectionName, question.questionValue, response]);
                            }
                        });
                    }
                });
                console.log('rows', rows);
                if (doc.autoTable) {
                    console.log('inside');
                    doc.autoTable({
                        head: [columns],
                        body: rows,
                        startY: 40,
                        styles: { font: "Golos" },
                        columnStyles: {
                            0: { cellWidth: 40 },
                            1: { cellWidth: 90 },
                            2: { cellWidth: 50 },
                        }
                    });
                }
    
                // Assuming addCompletionDate is a method you've defined to add the completion date
                this.addCompletionDate(doc);
    
                // Save or send the PDF as needed
                const filename = this.questionnaireName + '.pdf';
                doc.save(filename); // Save the PDF locally
            };
            image.src = imageUrl;
        } catch (error) {
            console.error('Error generating PDF:', error);
        }
    }

    addCompletionDate(doc) {
        let dateOfCompletionText;
        let completedDateTimeStr = '';
        if (this.questionnaireResponse.LastModifiedDate) {
            completedDateTimeStr = new Date(this.questionnaireResponse.LastModifiedDate).toLocaleDateString();
        }
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                dateOfCompletionText = 'Дата заповнення: ' + completedDateTimeStr;
                break;
            case 'Russian':
                dateOfCompletionText = 'Дата заполнения: ' + completedDateTimeStr;
                break;
            default:
                dateOfCompletionText = 'Date of completion: ' + completedDateTimeStr;
        }
        doc.text(dateOfCompletionText, 10, 280);
    }
}