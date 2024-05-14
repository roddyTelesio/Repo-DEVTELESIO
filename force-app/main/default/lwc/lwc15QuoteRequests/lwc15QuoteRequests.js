import {LightningElement, track, wire, api} from 'lwc';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getQuoteRequests from '@salesforce/apex/LWC15_QuoteRequests.getQuoteRequests';
import isProgramRenewed from '@salesforce/apex/LWC15_QuoteRequests.isProgramRenewed';
import getUWYearForOriginalProgram from '@salesforce/apex/LWC15_QuoteRequests.getUWYearForOriginalProgram';
import getTreaties from '@salesforce/apex/LWC15_QuoteRequests.getTreaties';
import getAccountBroker from '@salesforce/apex/LWC15_QuoteRequests.getAccountBroker';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate';
import deletePrograms from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import loadCurrentYearQuoteRequest from '@salesforce/apex/LWC15_QuoteRequests.loadCurrentYearQuoteRequest'; //RRA - ticket 1371 - 02082023
import loadPreviousYearQuoteRequest from '@salesforce/apex/LWC15_QuoteRequests.loadPreviousYearQuoteRequest';
import checkReinsurerBroker from '@salesforce/apex/LWC24_NewPlacementRequest.checkReinsurerBroker';//RRA - ticket 1571 - 13092023
import saveReinsurer from '@salesforce/apex/LWC15_QuoteRequests.saveReinsurer';
import getReinsurer from '@salesforce/apex/LWC15_QuoteRequests.getReinsurer';
import getBroker from '@salesforce/apex/LWC15_QuoteRequests.getBroker';
import toggleReqType from '@salesforce/apex/LWC15_QuoteRequests.toggleRequestType';
import REQUEST_TYPE_FIELD from '@salesforce/schema/Request__c.QuoteType__c';
import BROKER_FIELD from '@salesforce/schema/Request__c.Broker__c';
import TREATY_FIELD from '@salesforce/schema/Request__c.Treaty__c';
import SECTION_FIELD from '@salesforce/schema/Request__c.Section__c'; //RRA - ticket 1571 18092023
import PROGRAM_FIELD from '@salesforce/schema/Request__c.Program__c';
import REINSURER_FIELD from '@salesforce/schema/Request__c.Reinsurer__c';
import TECH_PHASETYPE_FIELD from '@salesforce/schema/Request__c.TECH_PhaseType__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import Id from '@salesforce/user/Id';

//custom label
import noBrokerRein from '@salesforce/label/c.noBrokerRein';
import requestQuoteExistAlready from '@salesforce/label/c.requestQuoteExistAlready'; //RRA - 1571 - 15092023
import TreatyNotAvailableForProgram from '@salesforce/label/c.TreatyNotAvailableForProgram';
import RequiredRequestTypeMissing from '@salesforce/label/c.RequiredRequestTypeMissing';
import QuoteRequestsCreatedSuccessfully from '@salesforce/label/c.QuoteRequestsCreatedSuccessfully';
import noTreatyField from '@salesforce/label/c.noTreatyField';
import noTreatyAvailable from '@salesforce/label/c.noTreatyAvailable';
import AskToReactivateQuote from '@salesforce/label/c.AskToReactivateQuote';
import AskToDeactivateQuote from '@salesforce/label/c.AskToDeactivateQuote';
import NoQuoteRequestsSelected from '@salesforce/label/c.NoQuoteRequestsSelected';
import AskToDeleteQuote from '@salesforce/label/c.AskToDeleteQuote';
import errorMsg from '@salesforce/label/c.errorMsg';
import SomeQuoteRequestAssociatedCancelTreatySection from '@salesforce/label/c.SomeQuoteRequestAssociatedCancelTreatySection';//RRA - ticket 585 - 16032023

const columnsQuoteRequest = [
    { label: 'Layer', fieldName: 'TECH_Layer__c' },
    { label: 'Section Number', fieldName: 'SectionNumber'},
    { label: 'Treaty ref', fieldName: 'TreatyReference__c' },
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Section', fieldName: 'TECH_SectionName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'reinsurerNameUrl', type: 'url', cellAttributes: { class: { fieldName: 'linkCSS' }}, typeAttributes: {label: { fieldName: 'TECH_ReinsurerName__c' }, target: '_self', disabled: {fieldName: 'disableLink'}} },
    { label: 'Request Type', fieldName: 'QuoteType__c' },
    { label: 'Quote', fieldName: 'quoteValue' },
    { label: 'Written share', fieldName: 'WrittenShareResponse__c' , type: 'number', cellAttributes: { alignment: 'left' }, typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'} },

    { label: '', fieldName: 'statusIconDate' , type: 'text', cellAttributes: { iconName: { fieldName: 'UtilityIconDate__c' }, iconPosition: 'left'}, initialWidth: 50 }, //RRA - ticket 1541 - 05072023
    { label: '', fieldName: 'statusIconComment' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Comment__c' }, iconPosition: 'left'}, initialWidth: 50 }, //RRA - 939
    { label: '', fieldName: 'statusIconAttachFile' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Attachment__c' }, iconPosition:'left'}, initialWidth: 50 }, //RRA - 939
    
    { label: 'Reinsurer Status', fieldName: 'ReinsurerStatus__c' },
    { label: 'Response Date', fieldName: 'ResponseDate__c' },
    { label: 'Last sent date', fieldName: 'LastSentDate__c' },
    { label: 'Expected answer date', fieldName: 'ExpectedResponseDate__c' }
];

const columnsLoadFromPrevYr = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
];

//RRA - ticket 1371 12122022 
const columnsLoadFromCurrentYr = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
];

export default class LWC15_QuoteRequests extends NavigationMixin(LightningElement) {
    label = {
        noBrokerRein,
        TreatyNotAvailableForProgram,
        RequiredRequestTypeMissing,
        QuoteRequestsCreatedSuccessfully,
        noTreatyField,
        noTreatyAvailable,
        AskToReactivateQuote,
        AskToDeactivateQuote,
        NoQuoteRequestsSelected,
        AskToDeleteQuote,
        errorMsg,
        SomeQuoteRequestAssociatedCancelTreatySection,
        requestQuoteExistAlready //RRA - 1571 - 15092023
    }

    @api selectedTreaty = null;
    @api selectedBroker = null;
    @api selectedReinsurer = null;
    @api selectedReinsurerStatus = null;
    @api selectedProgram = null;
    @api objectName = 'Account';
    @api fieldName = 'Name';
    @api allReadOnly = false;
    @track lstBrokerReins = [];
    @track lstSelectedRequest = [];
    @track searchBrokerLookupRecords = [];
    @track searchReinsurerLookupRecords = [];
    @track selectedRecords = [];
    @track selectedRein = [];
    @track selectedQuoteRequest = [];
    @track selectedQuoteRequest1 = [];
    @track lstSelectedBrokerReinsurer = [];
    @track dataLoadFromPrevYr = [];
    mapTreatyOptions = new Map();
    mapLoadPreviousQuoteOptions = new Map();
    mapIdTreatyIdSec = new Map();
    
     //RRA - ticket 1371 - 12192022
     isLoadFromCurrentYrModalOpen = false;
     loadFromCurrentYrTitle;
     spinnerLoadCurrentYear = false;
     @track dataLoadFromCurrentYr = [];
     @track lstSelectedCurrentBrokerReinsurer;
    
