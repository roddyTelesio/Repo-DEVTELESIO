import { LightningElement, api } from 'lwc';
import getRetroDocId from '@salesforce/apex/CLM_generateDoc.getRetroDocId';
import getMergeDocId from '@salesforce/apex/CLM_MergeDocx.getMergeDocId';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';


export default class CLM_fetchRetroGeneratedDocId extends LightningElement {
    @api docId;
    @api agreementId; 
    @api isSuccess = false;
    @api errMsg = '';
    @api pollingProcessName;

    intervalId = null;

    connectedCallback() {
        console.log('CLM_fetchRetroGeneratedDocId connected: start');
        this.startFetching();
    }

    startFetching() {
        console.log('CLM_fetchRetroGeneratedDocId startFetching: start');
        this.intervalId = setInterval(() => {

            if(this.pollingProcessName == 'getRetroDocId'){
                getRetroDocId({ agreementId: this.agreementId })
                .then(result => {
                    if (result && result.docId) {
                        this.result = `Retrieved DocId: ${result.docId}`;
                        this.isSuccess = true;
                        this.docId = result.docId;
                        console.log('docId', this.docId);
                
                        clearInterval(this.intervalId); // Stop polling
                        this.handleNavigate(null);
                    }
                })
                .catch(error => {
                    console.error('Error fetching DocId:', error);
                    this.isSuccess = false;
                    this.errMsg = error;
                    this.handleNavigate(null);
                });

            }else if(this.pollingProcessName == 'getMergeDocId'){
                getMergeDocId({ agreementId: this.agreementId })
                .then(result => {
                    if (result && result.docId) {
                        this.result = `Retrieved DocId: ${result.docId}`;
                        this.isSuccess = true;
                        this.docId = result.docId;
                        clearInterval(this.intervalId); // Stop polling
                        this.handleNavigate(null);
                    }
                })
                .catch(error => {
                    console.error('Error fetching DocId:', error);
                    this.isSuccess = false;
                    this.errMsg = error;
                    this.handleNavigate(null);
                });
            }
        }, 2000); // Poll every 2 seconds
    }

    // Make sure to clear the interval when the component is destroyed
    disconnectedCallback() {
        clearInterval(this.intervalId);
    }


    handleNavigate(event){
        const navigateNextEvent = new FlowNavigationNextEvent();
        try {
            this.dispatchEvent(navigateNextEvent);
            console.log('navigateNextEvent dispatchedSuccesfully');
        } catch (ex) {
            console.log('Exception: ' + ex);
        }
    }
}