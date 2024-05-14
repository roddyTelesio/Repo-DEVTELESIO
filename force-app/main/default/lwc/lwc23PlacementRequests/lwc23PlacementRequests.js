import {LightningElement, track, wire, api} from 'lwc';
import {getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getPlacementRequests from '@salesforce/apex/LWC23_PlacementRequests.getPlacementRequests';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate';
import deletePrograms from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import toggleReqType from '@salesforce/apex/LWC20_LeadRequests.toggleRequestType';
import getTreaties from '@salesforce/apex/LWC15_QuoteRequests.getTreaties';
import isProgramRenewed from '@salesforce/apex/LWC15_QuoteRequests.isProgramRenewed';
import getBroker from '@salesforce/apex/LWC15_QuoteRequests.getBroker';
import getReinsurer from '@salesforce/apex/LWC15_QuoteRequests.getReinsurer';
import savePlacementRequestRecord from '@salesforce/apex/LWC24_NewPlacementRequest.savePlacementRequestRecord';
import viewPlacementTable from '@salesforce/apex/LWC23_PlacementRequests.viewPlacementTable';
import disablePlacementInfo from '@salesforce/apex/LWC23_PlacementRequests.disablePlacementInfo';
import getAllSections from '@salesforce/apex/LWC24_NewPlacementRequest.getAllSections';
import Id from '@salesforce/user/Id';
import BROKER_FIELD from '@salesforce/schema/Request__c.Broker__c';
import TREATY_FIELD from '@salesforce/schema/Request__c.Treaty__c';
import PROGRAM_FIELD from '@salesforce/schema/Request__c.Program__c';
import REINSURER_FIELD from '@salesforce/schema/Request__c.Reinsurer__c';
import WRITTEN_SHARE from '@salesforce/schema/Request__c.WrittenShare__c'
import REQUEST_TYPE_FIELD from '@salesforce/schema/Request__c.LeadType__c';
import TECH_PHASETYPE_FIELD from '@salesforce/schema/Request__c.TECH_PhaseType__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import checkIfLeadRequestPresent from '@salesforce/apex/LWC23_PlacementRequests.checkIfLeadRequestPresent';
import getSelectedProgramDetail from '@salesforce/apex/LWC23_PlacementRequests.getSelectedProgramDetail';

import noTreatyAvailable from '@salesforce/label/c.noTreatyAvailable';
import noPlacementReq from '@salesforce/label/c.noPlacementReq';
import placementReqCreated from '@salesforce/label/c.placementReqCreated';
import noTreatyField from '@salesforce/label/c.noTreatyField';
import NoLeadPresentForProgram from '@salesforce/label/c.NoLeadPresentForProgram';
import AskToReactivatePlacement from '@salesforce/label/c.AskToReactivatePlacement';
import AskToDeactivatePlacement from '@salesforce/label/c.AskToDeactivatePlacement';
import AskToDeletePlacement from '@salesforce/label/c.AskToDeletePlacement';
import SomeQuoteRequestAssociatedCancelTreatySection from '@salesforce/label/c.SomeQuoteRequestAssociatedCancelTreatySection'; //RRA - ticket 585 - 16032023
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsPlacementRequest = [
    { label: 'Layer', fieldName: 'TECH_Layer__c'},
    { label: 'Treaty ref', fieldName: 'TreatyReference__c' },
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'reinsurerNameUrl', type: 'url', typeAttributes: {label: { fieldName: 'TECH_ReinsurerName__c' }, target: '_self'} },
    { label: 'Written share', fieldName: 'WrittenShare__c' , type: 'number', cellAttributes: { alignment: 'left' }, typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'} },

    { label: '', fieldName: 'statusIconComment' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Comment__c' }, iconPosition: 'left'}, initialWidth: 50 }, //RRA - 939
    { label: '', fieldName: 'statusIconAttachFile' , type: 'text', cellAttributes: { iconName: { fieldName: 'Utility_Icon_Attachment__c' }, iconPosition:'left'}, initialWidth: 50 }, //RRA - 939

    { label: 'Reinsurer Status', fieldName: 'ReinsurerStatus__c' },
    { label: 'Last sent date', fieldName: 'LastSentDate__c' },
    { label: 'Expected answer date', fieldName: 'ExpectedResponseDate__c' },
    { label: 'Response Date', fieldName: 'ResponseDate__c' },
    { label: 'Version', fieldName: 'Version__c' }
];

const placementTableColumns = [
  { label: 'Layer', fieldName: 'layer', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Treaty ref', fieldName: 'treatyRef', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Treaty', fieldName: 'treatyName', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Broker', fieldName: 'broker', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Reinsurer/Pool', fieldName: 'reinsurerPool', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Written share', fieldName: 'writtenShareNew' , typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'}, type: 'text', cellAttributes: { alignment: 'center', class: { fieldName: 'classBgColor' } }},
  { label: 'Reinsurer Status', fieldName: 'reinsurerStatus', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Last sent date', fieldName: 'lastSentDate', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Expected answer date', fieldName: 'expectedAnswerDate', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}},
  { label: 'Response Date', fieldName: 'responseDate', type: 'text', cellAttributes: { class: { fieldName: 'classBgColor' }}}
];

