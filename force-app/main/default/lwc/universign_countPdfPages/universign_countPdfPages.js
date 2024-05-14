import { loadScript } from 'lightning/platformResourceLoader';
import pdflib from '@salesforce/resourceUrl/pdflib';
import { LightningElement,  api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import getBase64doc from '@salesforce/apex/universign_sendTransaction.getBase64doc';

export default class Universign_countPdfPages extends LightningElement {
    @api contentDocumentId = '0695E000004fLaWQAU';
    @api isSuccess = false;
    @api errMsg = '';
    @api pageCount;
    pdfBase64Data; // Assuming you have base64-encoded PDF data

    renderedCallbackExecuted = false;

    renderedCallback() { 
        console.log('renderedCallback START ');
        if (!this.renderedCallbackExecuted) {
            loadScript(this, pdflib).then(() => {
                console.log('Script loaded successfully');
                this.renderedCallbackExecuted = true;
                this.handleGetBase64doc();
            }).catch(error => {
                console.log('Script loading error: ' + error.message);
                this.isSuccess = false;
                this.errMsg = error.message;
                this.handleNext();
            });
        }
        console.log('renderedCallback END ');
    }

    handleGetBase64doc() {
        console.log('handleGetBase64doc START ');
        getBase64doc({ contentDocumentId: this.contentDocumentId })
            .then(result => {
                // console.log('getBase64doc result:', result);
                this.pdfBase64Data = result;
                this.countPdf();
            })
            .catch(error => {
                console.error('Error:', error);
                this.isSuccess = false;
                this.errMsg = error.message;
                this.handleNext();
            });
        console.log('handleGetBase64doc END ');
    }

    async countPdf() {
        console.log('countPdf START ', new Date().toLocaleString());
        try{
            const pdfDoc = await window.PDFLib.PDFDocument.load(this.pdfBase64Data, { ignoreEncryption: true });
            const totalPages = pdfDoc.getPageCount();
            console.log('countPdf found totalPages at ', new Date().toLocaleString());
            console.log('countPdf totalPages:', totalPages);
            this.pageCount = totalPages;
            this.isSuccess = true;
        }catch(error){
            this.isSuccess = false;
            this.errMsg = error.message;
        }
        this.handleNext();
        console.log('countPdf END ');
    }


    handleNext(){
        console.log('handleNext START with isSuccess ' + this.isSuccess + ' ' + this.errMsg);
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            if(this.isDebug) console.log('FlowNavigationNextEvent dispatchedSuccesfully');
        } catch (ex) {
            if(this.isDebug) console.log('Exception: ' + ex);
        }
    }
}