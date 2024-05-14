import {LightningElement, track, wire, api} from 'lwc';
import {getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getSectionDetail from '@salesforce/apex/LWC20_LeadRequests.getSectionDetail';
import disableLeadInfo from '@salesforce/apex/LWC20_LeadRequests.disableLeadInfo';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate';
import deletePrograms from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import toggleReqType from '@salesforce/apex/LWC20_LeadRequests.toggleRequestType';
import getSelectedProgramDetail from '@salesforce/apex/LWC20_LeadRequests.getSelectedProgramDetail';
import getTreaties from '@salesforce/apex/LWC21_NewLeadRequest.getTreaties';
import Id from '@salesforce/user/Id';
import REQUEST_TYPE_FIELD from '@salesforce/schema/Request__c.LeadType__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';

//Custom Label
import LeadRequestsAlreadyAvailableForTreaty from '@salesforce/label/c.LeadRequestsAlreadyAvailableForTreaty';
import NoLeadRequestSelected from '@salesforce/label/c.NoLeadRequestSelected';
import AskToReactivateLead from '@salesforce/label/c.AskToReactivateLead';
import AskToDeactivateLead from '@salesforce/label/c.AskToDeactivateLead';
import AskToDeleteLead from '@salesforce/label/c.AskToDeleteLead';
import SimulativeLead from '@salesforce/label/c.SimulativeLead';
import SendLeadRequest from '@salesforce/label/c.SendLeadRequest';
import leadRequestAlreadySent from '@salesforce/label/c.LeadRequestsTypeIsAlready_sent';//RRA - ticket 1484 - 06062023
import errorMsg from '@salesforce/label/c.errorMsg';
import SomeQuoteRequestAssociatedCancelTreatySection from '@salesforce/label/c.SomeQuoteRequestAssociatedCancelTreatySection';; //RRA - ticket 585 - 16032023

const columnsLeadRequest = [
    { label: 'Layer', fieldName: 'TECH_Layer__c' },
    { label: 'Treaty ref', fieldName: 'TreatyReference__c' },
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'reinsurerNameUrl', type: 'url', typeAttributes: {label: { fieldName: 'TECH_ReinsurerName__c' }, target: '_self'} },

    { label: 'Quote', fieldName: 'quoteValue',wrapText: true, initialWidth:270},// RRA - 935 //MRA W-0939 28/07/022
    { label: 'MDP', fieldName: 'mdp',wrapText: true },// RRA - 935

    { label: 'Written share', fieldName: 'WrittenShare__c' , type: 'number', cellAttributes: { alignment: 'left' },  typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'}},

    { label: '', fieldName: 'statusIconComment' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Comment__c' }, iconPosition: 'left'}, initialWidth: 50 }, //RRA - 939
    { label: '', fieldName: 'statusIconAttachFile' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Attachment__c' }, iconPosition:'left'}, initialWidth: 50 }, //RRA - 939

    { label: 'Definitive / Simulated', fieldName: 'LeadType__c' },
    { label: 'Reinsurer Status', fieldName: 'ReinsurerStatus__c' },
    { label: 'Last sent date', fieldName: 'LastSentDate__c' },
    { label: 'Expected answer date', fieldName: 'ExpectedResponseDate__c' },
    { label: 'Response Date', fieldName: 'ResponseDate__c' }
];

export default class LWC20_LeadRequests extends NavigationMixin(LightningElement) {
    label = {
        LeadRequestsAlreadyAvailableForTreaty,
        NoLeadRequestSelected,
        AskToReactivateLead,
        AskToDeactivateLead,
        AskToDeleteLead,
        SimulativeLead,
        SendLeadRequest,
        errorMsg,
        SomeQuoteRequestAssociatedCancelTreatySection,
        leadRequestAlreadySent //RRA - ticket 1484 - 06062023
    }

    @api selectedProgram;
    @api allReadOnly = false;
    @api selectedTreaty = null;
    @api selectedBroker = null;
    @api selectedReinsurer = null;
    @api selectedReinsurerStatus = null;
    @track selectedLeadRequest = [];
    @track selectedLeadRequest1 = [];
    @track dataLeadRequest = [];
    newLeadReqBtn = false;  //RRA - ticket 585 - 06032023 
    wiredSection;
    sectionRetainToLeadPresent = false;
    isNewLeadRequestModalOpen = false;
    titleCountLeadRequest = 'Lead Requests (0)';
    spinnerLeadRequest = false;
    columnsLeadRequest = columnsLeadRequest;
    isLeadRequestPresent = false;
    valueUWYear;
    valuePrincipalCedComp;
    isOpenConfirmation = false;
    isDeleteOpen = false;
    statusModalTitle;
    status;
    statusFunction;
    delMsgTitle;
    delMessage;
    isReqTypeOpen = false;
    requestTypeOptions;
    statusLead = 'Lead';
    dataFiltered = false;
    disableSendBtn = true;
    displayHelptext = false;
    titleSendBtn;
    btnNameSendUpdateRemind;
    isSendUpdateRemindLeadReqOpenModal = false;
    titlePopUp;
    disableLeadInfo = false;
    disableUpdateRemind = true;
    displayErrorMsg = false;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('closeNewLeadRequestModal', this.closeNewLeadRequestModal, this);
        registerListener('closeSendUpdateRemindReqModal', this.closeSendUpdateRemindLeadReqModal, this);
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('valueTreaty', this.getValueTreaty, this);
        registerListener('valueBroker', this.getValueBroker, this);
        registerListener('valueReinsurer', this.getValueReinsurer, this);
        registerListener('valueReinsurerStatus', this.getValueReinsurerStatus, this);
        registerListener('valueProgram', this.getValueProgram, this);
        registerListener('refreshReq', this.refreshData, this);
        this.titleSendBtn = this.label.SendLeadRequest;

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

            disableLeadInfo({programId : this.selectedProgram})
            .then(result => {
                this.disableLeadInfo = result;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
    }

    displayHelptextValue(){
        this.displayHelptext = true;
    }

    closeSendUpdateRemindLeadReqModal(val){
        this.isSendUpdateRemindLeadReqOpenModal = val;
    }

    getVal(val){
        this.valueUWYear = val;
        this.selectedProgram = null;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
        this.selectedProgram = null;
    }

    getValueProgram(val){
        this.selectedProgram = val;
    }

    getValueTreaty(val){
        this.selectedTreaty = val;
        this.dataFiltered = true;
    }

    getValueReinsurer(val){
        this.selectedReinsurer = val;
        this.dataFiltered = true;
    }

    getValueBroker(val){
        this.selectedBroker = val;
        this.dataFiltered = true;
    }

    getValueReinsurerStatus(val){
        this.selectedReinsurerStatus = val;
        this.dataFiltered = true;
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getSectionDetail, {programId: '$selectedProgram', treatyId: '$selectedTreaty', reinsurerId: '$selectedReinsurer', brokerId: '$selectedBroker', reinsurerStatus: '$selectedReinsurerStatus'})  //RRA - ticket 585 - 15032023
    wiredGetSectionDetails(result){
        this.spinnerLeadRequest = true;
        console.log('result getSectionDetail == ', result);
        // RRA - 935
        let quoteValue; 
        let disableLink;
        let referenceTreaty;
        let reinsurerNameUrl;
        let reinsurerName;
        let layer;
        let treaty;
        let broker;
        let mdp;
        let reinsurer;
        let writtenShare;
        let iconAttach;
        let iconComment;
        let defSimul;
        let reinStat;
        let lastSendDat;
        let expectDat;
        let respDat;

        this.wiredSection = result;

        if(result.data){
            this.sectionRetainToLeadPresent = result.data.isProgramHasSectionsRetainToLead;
            this.dataLeadRequest = result.data.lstLeadRequest;
            let reinsurerNameUrl;
            let isDeactivatedProg = result.data.isDeactivatedProg; //RRA - ticket 0585 - 06032023

            if (isDeactivatedProg && this.dataLeadRequest.length == 0){
                this.newLeadReqBtn = isDeactivatedProg;
            }else{
                //program / treaty - RRA - ticket 585 - 07032023
                if (isDeactivatedProg && this.dataLeadRequest.length > 0){
                    this.disableLeadInfo = true;
                }else{
                    this.disableLeadInfo = false;
                    this.dataLeadRequest = result.data.lstLeadRequest.map(row => {
                        quoteValue = '' ; //MRA W-0935 28/07/022
                        reinsurerNameUrl = '../n/RespondOnBehalf?c__id='+row.Id+'-'+this.selectedProgram+'-'+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.statusLead+'-'+this.selectedTreaty+'-'+this.selectedBroker+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus+'-'+row.ReinsurerStatus__c;
    
                        //************
                        // -BEGIN-
                        // RRA - 10/06/2022 - 935 add columns Quote and MDP on Lead phase
                        // **********/
                        referenceTreaty = row.TreatyReference__c;
                        treaty = row.TECH_TreatyName__c;
                        broker = row.Broker__c;
                        mdp = ''; //MRA W-0935 28/07/022
                        writtenShare = row.WrittenShare__c;
                        iconAttach = row.Utility_Icon_Attachment__c;
                        iconComment = row.Utility_Icon_Comment__c;
                        defSimul = row.LeadType__c;
                        reinStat = row.ReinsurerStatus__c;
                        lastSendDat = row.LastSentDate__c;
                        expectDat = row.ExpectedResponseDate__c;
                        respDat = row.ResponseDate__c;
                        //MRA W-0935 28/07/022 START
                        if (row.TECH_ParentLeadRequestQuoteValue__c != undefined){
                            let eachQuoteValue = (row.TECH_ParentLeadRequestQuoteValue__c.trim()).split('**') ;
                            let i = 0 ;
                            eachQuoteValue.forEach(element => {
                                i++ ;
                                if (i === eachQuoteValue.length) 
                                quoteValue = (quoteValue==='' ?'':quoteValue)+ element ;
                                else
                                quoteValue = (quoteValue==='' ?'':quoteValue)+ element + '\n' ;
                            });
                        }
                        if (row.TECH_MDP_LeadParent__c != undefined){
                        let allMDPValues = (row.TECH_MDP_LeadParent__c.trim()).split('**') ;
                            let i = 0 ;
                            allMDPValues.forEach(element => {
                                i++ ;
                                if(element !== '' && element !== ' ' && element !== null){
                                    if (i === (allMDPValues.length - 1)) 
                                    mdp = (mdp==='' ?'':mdp)+ element ;
                                    else
                                    mdp = (mdp==='' ?'':mdp)+ element + '\n' ;
                                }
                            });
                        }
                        //MRA W-0935 28/07/022 : END
                        return {...row , reinsurerNameUrl, quoteValue, referenceTreaty, treaty, broker, mdp, writtenShare, iconAttach, iconComment, defSimul,reinStat,lastSendDat, expectDat, respDat, reinsurerName, disableLink}
                    });
                }
            }

            this.sortData('TECH_Layer__c', 'TECH_ReinsurerName__c' , 'asc');
            this.titleCountLeadRequest = 'Lead Requests (' + this.dataLeadRequest.length + ')';
            this.error = undefined;

            if(this.dataLeadRequest.length == 0 && this.dataFiltered == true){
                this.isLeadRequestPresent = true;
            }
            else if(this.dataLeadRequest.length > 0 && this.dataFiltered == false){
                this.isLeadRequestPresent = true;
            }
            else if(this.dataLeadRequest.length > 0 && this.dataFiltered == true){
                this.isLeadRequestPresent = true;
            }
            else{
                this.isLeadRequestPresent = false;
            }
        }
        else if(result.error){
            this.error = result.error;
        }
        this.spinnerLeadRequest = false;
    }


    refreshData(){
        return refreshApex(this.wiredSection);
    }

    handleOpenNewLeadRequestModal(){
        getSelectedProgramDetail({programId : this.selectedProgram})
        .then(result => {
            if(result.RenewedFromProgram__c != null && result.RenewedFromProgram__c != undefined && (result.TypeOfRenew__c == 'LTA/TR Identical Renew')){
                this.isNewLeadRequestModalOpen = true;
                this.displayErrorMsg = true;
            }
            else{
                this.getTreaties();
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    getTreaties(){
        getTreaties({programId: this.selectedProgram})
        .then(result => {
            if(result.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.LeadRequestsAlreadyAvailableForTreaty, variant: 'error',}), );
            }
            else{
                this.isNewLeadRequestModalOpen = true;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    handleCloseNewLeadRequestModal(){
        this.isNewLeadRequestModalOpen = false;
    }

    closeNewLeadRequestModal(val){
        this.isNewLeadRequestModalOpen = val;
    }

    handleOpenSendUpdateRemindModal(event){
        let selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        this.btnNameSendUpdateRemind = event.currentTarget.name;
            if(selectedRequests.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoLeadRequestSelected, variant: 'error',}), );
            }else{
                this.selectedLeadRequest = selectedRequests;
                let arr1 = [];
    
                for(var key in selectedRequests){
                    let ele = selectedRequests[key];
                    let obj = {};
                    obj.Broker = ele.Broker__c;
                    obj.Reinsurer = ele.Reinsurer__c;
                    obj.brokerRein = ele.Broker__c+'-'+ele.Reinsurer__c;
                    arr1.push(obj);
                }
                console.log('arr1 okok == ', this.arr1);

                this.isSendUpdateRemindLeadReqOpenModal = true;
                this.titlePopUp = this.btnNameSendUpdateRemind + ' Lead Request(s)';
                this.selectedLeadRequest1 =  arr1;
            }
    }

    handleCloseSendUpdateRemindModal(){
        this.isSendUpdateRemindLeadReqOpenModal = false;
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

    handleCloseModal(){
        this.isOpenConfirmation = false;
        this.isDeleteOpen = false;
        this.isReqTypeOpen = false;
    }

    handleSimulatedDefinitiveBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
        }else{
            this.isReqTypeOpen = true;
            //RRA - ticket 1484 - 06062023
            for (let i=0;i<selectedRequests.length;i++){
                let row = {...selectedRequests[i]};
                if (row.ReinsurerStatus__c == 'Sent' || row.ReinsurerStatus__c == 'Answered' || row.ReinsurerStatus__c == 'Timeout' || row.ReinsurerStatus__c == 'Refused'){
                    this.isReqTypeOpen = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: this.label.leadRequestAlreadySent,
                            variant: 'error',
                        }),
                    );
                    break;
                }else {
                    this.isReqTypeOpen = true;
                }
            }
        }
    }

    acceptToggleReqType(){
        this.spinnerLeadRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
            this.spinnerLeadRequest = false;
            this.isReqTypeOpen = false;
        }
        else{
            for (var key in selectedRequests) {
                var obj = selectedRequests[key];
                for(var req in this.requestTypeOptions){
                   var reqOpt = this.requestTypeOptions[req];
                   if(obj.LeadType__c == reqOpt.label){
                       obj.LeadType__c = reqOpt.value;
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
                    this.spinnerLeadRequest = false;
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
                    this.spinnerLeadRequest = false;
                }
            })
            .catch(error => {
                this.error = error;
            });
            this.isReqTypeOpen = false;
        }
    }

    reactivateBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Reactivate Quote Request';
            //You are going to reactivate the selected Lead Request(s). Do you want to continue?
            this.status = this.label.AskToReactivateLead;
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
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Deactivate Lead Request';
            //You are going to deactivate the selected Lead Request(s). Do you want to continue?
            this.status = this.label.AskToDeactivateLead;
            this.statusFunction = 'deactivate';
            this.isOpenConfirmation = true;
        }
    }

    acceptStatusChange(){
        this.spinnerLeadRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
            this.spinnerLeadRequest = false;
        }
        else{
            for (var key in selectedRequests) {
                var obj = selectedRequests[key];
                delete obj.LeadType__c;
            }

            if(this.statusFunction == 'reactivate'){
                changeStatus({lstRecords: selectedRequests, objectName: 'Request', status: '1', isButtonActDeact : false}) //RRA - ticket 585 06122022
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerLeadRequest = false;
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
                        this.spinnerLeadRequest = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
            else if(this.statusFunction == 'deactivate'){
                changeStatus({lstRecords: selectedRequests, objectName: 'Request', status: '2', isButtonActDeact : true}) //RRA - ticket 585 06122022
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerLeadRequest = false;
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
                        this.spinnerLeadRequest = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
        }
        this.isOpenConfirmation = false;
    }

    handleDeleteBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests 11 == ',selectedRequests);
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoLeadRequestSelected,
                    variant: 'error',
                }),
            );
        }
        else{
            this.delMsgTitle = 'Delete Lead Request';
            //You are going to delete the Lead Request(s). Do you want to continue?
            this.delMessage = this.label.AskToDeleteLead;
            this.isDeleteOpen = true;
        }
    }

    acceptDelete(){
        this.spinnerLeadRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRequests 22== ',selectedRequests);
        deletePrograms({lstRecords: selectedRequests, objectName: 'Request__c'})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.spinnerLeadRequest = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                         message: result.Success,
                         variant: 'success',
                    }),
                );
                this.spinnerLeadRequest = false;
                fireEvent(this.pageRef, 'refreshReq', 'refresh');
            }
        })
        .catch(error => {
            this.error = error;
        });
        this.isDeleteOpen = false;
    }

    handleRowSelection(event){
        let lstSelectedRequest = event.detail.selectedRows;
        let isRequestSimulated = false;
        let isReinsurerStatusSetup = false;

        if(lstSelectedRequest.length != 0){
            for(let i = 0; i < lstSelectedRequest.length; i++){
                if(lstSelectedRequest[i].LeadType__c == 'Simulated'){
                    isRequestSimulated = true;
                }
                if(lstSelectedRequest[i].ReinsurerStatus__c == 'Setup'){
                    isReinsurerStatusSetup = true;
                }
            }

            if(isRequestSimulated == true){
                this.disableSendBtn = true;
                //At least one selected request is simulated, please change the request to Definitive to Send.
                this.titleSendBtn = this.label.SimulativeLead;
            }
            else{
                this.disableSendBtn = false;
                this.titleSendBtn = this.label.SendLeadRequest;
            }

            //if selected rows have reinsurer status "Setup" -> disable update and remind button
            if(isReinsurerStatusSetup == true || (isReinsurerStatusSetup == false && this.disableLeadInfo == true)){
                this.disableUpdateRemind = true;
            }
            else{
               this.disableUpdateRemind = false;
            }
        }
        else{
            this.disableSendBtn = true;
            this.disableUpdateRemind = true;
            this.titleSendBtn = this.label.SendLeadRequest;
        }
    }

    sortData(fieldName, fieldName2, sortDirection) {
        let sortResult = Object.assign([], this.dataLeadRequest);
        this.dataLeadRequest = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else {
                if(a[fieldName2] < b[fieldName2])
                    return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])
                    return sortDirection === 'asc' ? 1 : -1;
                else
                    return 0;
            }
        })
    }
}