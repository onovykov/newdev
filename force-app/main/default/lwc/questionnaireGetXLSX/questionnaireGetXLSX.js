import { LightningElement, api } from "lwc";
import getQuestionnaireId from '@salesforce/apex/QuestionnaireController.getQuestionnaireId';
import getQuestionnaireDataForXLSX  from '@salesforce/apex/QuestionnaireController.getQuestionnaireDataForXLSX';
import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import XLSX from '@salesforce/resourceUrl/XLSX';


export default class QuestionnaireGetPDF extends LightningElement {
    @api recordId; // This property will store the record Id
    questionnaireId;
    questionnaireSection;
    questionnaireName;
    questionnaireLogo;
    questionnaireResponses = [];

    renderedCallback() {
        Promise.all([
            loadScript(this, JSPDF),
            loadScript(this, autoTable),
            loadScript(this, XLSX)
        ]).then(() => {
            console.log('jsPDF loaded successfully');
        }).catch(error => {
            console.error('Error loading jsPDF:', error);
        });
    }
    @api invoke() {
        console.log("Record Id:", this.recordId); // Access the record Id here

        getQuestionnaireDataForXLSX ({ questionnaireId: this.recordId})
                    .then(result =>{
                        console.log(result);
                        this.questionnaireResponses = result;
                            this.downloadXLSX();
                    })
                    .catch(error => {
                        // Handle any errors that occur during the Apex call
                        console.error("Error calling getQuestionnaireDataForXLSX:", error);
                    });
    }
    downloadXLSX() {
        // Import the XLSX library
        const XLSX = window.XLSX;
    // Determine unique questions
        const uniqueQuestions = [...new Set(this.questionnaireResponses.map(item => item.questionEnglish))];

        let consolidatedData = {};
        console.log('questionnaireResponses ',this.questionnaireResponses)
        // Group by respondent's email and populate the answers
        this.questionnaireResponses.forEach(response => {
            const email = response.respondentEmail;
            if (!consolidatedData[email]) {
                consolidatedData[email] = {
                    'Respondent': email,
                    'Questionnaire Response id': response.questionnaireResponseId,
                    'Market Segment': response.marketSegment,
                    'Response Status': response.status
                };
            }
            consolidatedData[email][response.sectionAndQuestionName] = response.value;
        });
        const dataForExcel = Object.values(consolidatedData);
        const sheet1 = XLSX.utils.json_to_sheet(dataForExcel);
        this.autoColumnWidth(sheet1);
        this.setColorForColumns(sheet1, ['Respondent', 'Questionnaire Response id', 'Market Segment', 'Response Status']); // A, B, C, D відповідають колонкам, які ви хочете забарвити в сірий колір
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, sheet1, 'All Answers');
        
        // Save the workbook as an XLSX file
        XLSX.writeFile(workbook, 'InterpipeQuestionnaireAnswers.xlsx');
    }
    autoColumnWidth(worksheet) {
        let colWidth = [];
        for (let key in worksheet) {
            if (worksheet.hasOwnProperty(key)) {
                let col = key.substring(0, 1);
                let val = worksheet[key].v;
                if (!colWidth[col]) {
                    colWidth[col] = 0;
                }
                if (val && colWidth[col] < val.toString().length) {
                    colWidth[col] = val.toString().length;
                }
            }
        }
        
        let MIN_WIDTH = 15;
        worksheet['!cols'] = [];
        for (let key in colWidth) {
            let width = colWidth[key] + 2; // Add some padding
            if (width < MIN_WIDTH) width = MIN_WIDTH;
            worksheet['!cols'].push({ width: width });
        }
    }
    setColorForColumns(worksheet, columns) {
        const GREY_BG = { patternType: 'solid', fgColor: 'D3D3D3', bgColor: 'D3D3D3' }; // Код D3D3D3 відповідає сірому кольору
    
        for (let cell in worksheet) {
            if (cell[0] >= 'A' && cell[0] <= 'Z' && columns.includes(cell[0])) { // Перевіряємо, чи входить колонка у заданий список
                if (!worksheet[cell].s) { 
                    worksheet[cell].s = {};
                }
                worksheet[cell].s.fill = GREY_BG;
            }
        }
    }
    
}