    spinnerQuoteRequest = false;
    spinnerNewQuoteRequest = false;
    columnsQuoteRequest = columnsQuoteRequest;
    dataQuoteRequest;
    titleCountQuoteRequest = 'Quote Requests (0)';
    titleCountBrokerReinsurer = 'Brokers / Reinsurers (0)';
    isQuoteRequestOpenModal = false;
    isNewReinsurerOpenModal = false;
    treatyOptions;
    valueTreaty;
    valueBroker;
    brokerOptions;
    requestTypeOptions;
    valueUWYear;
    valuePrincipalCedComp;
    loadFromPrevYrTitle = 'Load from <prev_year>';
    iconName = 'standard:account';
    required = false;
    txtReinsurerLookUpclassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    searchText;
    Label;
    prevYear = null;
    loadingText = false;
    messageFlag = false;
    selectedBrokerText = null;
    selectedBrokerName;
    selectedBrokerId;
    selectedId = 0;
    isProgramRenewed = false;
    disableQuoteReqSaveBtn = true;
    disableConfirmReinsurerBtn = true;
    selectedReinsurerLink = null;
    wiredQuoteRequest;
    wiredtreaties;
    wiredBroker;
    wiredAccountBroker
    isOpenRespondOnBehalf = false;
    isOpenConfirmation = false;
    statusModalTitle;
    status;
    statusFunction;
    columnsLoadFromCurrentYr = columnsLoadFromCurrentYr; //RRA - ticket 1371 - 01082023
    columnsLoadFromPrevYr = columnsLoadFromPrevYr;
    delMsgTitle;
    delMessage;
    isDeleteOpen = false;
    isReqTypeOpen = false;
    statusQuote = 'Quote';
    disableUpdateRemind = true;
    titlePopUp;
    btnNameSendUpdateRemind;
    isSendUpdateRemindQuoteReqOpenModal = false;
    isLoadFromPrevYrModalOpen = false;
    //selectedTreaties;//RRA - ticket 585 - 15032023 - get Treaty selected
    //selectedSections;//RRA - ticket 585 - 15032023 - get Section selected
    errorClickBtn = false; //RRA - ticket 585 - 15032023 

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('valueTreaty', this.getValueTreaty, this);
        registerListener('valueBroker', this.getValueBroker, this);
        registerListener('valueReinsurer', this.getValueReinsurer, this);
        registerListener('valueReinsurerStatus', this.getValueReinsurerStatus, this);
        registerListener('valueProgram', this.getValueProgram, this);
        registerListener('refreshReq', this.refreshData, this);
        registerListener('closeSendUpdateRemindReqModal', this.closeSendUpdateRemindQuoteReqModal, this);

        //RRA - ticket 585 - 15032023 - get Treaty selected
        /*let selectedTreaties = sessionStorage.getItem('selectedTreaties');
        let selectedSections = sessionStorage.getItem('selectedSections');

        if (selectedTreaties !=  undefined){
            if (selectedTreaties !=  undefined){
                if (selectedTreaties.includes(',')){
                    this.selectedTreaties = selectedTreaties.split(',');
                }else{
                    this.selectedTreaties = selectedTreaties;
                }
            }
        }

        if (selectedSections !=  undefined){
            if (selectedSections.includes(',')){
                this.selectedSections = selectedSections.split(',');
            }else{
                this.selectedSections = selectedSections;
            }
        }
        console.log('this.selectedTreaties Quote== ',this.selectedTreaties);
        console.log('this.selectedSections Quote== ',this.selectedSections);*/

        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let url = this.pageRef.state;
        let param = 'c__program';
        let paramValue = null;

        if(url != undefined && url != null){
            paramValue = url[param];
        }

