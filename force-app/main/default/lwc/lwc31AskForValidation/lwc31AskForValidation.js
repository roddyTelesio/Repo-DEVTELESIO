import {LightningElement, track, wire, api} from 'lwc';
import getProgramName from '@salesforce/apex/LWC31_AskForValidation.getProgramName';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import validateRequests from '@salesforce/apex/LWC31_AskForValidation.validateRequests';
import getAskToUsers from '@salesforce/apex/LWC31_AskForValidation.getAskToUsers';
import {registerListener, fireEvent} from 'c/pubSub';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import selectValidators from '@salesforce/label/c.selectValidators';
import sentForValidation from '@salesforce/label/c.sentForValidation';
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsDataRequest = [
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'}
];

const columnsAskTo = [
    { label: 'Validator', fieldName: 'Name'},
    { label: 'Email', fieldName: 'Email'}
];

 
export default class LWC31_AskForValidation extends LightningElement {
    label = {
        selectValidators,
        sentForValidation,
        errorMsg  
    }
    
    @api uwYear;
    @api principleCedComp;
    @api program;
    @api selectedDataRequest = [];
    @api totalPremium;
    @track programOpt = [];
    @track lstSelectedAskTo = [];
    programName;
    error;
    value;
    columnsDataRequest = columnsDataRequest;
    emailContent;
    columnsAskTo = columnsAskTo;
    PrincipleCedingCompany;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        let opt = {label: 'test', value: 'test'};
        this.programOpt.push(opt);
       
        getProgramName({programId: this.program})
        .then(result => {
            this.programOpt.push({label:result.programName, value:result.Id});
            this.value = result.Id;
        })
        .catch(error => {
            this.error = error;
        });
        this.filterRequests();
        this.getAskToUsers();
    }
    handleValidateRequests(){
        var table = this.template.querySelector('.askFor');
        var selectedContacts = table.getSelectedRows();
        console.log('selectedContacts == ', selectedContacts);
        if(selectedContacts.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.selectValidators, variant: 'error' }),);
        }
        else{
            validateRequests({lstRequests : this.selectedDataRequest, lstSelectedValidators : selectedContacts, comment : this.emailContent, requestLink : window.location.href})
            .then(result => {
                console.log('result == ', result);
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.sentForValidation, variant: 'success'  }),);
                    fireEvent(this.pageRef, 'closeModal');
                    window.location.reload();//RRA - ticket 01411 - 03042023
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            })
        }
    }
    filterRequests(){        
        let filteredList = [];
        let uniqueRequests = [];
        for(var i = 0; i < this.selectedDataRequest.length; i ++){
            let request = this.selectedDataRequest[i];
            if(request.Broker__c != null || request.Reinsurer__c){
                // Avoid duplicate Broker and Reinsurer for Treaty different
                let concatenatedIds = request.Treaty__c + request.Broker__c + request.Reinsurer__c;
                if(!uniqueRequests.includes(concatenatedIds)){
                    uniqueRequests.push(concatenatedIds);
                    filteredList.push(request);
                }
            }
        }
        this.selectedDataRequest = filteredList;

    }
    handleCloseConfirmationModal(){
        fireEvent(this.pageRef, 'closeModal');
    }    
    handleOnChangeComment(event){
        this.emailContent = event.currentTarget.value;;
    }
    getAskToUsers(){
        getAskToUsers({premium: this.totalPremium, PrincipleCedingCompany: this.principleCedComp})
        .then(result => {
            if(result.hasOwnProperty('Success')){
                this.lstSelectedAskTo = result.Success;
            }else{
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.error, variant: 'error' }),);
        });
        
    }
}