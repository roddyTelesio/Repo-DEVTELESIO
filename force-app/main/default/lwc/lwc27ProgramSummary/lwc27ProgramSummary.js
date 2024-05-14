import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import getProgramSummaryWired from '@salesforce/apex/LWC27_ProgramSummary.getProgramSummary';
import getReinsurer from '@salesforce/apex/LWC25_PortalFilters.getAccountReinsurer';
import getPrograms from '@salesforce/apex/LWC25_PortalFilters.getPrograms';
import checkBroker from '@salesforce/apex/LWC25_PortalFilters.checkBrokerContact';

const endorsementColumns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'statusMessage'},
    { label: 'Endorsement', fieldName: 'programUrl', type: 'url', typeAttributes: {label: {fieldName: 'programName'}, target: '_self'} }
    
];

const signingColumns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'requestStatus'},
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c'}
    
];

const placementColumns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'requestStatus'},
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c'}
   
];

const leadColumns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'requestStatus'},
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c'}
];

const quoteColumns = [
    { label: '', fieldName: 'statusIcon' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classStatusIcon' }, variant:'bare'}},
    { label: 'Status', fieldName: 'requestStatus'},
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c'},
    { label: 'Section', fieldName: 'TECH_SectionName__c' },
    { label: 'Version', fieldName: 'Version__c' }
];

export default class LWC27_ProgramSummary extends NavigationMixin(LightningElement) {
    @api valueUWYear;
    @api valuePrincipalCedComp;
    @api valueReinsurer;
    @api valueProgram;
    error;
    reinsurerOptions;
    isBroker = false;
    isSummaryPage = false;
    endorsementColumns = endorsementColumns;
    signingColumns = signingColumns;
    placementColumns = placementColumns;
    leadColumns = leadColumns;
    quoteColumns = quoteColumns;
    endorsementData;
    signingData;
    placementData;
    leadData;
    quoteData;
    disableOpenBtnQuote = false;
    disableOpenBtnLead = false;
    disableOpenBtnPlacement = false;
    disableOpenBtnSigning = false;
    valReinsurerId;
    valBrokerId = null;
    marketSubmissionVisible = false;
    spinner = false; 

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let param = 'c__portal';
        let paramValue = null;
        let nameUrl = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(currentUrl != undefined && currentUrl != null){
            paramValue = currentUrl[param];
        }

        if(nameUrl == 'portal_summary__c'){
            //summary
            this.isSummaryPage = true;
        }

        if(paramValue != null){
            let parameters = paramValue.split("-");

            if(parameters[0] != undefined){
                this.valueProgram = parameters[0];
                fireEvent(this.pageRef, 'programSummary', this.valueProgram);
            }

            if(parameters[1] != undefined){
                this.valueReinsurer = parameters[1];
            }

            if(parameters[2] != undefined){
                this.valueUWYear = parameters[2];
                fireEvent(this.pageRef, 'yearSummary', this.valueUWYear);
            }

            if(parameters[3] != undefined){
                this.valuePrincipalCedComp = parameters[3];
                fireEvent(this.pageRef, 'compSummary', this.valuePrincipalCedComp);
            }
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(checkBroker)
    wiredCheckBroker(result){
        if(result.data) {
            this.isBroker = result.data;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPrograms, {valueUWYear: '$valueUWYear', valuePrincipalCedComp: '$valuePrincipalCedComp'})
    wiredGetPrograms(result){
        this.spinner = true;
        this.wiredProgram = result;
        if(result.data){
            if(this.valueProgram == null){
                this.valueProgram = result.data[0].value;
            }
            this.error = undefined;
            this.spinner = false;
        }
        else if (result.error) {
            this.error = result.error;
            this.spinner = false;
        }
    }


    @wire(getReinsurer)
    wiredGetAccountReinsurer(result){
        this.spinner = true;
        this.wiredAccountReinsurer = result;
        if(result.data) {
            if(this.valueReinsurer == null && this.isBroker == true){
                this.valueReinsurer = result.data[0].value;
            }
        }
        else if (result.error) {
            this.error = result.error;
        }
        this.spinner = false;
    }

    //02/06: loading time issue: chenge simple function to -> wired function
    @wire(getProgramSummaryWired, {programId: '$valueProgram', reinsurerId: '$valueReinsurer', isUserBroker: '$isBroker'})
    wiredGetProgramSummary(result){
        this.spinner = true;
        this.wiredProgramSummary = result;
        if(result.data){
            let mapRequest = result.data;
            this.quoteData = this.applyCSSIcon(mapRequest.lstQuoteRequest, true);
            this.leadData = this.applyCSSIcon(mapRequest.lstLeadRequest, false);
            this.placementData = this.applyCSSIcon(mapRequest.lstPlacementRequest, false);
            this.signingData = this.applyCSSIcon(mapRequest.lstSigningRequest, false);

            let programStage = mapRequest.programStage;
            this.valBrokerId = mapRequest.valBrokerId;
            this.valReinsurerId = mapRequest.valReinsurerId;
            this.error = undefined;

            if(this.quoteData == undefined || this.quoteData.length == 0 ){
                this.disableOpenBtnQuote = true;
            }
            else{
                this.disableOpenBtnQuote = false;
            }

            if(this.leadData == undefined || this.leadData.length == 0 ){
                this.disableOpenBtnLead = true;
            }
            else{
                this.disableOpenBtnLead = false;
            }

            if(this.placementData == undefined || this.placementData.length == 0 ){
                this.disableOpenBtnPlacement = true;
            }
            else{
                this.disableOpenBtnPlacement = false;
            }

            if(this.signingData == undefined || this.signingData.length == 0 ){
                this.disableOpenBtnSigning = true;
            }
            else{
                this.disableOpenBtnSigning = false;
            }

            this.error = undefined;
            this.spinner = false;
        }
        else if (result.error) {
            this.error = result.error;
            this.spinner = false;
        }
    }

    applyCSSIcon(lstRequest, isPhaseQuote){
         //RRA -1045 the colors on the round shapes don't display on portal users to check the status of request => add slds-icon  and change the size of icon in _x-small
         
        let defaultIcon = 'slds-icon slds-icon-text-default slds-icon_x-small'; //grey
        let errorIcon = 'slds-icon slds-icon-text-error slds-icon_x-small'; //red
        let successIcon = 'slds-icon slds-icon-text-success slds-icon_x-small'; //green
        let warningIcon = 'slds-icon slds-icon-text-warning slds-icon_x-small'; //yellow
        let orangeIcon = 'orangeIcon slds-icon--medium';
        let lstUpdRequest = [];
        let today = new Date();

        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = today.getFullYear();

        today = yyyy + '-' + mm + '-' + dd; //2020-07-10

        // Red -> If the request has not been answered yet -> Not Answered
        // Green -> If the request has been answered, Sent answer is true = 'Answered' -> Answered
        // Grey -> If No answer + Expected answered date has been reached -> Timeout
        // Grey -> Quote only (if Quote Request Type = for information) -> Not Approached to answer

        for(let i = 0; i < lstRequest.length; i++){
            let row = { ...lstRequest[i] };

            if(row.QuoteType__c == '2'){
                row['classStatusIcon'] = defaultIcon;
                row['requestStatus'] = 'Not Approached to answer';
            }
            else if(row.ResponseDate__c != null && row.ResponseDate__c != undefined){
                row['classStatusIcon'] = successIcon;
                row['requestStatus'] = 'Answered';
            }
            else if((row.ResponseDate__c == null || row.ResponseDate__c == undefined) && today <= row.ExpectedResponseDate__c){
                row['classStatusIcon'] = errorIcon;
                row['requestStatus'] = 'Not Answered';
            }
            else if(row.ReinsurerStatus__c == 'Sent' && today > row.ExpectedResponseDate__c){
                row['classStatusIcon'] = defaultIcon;
                row['requestStatus'] = 'Timeout';
            }
            else if(row.ReinsurerStatus__c != 'Sent' && row.QuoteType__c == '2'){
                row['classStatusIcon'] = defaultIcon;
                row['requestStatus'] = 'Not Approached to answer';
            }
            else if(row.ReinsurerStatus__c == 'Timeout'){
                row['classStatusIcon'] = defaultIcon;
                // row['classStatusIcon'] = errorIcon; //MBE - 28/09 - icon should be grey
                row['requestStatus'] = 'Timeout';
            }
            else if(row.ReinsurerStatus__c == 'Answered'){
                row['classStatusIcon'] = successIcon;
                row['requestStatus'] = 'Answered';
            }
            else if(row.ReinsurerStatus__c == 'Refused'){
                row['classStatusIcon'] = successIcon;
                row['requestStatus'] = 'Answered';
            }

            lstUpdRequest.push(row);
        }

        return lstUpdRequest;
    }

    openBtn(event){
        let name = event.target.name;
        
        if(this.valBrokerId == undefined){
            this.valBrokerId = null;
        }
        if(name == 'Quote'){
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__webPage',
            //     attributes: {
            //         url: '/portal/s/request?c__details='+this.valueProgram+'-'+this.valReinsurerId+'-'+this.valBrokerId+'-'+name
            //     }
            // });
            let selectedRequestId = this.quoteData[0]['Id'];
          
            let url = '/portal/s/request?c__details='+this.valueProgram+'-'+this.valReinsurerId+'-'+this.valBrokerId+'-'+name+'-'+selectedRequestId; // RRA - 1046
            window.open( url, '_self' );
        }else if (name == 'Lead'){
            let selectedRequestId = this.leadData[0]['Id'];
            let url = '/portal/s/request?c__details='+this.valueProgram+'-'+this.valReinsurerId+'-'+this.valBrokerId+'-'+name+'-'+selectedRequestId; // RRA - 1046
            window.open( url, '_self' );
        }else if (name == 'Placement'){
            let selectedRequestId = this.placementData[0]['Id'];
            let url = '/portal/s/request?c__details='+this.valueProgram+'-'+this.valReinsurerId+'-'+this.valBrokerId+'-'+name+'-'+selectedRequestId; // RRA - 1046
            window.open( url, '_self' );
        }else if (name == 'Signing'){ // RRA - 1046
            let selectedRequestId = this.signingData[0]['Id'];
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__webPage',
            //     attributes: {
            //         url: '/portal/s/request?c__details='+this.valueProgram+'-'+selectedRequestId+'-'+name
            //     }
            // });

            let url = '/portal/s/request?c__details='+this.valueProgram+'-'+selectedRequestId+'-'+name;
            window.open( url, '_self' );
        }
    }
}