export default class Lwc23PlacementRequests extends NavigationMixin(LightningElement) {
    label = {
        noTreatyAvailable,
        noPlacementReq,
        placementReqCreated,
        noTreatyField,
        NoLeadPresentForProgram,
        AskToReactivatePlacement,
        AskToDeactivatePlacement,
        AskToDeletePlacement,
        errorMsg,
        SomeQuoteRequestAssociatedCancelTreatySection
    }

    @api selectedProgram;
    @api allReadOnly = false;
    @api selectedTreaty = null;
    @api selectedBroker = null;
    @api selectedReinsurer = null;
    @api selectedReinsurerStatus = null;
    @api objectName = 'Account';
    @api fieldName = 'Name';
    @track dataPlacementRequest = [];
    @track selectedPlacementRequest = [];
    @track selectedPlacementRequest1 = [];
    @track searchBrokerLookupRecords = [];
    @track searchReinsurerLookupRecords = [];
    @track selectedRecords = [];
    @track selectedRein = [];
    @track lstBrokerReins = [];
    @track lstSelectedRequest = [];
    @track lstAllSections = [];
    wiredSection;
    isNewPlacementRequestModalOpen = false;
    titleCountPlacementRequest = 'Placement Requests (0)';
    spinnerPlacementRequest = false;
    columnsPlacementRequest = columnsPlacementRequest;
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
    valueTreaty;
    treatyOptions;
    isProgramRenewed = false;
    txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    selectedBrokerText = null;
    selectedBrokerName;
    selectedBrokerId;
    iconName = 'standard:account';
    loadingText = false;
    messageFlag = false;
    titleCountFollowers = 'Follower(s) (0)';
    loadFromPrevYrTitle = 'Load from <prev_year>';
    prevYear = null;
    disableConfirmReinsurerBtn = true;
    isNewReinsurerOpenModal = false;
    txtReinsurerLookUpclassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    required = false;
    searchText;
    disablePlacementReqSaveBtn = true;
    selectedId = 0;
    statusPlacement = 'Placement';
    wiredRequestDetails;
    placementTableData;
    placementTableColumns = placementTableColumns;
    isPlacementTableOpen = false;
    disablePlacementInfo = false;
    disableUpdateRemind = true;
    wiredPlacementTableData;
    btnNameSendUpdateRemind;
    isSendUpdateRemindPlacementReqOpenModal = false;
    titlePopUp;
    displayErrorMsg = false;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        registerListener('closeNewPlacementRequestModal', this.closeNewPlacementRequestModal, this);
        registerListener('year', this.getVal, this);
        registerListener('comp', this.getComp, this);
        registerListener('valueTreaty', this.getValueTreaty, this);
        registerListener('valueBroker', this.getValueBroker, this);
        registerListener('valueReinsurer', this.getValueReinsurer, this);
        registerListener('valueReinsurerStatus', this.getValueReinsurerStatus, this);
        registerListener('valueProgram', this.getValueProgram, this);
        registerListener('refreshReq', this.refreshData, this);
        registerListener('closeSendUpdateRemindReqModal', this.closeSendUpdateRemindPlacementReqModal, this);
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
            this.prevYear = parseInt(this.valueUWYear) - 1;
            this.loadFromPrevYrTitle = 'Load from ' + this.prevYear;
        }

        registerListener('year', this.getVal, this);

        disablePlacementInfo({programId : this.selectedProgram})
        .then(result => {
            this.disablePlacementInfo = result;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    closeSendUpdateRemindPlacementReqModal(val){
        this.isSendUpdateRemindPlacementReqOpenModal = val;
    }

    getVal(val){
        this.valueUWYear = val;
        this.selectedProgram = null;
        this.prevYear = parseInt(this.valueUWYear) - 1;
        this.loadFromPrevYrTitle = 'Load from ' + this.prevYear;
        this.spinnerPlacementRequest = true;
    }

    getComp(val){
        this.valuePrincipalCedComp = val;
        this.selectedProgram = null;
        this.spinnerPlacementRequest = true;
    }

    getValueProgram(val){
        this.selectedProgram = val;
        this.spinnerPlacementRequest = true;
    }

    getValueTreaty(val){
        this.selectedTreaty = val;
        this.valueTreaty = val;
        this.spinnerPlacementRequest = true;
    }

    getValueReinsurer(val){
        this.selectedReinsurer = val;
        this.spinnerPlacementRequest = true;
    }

    getValueBroker(val){
        this.selectedBroker = val;
        this.spinnerPlacementRequest = true;
    }

    getValueReinsurerStatus(val){
        this.selectedReinsurerStatus = val;
        this.spinnerPlacementRequest = true;
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getAllSections, {treatyId: '$valueTreaty', lstBrokerReinsurers: '$lstBrokerReins'})
    getAllSections(result){
        this.wiredRequestDetails = result;

        if(result.data){
            this.lstAllSections = result.data.lstSections;
            let mapLastCreatedRequestBySectionId = result.data.mapLastCreatedRequestBySectionId;
            let lstUpdSectionsRequest = [];

            for(let j = 0; j < this.lstAllSections.length; j++){
                let rowSection = { ...this.lstAllSections[j] };
                let typeOfQuote = rowSection.QuoteType__c;
                let typeOfTreaty = rowSection.TECH_TypeofTreaty__c;
                let ltaProgram = rowSection.Program__r.LTA__c;
                let request = {};
                if(mapLastCreatedRequestBySectionId[rowSection.Id] != undefined){
                    request = mapLastCreatedRequestBySectionId[rowSection.Id];
                }
                else{
                    request['Section__c'] = this.lstAllSections[j].Id
                }
                rowSection['request'] = request;

                if(typeOfQuote == '1'){
                    rowSection['isQuoteTypeFixedRate'] = true;
                }
                else if(typeOfQuote == '2'){
                    rowSection['isQuoteTypeVariableRate'] = true;
                }
                else if(typeOfQuote == '3'){
                    rowSection['isQuoteTypeFlatPremium'] = true;
                }
                else if(typeOfQuote == '4'){
                    rowSection['isQuoteTypeMDP'] = true;
                }
                else if(typeOfQuote == '5'){
                    rowSection['isQuoteTypeFlatCommission'] = true;
                }
                else if(typeOfQuote == '6'){
                    rowSection['isQuoteTypeVariableCommission'] = true;
                }
                else if(typeOfQuote == '8'){
                    rowSection['isQuoteTypePerHeadVariable'] = true;
                }
                else if(typeOfQuote == '9'){
                    rowSection['isQuoteTypeRiskPremiumBasis'] = true;
                }
                else if(typeOfQuote == '10'){
                    rowSection['isQuoteTypePerHeadPremium'] = true;
                }

                if(typeOfTreaty == '3'){
                    rowSection['isTreatyTypeQS'] = true;
                }
                else if(typeOfTreaty == '4'){
                    rowSection['isTreatyTypeSurplus'] = true;
                }
                else if(typeOfTreaty == '2'){
                    rowSection['isTreatyTypeXL'] = true;
                }
                else if(typeOfTreaty == '1'){
                    rowSection['isTreatyTypeSL'] = true;
                }

                if(ltaProgram == '1'){
                    rowSection['LTAProgramYes'] = true;
                }
                else{
                    rowSection['LTAProgramYes'] = false;
                }

                rowSection['ReinstatementStr'] = 'reinstatement';
                lstUpdSectionsRequest.push(rowSection);
            }

            this.lstAllSections = lstUpdSectionsRequest;
        }
        else if (result.error) {
            this.lstAllSections = undefined;
        }
    }


    @wire(getPlacementRequests, {programId: '$selectedProgram', treatyId: '$selectedTreaty', reinsurerId: '$selectedReinsurer', brokerId: '$selectedBroker', reinsurerStatus: '$selectedReinsurerStatus'})
    wiredGetSectionDetails(result){
        this.spinnerPlacementRequest = true;
        this.wiredSection = result;
        if(result.data){
                this.dataPlacementRequest = result.data.lstPlacementRequestsToDisplay;  //RRA - ticket 585 - 07032023
                let isDeactivatedProg = result.data.isDeactivatedProg;  //RRA - ticket 585 - 07032023
                let reinsurerNameUrl;

                //RRA - ticket 585 - 07032023
                if (isDeactivatedProg &&  this.dataPlacementRequest.length == 0){
                    this.disablePlacementInfo = isDeactivatedProg;
                    this.disableUpdateRemind = isDeactivatedProg;
                }else{
                    //Program Section RRA - ticket 585 - 07032023
                    if (isDeactivatedProg && this.dataPlacementRequest.length > 0){
                        this.disablePlacementInfo = true;
                        this.disableUpdateRemind = true;
                    }else {
                        this.disablePlacementInfo = false;
                        this.dataPlacementRequest = result.data.lstPlacementRequestsToDisplay.map(row => {
                            reinsurerNameUrl = '../n/RespondOnBehalf?c__id='+row.Id+'-'+this.selectedProgram+'-'+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.statusPlacement+'-'+this.selectedTreaty+'-'+this.selectedBrokerId+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus+'-'+row.ReinsurerStatus__c;
                            return {...row , reinsurerNameUrl}
                        });
                    }
                }

                //this.titleCountPlacementRequest = 'Placement Requests (' + this.dataPlacementRequest.length + ')';
                this.titleCountPlacementRequest = this.dataPlacementRequest.length > 0 ? 'Placement Requests' + ' (' + this.dataPlacementRequest.length + ')' : 'Placement Requests (0)' ; //RRA - ticket 585 07122023
                //this.sortData('TECH_Layer__c', 'TECH_ReinsurerName__c' , 'asc'); //RRA - ticket 1571 09202023
                this.error = undefined;
            }
            else if(result.error){
                this.error = result.error;
            }
            this.spinnerPlacementRequest = false;
    }

    refreshData(){
        return refreshApex(this.wiredSection);
    }

    handleOpenNewPlacementRequestModal(){
        getSelectedProgramDetail({programId : this.selectedProgram})
        .then(result => {
            if(result.RenewedFromProgram__c != null && result.RenewedFromProgram__c != undefined && (result.TypeOfRenew__c == 'LTA/TR Identical Renew')){
                this.isNewPlacementRequestModalOpen = true;
                this.displayErrorMsg = true;
            }
            else{
                this.openNewPlacementModal();
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    openNewPlacementModal(){
        if(this.treatyOptions.length == 1){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyAvailable, variant: 'error' }),);
        }
        else{
            checkIfLeadRequestPresent({ programId:this.selectedProgram})
            .then(data => {
                if(data == false){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoLeadPresentForProgram, variant: 'error' }),);
                }
                else{
                    isProgramRenewed({programId: this.selectedProgram})
                    .then(result => {
                        this.isProgramRenewed = result;
                    })
                    .catch(error => {
                        this.error = error;
                    });
                    this.isNewPlacementRequestModalOpen = true;
                    this.lstBrokerReins = [];
                    this.titleCountFollowers = 'Followers(s) (0)';
                    this.selectedBrokerText = null;
                    this.selectedBrokerName = null;
                    this.selectedBrokerId = null;
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }

    handleCloseNewPlacementRequestModal(){
        this.isNewPlacementRequestModalOpen = false;
        this.displayErrorMsg = false;
        this.valueTreaty = null;
        this.selectedBrokerText = null;
        this.selectedBrokerName = null;
        this.selectedBrokerId = null;
        this.lstBrokerReins = [];
        this.titleCountFollowers = 'Followers(s) (0)';
        this.disablePlacementReqSaveBtn = true;
    }

    closeNewPlacementRequestModal(val){
        this.isNewPlacementRequestModalOpen = val;
    }

    handleOpenSendUpdateRemindModal(event){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        this.btnNameSendUpdateRemind = event.currentTarget.name;
        if(selectedRequests.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noPlacementReq, variant: 'error',}), );
        }else{
            this.selectedPlacementRequest = selectedRequests;
            let arr1 = [];

            for(var key in selectedRequests){
                let ele = selectedRequests[key];
                let obj = {};
                obj.Broker = ele.Broker__c;
                obj.Reinsurer = ele.Reinsurer__c;
                obj.brokerRein = ele.Broker__c+'-'+ele.Reinsurer__c;
                arr1.push(obj);
            }

            this.isSendUpdateRemindPlacementReqOpenModal = true;
            this.titlePopUp = this.btnNameSendUpdateRemind + ' Placement Request(s)';
            this.selectedPlacementRequest1 =  arr1;
        }
    }

    handleCloseSendUpdateRemindModal(){
        this.isSendUpdateRemindPlacementReqOpenModal = false;
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
        this.isPlacementTableOpen = false;
    }

    handleSimulatedDefinitiveBtn(){
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
        }
        else{
            this.isReqTypeOpen = true;
        }
    }

    acceptToggleReqType(){
        this.spinnerPlacementRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
            this.spinnerPlacementRequest = false;
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
                    this.spinnerPlacementRequest = false;
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
                    this.spinnerPlacementRequest = false;
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
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Reactivate Quote Request';
            //You are going to reactivate the selected Placement Request(s). Do you want to continue?
            this.status = this.label.AskToReactivatePlacement;
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
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Deactivate Placement Request';
            //You are going to deactivate the selected Placement Request(s). Do you want to continue?
            this.status = this.label.AskToDeactivatePlacement;
            this.statusFunction = 'deactivate';
            this.isOpenConfirmation = true;
        }
    }

    acceptStatusChange(){
        this.spinnerPlacementRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
            this.spinnerPlacementRequest = false;
        }
        else{
            for (var key in selectedRequests) {
                var obj = selectedRequests[key];
                delete obj.LeadType__c;
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
                        this.spinnerPlacementRequest = false;
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
                        this.spinnerPlacementRequest = false;
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
                        this.spinnerPlacementRequest = false;
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
                        this.spinnerPlacementRequest = false;
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
        if(selectedRequests.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noPlacementReq,
                    variant: 'error',
                }),
            );
        }else{
            this.delMsgTitle = 'Delete Placement Request';
            //You are going to delete the Placement Request(s). Do you want to continue?
            this.delMessage = this.label.AskToDeletePlacement;
            this.isDeleteOpen = true;
        }
    }

    acceptDelete(){
        this.spinnerPlacementRequest = true;
        var selectedRequests = this.template.querySelector('lightning-datatable').getSelectedRows();
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
                this.spinnerPlacementRequest = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                         message: result.Success,
                         variant: 'success',
                    }),
                );
                this.spinnerPlacementRequest = false;
                fireEvent(this.pageRef, 'refreshReq', 'refresh');
            }
        })
        .catch(error => {
            this.error = error;
        });
        this.isDeleteOpen = false;
    }

    handleChangeTreaty(event){
        this.valueTreaty = event.detail.value;

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
            this.treatyOptions = treatyOpt;
        }
        else if(result.error){
            this.error = result.error;
        }
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
        this.txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.selectedBrokerText = selectName;
        this.selectedBrokerName = selectName;
        this.selectedBrokerId = recId;
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
        this.searchReinsurerLookupRecords = [];
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

    setSelectedReinsurerLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let treatyName = '';
         let reinsurerObj = {  'recId' : recId ,'recName' : selectName };
        this.selectedRein.push(reinsurerObj);

        if(this.valueTreaty == 'All'){

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                this.selectedId = this.selectedId + 1;
                let newsObject = { 'recId' : recId ,'recName' : selectName
                                    , 'TECH_ReinsurerName__c' : selectName
                                    , 'TECH_BrokerName__c' : this.selectedBrokerName
                                    , 'TECH_TreatyName__c' : this.treatyOptions[i].label
                                    , 'Reinsurer__c' : recId
                                    , 'Broker__c' : this.selectedBrokerId
                                    , 'QuoteType__c' : null
                                    , 'Treaty__c' : this.treatyOptions[i].value
                                    , 'Checked' : false
                                    , 'Program__c' : this.selectedProgram
                                    , 'selectedId' : this.selectedId
                                    , 'BrokerReinsurer' : this.selectedBrokerId + '-' + recId
                                    , 'TreatyBrokerReinsurer' : this.treatyOptions[i].value + '-' + this.selectedBrokerId + '-' + recId
                                    ,'WrittenShare__c':null
                };
                this.selectedRecords.push(newsObject);
            }
        }
        else{
            treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);
            this.selectedId = this.selectedId + 1;
            let newsObject = { 'recId' : recId ,'recName' : selectName
                                , 'TECH_ReinsurerName__c' : selectName
                                , 'TECH_BrokerName__c' : this.selectedBrokerName
                                , 'TECH_TreatyName__c' : treatyName
                                , 'Reinsurer__c' : recId
                                , 'Broker__c' : this.selectedBrokerId
                                , 'QuoteType__c' : null
                                , 'Treaty__c' : this.valueTreaty
                                , 'Checked' : false
                                , 'Program__c' : this.selectedProgram
                                , 'selectedId' : this.selectedId
                                , 'BrokerReinsurer' : this.selectedBrokerId + '-' + recId
                                , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + this.selectedBrokerId + '-' + recId
                                ,'WrittenShare__c':null
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

    handleConfirmReinsurer(){
        if(this.lstBrokerReins != undefined){
            for(let j = 0; j < this.lstBrokerReins.length; j++){
                this.selectedRecords.push(this.lstBrokerReins[j]);
            }
        }

        this.lstBrokerReins = this.getUniqueData(this.selectedRecords, 'TreatyBrokerReinsurer');
        this.titleCountFollowers = 'Followers(s)' + ' (' + this.lstBrokerReins.length + ')';
        this.selectedRecords = [];
        this.selectedRein = [];
        this.isNewReinsurerOpenModal = false;
        this.disablePlacementReqSaveBtn = false;
    }

    handleChangeBrokerReinsCheckbox(event){
        let checkboxChecked = event.currentTarget.checked;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedRequest = [];

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            let request = this.lstBrokerReins[i];
            if(this.lstBrokerReins[i].selectedId == selectedIdVal){
                request.Checked = checkboxChecked;
            }
            lstUpdatedRequest.push(request);
        }

        this.lstBrokerReins = lstUpdatedRequest;
    }

    handleDeleteRequestBtn(){

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            if(this.lstBrokerReins[i].Checked == true){
                this.lstSelectedRequest.push(this.lstBrokerReins[i]);
            }
        }

        this.lstBrokerReins = this.lstBrokerReins.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedRequest);
        if(this.lstBrokerReins.length == 0){
            this.disablePlacementReqSaveBtn = true;
        }
        this.titleCountFollowers = 'Followers(s)' + ' (' + this.lstBrokerReins.length + ')';
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

    getPicklistLabel(picklistOptions, selectedPicklistOpt){
        for(let i = 0; i < picklistOptions.length; i++){
            if(picklistOptions[i].value == selectedPicklistOpt){
                return picklistOptions[i].label;
            }
        }
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    handleChangeWrittenShare(event){
        let writtenShare = event.currentTarget.value;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedRequest = [];

        for(let i = 0; i < this.lstBrokerReins.length; i++){
            let request = this.lstBrokerReins[i];
            if(this.lstBrokerReins[i].selectedId == selectedIdVal){
                request.WrittenShare__c = writtenShare;
            }
            lstUpdatedRequest.push(request);
        }

        this.lstBrokerReins = lstUpdatedRequest;
    } 

    handleSavePlacementRequest(){
        let lstParentPlacementRequestToInsert = [];
        let lstChildPlacementRequest = [];


        for(let i = 0; i < this.lstBrokerReins.length; i++){
            let objParentPlacementRequest = {
                Reinsurer__c : REINSURER_FIELD,
                Broker__c : BROKER_FIELD,
                WrittenShare__c : WRITTEN_SHARE,
                TECH_PhaseType__c : TECH_PHASETYPE_FIELD,
                Program__c : PROGRAM_FIELD,
                Treaty__c : TREATY_FIELD
            }

            objParentPlacementRequest.Reinsurer__c = this.lstBrokerReins[i].Reinsurer__c;
            objParentPlacementRequest.Broker__c = this.lstBrokerReins[i].Broker__c;
            objParentPlacementRequest.WrittenShare__c = this.lstBrokerReins[i].WrittenShare__c;
            objParentPlacementRequest.Program__c = this.selectedProgram;
            objParentPlacementRequest.Treaty__c = this.lstBrokerReins[i].Treaty__c;
            objParentPlacementRequest.TECH_PhaseType__c = '4';
            lstParentPlacementRequestToInsert.push(objParentPlacementRequest);
        }

        if (this.lstAllSections!=null || this.lstAllSections!=undefined){
            for(let i = 0; i < this.lstAllSections.length; i++){
                let rowRequest = {... this.lstAllSections[i].request};
                rowRequest['Section__c'] = this.lstAllSections[i].Id;
                rowRequest['Treaty__c'] = this.lstAllSections[i].Treaty__c;
                rowRequest['Program__c'] = this.lstAllSections[i].Program__c;
                rowRequest['TECH_PhaseType__c'] = '4';
                rowRequest['Id'] = null;
                rowRequest['Broker__c'] = null;
                rowRequest['Reinsurer__c'] = null;
                rowRequest['QuoteStatus__c'] = null;
                rowRequest['Quote__c'] = null;
                lstChildPlacementRequest.push(rowRequest);
            }
        }

        savePlacementRequestRecord({ lstParentPlacementRequest : lstParentPlacementRequestToInsert, lstChildPlacementRequest : lstChildPlacementRequest})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                let lstNewRequest = result.lstRequestDetails;
                let reinsurerNameUrl;
                lstNewRequest = lstNewRequest.map(row => {
                    reinsurerNameUrl = '../n/RespondOnBehalf?c__id='+row.Id+'-'+this.selectedProgram+'-'+this.valueUWYear+'-'+this.valuePrincipalCedComp+'-'+this.statusPlacement+'-'+this.selectedTreaty+'-'+this.selectedBrokerId+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus+'-'+row.ReinsurerStatus__c;
                    return {...row , reinsurerNameUrl}
                });

                let lstAllRequest = [];

                for(let i = 0; i < this.dataPlacementRequest.length; i++){
                    lstAllRequest.push(this.dataPlacementRequest[i]);
                }

                for(let i = 0; i < lstNewRequest.length; i++){
                    lstAllRequest.push(lstNewRequest[i]);
                }
                
                this.dataPlacementRequest = lstAllRequest;
                this.sortData('TECH_Layer__c', 'TECH_ReinsurerName__c' , 'asc');
                this.titleCountPlacementRequest = 'Placement Requests' + ' (' + this.dataPlacementRequest.length + ')';
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.placementReqCreated, variant: 'success' }),);
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });

        this.isNewPlacementRequestModalOpen = false;
    }

    viewPlacementTable(){
            viewPlacementTable({ programId:this.selectedProgram})
            .then(data => {
                if(data){
                    console.log ('data == ', data);
                    var tempData = JSON.parse( JSON.stringify( data ) );
                    console.log ('tempData == ', tempData);
                    let dataSub = data[0].sub;
                    console.log ('dataSub == ', dataSub);
                    var finalData = [];
                    var lstOnlyBroker = [];
                    var lstOnlyReinsurer = [];
                    let lstOnlyPool = [] ;
                    var lstTotal = [];
                    for ( var i = 0; i < tempData.length; i++ ) {
                        if(tempData[i]['type'] == 'Lead'){
                            tempData[i].colorStyle = "background-color: #F0F8FF;";
                            tempData[i].boldStyle = "font-weight: bold;";
                        }
                        else if(tempData[i]['type'] == 'total'){
                            tempData[i].colorStyle = "background-color: #dddddd;";
                            tempData[i].boldStyle = "";
                        }
                        else{
                            tempData[i].colorStyle = "";
                            tempData[i].boldStyle = "";
                        }
                        tempData[i].nameStyle = "";
                        tempData[i].rowStyle = "";
                        tempData[i].parentId = ""; 

                        if(tempData[i]['writtenShare'] != undefined){
                            let formattedWrittenShareArray = (tempData[i]['writtenShare'].toFixed(6)).toString().split('.');
                            tempData[i]['writtenShare'] = formattedWrittenShareArray[0]+','+formattedWrittenShareArray[1]+'%';
                        }
                        //finalData.push(tempData[i]); 
                        lstOnlyReinsurer.push(tempData[i]);

                        
                        if(tempData[i]['sub'].length > 0){
                            tempData[i].iconName = "utility:chevronright";

                            for(var j = 0; j < tempData[i]['sub'].length; j++){
                                var child = tempData[i]['sub'][j];

                                if(child['type'] == 'Lead'){
                                    child.boldStyle = "font-weight: bold;";
                                }
                                else{
                                    child.boldStyle = "";
                                }

                                if(child['type'] == 'total' ){
                                    if(parseFloat(child.writtenShare) == parseFloat(child.treatyPlacementShare)){
                                        child.totalColorCss = 'slds-text-title_bold slds-text-color_success';
                                    }
                                    else{
                                        console.log('ERROR');
                                        child.totalColorCss = 'slds-text-title_bold slds-text-color_error';
                                    }
                                }
                                else{
                                    child.totalColorCss = '';
                                }

                                child.parentId = tempData[i]['id'];
                                child.nameStyle = ""
                                child.rowStyle = "hide";
                                child.iconName = "";

                                if(child['writtenShare'] != undefined){
                                    let formattedChildWrittenShareArray = (child['writtenShare'].toFixed(6)).toString().split('.');
                                    child['writtenShare'] = formattedChildWrittenShareArray[0]+','+formattedChildWrittenShareArray[1]+'%';
                                }

                            //RRA - ticket 1358 - 12122022
                                if(child['broker'] === undefined && child['reinsurerPool'] !== undefined){
                                    if (child['reinsurerPool'].includes("Pool")) {
                                        lstOnlyPool.push(child);
                                    }else{
                                        lstOnlyReinsurer.push(child) ;
                                    }
                                }else if (child['broker'] !== undefined && child['reinsurerPool'] !== undefined){
                                    lstOnlyBroker.push(child);
                                }else if (child['type']==='total'){
                                    lstTotal.push(child);
                                }
                            }
                        }
                        else{
                            tempData[i].iconName = "";
                        }

                        delete tempData[i].sub; 

                    }

                    //lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.broker.localeCompare(b.broker)) || (a.reinsurerPool.localeCompare(b.reinsurerPool))) ; 
                    //lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.reinsurerPool.localeCompare(b.reinsurerPool))) ; 
                    
                    //this.placementTableData = finalData.concat(lstOnlyReinsurer).concat(lstOnlyBroker).concat(lstTotal); 

                    //Step 1 : Sort by Reinsurer 
                    lstOnlyReinsurer = this.sortByField ('reinsurerPool', lstOnlyReinsurer, 'asc');
                    //Step 2 : Sort by Broker 
                    lstOnlyBroker = this.sortDataFields (lstOnlyBroker, 'broker','reinsurerPool', 'asc');

                    //Step 3 : Sort by Pool 
                    lstOnlyPool = this.sortByField ('reinsurerPool', lstOnlyPool, 'asc');
                    
                    //Step 4: Merge each list (Reinsurer / Broker / Pool)
                    finalData = lstOnlyReinsurer.concat(lstOnlyBroker).concat(lstOnlyPool).concat(lstTotal); //RRA - ticket 1358 - 12122022

                    //Step 5 : Sort by ParentId
                    finalData =  this.sortByField ('parentId', finalData, 'asc');

                    //Step 6 : Sort by Layer
                    finalData =  this.sortByField ('layer', finalData, 'asc');

                    this.placementTableData = finalData;
                    console.log ('this.placementTableData == ', this.placementTableData);

                }  
                    this.isPlacementTableOpen = true;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
    }

    showOrHideChildrenRows(event){
        let rowId = event.target.dataset.rowid;
        let isExpanded = event.target.dataset.expanded;
        event.target.iconName = JSON.parse(isExpanded) ? "utility:chevronright": "utility:chevrondown";
        event.target.dataset.expanded = JSON.stringify(!JSON.parse(isExpanded));
         
        this.placementTableData = this.placementTableData.map((obj) => {
            if(obj.parentId == rowId &&  !JSON.parse(isExpanded)){
                obj.rowStyle = "";
                if(obj['type'] == 'Lead'){
                    obj.colorStyle = "background-color: #F0F8FF;";
                }
                else if(obj['type'] == 'total'){
                    obj.colorStyle = "background-color: #dddddd;";
                }
                else{
                    obj.colorStyle = "";
                }
            }
            if(obj.parentId == rowId && JSON.parse(isExpanded)){
                obj.rowStyle = "hide";
                obj.colorStyle = "";
            }
            return obj;
        });

    }

    get placementTableDataAA() {
        return JSON.parse(JSON.stringify(this.placementTableData));
      }

    convertProxyObjectToPojo(proxyObj) {
      return _.cloneDeep(proxyObj);
    }

    sortData(fieldName,fieldName2, sortDirection) {
        let sortResult = Object.assign([], this.dataPlacementRequest);
        this.dataPlacementRequest = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            }
            else{
                if(a[fieldName2] < b[fieldName2]){
                    return sortDirection === 'asc' ? -1 : 1;
                }
                else if(a[fieldName2] > b[fieldName2]){
                    return sortDirection === 'asc' ? 1 : -1;
                }
                else{
                    return 0;
                }
            }
        })
    }

    sortDataFields(lstData, fieldName,fieldName2, sortDirection) {
        let sortResult = Object.assign([], lstData);
        lstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            }
            else{
                if(a[fieldName2] < b[fieldName2]){
                    return sortDirection === 'asc' ? -1 : 1;
                }
                else if(a[fieldName2] > b[fieldName2]){
                    return sortDirection === 'asc' ? 1 : -1;
                }
                else{
                    return 0;
                }
            }
        })
        return sortResult;
    }

    handleRowSelection(event){
        let lstSelectedRequest = event.detail.selectedRows;
        let isReinsurerStatusSetup = false;

        if(lstSelectedRequest.length != 0){
            for(let i = 0; i < lstSelectedRequest.length; i++){
                if(lstSelectedRequest[i].ReinsurerStatus__c == 'Setup'){
                    isReinsurerStatusSetup = true;
                }
            }

            //if selected rows have reinsurer status "Setup" -> disable update and remind button
            if(isReinsurerStatusSetup == true || (isReinsurerStatusSetup == false && this.disablePlacementInfo == true)){
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
    sortByField(fieldName, lstData, sortDirection) {
        let sortResult = Object.assign([], lstData);
        let lstSortedData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            }
            else{
                return 0;
            }
        })
        return lstSortedData;
    }
}