        if(paramValue != null){
            let parameters = paramValue.split("-");
            this.valueUWYear = parameters[1];
            this.valuePrincipalCedComp = parameters[2];
            if(parameters[4] != 'null' && parameters[4] != 'undefined'){
                this.valueTreaty = parameters[4];
                this.selectedTreaty = parameters[4];
            }
            if(parameters[5] != 'null' && parameters[5] != 'undefined'){
                this.selectedBroker = parameters[5];
            }
            if(parameters[6] != 'null' && parameters[6] != 'undefined'){
                this.selectedReinsurer = parameters[6];
            }
            if(parameters[7] != 'null' && parameters[7] != 'undefined'){
                this.selectedReinsurerStatus = parameters[7];
            }

            let progId = parameters[0];
            this.getUWYearForOriginalProgram(progId);
        }

        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
    }

    closeSendUpdateRemindQuoteReqModal(val){
        this.isSendUpdateRemindQuoteReqOpenModal = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getVal(val){
        this.valueUWYear = val;
        this.selectedProgram = null;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
        this.selectedProgram = null;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getValueProgram(val){
        this.selectedProgram = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
        this.getUWYearForOriginalProgram(this.selectedProgram);
    }

    getValueTreaty(val){
        this.selectedTreaty = val;
        this.valueTreaty = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getValueReinsurer(val){
        this.selectedReinsurer = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getValueBroker(val){
        this.selectedBroker = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getValueReinsurerStatus(val){
        this.selectedReinsurerStatus = val;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REQUEST_TYPE_FIELD})
    setRequestPicklistOptions({error, data}) {
        if(data){
            this.requestTypeOptions = data.values;
        }
        else{
            this.error = error;
        }
    }

    refreshData(){
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    getQuoteRequests(){
        this.spinnerQuoteRequest = true;
        if(this.selectedTreaty == 'All'){
            this.selectedTreaty = null;
        }
        getQuoteRequests({programId: this.selectedProgram, treatyId: this.selectedTreaty, reinsurerId: this.selectedReinsurer, brokerId: this.selectedBroker, reinsurerStatus: this.selectedReinsurerStatus})//RRA - ticket 585 - 15032023
        .then(result => {
            console.log(' result == ',  result);
            this.spinnerQuoteRequest = true;
            this.error = undefined;
            this.dataQuoteRequest = result.lstQuoteRequestsToDisplay;//RRA - ticket 585 - 06122022
            this.titleCountQuoteRequest = this.dataQuoteRequest.length > 0 ? 'Quote Requests' + ' (' + result.lstQuoteRequestsToDisplay.length + ')' : 'Quote Requests (0)' ; //RRA - ticket 585 - 06122022

            let reinsurerNameUrl;
            let customType;
            let disableLink;
            let quoteValue;
            let linkCSS;
            let isDeactivatedProg = result.isDeactivatedProg;
            //let isActivatedTreaty;  //RRA - ticket 585 - 15032023
            //let isActivatedSection;  //RRA - ticket 585 - 15032023
            //let lstStatutSecTreat = result.lstStatusQuoteSecTreaty;   //RRA - ticket 585 - 15032023
            //console.log(' lstStatutSecTreat == ',  lstStatutSecTreat);

            //RRA - ticket 585 - 15032023
            /*if (lstStatutSecTreat.includes('2')){
                isActivatedSection = false;
                isActivatedTreaty = false
            }else{
                isActivatedSection = true;
                isActivatedTreaty= true;
            }
            console.log(' isDeactivatedProg Quote== ',  isDeactivatedProg);
            console.log(' isActivatedTreaty Quote== ',  isActivatedTreaty);
            console.log(' isActivatedSection Quote== ',  isActivatedSection);*/

            //RRA - ticket 585 - 15032023
            // Check Treaty
            /*if (isActivatedTreaty == false){
                this.newLeadReqBtn = isActivatedTreaty; 
                this.disableLeadInfo = isActivatedTreaty; 
                this.errorClickBtn = true;
            }
            //Check Section
            else if (isActivatedSection == false){
                this.newLeadReqBtn = isActivatedSection; 
                this.disableLeadInfo = isActivatedSection; 
                this.errorClickBtn = true;
            }else {*/
                //RRA - ticket 585 - 06122022
                if (isDeactivatedProg &&  this.dataQuoteRequest.length == 0){
                    this.allReadOnly = isDeactivatedProg;
                }/*else if (isActivatedTreaty &&  this.dataQuoteRequest.length == 0){
                    this.allReadOnly = false;
                }else if (isActivatedSection &&  this.dataQuoteRequest.length == 0){
                    this.allReadOnly = false;
                }*/else{
                    this.dataQuoteRequest = result.lstQuoteRequestsToDisplay.map(row => {
                    reinsurerNameUrl = '../n/RespondOnBehalf?c__id='+row.Id+'-'+this.selectedProgram+'-'+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.statusQuote+'-'+this.valueTreaty+'-'+this.selectedBroker+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus +'-'+row.ReinsurerStatus__c;
                    customType = 'url';
                    if (isDeactivatedProg && this.dataQuoteRequest.length > 0){
                        this.allReadOnly = isDeactivatedProg; //RRA - ticket 585 06122022
                    } /*else if (isActivatedTreaty && this.dataQuoteRequest.length > 0){
                        this.allReadOnly = false; //RRA - ticket 585 1303202
                    }else if (isActivatedSection && this.dataQuoteRequest.length > 0){
                        this.allReadOnly = false; //RRA - ticket 585 1303202
                    }*/
                    if(row.Section__r != undefined){
                        if(row.Section__r.QuoteType__c == '1'){
                            if(row.FixedRate__c != undefined  && row.FixedRate__c != null){
                                quoteValue = parseFloat(row.FixedRate__c).toFixed(6) + '%';
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '2'){
                            if(row.MinRate__c != null && row.MaxRate__c != null && row.ProvisionalRate__c != null){
                                quoteValue = parseFloat(row.MinRate__c).toFixed(6) + '%/' + parseFloat(row.MaxRate__c).toFixed(6) + '%/' + parseFloat(row.ProvisionalRate__c).toFixed(6);
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '3'){
                            if(row.FlatPremium__c != undefined  && row.FlatPremium__c != ''){
                                quoteValue = parseFloat(row.FlatPremium__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '4'){
                            if(row.MDP__c != undefined  && row.MDP__c != ''){
                                quoteValue = parseFloat(row.MDP__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '5'){
                            if(row.FixedCommission__c != null){
                                quoteValue = parseFloat(row.FixedCommission__c).toFixed(6) + '%';
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '6'){
                            if(row.MinVarCommission__c != null && row.MaxVarCommission__c != null && row.ProvisionalCommission__c != null){
                                quoteValue = parseFloat(row.MinVarCommission__c).toFixed(6) + '%/' + parseFloat(row.MaxVarCommission__c).toFixed(6) + '%/' + parseFloat(row.ProvisionalCommission__c).toFixed(6);
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '7'){
                            if(row.PerHeadPremium__c != undefined && row.PerHeadPremium__c != ''){
                                quoteValue = parseFloat(row.PerHeadPremium__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '8'){
                            if(row.MinPerHeadAmount__c != null && row.MaxPerHeadAmount__c != null && row.ProvisionalPerHeadPremium__c != null){
                                quoteValue = row.MinPerHeadAmount__c  + '/' + row.MaxPerHeadAmount__c  + '/' + row.ProvisionalPerHeadPremium__c;
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '9' && row.Section__r.TECH_TypeofTreaty__c == '3'){
                            if(row.EstimatedInsurancePremium__c != undefined && row.EstimatedInsurancePremium__c != ''){
                                quoteValue = parseFloat(row.EstimatedInsurancePremium__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '9' && row.Section__r.TECH_TypeofTreaty__c == '4'){
                            if(row.EstimatedReinsurancePremium__c != undefined && row.EstimatedReinsurancePremium__c != ''){
                                quoteValue = parseFloat(row.EstimatedReinsurancePremium__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                        else if(row.Section__r.QuoteType__c == '10'){
                            if(row.PerHeadPremium__c != undefined && row.PerHeadPremium__c != ''){
                                quoteValue = parseFloat(row.PerHeadPremium__c).toString();
                            }
                            else{
                                quoteValue = '';
                            }
                        }
                    }
                    return {...row , reinsurerNameUrl, quoteValue, disableLink, customType}
                });
              }
            //}

            console.log('  this.errorClickBtn Quote== ', this.errorClickBtn);

            for(var i = 0; i < this.dataQuoteRequest.length; i++){
                this.dataQuoteRequest[i]['SectionNumber'] = this.dataQuoteRequest[i].Section__r.SectionNumber__c;
            }

            //this.sortData('TECH_Layer__c','SectionNumber' ,'TECH_ReinsurerName__c', 'asc');//RRA - ticket 1571 09202023
            this.spinnerQuoteRequest = false;
        })
        .catch(error => {
            this.error = error;
            this.spinnerQuoteRequest = false;
        });
    }

    handleOpenQuoteRequestModal(){
            if(this.treatyOptions.length == 1){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.TreatyNotAvailableForProgram, variant: 'error' }),);
            }
            else{
                isProgramRenewed({ programId: this.selectedProgram })
                .then(result => {
                    this.isProgramRenewed = result;
                    console.log('result handleOpenQuoteRequestModal ==' , result);
                })
                .catch(error => {
                    this.error = error;
                });
    
                this.isQuoteRequestOpenModal = true;
                this.lstBrokerReins = [];
                this.titleCountBrokerReinsurer = 'Brokers / Reinsurers (0)';
                this.selectedBrokerText = null;
                this.selectedBrokerName = null;
                this.selectedBrokerId = null;
                this.valueTreaty = 'All';
            }
    }

    handleCloseQuoteRequestModal(){
        this.isQuoteRequestOpenModal = false;
        this.lstBrokerReins = [];
        this.titleCountBrokerReinsurer = 'Brokers / Reinsurers (0)';
        this.selectedBrokerText = null;
        this.selectedBrokerName = null;
        this.selectedBrokerId = null;
        this.valueTreaty = null;
        this.disableQuoteReqSaveBtn = true;
    }

    @wire(getTreaties, {programId: '$selectedProgram'})
    wiredGetTreaties(result){
        this.wiredtreaties = result;
        if(result.data){
            let all = { label: "All", value:"All" };
            let treatyOpt = [];

            for(let i = 0; i < result.data.length; i++){
                treatyOpt.push(result.data[i]);
            }

            treatyOpt.push(all);
            
            console.log('treatyOpt getTreaties ==' , treatyOpt);
            
            this.treatyOptions = treatyOpt;
            this.valueTreaty = 'All';
        }
        else if(result.error){
            this.error = result.error;
        }
    }

    @wire(getAccountBroker)
    wiredGetAccountBroker(result){
        this.wiredAccountBroker = result;
        if(result.data) {
            this.brokerOptions = result.data;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
        }
    }

    handleChangeTreaty(event){
        this.valueTreaty = event.detail.value;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    handleChangeBroker(event){
        this.valueBroker = event.detail.value;
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    handleChangeRequestType(event){
        let requestTypeVal = event.currentTarget.value;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedRequest = [];

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            let request = this.lstBrokerReins[i];
            if(this.lstBrokerReins[i].TreatyBrokerReinsurer == selectedIdVal){
                request.QuoteType__c = requestTypeVal;
            }
            lstUpdatedRequest.push(request);
        }
        this.lstBrokerReins = lstUpdatedRequest;
        this.getQuoteRequests();
    }

    handleChangeBrokerReinsCheckbox(event){
        let checkboxChecked = event.currentTarget.checked;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedRequest = [];

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            let request = this.lstBrokerReins[i];
            if(this.lstBrokerReins[i].TreatyBrokerReinsurer == selectedIdVal){
                request.Checked = checkboxChecked;
            }
            lstUpdatedRequest.push(request);
        }

        this.lstBrokerReins = lstUpdatedRequest;
        this.getQuoteRequests();
    }

    handleDeleteRequestBtn(){

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            if(this.lstBrokerReins[i].Checked == true){
                this.lstSelectedRequest.push(this.lstBrokerReins[i]);
            }
        }

        this.lstBrokerReins = this.lstBrokerReins.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedRequest);
        if(this.lstBrokerReins.length == 0){
            this.disableQuoteReqSaveBtn = true;
        }
        this.spinnerQuoteRequest = true;
        this.getQuoteRequests();
    }

    handleSaveBrokerReins(){
        let lstRequestToInsert = [];
        let requestTypeEmpty = false;
        let idProgram;
        let lstTreatyId = [];
        this.spinnerQuoteRequest = true; //RRA - ticket 1381 - 16122022
        this.disableQuoteReqSaveBtn = true;//RRA - ticket 1381 - 16122022
        let lstReinsurerBroker = []; //RRA - ticket 1571 - 14092023
        
        console.log('lstBrokerReins == ', this.lstBrokerReins);
        for(let i = 0; i < this.lstBrokerReins.length; i++){    
            let objReinsurer = {
                Reinsurer__c : REINSURER_FIELD,
                Broker__c : BROKER_FIELD,
                Treaty__c : TREATY_FIELD,
                Section__c: SECTION_FIELD, //RRA - ticket 1571 - 18092023
                Program__c : PROGRAM_FIELD,
                TECH_PhaseType__c: TECH_PHASETYPE_FIELD,
                QuoteType__c : REQUEST_TYPE_FIELD
            }
            //RRA - ticket 1571 - 15092023
            if(this.lstBrokerReins[i].Broker__c == null || this.lstBrokerReins[i].Broker__c == undefined){
                lstReinsurerBroker.push(this.lstBrokerReins[i].Treaty__c + '-' + this.lstBrokerReins[i].Reinsurer__c);
            }
            else{
                lstReinsurerBroker.push(this.lstBrokerReins[i].Treaty__c + '-' + this.lstBrokerReins[i].Broker__c + '-' + this.lstBrokerReins[i].Reinsurer__c);
            }
            console.log('lstReinsurerBroker == ', lstReinsurerBroker);
            console.log('this.lstBrokerReins[i].Section__c == ', this.lstBrokerReins[i].Section__c);
            objReinsurer.Reinsurer__c = this.lstBrokerReins[i].Reinsurer__c;
            objReinsurer.Broker__c = this.lstBrokerReins[i].Broker__c;
            objReinsurer.Treaty__c = this.lstBrokerReins[i].Treaty__c;
            objReinsurer.Section__c = this.lstBrokerReins[i].Section__c; //RRA - ticket 1571 - 18092023
            objReinsurer.Program__c = this.lstBrokerReins[i].Program__c;
            objReinsurer.QuoteType__c = this.lstBrokerReins[i].QuoteType__c;          
            objReinsurer.TECH_PhaseType__c = '3';
            lstRequestToInsert.push(objReinsurer);
            
            console.log('lstRequestToInsert == ', lstRequestToInsert);
            
            if(this.lstBrokerReins[i].QuoteType__c == null){
                requestTypeEmpty = true;
            }
            lstTreatyId.push(this.lstBrokerReins[i].Treaty__c);
            idProgram = this.lstBrokerReins[0].Program__c
        }

        if(requestTypeEmpty == true){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RequiredRequestTypeMissing, variant: 'error' }),);
        }
        else if(lstRequestToInsert.length == 0){
            this.disableQuoteReqSaveBtn = true;
        }
        else{
            
            //RRA - ticket 1571 - 13092023
            checkReinsurerBroker({ lstIds : lstReinsurerBroker, programId : idProgram, recordTypeName : 'Quote'})
            .then(result => {
                console.log('result == ', result);
                if(result == true){
                    this.isQuoteRequestOpenModal = true;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.requestQuoteExistAlready, variant: 'error'}), );
                }
                else{
                    saveReinsurer({lstRequest : lstRequestToInsert, lstTreaty : lstTreatyId})
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                        }
                        else{
                            let lstNewRequest = result.lstRequestDetails;
                            let reinsurerNameUrl;
                            let disableLink;
        
                            lstNewRequest = lstNewRequest.map(row => {
                                reinsurerNameUrl = '../n/RespondOnBehalf?c__id='+row.Id+'-'+this.selectedProgram+'-'+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.statusQuote+'-'+this.valueTreaty+'-'+this.selectedBroker+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus+'-'+row.ReinsurerStatus__c;
                                return {...row , reinsurerNameUrl, disableLink}
                            });
        
                            let lstAllRequest = [];
        
                            for(let i = 0; i < this.dataQuoteRequest.length; i++){
                                lstAllRequest.push(this.dataQuoteRequest[i]);
                            }
        
                            for(let i = 0; i < lstNewRequest.length; i++){
                                lstNewRequest[i]['SectionNumber'] = lstNewRequest[i].Section__r.SectionNumber__c;
                                lstAllRequest.push(lstNewRequest[i]);
                            }
        
                            this.dataQuoteRequest = lstAllRequest;
        
                            //this.sortData('TECH_Layer__c','SectionNumber' ,'TECH_ReinsurerName__c', 'asc');//RRA - ticket 1571 09202023
                            this.titleCountQuoteRequest = 'Quote Requests' + ' (' + this.dataQuoteRequest.length + ')';
                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.QuoteRequestsCreatedSuccessfully, variant: 'success' }),);
                            fireEvent(this.pageRef, 'refreshBrokerFilters', '');
                            fireEvent(this.pageRef, 'refreshReinsurerFilters', '');
                            this.disableQuoteReqSaveBtn = true; //RRA - ticket 1381 - 16122022
                            this.getQuoteRequests();
                            this.isQuoteRequestOpenModal = false; //RRA - ticket 1571 - 13092023
                        }
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                    });
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
            //this.isQuoteRequestOpenModal = false;
        }
        this.spinnerQuoteRequest = false; //RRA - ticket 1381 - 16122022
    }

    handleOpenNewReinsurerModal(){
        this.disableConfirmReinsurerBtn = true;
        if(this.valueTreaty == undefined || this.valueTreaty == null){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyField, variant: 'error' }),);
        }
        else if(this.valueTreaty == 'All' && this.treatyOptions.length == 1){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyAvailable, variant: 'error' }),);
        }
        else{
            this.isNewReinsurerOpenModal = true;
        }
    }

    handleCloseNewReinsurerModal(){
        this.isNewReinsurerOpenModal = false;
        this.disableConfirmReinsurerBtn = true;
        this.selectedRecords = [];
        this.selectedRein = [];
    }

    searchReinsurerLookupField(event){
        let currentText = event.target.value;
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.loadingText = true;

        getReinsurer({ ObjectName: this.objectName, fieldName: this.fieldName, value: currentText, selectedRecId : selectRecId })
        .then(result => {
            this.searchReinsurerLookupRecords = result;
            this.loadingText = false;
            this.txtReinsurerLookUpclassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    setSelectedReinsurerLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let treatyName = '';
        let brokerName = this.getPicklistLabel(this.brokerOptions, this.selectedBrokerId);
        let reinsurerObj = {  'recId' : recId ,'recName' : selectName };
        this.selectedRein.push(reinsurerObj);
        
        //RRA - ticket 1571 - 15092023
        for(let i = 0; i < this.treatyOptions.length - 1; i++){
            this.mapTreatyOptions.set(this.treatyOptions[i].value, this.treatyOptions[i].idSec);
        }
        if(this.valueTreaty == 'All'){

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                this.selectedId = this.selectedId + 1;
                let newsObject = { 'recId' : recId ,'recName' : selectName
                                    , 'TECH_ReinsurerName__c' : selectName
                                    , 'TECH_BrokerName__c' : this.selectedBrokerName
                                    , 'TECH_TreatyName__c' : this.treatyOptions[i].label
                                    , 'Reinsurer__c' : recId
                                    , 'Broker__c' : this.selectedBrokerId
                                    , 'QuoteType__c' : '1'
                                    , 'Treaty__c' : this.treatyOptions[i].value
                                    , 'Section__c' : this.treatyOptions[i].idSec //RRA - ticket 1571 - 15092023
                                    , 'Checked' : false
                                    , 'Program__c' : this.selectedProgram
                                    , 'selectedId' : this.selectedId
                                    , 'BrokerReinsurer' : this.selectedBrokerId + '-' + recId
                                    , 'TreatyBrokerReinsurer' : this.treatyOptions[i].value + '-' + this.selectedBrokerId + '-' + recId
                };
                this.selectedRecords.push(newsObject);
            }
        }
        else{
            console.log(' this.treatyOptions single value ==', this.treatyOptions);
            console.log(' valueTreaty single value ==', this.valueTreaty);
            
             //RRA - ticket 1571 - 15092023
            treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);
            this.selectedId = this.selectedId + 1;

            let newsObject = { 'recId' : recId ,'recName' : selectName
                                , 'TECH_ReinsurerName__c' : selectName
                                , 'TECH_BrokerName__c' : this.selectedBrokerName
                                , 'TECH_TreatyName__c' : treatyName
                                , 'Reinsurer__c' : recId
                                , 'Broker__c' : this.selectedBrokerId
                                , 'QuoteType__c' : '1'
                                , 'Treaty__c' : this.valueTreaty
                                , 'Section__c' : this.mapTreatyOptions.get(this.valueTreaty)  //RRA - ticket 1571 - 15092023
                                , 'Checked' : false
                                , 'Program__c' : this.selectedProgram
                                , 'selectedId' : this.selectedId
                                , 'BrokerReinsurer' : this.selectedBrokerId + '-' + recId
                                , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + this.selectedBrokerId + '-' + recId
            };

            this.selectedRecords.push(newsObject);
        }

        if(this.selectedRein.length == 0){
            this.disableConfirmReinsurerBtn = true;
        }
        else{
            this.disableConfirmReinsurerBtn = false;
        }

        this.txtReinsurerLookUpclassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let selRecords = this.selectedRein;
        this.searchText = null;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        this.dispatchEvent(selectedEvent);

        let selRecordsBrokerRein = this.selectedRecords;
        const selectedEventBrokerRein = new CustomEvent('selectedBrokerRein', { detail: {selRecordsBrokerRein}, });
        this.dispatchEvent(selectedEventBrokerRein);
    }

    removeReinsurerLookupRecord(event){
        let selectRecId = [];
        let selectRecIdBrokerRein = [];

        for(let i = 0; i < this.selectedRein.length; i++){
            if(event.detail.name !== this.selectedRein[i].recId){
                selectRecId.push(this.selectedRein[i]);
            }
        }

        this.selectedRein = [...selectRecId];
        let selRecords = this.selectedRein;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        this.dispatchEvent(selectedEvent);

        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId){
                selectRecIdBrokerRein.push(this.selectedRecords[i]);
            }
        }

        this.selectedRecords = [...selectRecIdBrokerRein];
        let selRecordsBrokerRein = this.selectedRecords;
        const selectedEventBrokerRein = new CustomEvent('selectedBrokerRein', { detail: {selRecordsBrokerRein}, });
        this.dispatchEvent(selectedEventBrokerRein);

        if(this.selectedRein.length == 0){
            this.disableConfirmReinsurerBtn = true;
        }
        else{
            this.disableConfirmReinsurerBtn = false;
        }
    }

    handleConfirmReinsurer(){
        console.log('this.lstBrokerReins  COMFIRM ==', this.lstBrokerReins );
        if(this.lstBrokerReins != undefined){
            for(let j = 0; j < this.lstBrokerReins.length; j++){
                this.selectedRecords.push(this.lstBrokerReins[j]);
            }
        }
        
        console.log('this.selectedRecords  COMFIRM ==', this.selectedRecords );

        this.lstBrokerReins = this.getUniqueData(this.selectedRecords, 'TreatyBrokerReinsurer');
        this.titleCountBrokerReinsurer = 'Brokers / Reinsurers' + ' (' + this.lstBrokerReins.length + ')';
        this.selectedRecords = [];
        this.selectedRein = [];
        this.isNewReinsurerOpenModal = false;
        this.disableQuoteReqSaveBtn = false;
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    searchBrokerLookUpField(event){
        let currentText = event.target.value;
        let selectRecId = [];
        if(currentText == ''){
            this.selectedBrokerText = null;
            this.selectedBrokerName = null;
            this.selectedBrokerId = null;
        }

        this.loadingText = true;

        getBroker({ ObjectName: 'Account', fieldName: 'Name', value: currentText, selectedRecId : selectRecId })
        .then(result => {
            this.searchBrokerLookupRecords = result;
            this.loadingText = false;

            this.txtBrokerLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    setSelectedBrokerLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let brokerName = '';
        let treatyName = '';
        this.txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.selectedBrokerText = selectName;
        this.selectedBrokerName = selectName;
        this.selectedBrokerId = recId;
    }
    
    //RRA - ticket 1371 - 01082023
    loadFromCurrentYearBtn(){
        let lstOnlyBroker = [];
        let lstOnlyReinsurer = [];
        this.spinnerLoadCurrentYear = true;  
        if(this.valueTreaty == undefined || this.valueTreaty == null){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyField, variant: 'error' }),);
        }
        else if(this.valueTreaty == 'All' && this.treatyOptions.length == 1){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyAvailable, variant: 'error' }),);
        }
        else{
            console.log('programId == ', this.selectedProgram);
            loadCurrentYearQuoteRequest({programId: this.selectedProgram})
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                        }
                        else{
                            if (result.lstRequest.length > 0 ){
                                this.isLoadFromCurrentYrModalOpen = true;
                                this.loadFromCurrentYrTitle = 'Load from ' + result.uwy;
                                this.error = undefined;     
                                let treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);
                                let lstLoadFromCurrentYrData = result.lstRequest;
                                console.log('lstLoadFromCurrentYrData == ', lstLoadFromCurrentYrData);
                                refreshApex(lstLoadFromCurrentYrData);
                                let lstLoadCurrentQuoteRequest = [];
                                let newsObject = {};
                                console.log('programId == ', this.selectedProgram);
                                for(let i = 0; i < lstLoadFromCurrentYrData.length; i++){
                                    this.selectedId = this.selectedId + 1;
                                    newsObject = { 'recId' : lstLoadFromCurrentYrData[i].Reinsurer__c
                                    ,'recName' : lstLoadFromCurrentYrData[i].TECH_ReinsurerName__c 
                                    , 'TECH_ReinsurerName__c' : lstLoadFromCurrentYrData[i].TECH_ReinsurerName__c
                                    , 'TECH_BrokerName__c' : lstLoadFromCurrentYrData[i].TECH_BrokerName__c
                                    , 'TECH_TreatyName__c' : treatyName
                                    , 'Reinsurer__c' : lstLoadFromCurrentYrData[i].Reinsurer__c
                                    , 'Broker__c' : lstLoadFromCurrentYrData[i].Broker__c 
                                    , 'QuoteType__c' : '1'
                                    , 'Treaty__c' : this.valueTreaty
                                    , 'Section__c' : lstLoadFromCurrentYrData[i].Section__c //RRA - ticket 1571 - 15092023
                                    , 'Checked' : false
                                    , 'selectedId' : this.selectedId
                                    , 'Program__c' : this.selectedProgram
                                    , 'BrokerReinsurer' : lstLoadFromCurrentYrData[i].Broker__c + '-' + lstLoadFromCurrentYrData[i].Reinsurer__c
                                    , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + lstLoadFromCurrentYrData[i].Broker__c + '-' + lstLoadFromCurrentYrData[i].Reinsurer__c
                                    };
                                    lstLoadCurrentQuoteRequest.push(newsObject);
                                } 
                                    console.log('lstLoadPrevQuoteRequest == ', lstLoadCurrentQuoteRequest);
                                    let lstFilterLoadedCurrentRequest = this.getUniqueData(lstLoadCurrentQuoteRequest, 'TreatyBrokerReinsurer');
                                    console.log('lstFilterLoadedCurrentRequest == ', lstFilterLoadedCurrentRequest);
                                    
                                    lstFilterLoadedCurrentRequest = lstFilterLoadedCurrentRequest.map(row => {
                                        if (row.TECH_BrokerName__c !== undefined && row.TECH_ReinsurerName__c !== undefined) {
                                            lstOnlyBroker.push({...row }) ;
                                        }
                                        else if(row.TECH_BrokerName__c === undefined && row.TECH_ReinsurerName__c !== undefined){
                                            lstOnlyReinsurer.push({...row}) ;
                                        }
                                        return {...row }
                                    });
                
                                    lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.TECH_BrokerName__c.localeCompare(b.TECH_BrokerName__c)) || (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                                    lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                                    this.dataLoadFromCurrentYr = lstOnlyBroker.concat(lstOnlyReinsurer);
                                    
                                    let lstUpdateReinsurerFromCurrYr = this.getUniqueData(this.dataLoadFromCurrentYr, 'BrokerReinsurer'); //RRA - ticket 1571 - 11102023
                                    this.dataLoadFromCurrentYr = lstUpdateReinsurerFromCurrYr;
                                    console.log('dataLoadFromCurrentYr == ', this.dataLoadFromCurrentYr);

                            }else{
                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'No request(s) for Current year', variant: 'error' }),);
                            }
                            
                        }
                        
                        this.lstBrokerReins = this.getUniqueData(this.lstBrokerReins, 'TreatyBrokerReinsurer');
                        this.titleCountBrokerReinsurer = 'Brokers / Reinsurers' + ' (' + this.lstBrokerReins.length + ')';

                        if(this.lstBrokerReins.length == 0){
                            this.disableQuoteReqSaveBtn = true;
                        }
                        else{
                            this.disableQuoteReqSaveBtn = false;
                        }
                        window.setTimeout(() => { this.spinnerLoadCurrentYear = false;}, 2000)
                        //this.spinnerLoadPreviousYear = false;  //RRA - ticket 1299 02/11/2022 
                        
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                    });
            }
    }

    loadFromPrevYearBtn(){
        if(this.valueTreaty == undefined || this.valueTreaty == null){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyField, variant: 'error' }),);
        }
        else if(this.valueTreaty == 'All' && this.treatyOptions.length == 1){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyAvailable, variant: 'error' }),);
        }
        else{
            console.log('programId Previous== ', this.selectedProgram);
            console.log('valueTreaty Previous == ', this.valueTreaty);
            //RRA --
            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                if(this.valueTreaty == 'All' || this.valueTreaty == this.treatyOptions[i].value){
                    this.mapIdTreatyIdSec.set(this.treatyOptions[i].value,  this.treatyOptions[i].idSec);//RRA - ticket 1571 - 18092023
                }
            }
            loadPreviousYearQuoteRequest({programId: this.selectedProgram, selectedTreaty : this.valueTreaty})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                }
                else{
                    this.isLoadFromPrevYrModalOpen = true;
                    this.loadFromPrevYrTitle = this.loadFromPrevYrTitle;
                    this.error = undefined;     
                    let treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);
                    let lstLoadFromPrevYrData = result.lstRequest;
                    let lstLoadPrevQuoteRequest = [];
                    let lstOnlyBroker = [];
                    let lstOnlyReinsurer = [];
                    console.log('lstLoadFromPrevYrData == ', lstLoadFromPrevYrData);
                     console.log('valueTreaty 11 == ', this.valueTreaty);
                     console.log('treatyName 11 == ', treatyName);
                    //RRA - ticket 1571 - 15092023
                    
                    for(let i = 0; i < lstLoadFromPrevYrData.length; i++){
                        //this.mapLoadPreviousQuoteOptions.set(lstLoadFromPrevYrData[i].Treaty__c, lstLoadFromPrevYrData[i].Section__c);
                        this.selectedId = this.selectedId + 1;
                        let newsObject = { 'recId' : lstLoadFromPrevYrData[i].Reinsurer__c
                                            ,'recName' : lstLoadFromPrevYrData[i].TECH_ReinsurerName__c
                                            , 'TECH_ReinsurerName__c' : lstLoadFromPrevYrData[i].TECH_ReinsurerName__c
                                            , 'TECH_BrokerName__c' : lstLoadFromPrevYrData[i].TECH_BrokerName__c
                                            , 'TECH_TreatyName__c' : treatyName
                                            , 'Reinsurer__c' : lstLoadFromPrevYrData[i].Reinsurer__c
                                            , 'Broker__c' : lstLoadFromPrevYrData[i].Broker__c
                                            , 'QuoteType__c' : '1'
                                            , 'Treaty__c' : this.valueTreaty
                                            , 'Section__c' :  this.mapIdTreatyIdSec.get(this.valueTreaty)//RRA - ticket 1571 - 18092023
                                            , 'Checked' : false
                                            , 'selectedId' : this.selectedId
                                            , 'Program__c' : this.selectedProgram
                                            , 'BrokerReinsurer' : lstLoadFromPrevYrData[i].Broker__c + '-' + lstLoadFromPrevYrData[i].Reinsurer__c
                                            , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + lstLoadFromPrevYrData[i].Broker__c + '-' + lstLoadFromPrevYrData[i].Reinsurer__c
                        };
                        lstLoadPrevQuoteRequest.push(newsObject);
                    }
                    let lstFilterLoadedPrevRequest = this.getUniqueData(lstLoadPrevQuoteRequest, 'TreatyBrokerReinsurer');
                    console.log('lstFilterLoadedPrevRequest == ', lstFilterLoadedPrevRequest);
                    //RRA - ticket 1099 - 09122022
                    lstFilterLoadedPrevRequest = lstFilterLoadedPrevRequest.map(row => {
                        if (row.TECH_BrokerName__c !== undefined && row.TECH_ReinsurerName__c !== undefined) {
                            lstOnlyBroker.push({...row }) ;
                        }
                        else if(row.TECH_BrokerName__c === undefined && row.TECH_ReinsurerName__c !== undefined){
                            lstOnlyReinsurer.push({...row}) ;
                        }
                        return {...row }
                    });

                    //RRA - ticket 1099 - 09122022
                    lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.TECH_BrokerName__c.localeCompare(b.TECH_BrokerName__c)) || (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                    lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;

                    //this.dataLoadFromPrevYr = lstFilterLoadedPrevRequest;
                    //RRA - ticket 1099 - 09122022
                    this.dataLoadFromPrevYr = lstOnlyBroker.concat(lstOnlyReinsurer);
                    let lstUpdateReinsurerFromPrevYr = this.getUniqueData(this.dataLoadFromPrevYr, 'BrokerReinsurer'); //RRA - ticket 1571 - 11102023
                    this.dataLoadFromPrevYr = lstUpdateReinsurerFromPrevYr;
                    //return refreshApex (this.dataLoadFromPrevYr);
                }
                
                this.lstBrokerReins = this.getUniqueData(this.lstBrokerReins, 'TreatyBrokerReinsurer');
                console.log('lstBrokerReins loadFromPrevious == ', this.lstBrokerReins );
                this.titleCountBrokerReinsurer = 'Brokers / Reinsurers' + ' (' + this.lstBrokerReins.length + ')';

                if(this.lstBrokerReins.length == 0){
                    this.disableQuoteReqSaveBtn = true;
                }
                else{
                    this.disableQuoteReqSaveBtn = false;
                }
                
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }
    
    //RRA - ticket 1371 - 01082023
    handleLoadPopUpCurrent(event){
        if(this.lstSelectedCurrentBrokerReinsurer.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noBrokerRein, variant: 'error' }),);
        }
        else{
            //load from previous year
            let lstAvailableTreaty = [];

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                if(this.valueTreaty == 'All' || this.valueTreaty == this.treatyOptions[i].value){
                    lstAvailableTreaty.push(this.treatyOptions[i].value + '-' + this.treatyOptions[i].label);
                    this.mapIdTreatyIdSec.set(this.treatyOptions[i].value, this.treatyOptions[i].idSec);//RRA - ticket 1571 - 19092023
                }
            }

            let lstUpdBrokerReins = [ ...this.lstBrokerReins ];

            for(let i = 0; i < lstAvailableTreaty.length; i++){
                let treatyValue = lstAvailableTreaty[i].split('-')[0];
                let treatyLabel = lstAvailableTreaty[i].split('-')[1];
                for(let j = 0; j < this.lstSelectedCurrentBrokerReinsurer.length; j++){
                    let row = { ...this.lstSelectedCurrentBrokerReinsurer[j] };
                    row['Treaty__c'] = treatyValue;
                    row['Section__c'] = this.mapIdTreatyIdSec.get(treatyValue);//RRA - ticket 1571 - 19092023
                    row['TECH_TreatyName__c'] = treatyLabel;
                    row['Broker__c'] = this.selectedBrokerId != null ? this.selectedBrokerId : row.Broker__c; //RRA - ticket 1299 02/11/2022 
                    row['Program__c'] = this.selectedProgram;
                    row['TreatyBrokerReinsurer'] = treatyValue + '-' + row.Broker__c + '-' + row.Reinsurer__c;
                    lstUpdBrokerReins.push(row);
                }
            }

            this.lstBrokerReins = this.getUniqueData(lstUpdBrokerReins, 'TreatyBrokerReinsurer');
            this.titleCountBrokerReinsurer = 'Brokers / Reinsurers (' + this.lstBrokerReins.length + ')';

            if(this.lstBrokerReins.length == 0){
                this.disableQuoteReqSaveBtn = true;
            }
            else{
                this.disableQuoteReqSaveBtn = false;
            }
            this.handleCloseLoadFromCurrentYrModal();
        }
    }

    handleLoadPopUp(event){
        if(this.lstSelectedBrokerReinsurer.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noBrokerRein, variant: 'error' }),);
        }
        else{
            //load from previous year
            let lstAvailableTreaty = [];

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                if(this.valueTreaty == 'All' || this.valueTreaty == this.treatyOptions[i].value){
                    lstAvailableTreaty.push(this.treatyOptions[i].value + '-' + this.treatyOptions[i].label);
                    this.mapIdTreatyIdSec.set(this.treatyOptions[i].value, this.treatyOptions[i].idSec);//RRA - ticket 1571 - 18092023
                }
            }

            let lstUpdBrokerReins = [ ...this.lstBrokerReins ];

            for(let i = 0; i < lstAvailableTreaty.length; i++){
                let treatyValue = lstAvailableTreaty[i].split('-')[0];
                let treatyLabel = lstAvailableTreaty[i].split('-')[1];
                for(let j = 0; j < this.lstSelectedBrokerReinsurer.length; j++){
                    let row = { ...this.lstSelectedBrokerReinsurer[j] };
                    row['Treaty__c'] = treatyValue;
                    row['Section__c'] = this.mapIdTreatyIdSec.get(treatyValue);//RRA - ticket 1571 - 18092023
                    row['TECH_TreatyName__c'] = treatyLabel;
                    row['Program__c'] = this.selectedProgram;
                    row['TreatyBrokerReinsurer'] = treatyValue + '-' + row.Broker__c + '-' + row.Reinsurer__c;
                    lstUpdBrokerReins.push(row);
                }
            }
            
            console.log('lstUpdBrokerReins 22 == ', lstUpdBrokerReins);

            this.lstBrokerReins = this.getUniqueData(lstUpdBrokerReins, 'TreatyBrokerReinsurer');
            this.titleCountBrokerReinsurer = 'Brokers / Reinsurers (' + this.lstBrokerReins.length + ')';

            if(this.lstBrokerReins.length == 0){
                this.disableQuoteReqSaveBtn = true;
            }
            else{
                this.disableQuoteReqSaveBtn = false;
            }
            this.handleCloseLoadFromPrevYrModal();
        }
    }

    handleBrokerReinsurerRowSelection(event){
        this.lstSelectedBrokerReinsurer = event.detail.selectedRows;
    }
    
    //RRA - ticket 1371 - 02082023
    handleBrokerReinsurerRowSelectionCurrent(event){
        this.lstSelectedCurrentBrokerReinsurer = event.detail.selectedRows;
    }

    getPicklistLabel(picklistOptions, selectedPicklistOpt){
        for(let i = 0; i < picklistOptions.length; i++){
            if(picklistOptions[i].value == selectedPicklistOpt){
                return picklistOptions[i].label;
            }
        }
    }

    handleCloseRespondOnBehalfModal(){
        this.isOpenRespondOnBehalf = false;
    }


    reactivateBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoQuoteRequestsSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Reactivate Quote Request';
            //You are going to reactivate the selected Quote Request(s). Do you want to continue?
            this.status = this.label.AskToReactivateQuote;
            this.statusFunction = 'reactivate';
            this.isOpenConfirmation = true;
        }
    }

    deactivateBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoQuoteRequestsSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Deactivate Quote Request';
            //You are going to deactivate the selected Quote Request(s). Do you want to continue?
            this.status = this.label.AskToDeactivateQuote;
            this.statusFunction = 'deactivate';
            this.isOpenConfirmation = true;
        }
    }

    acceptStatusChange(){
        this.spinnerQuoteRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoQuoteRequestsSelected,
                    variant: 'error',
                }),
            );
            this.spinnerQuoteRequest = false;
        }
        else{
            for (var key in selectedRequests) {
                var obj = selectedRequests[key];
                delete obj.QuoteType__c;
                delete obj.Quote__c;
            }

            if(this.statusFunction == 'reactivate'){
                changeStatus({lstRecords: selectedRequests, objectName: 'Request', status: '1', isButtonActDeact : false}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerQuoteRequest = false;
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                 title: 'Success',
                                 message: result.Success,
                                 variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshReq', 'refresh');
                        this.spinnerQuoteRequest = false;
                        this.getQuoteRequests();
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
            else if(this.statusFunction == 'deactivate'){
                changeStatus({lstRecords: selectedRequests, objectName: 'Request', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerQuoteRequest = false;
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result.Success,
                                variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshReq', 'refresh');
                        this.spinnerQuoteRequest = false;
                        this.getQuoteRequests();
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
        }
        this.isOpenConfirmation = false;
    }

    deleteBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests == ',selectedRequests);
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoQuoteRequestsSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.delMsgTitle = 'Delete Quote Request';
            //You are going to delete the Quote Request(s). Do you want to continue?
            this.delMessage = this.label.AskToDeleteQuote;
            this.isDeleteOpen = true;
        }
        
    }

    acceptDelete(){
        console.log('OK delete');
        this.spinnerQuoteRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests ==',selectedRequests);
        deletePrograms({lstRecords: selectedRequests, objectName: 'Request__c'})
        .then(result => {
            console.log('result = ', result);
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.spinnerQuoteRequest = false;
            }
            else{
                console.log('resultSuccess = ', result);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                         message: result.Success,
                         variant: 'success',
                    }),
                );
                this.spinnerQuoteRequest = false;
                fireEvent(this.pageRef, 'refreshReq', 'refresh');
                this.getQuoteRequests();
            }
        })
        .catch(error => {
            this.error = error;
        });
        this.isDeleteOpen = false;
    }

    handleCloseModal(){
        this.isOpenConfirmation = false;
        this.isDeleteOpen = false;
        this.isReqTypeOpen = false;
    }

    quoteInfoBtn(){
        //RRA - ticket 585 - 15032023
        let lstStatusConvert;
        let lstStatus = [];
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests == ',selectedRequests);
        let errorClickBtn = false;
        if (selectedRequests.length > 0){
            for (let i=0;i<selectedRequests.length;i++){
                lstStatus.push(selectedRequests[i].Treaty__r.Status__c + '_' + selectedRequests[i].Section__r.Status__c);
            }
            lstStatusConvert = JSON.parse(JSON.stringify(lstStatus));
            console.log('lstStatusConvert == ', lstStatusConvert);
            if (lstStatusConvert.includes('1_2') || lstStatusConvert.includes('2_1') || lstStatusConvert.includes('2_2')){
                errorClickBtn = true;
            }
            console.log('errorClickBtn == ', errorClickBtn);
        }
        if (errorClickBtn){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SomeQuoteRequestAssociatedCancelTreatySection, variant: 'error' }),);
        }else{
            if(selectedRequests.length == 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.label.NoQuoteRequestsSelected,
                        variant: 'error',
                    }),
                );
            }
            else{
                this.isReqTypeOpen = true;
            }
        }
    }

    acceptToggleReqType(){
        this.spinnerQuoteRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoQuoteRequestsSelected,
                    variant: 'error',
                }),
            );
            this.spinnerQuoteRequest = false;
            this.isReqTypeOpen = false;
        }
        else{
            for (var key in selectedRequests) {
                var obj = selectedRequests[key];
                delete obj.Quote__c;

                for(var req in this.requestTypeOptions){
                    var reqOpt = this.requestTypeOptions[req];
                    if(obj.QuoteType__c == reqOpt.label){
                        obj.QuoteType__c = reqOpt.value;
                    }
                }
            }

            toggleReqType({lstRecords: selectedRequests})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                    this.spinnerQuoteRequest = false;
                }
                else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                             title: 'Success',
                             message: result.Success,
                             variant: 'success',
                        }),
                    );
                    fireEvent(this.pageRef, 'refreshReq', 'refresh');
                    this.spinnerQuoteRequest = false;
                    this.getQuoteRequests();
                }
            })
            .catch(error => {
                this.error = error;
            });
            this.isReqTypeOpen = false;
        }
    }

    handleOpenSendUpdateRemindModal(event){
        //RRA - ticket 585 - 15032023
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests == ',selectedRequests);
        let errorClickBtn;
        let lstStatusConvert;
        let lstStatus = [];
            if (selectedRequests.length > 0){
                for (let i=0;i<selectedRequests.length;i++){
                    lstStatus.push(selectedRequests[i].Treaty__r.Status__c + '_' + selectedRequests[i].Section__r.Status__c)
                }
                lstStatusConvert = JSON.parse(JSON.stringify(lstStatus));
                console.log('lstStatusConvert == ', lstStatusConvert);
                if (lstStatusConvert.includes('1_2') || lstStatusConvert.includes('2_1') || lstStatusConvert.includes('2_2')){
                    errorClickBtn = true;
                }
                console.log('errorClickBtn == ', errorClickBtn);
            }
        if (errorClickBtn){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SomeQuoteRequestAssociatedCancelTreatySection, variant: 'error' }),);
        }else{
            if(selectedRequests.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoQuoteRequestsSelected, variant: 'error',}), );
            }
            else{
                this.selectedQuoteRequest = selectedRequests;
                this.btnNameSendUpdateRemind = event.currentTarget.name;
                let arr1 = [];
    
                for(var key in selectedRequests){
                    let ele = selectedRequests[key];
                    let obj = {};
                    obj.Broker = ele.Broker__c;
                    obj.Reinsurer = ele.Reinsurer__c;
                    obj.brokerRein = ele.Broker__c+'-'+ele.Reinsurer__c;
                    arr1.push(obj);
                }
    
                this.isSendUpdateRemindQuoteReqOpenModal = true;
                this.titlePopUp = this.btnNameSendUpdateRemind + ' Quote Request(s)';
                this.selectedQuoteRequest1 =  arr1;
            }
        }
    }

    handleCloseSendUpdateRemindModal(){
        this.isSendUpdateRemindQuoteReqOpenModal = false;
    }

    handleRowSelection(event){
        let lstSelectedRequest = event.detail.selectedRows;
        let isReinsurerStatusSetup = false;

        if(lstSelectedRequest.length > 0){
            for(let i = 0; i < lstSelectedRequest.length; i++){
                if(lstSelectedRequest[i].ReinsurerStatus__c == 'Setup'){
                    isReinsurerStatusSetup = true;
                }
            }
            if(isReinsurerStatusSetup == true || this.allReadOnly == true){
                this.disableUpdateRemind = true;
            }
            else{
                this.disableUpdateRemind = false;
            }
        }
        else{
            this.disableUpdateRemind = true;
        }
    }

    sortData(fieldName,fieldName2, fieldName3, sortDirection) {
        let sortResult = Object.assign([], this.dataQuoteRequest);
        this.dataQuoteRequest = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                if(a[fieldName2] < b[fieldName2])
                    return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])
                    return sortDirection === 'asc' ? 1 : -1;
                else{
                    if(a[fieldName3] < b[fieldName3])
                        return sortDirection === 'asc' ? -1 : 1;
                    else if(a[fieldName3] > b[fieldName3])
                        return sortDirection === 'asc' ? 1 : -1;
                    else
                        return 0;
                }
            }
        })
    }

    getUWYearForOriginalProgram(selectedProgram){
        getUWYearForOriginalProgram({programId: selectedProgram})
        .then(result => {
            if(result != null){
                this.loadFromPrevYrTitle = 'Load from ' + result;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    handleCloseLoadFromPrevYrModal(){
        this.isLoadFromPrevYrModalOpen = false;
        this.lstSelectedBrokerReinsurer = [];
    }
    
    //RRA - ticket 1371 - 01082023
    handleCloseLoadFromCurrentYrModal(){
        this.isLoadFromCurrentYrModalOpen = false;
        this.lstSelectedCurrentBrokerReinsurer = [];
    }
}