import { LightningElement, api, wire,track } from 'lwc';
import getQuestionnaireData from '@salesforce/apex/QuestionnaireController.getQuestionnaireData';
import createAnswer from '@salesforce/apex/QuestionnaireController.createAnswer';
import updateResponseStatus from '@salesforce/apex/QuestionnaireController.updateResponseStatus';
import updateResponseLanguage from '@salesforce/apex/QuestionnaireController.updateResponseLanguage';
import sendEmailWithAttachmentToRespondent from '@salesforce/apex/QuestionnaireResponseEmailer.sendEmailWithAttachmentToRespondent';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {loadScript} from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import autoTable from '@salesforce/resourceUrl/jsPDFAutotable'
import IMAGES from "@salesforce/resourceUrl/SiteImages";
import GOLOS_FONT from '@salesforce/resourceUrl/Golos';
import { loadStyle } from 'lightning/platformResourceLoader';
import CustomSLDS from '@salesforce/resourceUrl/CustomSLDS';


export default class QuestionnaireWrapper extends LightningElement {
    @api questionnaireId = '';
    @track questionnaireSections = [];
    @track questionnaireResponse = {};
    @track visibleSection = {};
    @track currentSectionNumber;
    @track maxSectionNumber;
    @track disablePrevious = true;
    @track progress = 0;
    @track questionDependencyMap = {};
    questionnaireName;
    questionnaireLogo;
    isClosed;
    companyName = 'Interpipe';
    timersByQuestions = {};
    EN = IMAGES + '/EN.png';
    UA = IMAGES + '/ua.png';
    RU = IMAGES + '/ru.png';
    currentPageReference = null; 
    urlStateParameters = null;
    questionnaireCompleted = false;
    @api responseId = null;
    urlLanguage = null;
    finishToggled = false;
    @track showStartPage = false; // To control the visibility of the start page
    selectedLanguage = ''; // To store the selected language
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
        //   console.log('this.urlStateParameters', this.urlStateParameters)
          this.setParametersBasedOnUrl();
       }
    }
    setParametersBasedOnUrl() {
        // Перевіряємо, чи існує recordId у urlStateParameters і очищуємо його від пробілів та %20
        if (this.urlStateParameters.recordId) {
            // Видаляємо %20 з початку та кінця строки, якщо вони є
            let cleanedRecordId = this.urlStateParameters.recordId.trim();
            cleanedRecordId = decodeURIComponent(cleanedRecordId); // Декодуємо URL-кодування
            cleanedRecordId = cleanedRecordId.replace(/^\s+|\s+$/g, ''); // Видаляємо пробіли з початку і кінця строки
            // console.log(cleanedRecordId);
            this.responseId = cleanedRecordId;
        } else {
            this.responseId = null;
        }
    
        this.urlLanguage = this.urlStateParameters.language || null;
    }
    @wire(getQuestionnaireData, { questionnaireId: '$questionnaireId', responseId: '$responseId' }) handleQuestions(result) {
        
        const { error, data } = result;
        if (data) {
            let newData = JSON.parse(JSON.stringify(data));
            // console.log('newData',newData);
            if(newData.isClosed) {
                this.isClosed = true;
            }
            if(newData.questionnaireResponse.Respondent_Language__c != null){
                this.showStartPage = false;
            }else{
                this.showStartPage = true;
            }
            this.questionnaireSections = newData.questionnaireSections;
            this.questionnaireResponse = newData.questionnaireResponse;
            this.questionnaireName = this.questionnaireSections[0].questionnaireName;
            this.questionnaireLogo = IMAGES + '/' + this.questionnaireSections[0].logoFileName;
            this.determineCompanyName();

            this.questionnaireSections.forEach(section => {
                section.questions.forEach(question => {
                    if (question.conrtolQuestionId) {
                        if (!this.questionDependencyMap[question.conrtolQuestionId]) {
                            this.questionDependencyMap[question.conrtolQuestionId] = [];
                        }
                        this.questionDependencyMap[question.conrtolQuestionId].push({
                            dependentQuestionId: question.questionId,
                            requiredValue: question.value,
                        });
                    }
                });
            });
            
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
                    // Set initial value from related answer
                    initialValue: question.currentUserAnswerId && question.currentUserAnswerId.Value__c ? question.currentUserAnswerId.Value__c : null,
                    isVisible: question.isVisible,
                    isRequiredAndVisible: question.isRequired && question.isVisible,
                }));
                console.log('section', section)

                return section;
            });

            if(this.questionnaireResponse.Status__c == 'Complete'){
                this.questionnaireCompleted = true;
            }
            this.questionnaireSections.sort((a, b) => a.order - b.order);
            this.visibleSection = this.questionnaireSections[0];
            this.currentSectionNumber = 0;
            this.maxSectionNumber = this.questionnaireSections.length;
            // console.log('this.questionnaireSections', JSON.parse(JSON.stringify(this.questionnaireSections)));
            this.calculateProgress();
        }
        if (error) {
            console.error(error);
        }
    }
    
    determineCompanyName() {
        const logoFileName = this.questionnaireSections[0].logoFileName;
        const respondentLanguage = this.questionnaireResponse.Respondent_Language__c;
        
        if (logoFileName === 'QuestionnaiteInterpipeSteel.jpeg') {
            switch (respondentLanguage) {
                case 'Ukrainian':
                    this.companyName = 'Інтерпайп Сталь';
                    break;
                case 'Russian':
                    this.companyName = 'Интерпайп Сталь';
                    break;
                default:
                    this.companyName = 'Interpipe Steel';
            }
        } else if (logoFileName === 'QuestionnaireKLWLogo.jpeg') {
            this.companyName = 'KLW';
        } else {
            switch (respondentLanguage) {
                case 'Ukrainian':
                    this.companyName = 'Інтерпайп';
                    break;
                case 'Russian':
                    this.companyName = 'Интерпайп';
                    break;
                default:
                    this.companyName = 'Interpipe';
            }
        }
    }
    handleLanguageSelection(event) {
        this.selectedLanguage = event.currentTarget.dataset.language;
        const buttons = this.template.querySelectorAll('.lang-button');
        buttons.forEach(button => {
            button.classList.remove('pressed');
        });
        event.target.classList.add('pressed');
    }
    startQuestionnaire() {
        this.showStartPage = false;
        this.updateQuestionnaireResponseLanguage();
    }
    updateQuestionnaireResponseLanguage() {
        updateResponseLanguage({ questionnaireResponseId: this.responseId, newLanguage: this.selectedLanguage})
            .then(result => {
                console.log(result);
                window.location.reload();
            })
            .catch(error => {
                console.error('Error updating repsonse record:', error);
            });
    }
   
    connectedCallback(){
            loadStyle(this, CustomSLDS)
                .then(() => {
                    // console.log('Custom styles loaded.');
                })
                .catch(error => {
                    console.error('Error loading custom styles', error);
                });
    }
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
                if (window.jspdf.autoTable) {
                    jsPDF.API.autoTable = window.jspdf.autoTable; 
                }
            }
        }).catch(error => {
            console.error('Error :', error);
        });
    }
    
    
    handleCheckboxGroupChange(event) {
        // console.log('event.detail', JSON.parse(JSON.stringify(event.detail.updatedOptions || {})));
        const updatedOptions = event.detail.updatedOptions;
        this.handleQuestionChange(event);
        this.questionnaireSections = this.questionnaireSections.map((item) => {
            if (item.isCheckboxGroup) {
                return {
                    ...item,
                    options: updatedOptions
                };
            }
            return item;
        });
    }

    handleQuestionChange(event) {
        const questionId = event.currentTarget.dataset.id;
        let response;

        if(event.detail.updatedOptions){
            const updatedOptions = event.detail.updatedOptions;
            const checkedOptions = updatedOptions.filter(option => option.isChecked);
            const checkedValues = checkedOptions.map(option => option.value);
            const checkedValuesString = checkedValues.join(', ');
            response = checkedValuesString;
        }else{
            response = event.target.value;
        }

        this.updateInitialValue(questionId, response);
        this.calculateProgress();
        this.updateQuestionnaireResponseStatus();

        if (this.timersByQuestions[questionId]) {
            clearTimeout(this.timersByQuestions[questionId]);
        }
        this.timersByQuestions[questionId] = setTimeout(() => {
            this.doneTyping(questionId, response);
          }, 1500);

        // console.log('this timers by questions ', JSON.parse(JSON.stringify(this.timersByQuestions)))
    }

    doneTyping(questionId, response) {
         createAnswer({ questionId: questionId, response: response, responseId: this.responseId})
            .then(result => {
                // console.log('APEX UPDATED');
            })
            .catch(error => {
                console.error('Error creating answer record:', error);
            });
            
        
    }

    updateInitialValue(questionId, response) {
        // console.log('questionId', questionId, ' response ', response)
        this.questionnaireSections = this.questionnaireSections.map((section) => {
            return {
                ...section,
                questions: section.questions.map((question) => {
                    if (question.Id === questionId) {
                        return {
                            ...question,
                            initialValue: response,
                        };
                    }
                    return question;
                }),
            };
        });

        if (this.questionDependencyMap[questionId]) {
            this.questionDependencyMap[questionId].forEach(dependency => {
                this.questionnaireSections = this.questionnaireSections.map(section => {
                    return {
                        ...section,
                        questions: section.questions.map(question => {
                            if (question.Id === dependency.dependentQuestionId) {
                                const requiredValues = dependency.requiredValue.split(',').map(value => value.trim());
                                const shouldHide = requiredValues.includes(response);
                                return {
                                    ...question,
                                    isVisible: !shouldHide,
                                    isRequiredAndVisible: question.isRequired && !shouldHide,
                                };
                            }
                            return question;
                        }),
                    };
                });
            });
        }

        this.questionnaireSections = this.questionnaireSections.map(section => {
            if (section.conrtolQuestionId) {
                const controlQuestion = this.questionnaireSections.flatMap(sec => sec.questions).find(q => q.Id === section.conrtolQuestionId);
                if (controlQuestion) {
                    const requiredValues = section.value.split(',').map(value => value.trim());
                    const shouldHideSection = requiredValues.includes(controlQuestion.initialValue);
                    return {
                        ...section,
                        isVisible: !shouldHideSection,
                    };
                }
            }
            return section;
        });

        this.visibleSection = this.questionnaireSections[this.currentSectionNumber];
    }

    calculateProgress() {
        const totalQuestions = this.questionnaireSections
            .map(section => section.questions)
            .flat()
            .length;
        const answeredQuestions = this.questionnaireSections
            .map(section => section.questions)
            .flat()
            .filter(question => question.initialValue !== null && question.initialValue !=='').length;

        this.progress = ((answeredQuestions / totalQuestions) * 100).toFixed(0);
        // console.log('this.this.questionnaireSections',JSON.parse(JSON.stringify(this.questionnaireSections)))
        this.updateProgressBarStyle();
    }

    updateProgressBarStyle() {
        const progressBarFill = this.template.querySelector('.progress-fill');
        const progressBarText = this.template.querySelector('.progress-text');
        if (progressBarFill) {
            progressBarFill.style.width = this.progress + '%';
        }
        if (progressBarText) {
            progressBarText.textContent = this.progress + '%';
        }
    }

    updateQuestionnaireResponseStatus() {
        this.progress = parseInt(this.progress);
        if (this.progress > 0 && this.progress < 100) {
            this.questionnaireResponse.Status__c = 'Incomplete';
        } else if(this.progress == 0)  {
            this.questionnaireResponse.Status__c = 'Not Started';
        }
        updateResponseStatus({ questionnaireResponseId: this.questionnaireResponse.Id, newStatus: this.questionnaireResponse.Status__c})
            .then(result => {
                // console.log(result);
            })
            .catch(error => {
                console.error('Error updating repsonse record:', error);
            });
        // updateResponseStatus(this.questionnaireResponse.Id, this.questionnaireResponse.Status__c);
    }

    nextPage() {
        do {
            this.currentSectionNumber++;
        } while (
            this.currentSectionNumber < this.maxSectionNumber - 1 &&
            !this.questionnaireSections[this.currentSectionNumber].isVisible
        );
    
        if (this.currentSectionNumber < this.maxSectionNumber) {
            if (this.validateRequiredFields()) {
                this.visibleSection = this.questionnaireSections[this.currentSectionNumber];
                this.disablePrevious = false;
            } else {
                this.showErrorMessage();
                do {
                    this.currentSectionNumber--;
                } while (
                    this.currentSectionNumber > 0 &&
                    !this.questionnaireSections[this.currentSectionNumber].isVisible
                );
            }
        }
    
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    
    previousPage() {
        do {
            this.currentSectionNumber--;
        } while (
            this.currentSectionNumber > 0 &&
            !this.questionnaireSections[this.currentSectionNumber].isVisible
        );
    
        if (this.currentSectionNumber >= 0) {
            this.visibleSection = this.questionnaireSections[this.currentSectionNumber];
            if (this.currentSectionNumber === 0) {
                this.disablePrevious = true;
            }
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    finishQuestionnaire() {
        if (this.validateRequiredFields()) {
            this.progress = 100;
            this.updateProgressBarStyle();
            this.questionnaireResponse.Status__c = 'Complete';
            updateResponseStatus({ questionnaireResponseId: this.questionnaireResponse.Id, newStatus: this.questionnaireResponse.Status__c})
                .then(result => {
                    // console.log(result);
                })
                .catch(error => {
                    console.error('Error updating repsonse record:', error);
                });
            this.finishToggled = true;

        }
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
                    console.log('splitQuestionnaireName', splitQuestionnaireName.length);
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
                const columns = ['Questions', 'Answers'];
                const rows = [];
                this.questionnaireSections.forEach(section => {
                    if(section.isVisible) {
                        section.questions.forEach(question => {
                            if(question.isVisible){
                                let response = question.initialValue || '';
                                if (question.isCheckboxGroup) {
                                    response = response.split(',').join('\n');
                                }
                                rows.push([question.questionValue, response]);
                            }
                        });
                    }
                });
    
                if (doc.autoTable) {
                    doc.autoTable({
                        head: [columns],
                        body: rows,
                        startY: 40,
                        styles: { font: "Golos" },
                        columnStyles: {
                            0: { cellWidth: 120 },
                            1: { cellWidth: 60 },
                        }
                    });
                }

                // Assuming addCompletionDate is a method you've defined to add the completion date
                this.addCompletionDate(doc);
    
                const filename = this.questionnaireName + '.pdf';
                doc.save(filename);
            };
            image.src = imageUrl;
        } catch (error) {
            console.error('PDF Error:', error);
        }
    }
    
    
    // Ensure you have the addCompletionDate method defined somewhere in your code.
    
    
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
    
    
    validateRequiredFields() {

        this.template.querySelectorAll('lightning-input').forEach(input => {
            input.reportValidity();
        })

        this.template.querySelectorAll('lightning-combobox').forEach(input => {
            input.reportValidity();
        });

        this.template.querySelectorAll('lightning-textarea').forEach(input => {
            input.reportValidity();
        })
        this.template.querySelectorAll('lightning-radio-group').forEach(input => {
            input.reportValidity();
        })

        this.template.querySelectorAll('c-custom-checkbox-group').forEach(input => {
            input.reportValidity();
        })
        
        for (const question of this.visibleSection.questions) {
            // console.log('question.Required', question.isRequired);
            // console.log('question.initialValue', question.initialValue);


            if (question.isRequiredAndVisible && !question.initialValue) {
                // question.errorMessage = 'Це поле є обов\'язковим';
                return false;
            }else{
                question.errorMessage = '';
            }
        }
        return true;
    }

    showErrorMessage() {
        let message = 'Please fill in all required fields before proceeding.';
        let title = 'Validation Error';
    
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                message = 'Будь ласка, заповніть усі необхідні поля перед продовженням.';
                title = 'Помилка перевірки';
                break;
            case 'Russian':
                message = 'Пожалуйста, заполните все необходимые поля перед продолжением.';
                title = 'Ошибка проверки';
                break;
        }
    
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning',
        });
        this.dispatchEvent(event);
    }
    
    
    get displayPageNumber() {
        return this.questionnaireSections[this.currentSectionNumber]?.order + 1; 
    }
    get englishIconClass() {
        return this.selectedLanguage === 'English' ? 'language-icon selected' : 'language-icon';
    }
    
    get ukrainianIconClass() {
        return this.selectedLanguage === 'Ukrainian' ? 'language-icon selected' : 'language-icon';
    }
    
    get russianIconClass() {
        return this.selectedLanguage === 'Russian' ? 'language-icon selected' : 'language-icon';
    }
    get isNextVisibleSectionExists() {
        return this.questionnaireSections.slice(this.currentSectionNumber + 1).some(section => section.isVisible);
    }
    get startButtonDisabled() {
        return !this.selectedLanguage; // The button is disabled if no language is selected
    }
    get finalMessage() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return {
                    header: 'Ваша анкета отримана.',
                    body: 'Дякуємо, що прийняли участь в нашому щорічному Опитуванні Задоволеності Клієнтів!',
                    closing: 'З повагою,',
                    team: 'Команда маркетингу,',
                    company: this.companyName
                };
            case 'Russian':
                return {
                    header: 'Ваша анкета получена.',
                    body: 'Спасибо за то, что приняли участие в нашем ежегодном Опросе Удовлетворенности Клиентов!',
                    closing: 'С уважением,',
                    team: 'Команда маркетинга,',
                    company: this.companyName
                };
            default:
                return {
                    header: 'Your form has been received.',
                    body: 'Thank you for taking part in our yearly Customer Satisfaction Survey!',
                    closing: 'Respectfully,',
                    team: 'Marketing team,',
                    company: this.companyName
                };
        }
    }    
    get alreadyCompletedMessage() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return 'Ви вже заповнили це опитування.';
            case 'Russian':
                return 'Вы уже заполнили этот опрос.';
            default:
                return 'You have already completed the survey.'; // Default to English
        }
    }

    get alreadyCompletedMessage() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return 'Ви вже заповнили це опитування.';
            case 'Russian':
                return 'Вы уже заполнили этот опрос.';
            default:
                return 'You have already completed the survey.'; // Default to English
        }
    }
    
    get downloadInstructions() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return 'Ви можете завантажити копію ваших відповідей, натиснувши тут';
            case 'Russian':
                return 'Вы можете скачать копию ваших ответов, нажав здесь';
            default:
                return 'You can download a copy of the answers by clicking here'; // Default to English
        }
    }

    get downloadPdfLabel() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return 'Завантажити PDF';
            case 'Russian':
                return 'Скачать PDF';
            default:
                return 'Download PDF'; // Default to English
        }
    }
    get buttonLabels() {
        switch(this.questionnaireResponse.Respondent_Language__c) {
            case 'Ukrainian':
                return {
                    previous: 'Попередня',
                    next: 'Наступна',
                    finish: 'Завершити'
                };
            case 'Russian':
                return {
                    previous: 'Предыдущая',
                    next: 'Следующая',
                    finish: 'Завершить'
                };
            default:
                return {
                    previous: 'Previous',
                    next: 'Next',
                    finish: 'Finish'
                };
        }
    }
    get logoStyle() {
        return `background-image:url(${this.questionnaireLogo});
                width: 111px;
                height: 111px;
                background-size: cover;
                background-position: center;
                background-repeat: no-repeat;`;
    }

    
}