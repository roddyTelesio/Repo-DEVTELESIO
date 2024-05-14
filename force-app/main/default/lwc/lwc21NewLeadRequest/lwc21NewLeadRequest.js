import {LightningElement, track, wire, api} from 'lwc';
import {getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getTreaties from '@salesforce/apex/LWC21_NewLeadRequest.getTreaties';
import getBroker from '@salesforce/apex/LWC21_NewLeadRequest.getBroker';
import getSectionRetainToLeadDetails from '@salesforce/apex/LWC21_NewLeadRequest.getSectionRetainToLeadDetails';
import loadReinsurerFromQuote from '@salesforce/apex/LWC21_NewLeadRequest.loadReinsurerFromQuote';
import saveLeadRequestRecord from '@salesforce/apex/LWC21_NewLeadRequest.saveLeadRequestRecord';
import LEAD_TYPE_FIELD from '@salesforce/schema/Request__c.LeadType__c';
import REINSURER_STATUS_FIELD from '@salesforce/schema/Request__c.ReinsurerStatus__c';
import checkReinsurerBroker from '@salesforce/apex/LWC24_NewPlacementRequest.checkReinsurerBroker';//RRA - ticket 1571 - 20092023
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import QUOTE_FIELD from '@salesforce/schema/Request__c.Quote__c';
import REASONFORREFUSAL_FIELD from '@salesforce/schema/Request__c.ReasonRefusal__c';
import WRITTENSHARE_REQUEST_FIELD from '@salesforce/schema/Request__c.WrittenShare__c';
import BROKER_REQUEST_FIELD from '@salesforce/schema/Request__c.Broker__c';
import REINSURER_REQUEST_FIELD from '@salesforce/schema/Request__c.Reinsurer__c';
import PROGRAM_REQUEST_FIELD from '@salesforce/schema/Request__c.Program__c';
import TREATY_REQUEST_FIELD from '@salesforce/schema/Request__c.Treaty__c';
import TECHPHASETYPE_REQUEST_FIELD from '@salesforce/schema/Request__c.TECH_PhaseType__c';
import SECTION_OBJECT from '@salesforce/schema/Section__c';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import REINSTATEMENT_FIELD from '@salesforce/schema/Section__c.Reinstatements__c';
import EPINATURE_FIELD from '@salesforce/schema/Section__c.Nature__c';
import Id from '@salesforce/user/Id';

//import labels
import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import NumberErrorMessage from '@salesforce/label/c.NumberErrorMessage';
import twoDpErrorMessage from '@salesforce/label/c.twoDpErrorMessage';
import maxHundredErrorMessage from '@salesforce/label/c.maxHundredErrorMessage';
import minHundredErrorMessage from '@salesforce/label/c.minHundredErrorMessage';
import maxThousandErrorMessage from '@salesforce/label/c.maxThousandErrorMessage';
import LeadRequestsCreatedSuccessfully from '@salesforce/label/c.LeadRequestsCreatedSuccessfully';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import noRequestAvailable from '@salesforce/label/c.noRequestAvailable';
import noBrokerRein from '@salesforce/label/c.noBrokerRein';
import errorMsg from '@salesforce/label/c.errorMsg';
import requestPlacementExistAlready from '@salesforce/label/c.requestPlacementExistAlready';//RRA - ticket 1571 - 20092023

const columnsLeader = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
    { label: 'Type', fieldName: 'LeadType__c' },
    { label: 'Written share', fieldName: 'WrittenShare__c' , type: 'number', cellAttributes: { alignment: 'left' } }
];
const columnsLoadFromQuote = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
];

export default class LWC21_NewLeadRequest extends LightningElement {
    label = {
        DecimalPlacesErrorMessage,
        NumberErrorMessage,
        twoDpErrorMessage,
        maxHundredErrorMessage,
        minHundredErrorMessage,
        maxThousandErrorMessage,
        LeadRequestsCreatedSuccessfully,
        FormEntriesInvalid,
        noRequestAvailable,
        noBrokerRein,
        errorMsg,
        requestPlacementExistAlready//RRA - ticket 1571 - 20092023
    }

    @api valueTreaty;
    @api valueTreatyChange;
    @api lstSelectedLeaderBrokerReinsurer = [];
    @api lstLeadRequestId = [];
    @api programId;
    @track lstLeader = [];
    @track dataLeader = [];
    @track lstSelectedLeader = [];
    @track lstSectionRequestRetainToLead = [];
    @track searchBrokerLookupRecords = [];
    @track dataLoadFromQuote = [];
    @track lstAllRequests = [];
    @track lstRequestLoadFromQuote = [];
    treatyOptions;
    hasRendered = false
    titleCountLeader = 'Leader(s) (0)';
    columnsLeader = columnsLeader;
    typeOption;
    isNewLeaderOpenModal = false;
    disableLeaderSaveBtn = true;
    txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    selectedBrokerText = null;
    selectedBrokerName;
    selectedBrokerId;
    messageFlag = false;
    loadingText = false;
    isTreatyNull = true;
    isOpenConfirmation = false;
    isAcceptButtonSaveClick = false;
    giveAccess = false;
    isOpen = false;
    columnsLoadFromQuote = columnsLoadFromQuote;
    selectedRows;
    displaySpinner = false;
    wiredLeaderFollowers;
    wiredRequestDetails;
    wiredAccountBroker;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfoRequest;

    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfoSection;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('updatedListReinsurer', this.getUpdatedListReinsurer, this);
        registerListener('isNewReinsurerLeaderOpenModal', this.closeNewReinsurerLeaderModal, this);

        if(this.valueTreaty == null || this.valueTreaty == undefined){
            this.isTreatyNull = true;
        }
        else{
            this.isTreatyNull = false;
        }

        this.getTreaties();
    }

    closeNewReinsurerLeaderModal(val){
        this.isNewLeaderOpenModal = val;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: QUOTE_FIELD})
    setQuotePicklistOpt({error, data}) {
        if(data){
            this.quoteOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: REASONFORREFUSAL_FIELD})
    setReasonForRefusalPicklistOpt({error, data}) {
        if(data){
            this.reasonForRefusalOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoSection.data.defaultRecordTypeId', fieldApiName: CURRENCY_FIELD})
    setCurrencyPicklistOpt({error, data}) {
        if(data){
            this.currencyOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoSection.data.defaultRecordTypeId', fieldApiName: REINSTATEMENT_FIELD})
    setReinstatementPicklistOpt({error, data}) {
        if(data){
            this.reinstatementOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoSection.data.defaultRecordTypeId', fieldApiName: EPINATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    getTreaties(){
        getTreaties({programId: this.programId})
        .then(result => {
            let treatyOpt = [];

            for(let i = 0; i < result.length; i++){
                treatyOpt.push(result[i]);
            }

            this.treatyOptions = treatyOpt;

        })
        .catch(error => {
            this.error = error;
        });
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

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: LEAD_TYPE_FIELD})
    setTypePicklistOpt({error, data}) {
        if(data){
            this.typeOption = data.values;
        }
        else{
            this.error = error;
        }
    }

    getUpdatedListReinsurer(val){
        let updLstLeader = val;
        let arr1 = [];
        let lstUpdSelectedLeaderBrokerReinsurer = [];

        for(var key in updLstLeader){
            let ele = updLstLeader[key];
            lstUpdSelectedLeaderBrokerReinsurer.push(ele.Broker__c + '-' + ele.Reinsurer__c);
            let newsObject = { 'recId' : ele.Reinsurer__c
                                ,'recName' : ele.TECH_ReinsurerName__c
                                , 'TECH_ReinsurerName__c' : ele.TECH_ReinsurerName__c
                                , 'TECH_TreatyName__c' : ele.TECH_TreatyName__c
                                , 'Reinsurer__c' : ele.Reinsurer__c
                                , 'Program__c' : this.programId //RRA - ticket 1571 - 20092023
                                , 'LeadType__c' :  ele.LeadType__c
                                , 'Treaty__c' : ele.Treaty__c
                                , 'Checked' : false
                                , 'TECH_BrokerName__c' : ele.TECH_BrokerName__c
                                , 'WrittenShare__c' : ele.WrittenShare__c
                                , 'Broker__c' : ele.Broker__c
                                , 'BrokerReinsurer' : ele.Broker__c + '-' + ele.Reinsurer__c
            };
            arr1.push(newsObject);
        }

        this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
        this.lstLeader = arr1;
        this.titleCountLeader = 'Leader(s) (' + this.lstLeader.length + ')';
        if(this.lstLeader.length == 0){
            this.disableLeaderSaveBtn = true;
        }
        else{
            this.disableLeaderSaveBtn = false;
        }
    }

    handleSaveLeadRequest(){
        this.displaySpinner = true;

        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if(allValid) {
            console.log('is valid');
            let lstParentLeadRequestToInsert = [];
            let lstChildLeadRequestToInsert = [];
            let lstReinsurerBroker = [];
            let idProgram;
            console.log('this.lstLeader == ',this.lstLeader);
            for(let i = 0; i < this.lstLeader.length; i++){
                let objParentLeadRequest = {
                    Reinsurer__c : REINSURER_REQUEST_FIELD,
                    Broker__c : BROKER_REQUEST_FIELD,
                    WrittenShare__c : WRITTENSHARE_REQUEST_FIELD,
                    TECH_PhaseType__c : TECHPHASETYPE_REQUEST_FIELD,
                    Program__c : PROGRAM_REQUEST_FIELD,
                    Treaty__c : TREATY_REQUEST_FIELD,
                    LeadType__c : LEAD_TYPE_FIELD,
                    ReinsurerStatus__c : REINSURER_STATUS_FIELD
                }

                objParentLeadRequest.Reinsurer__c = this.lstLeader[i].Reinsurer__c;
                objParentLeadRequest.Broker__c = this.lstLeader[i].Broker__c;
                objParentLeadRequest.WrittenShare__c = parseFloat(this.lstLeader[i].WrittenShare__c);
                objParentLeadRequest.Program__c = this.programId;
                objParentLeadRequest.Treaty__c = this.lstLeader[i].Treaty__c;
                objParentLeadRequest.TECH_PhaseType__c = '4';
                objParentLeadRequest.LeadType__c = this.lstLeader[i].LeadType__c;
                objParentLeadRequest.ReinsurerStatus__c = 'Setup';
                objParentLeadRequest.CommentsResponse__c = null; 
                lstParentLeadRequestToInsert.push(objParentLeadRequest);
                
                //RRA - ticket 1571 - 15092023
                if(this.lstLeader[i].Broker__c == null || this.lstLeader[i].Broker__c == undefined){
                    lstReinsurerBroker.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Reinsurer__c);
                }
                else{
                    lstReinsurerBroker.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
                }
                idProgram = this.lstLeader[0].Program__c
            }
            console.log ('this.lstSectionRequestRetainToLead = ', this.lstSectionRequestRetainToLead);
            for(let i = 0; i < this.lstSectionRequestRetainToLead.length; i++){
                let rowRequest = {... this.lstSectionRequestRetainToLead[i].request};
                rowRequest['Section__c'] = this.lstSectionRequestRetainToLead[i].Id;
                rowRequest['Treaty__c'] = this.lstSectionRequestRetainToLead[i].Treaty__c;
                rowRequest['Program__c'] = this.lstSectionRequestRetainToLead[i].Program__c;
                rowRequest['TECH_PhaseType__c'] = '4';
                rowRequest['Id'] = null;
                rowRequest['Broker__c'] = null;
                rowRequest['Reinsurer__c'] = null;
                rowRequest['QuoteStatus__c'] = null;
                rowRequest['Quote__c'] = null;
                rowRequest['ReinsurerStatus__c'] = 'Setup';
                rowRequest['ResponseDate__c'] = null;
                rowRequest['LastSentDate__c'] = null;
                rowRequest['QuoteOnBehalf__c'] = false;
                rowRequest['LeadOnBehalf__c'] = false;
                rowRequest['PlacementOnBehalf__c'] = false;
                rowRequest['ExpectedResponseDate__c'] = null; // RRA - 01/06/2022 - 1104
                rowRequest['VersionMajor__c'] = 0; // RRA - 01/06/2022 - 1104
                rowRequest['VersionMinor__c'] = 0;// RRA - 01/06/2022 - 1104
                rowRequest['CommentsResponse__c'] = null; // RRA - 02/06/2022 - 1104
                console.log('### MRA rowRequest= ', JSON.stringify(rowRequest)) ;
                lstChildLeadRequestToInsert.push(rowRequest);
            }

            console.log ('### MRA lstChildLeadRequestToInsert = ', JSON.stringify(lstChildLeadRequestToInsert));
            console.log ('### MRA lstParentLeadRequestToInsert = ', JSON.stringify(lstParentLeadRequestToInsert));
 
            console.log('lstReinsurerBroker Lead== ', lstReinsurerBroker);
            console.log('idProgram Lead == ', idProgram);

            //RRA - ticket 1571 - 20092023
            checkReinsurerBroker({ lstIds : lstReinsurerBroker, programId : idProgram, recordTypeName : 'Lead'})
            .then(result => {
                console.log('result Lead == ', result);
                if(result == true){
                    this.displaySpinner = false;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.requestPlacementExistAlready, variant: 'error'}), );
                }
                else{
                    saveLeadRequestRecord({ lstParentLeadRequest : lstParentLeadRequestToInsert, lstChildLeadRequest : lstChildLeadRequestToInsert})
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                            this.displaySpinner = false;
                        }
                        else{
                            this.displaySpinner = false;
                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.LeadRequestsCreatedSuccessfully, variant: 'success' }),);
                            if(this.isAcceptButtonSaveClick == true){
                               this.isOpenConfirmation = false;
                               this.isAcceptButtonSaveClick = false;
                               this.lstLeader = [];
                               this.titleCountLeader = 'Leader(s) (0)';
                               this.valueTreaty = this.valueTreatyChange;
                               this.disableLeaderSaveBtn = true;
                            }
                            else{
                                this.handleCloseNewLeadRequestModal();
                            }
                            fireEvent(this.pageRef, 'refreshBrokerFilters', '');
                            fireEvent(this.pageRef, 'refreshReinsurerFilters', '');
                        }
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                        this.displaySpinner = false;
                    });
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
        else{
            this.displaySpinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
        }
    }

    handleCloseNewLeadRequestModal(){
        fireEvent(this.pageRef, 'refreshReq', 'refresh');
        fireEvent(this.pageRef, 'closeNewLeadRequestModal', false);
    }

    handleChangeTreaty(event){
        this.valueTreatyChange = event.detail.value;
        if(this.valueTreatyChange == null || this.valueTreatyChange == undefined){
            this.isTreatyNull = true;
        }
        else{
            this.isTreatyNull = false;
        }

        if(this.disableLeaderSaveBtn == true){
            this.lstLeader = [];
            this.titleCountLeader = 'Leader(s) (0)';
            this.valueTreaty = event.detail.value;
        }
        else{
            this.isOpenConfirmation = true;
        }
    }

    handleCloseConfirmationModal(){
        this.isOpenConfirmation = false;
        this.lstLeader = [];
        this.disableLeaderSaveBtn = true;
        this.titleCountLeader = 'Leader(s) (0)';
        this.valueTreaty = this.valueTreatyChange;
    }

    acceptSaveLeadRequestBeforeTreatyChange(){
        this.isAcceptButtonSaveClick = true;
        this.handleSaveLeadRequest();
    }

    @wire(getSectionRetainToLeadDetails, {treatyId: '$valueTreaty', lstLeader: '$lstSelectedLeaderBrokerReinsurer'})
    wiredGetSectionRetainToLeadDetails(result){
        this.wiredRequestDetails = result;
        if(result.data){
            this.lstSectionRequestRetainToLead = result.data.lstSections;
            let mapLastCreatedRequestBySectionId = result.data.mapLastCreatedRequestBySectionId;

            console.log('mapLastCreatedRequestBySectionId ', mapLastCreatedRequestBySectionId);
            let lstUpdSectionsRequest = [];

            for(let j = 0; j < this.lstSectionRequestRetainToLead.length; j++){
                let rowSection = { ...this.lstSectionRequestRetainToLead[j] };
                let typeOfQuote = rowSection.QuoteType__c;
                let typeOfTreaty = rowSection.TECH_TypeofTreaty__c;
                let ltaProgram = rowSection.Program__r.LTA__c;
                let request = {};
                if(mapLastCreatedRequestBySectionId[rowSection.Id] != undefined){
                    request = { ...mapLastCreatedRequestBySectionId[rowSection.Id] };
                }
                else{
                    request['Section__c'] = this.lstSectionRequestRetainToLead[j].Id
                }

                console.log('request attached to Section ', request);
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
                console.log('typeOfTreaty == ', typeOfTreaty);
                if(typeOfTreaty == '3'){
                    rowSection['isTreatyTypeQS'] = true;
                    //rowSection['isTreatyTypeAXAXLQS'] = false;
                }
                else if(typeOfTreaty == '4'){
                    rowSection['isTreatyTypeSurplus'] = true;
                }
                else if(typeOfTreaty == '2'){
                    rowSection['isTreatyTypeXL'] = true;
                }
                else if(typeOfTreaty == '1'){
                    rowSection['isTreatyTypeSL'] = true;
                }//RRA - ticket 1966 - 18032024
                else if(typeOfTreaty == '5'){
                    rowSection['isTreatyTypeAXAXLQS'] = true;
                    //rowSection['isTreatyTypeQS'] = true;
                }
                if(ltaProgram == '1'){
                    rowSection['LTAProgramYes'] = true;
                }
                else{
                    rowSection['LTAProgramYes'] = false;
                }

                if(rowSection.request.OrUnlimited__c == true){
                    rowSection['disableLossCarryingForward'] = true;
                    rowSection['LossCarryingForward__c'] = '';
                }
                else{
                    rowSection['disableLossCarryingForward'] = false;
                }

                if(rowSection.request.NoClaimBonusAmount__c == null || rowSection.request.NoClaimBonusAmount__c == '' || rowSection.request.NoClaimBonusAmount__c == undefined){
                    rowSection['disableNoClaimBonusPerc'] = false;
                }
                else{
                    rowSection['disableNoClaimBonusPerc'] = true;
                }

                if(rowSection.request.NoClaimBonus__c == null || rowSection.request.NoClaimBonus__c == '' || rowSection.request.NoClaimBonus__c == undefined){
                    rowSection['disableNoClaimBonusAmount'] = false;
                }
                else{
                    rowSection['disableNoClaimBonusAmount'] = true;
                }

                if((rowSection.request.DepoPremium__c == null || rowSection.request.DepoPremium__c == '' || rowSection.request.DepoPremium__c == undefined) && (rowSection.request.MinPremium__c == null || rowSection.request.MinPremium__c == '' || rowSection.request.MinPremium__c == undefined)){
                    rowSection['disableMDP'] = false;
                }
                else{
                    rowSection['disableMDP'] = false;
                }

                if(rowSection.request.MDP__c == null || rowSection.request.MDP__c == '' || rowSection.request.MDP__c == undefined){
                    rowSection['disableMinPremium'] = false;
                    rowSection['disableDepoPremium'] = false;
                }
                else{
                    rowSection['disableMinPremium'] = true;
                    rowSection['disableDepoPremium'] = true;
                }

                //QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
                if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                    let totalEPI = 0;
                    let cessionPerc = 0;
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    if(rowSection.Cession_Perc__c != undefined){
                        cessionPerc = rowSection.Cession_Perc__c;
                    }

                    let cededPremiumValue = totalEPI * (cessionPerc / 100);
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    rowSection['request'] = request;
                }

                //(QS or Surplus) + PerHead
                else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                    let totalEPI = 0;
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    let cededPremiumValue = totalEPI;
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    rowSection['request'] = request;
                }
                // RRA - ticket 1966 - 18032024
                //AXA XL QS + (FlatCommission or VariableCommission or RiskPremiumBasis or PerHead)
                else if(typeOfTreaty == '5' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9' || typeOfQuote == '7')){
                    let totalEPI = 0;
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    let cededPremiumValue = totalEPI * (rowSection.Cession_Perc__c/100);//RRA - ticket 1966 - 03042024
                    console.log('cededPremiumValue == ', cededPremiumValue);
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    rowSection['request'] = request;
                }

                //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
                else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                    let totalEPI = 0;
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    let cededPremiumValue = totalEPI;
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    rowSection['request'] = request;
                }

                //(SL or XL) + FixedRate
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                    let totalEPI = 0;
                    let fixedRate = 0;
                    let expectedMDP = 0;  //RRA - ticket 1385 - 10052023
                    let expectedDP = 0; //RRA - ticket 1385 - 10052023
                    let expectedMP = 0; //RRA - ticket 1385 - 10052023

                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    if(rowSection.request.FixedRate__c != undefined){
                        fixedRate = rowSection.request.FixedRate__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMDP__c != undefined){
                    expectedMDP = rowSection.ExpectedMDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedDP__c != undefined){
                        expectedDP = rowSection.ExpectedDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMP__c != undefined){
                        expectedMP = rowSection.ExpectedMP__c;
                    }
                      
                    let cededPremiumValue = totalEPI * (fixedRate / 100);
                    let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                    let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                    let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                    
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    request['MDP__c'] = Math.round(mdp/100)*100;
                    request['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                    request['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                    rowSection['request'] = request;

                    //RRA - ticket 1385 - 10052023
                    if (!mdp){
                        if(!expDP && !expMP){
                            rowSection['disableMDP'] = false;
                            rowSection['disableMinPremium'] = false;
                            rowSection['disableDepoPremium'] = false;
                        }else{
                            rowSection['disableMDP'] = true;
                        }
                    }else{
                        rowSection['disableMinPremium'] = true;
                        rowSection['disableDepoPremium'] = true;
                    }
                }

                //(SL or XL) + FlatPremium
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                    let flatPremium = 0;
                    if(rowSection.request.FlatPremium__c != undefined){
                        flatPremium = rowSection.request.FlatPremium__c;
                    }
                    let cededPremiumValue = flatPremium;
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    rowSection['request'] = request;
                }

                //(SL or XL) + MDP
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                    let MDP = 0;
                    let expectedMDP = 0; //RRA - ticket 1385 - 10052023
                    
                    if(rowSection.request.MDP__c != undefined){
                        MDP = rowSection.request.MDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMDP__c != undefined){
                        expectedMDP = rowSection.ExpectedMDP__c;
                    }
                    
                    let cededPremiumValue = MDP;
                    let mdp = MDP * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    request['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1385 - 10052023
                    
                    rowSection['request'] = request;
                }

                //(SL or XL) + VariableRate
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                    let totalEPI = 0;
                    let expectedMDP = 0;  //RRA - ticket 1385 - 10052023
                    let minRate = 0;
                    let expectedDP = 0;  //RRA - ticket 1385 - 10052023
                    let expectedMP = 0; //RRA - ticket 1385 - 10052023
                    
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    if(rowSection.request.MinRate__c != undefined){
                        minRate = rowSection.request.MinRate__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMDP__c != undefined){
                        expectedMDP = rowSection.ExpectedMDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedDP__c != undefined){
                        expectedDP = rowSection.ExpectedDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMP__c != undefined){
                        expectedMP = rowSection.ExpectedMP__c;
                    }
                    
                    let cededPremiumValue = totalEPI * (minRate / 100);
                    let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                    let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                    let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                    
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    request['MDP__c'] = Math.round(mdp/100)*100;//RRA - ticket 1385 - 10052023
                    request['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                    request['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                    rowSection['request'] = request;
                    
                    //RRA - ticket 1385 - 10052023
                    if (!mdp){
                        if(!expDP && !expMP){
                            rowSection['disableMDP'] = false;
                            rowSection['disableMinPremium'] = false;
                            rowSection['disableDepoPremium'] = false;
                        }else{
                            rowSection['disableMDP'] = true;
                        }
                    }else{
                        rowSection['disableMinPremium'] = true;
                        rowSection['disableDepoPremium'] = true;
                    }
                }

                //(SL or XL) + PerHeadPremium
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                    let totalEPI = 0;
                    let perHeadPremium = 0;
                    let expectedMDP = 0;  //RRA - ticket 1385 - 10052023
                    let expectedDP = 0;  //RRA - ticket 1385 - 10052023
                    let expectedMP = 0; //RRA - ticket 1385 - 10052023
                    
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    if(rowSection.request.PerHeadPremium__c != undefined){
                        perHeadPremium = rowSection.request.PerHeadPremium__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMDP__c != undefined){
                        expectedMDP = rowSection.ExpectedMDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedDP__c != undefined){
                        expectedDP = rowSection.ExpectedDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMP__c != undefined){
                        expectedMP = rowSection.ExpectedMP__c;
                    }
                    
                    let cededPremiumValue = totalEPI * perHeadPremium;
                    let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                    let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                    let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                    
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    request['MDP__c'] = Math.round(mdp/100)*100;//RRA - ticket 1385 - 10052023
                    request['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                    request['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                    rowSection['request'] = request;
                    
                    //RRA - ticket 1385 - 10052023
                    if (!mdp){
                        if(!expDP && !expMP){
                            rowSection['disableMDP'] = false;
                            rowSection['disableMinPremium'] = false;
                            rowSection['disableDepoPremium'] = false;
                        }else{
                            rowSection['disableMDP'] = true;
                        }
                    }else{
                        rowSection['disableMinPremium'] = true;
                        rowSection['disableDepoPremium'] = true;
                    }
                }

                //(SL or XL) + PerHeadVariable
                else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                    let totalEPI = 0;
                    let expectedMDP = 0;  //RRA - ticket 1385 - 10052023
                    let minPerHeadAmount = 0;
                    let expectedDP = 0;  //RRA - ticket 1385 - 10052023
                    let expectedMP = 0; //RRA - ticket 1385 - 10052023
                    
                    if(rowSection.TotalEPI__c != undefined){
                        totalEPI = rowSection.TotalEPI__c;
                    }
                    if(rowSection.request.MinPerHeadAmount__c != undefined){
                        minPerHeadAmount = rowSection.request.MinPerHeadAmount__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMDP__c != undefined){
                        expectedMDP = rowSection.ExpectedMDP__c;
                    }//RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedDP__c != undefined){
                        expectedDP = rowSection.ExpectedDP__c;
                    }
                    //RRA - ticket 1385 - 10052023
                    if(rowSection.ExpectedMP__c != undefined){
                        expectedMP = rowSection.ExpectedMP__c;
                    }
                    
                    let cededPremiumValue = totalEPI * minPerHeadAmount;
                    let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                    let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                    let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                    
                    request['CededPremium__c'] = Math.round(cededPremiumValue);
                    request['MDP__c'] = Math.round(mdp/100)*100;//RRA - ticket 1385 - 10052023
                    request['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                    request['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                    rowSection['request'] = request;
                    
                    //RRA - ticket 1385 - 10052023
                    if (!mdp){
                        if(!expDP && !expMP){
                            rowSection['disableMDP'] = false;
                            rowSection['disableMinPremium'] = false;
                            rowSection['disableDepoPremium'] = false;
                        }else{
                            rowSection['disableMDP'] = true;
                        }
                    }else{
                        rowSection['disableMinPremium'] = true;
                        rowSection['disableDepoPremium'] = true;
                    }
                }
                // default value for overiding commission
                if(typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9'){
                    request['OverridingCommission__c'] = 0.000000;
                    rowSection['request'] = request;
                }

                if(rowSection.Reinstatements__c == '1'){
                    rowSection['ReinstatementStr'] = 'None';
                }
                else if(rowSection.Reinstatements__c == '2'){
                    rowSection['ReinstatementStr'] = 'Free and Unlimited';
                }
                else if(rowSection.Reinstatements__c == '3'){
                    //Other
                    rowSection['ReinstatementStr'] = rowSection.TECH_Reinstatement__c;
                }
                //SAU
                let sectionName = rowSection['SectionNumber__c'] + ' - ' + rowSection['Name'];
                rowSection['sectionName'] = sectionName;

                lstUpdSectionsRequest.push(rowSection);
            }

            this.lstSectionRequestRetainToLead = lstUpdSectionsRequest;
            this.sortData('SectionNumber__c','asc');
        }
        else if (result.error) {
            this.lstSectionRequestRetainToLead = undefined;
        }
    }

    refreshDataRequest(){
        return refreshApex(this.wiredRequestDetails);
    }

    handleOpenNewLeaderModal(){
        this.isNewLeaderOpenModal = true;
    }

    handleCloseNewLeaderModal(){
        this.isNewLeaderOpenModal = false;
    }

    handleChangeType(event){
        let typeVal = event.currentTarget.value;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedLeader = [];

        for(let i = 0; i < this.lstLeader.length; i++){
            let leader = { ...this.lstLeader[i] };
            if(this.lstLeader[i].BrokerReinsurer == selectedIdVal){
                leader.LeadType__c = typeVal;
            }
            lstUpdatedLeader.push(leader);
        }

        this.lstLeader = lstUpdatedLeader;
    }

    handleChangeWrittenShare(event){
        let writtenShareValue = event.currentTarget.value;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedLeader = [];

        for(let i = 0; i < this.lstLeader.length; i++){
            let leader = { ...this.lstLeader[i] };
            if(this.lstLeader[i].BrokerReinsurer == selectedIdVal){
                leader.WrittenShare__c = parseFloat(writtenShareValue);
            }
            lstUpdatedLeader.push(leader);
        }

        this.lstLeader = lstUpdatedLeader;
    }

    handleChangeLeaderCheckbox(event){
        let checkboxChecked = event.currentTarget.checked;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedLeader = [];

        for(let i = 0; i < this.lstLeader.length; i++){
            let leader = { ...this.lstLeader[i] };
            if(this.lstLeader[i].BrokerReinsurer == selectedIdVal){
                leader.Checked = checkboxChecked;
            }
            lstUpdatedLeader.push(leader);
        }

        this.lstLeader = lstUpdatedLeader;
    }

    handleDeleteLeaderBtn(){
        for(let i = 0; i < this.lstLeader.length; i++){
            if(this.lstLeader[i].Checked == true){
                this.lstSelectedLeader.push(this.lstLeader[i]);
            }
        }

        this.lstLeader = this.lstLeader.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedLeader);
        let lstUpdSelectedLeaderBrokerReinsurer = [];

        for(let i = 0; i < this.lstLeader.length; i++){
            lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
        }

        this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
        this.titleCountLeader = 'Leader(s) (' + this.lstLeader.length + ')';
        if(this.lstLeader.length == 0){
            this.disableLeaderSaveBtn = true;
        }
        else{
            this.disableLeaderSaveBtn = false;
        }
    }

    handleOnChangeInputValue(event){
        let eventId = event.currentTarget.id;
        let sectionId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestRetainToLead = [];
        let fieldType = event.currentTarget.type;

        if(fieldName == 'OrUnlimited__c'){
           value = event.currentTarget.checked;
        }

        for(let j = 0; j < this.lstSectionRequestRetainToLead.length; j++){
            let rowSection = { ...this.lstSectionRequestRetainToLead[j] };
            let rowRequest = {};
            let typeOfQuote = rowSection.QuoteType__c;
            let typeOfTreaty = rowSection.TECH_TypeofTreaty__c;
            
            if(this.lstSectionRequestRetainToLead[j].Id == sectionId){
                rowRequest = { ...this.lstSectionRequestRetainToLead[j].request };
                if(fieldType == 'number'){
                    rowRequest[fieldName] =  parseFloat(value);
                }
                else{
                    rowRequest[fieldName] = value;
                }

                rowSection['request'] = rowRequest;

                if(fieldName == 'FixedRate__c' || fieldName == 'FlatPremium__c' || fieldName == 'MDP__c' || fieldName == 'MinRate__c' || fieldName == 'PerHeadPremium__c' || fieldName == 'MinPerHeadAmount__c'){
                    //(SL or XL) + FixedRate
                    if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                        let totalEPI = 0;
                        let fixedRate = 0;
                        let expectedMDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedMP = 0; //RRA - ticket 1385 - 10052023
                        
                        if(rowSection.TotalEPI__c != undefined){
                            totalEPI = rowSection.TotalEPI__c;
                        }
                        if(rowSection.request.FixedRate__c != undefined){
                            fixedRate = rowSection.request.FixedRate__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMDP__c != undefined){
                            expectedMDP = rowSection.ExpectedMDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedDP__c != undefined){
                            expectedDP = rowSection.ExpectedDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMP__c != undefined){
                            expectedMP = rowSection.ExpectedMP__c;
                        }
                        
                        console.log('fixedRate ==', fixedRate);
                        console.log('expectedMDP ==', expectedMDP);
                        console.log('expectedDP ==', expectedDP);
                        console.log('expectedMP ==', expectedMP);
                    
                        let cededPremiumValue = totalEPI * (fixedRate / 100);
                        let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                        let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                        let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                        rowSection['request'] = rowRequest;
                        
                        //RRA - ticket 1385 - 10052023
                        if (!mdp){
                            if(!expDP && !expMP){
                                rowSection['disableMDP'] = false;
                                rowSection['disableMinPremium'] = false;
                                rowSection['disableDepoPremium'] = false;
                            }else{
                                rowSection['disableMDP'] = true;
                            }
                        }else{
                            rowSection['disableMinPremium'] = true;
                            rowSection['disableDepoPremium'] = true;
                        }
                    }

                    //(SL or XL) + FlatPremium
                    else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                        let flatPremium = 0;
                        if(rowSection.request.FlatPremium__c != undefined){
                            flatPremium = rowSection.request.FlatPremium__c;
                        }
                        let cededPremiumValue = flatPremium;
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowSection['request'] = rowRequest;
                    }

                    //(SL or XL) + MDP
                    else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                        let MDP = 0;
                        if(rowSection.request.MDP__c != undefined){
                            MDP = rowSection.request.MDP__c;
                        }
                        let cededPremiumValue = MDP;
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowSection['request'] = rowRequest;
                    }

                    //(SL or XL) + VariableRate
                    else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                        let totalEPI = 0;
                        let minRate = 0;
                        let expectedMDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedMP = 0; //RRA - ticket 1385 - 10052023
                        
                        if(rowSection.TotalEPI__c != undefined){
                            totalEPI = rowSection.TotalEPI__c;
                        }
                        if(rowSection.request.MinRate__c != undefined){
                            minRate = rowSection.request.MinRate__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMDP__c != undefined){
                            expectedMDP = rowSection.ExpectedMDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedDP__c != undefined){
                            expectedDP = rowSection.ExpectedDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMP__c != undefined){
                            expectedMP = rowSection.ExpectedMP__c;
                        }
                        
                        console.log('minRate ==', minRate);
                        console.log('expectedMDP ==', expectedMDP);
                        
                        let cededPremiumValue = totalEPI * (minRate / 100);
                        let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                        let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                        let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                        rowSection['request'] = rowRequest;
                        
                        //RRA - ticket 1385 - 10052023
                        if (!mdp){
                            if(!expDP && !expMP){
                                rowSection['disableMDP'] = false;
                                rowSection['disableMinPremium'] = false;
                                rowSection['disableDepoPremium'] = false;
                            }else{
                                rowSection['disableMDP'] = true;
                            }
                        }else{
                            rowSection['disableMinPremium'] = true;
                            rowSection['disableDepoPremium'] = true;
                        }
                    }

                    //(SL or XL) + PerHeadPremium
                    else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                        let totalEPI = 0;
                        let expectedMDP = 0; //RRA - ticket 1385 - 10052023
                        let perHeadPremium = 0;
                        let expectedDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedMP = 0; //RRA - ticket 1385 - 10052023
                        
                        if(rowSection.TotalEPI__c != undefined){
                            totalEPI = rowSection.TotalEPI__c;
                        }
                        if(rowSection.request.PerHeadPremium__c != undefined){
                            perHeadPremium = rowSection.request.PerHeadPremium__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMDP__c != undefined){
                            expectedMDP = rowSection.ExpectedMDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedDP__c != undefined){
                            expectedDP = rowSection.ExpectedDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMP__c != undefined){
                            expectedMP = rowSection.ExpectedMP__c;
                        }
                        
                        console.log('perHeadPremium ==', perHeadPremium);
                        console.log('expectedMDP ==', expectedMDP);
                        let cededPremiumValue = totalEPI * perHeadPremium;
                        let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                        let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                        let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                        
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                        rowSection['request'] = rowRequest;
                        
                        //RRA - ticket 1385 - 10052023
                        if (!mdp){
                            if(!expDP && !expMP){
                                rowSection['disableMDP'] = false;
                                rowSection['disableMinPremium'] = false;
                                rowSection['disableDepoPremium'] = false;
                            }else{
                                rowSection['disableMDP'] = true;
                            }
                        }else{
                            rowSection['disableMinPremium'] = true;
                            rowSection['disableDepoPremium'] = true;
                        }
                    }

                    //(SL or XL) + PerHeadVariable
                    else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                        let totalEPI = 0;
                        let expectedMDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedDP = 0; //RRA - ticket 1385 - 10052023
                        let expectedMP = 0; //RRA - ticket 1385 - 10052023
                        let minPerHeadAmount = 0;
                        
                        if(rowSection.TotalEPI__c != undefined){
                            totalEPI = rowSection.TotalEPI__c;
                        }
                        if(rowSection.request.MinPerHeadAmount__c != undefined){
                            minPerHeadAmount = rowSection.request.MinPerHeadAmount__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMDP__c != undefined){
                            expectedMDP = rowSection.ExpectedMDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedDP__c != undefined){
                            expectedDP = rowSection.ExpectedDP__c;
                        }
                        //RRA - ticket 1385 - 10052023
                        if(rowSection.ExpectedMP__c != undefined){
                            expectedMP = rowSection.ExpectedMP__c;
                        }
                        
                        console.log('minPerHeadAmount ==', minPerHeadAmount);
                        console.log('expectedMDP ==', expectedMDP);
                        
                        let cededPremiumValue = totalEPI * minPerHeadAmount;
                        let mdp = cededPremiumValue * (expectedMDP/100); //RRA - ticket 1385 - 10052023
                        let expDP = cededPremiumValue * (expectedDP/100); //RRA - ticket 1385 - 10052023
                        let expMP = cededPremiumValue * (expectedMP/100); //RRA - ticket 1385 - 10052023
                        
                        rowRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        rowRequest['MDP__c'] = Math.round(mdp/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['DepoPremium__c'] = Math.round(expDP/100)*100; //RRA - ticket 1385 - 10052023
                        rowRequest['MinPremium__c'] = Math.round(expMP/100)*100; //RRA - ticket 1385 - 10052023
                        rowSection['request'] = rowRequest;
                        
                        //RRA - ticket 1385 - 10052023
                        if (!mdp){
                            if(!expDP && !expMP){
                                rowSection['disableMDP'] = false;
                                rowSection['disableMinPremium'] = false;
                                rowSection['disableDepoPremium'] = false;
                            }else{
                                rowSection['disableMDP'] = true;
                            }
                        }else{
                            rowSection['disableMinPremium'] = true;
                            rowSection['disableDepoPremium'] = true;
                        }
                    }
                }

                if(fieldName == 'OrUnlimited__c'){
                    let orUnlimitedCheck = event.currentTarget.checked;
                    if(orUnlimitedCheck == true){
                        rowSection['disableLossCarryingForward'] = true;
                        rowSection['LossCarryingForward__c'] = '';

                        let inputs = this.template.querySelectorAll('[data-id='+sectionId+']');
                        for(let i = 0; i < inputs.length; i++) {
                            inputs[i].value = '';
                        }
                    }
                    else{
                        rowSection['disableLossCarryingForward'] = false;
                    }
                }
                else if(fieldName == 'NoClaimBonusAmount__c'){
                    let noClaimBonusAmountValue = event.currentTarget.value;
                    if(noClaimBonusAmountValue == null || noClaimBonusAmountValue == ''){
                        rowSection['disableNoClaimBonusPerc'] = false;
                    }
                    else{
                        rowSection['disableNoClaimBonusPerc'] = true;
                    }
                }
                else if(fieldName == 'NoClaimBonus__c'){
                    let noClaimBonusValue = event.currentTarget.value;
                    if(noClaimBonusValue == null || noClaimBonusValue == ''){
                        rowSection['disableNoClaimBonusAmount'] = false;
                    }
                    else{
                        rowSection['disableNoClaimBonusAmount'] = true;
                    }
                }
                else if(fieldName == 'MDP__c'){
                    let MDPValue = event.currentTarget.value;
                    if(MDPValue == null || MDPValue == ''){
                        rowSection['disableMinPremium'] = false;
                        rowSection['disableDepoPremium'] = false;
                    }
                    //RRA - ticket 1395 - 10052023 - code commented
                    /*else{
                        rowSection['disableMinPremium'] = true;
                        rowSection['disableDepoPremium'] = true;
                    }*/
                }
                //AMI 16/06/22 W:0738
                //disable mdp when depo premium or min premium is entered
                //enable mdp when depo premium and min premium is entered
                else if(fieldName == 'DepoPremium__c' || fieldName == 'MinPremium__c'){
                    let depoPre =  rowSection.request.DepoPremium__c;
                    let minPre =  rowSection.request.MinPremium__c;

                    if(!depoPre && !minPre){
                        rowSection['disableMDP'] = false;
                    }else{
                        rowSection['disableMDP'] = true;
                    }
                }
            }
            else{
                rowRequest = { ...this.lstSectionRequestRetainToLead[j].request };
            }
            lstUpdSectionRequestRetainToLead.push(rowSection);
        }

        this.lstSectionRequestRetainToLead = lstUpdSectionRequestRetainToLead;
    }

    loadFromQuoteBtn(){
        loadReinsurerFromQuote({treatyId: this.valueTreaty})
        .then(result => {
            console.log('result load == ', result);
            this.lstRequestLoadFromQuote = result;
            if(this.lstRequestLoadFromQuote.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noRequestAvailable, variant: 'error' }),);
            }
            else{
                this.isOpen = true;
                this.displaySpinner = true;
                let lstUpdLoadReinsurerFromQuote = [];
                let lstOnlyBroker = [];
                let lstOnlyReinsurer = [];

                for(let i = 0; i < result.length; i++){
                    let newsObject = { 'recId' : result[i].Reinsurer__c
                                        ,'recName' : result[i].TECH_ReinsurerName__c
                                        , 'TECH_ReinsurerName__c' : result[i].TECH_ReinsurerName__c
                                        , 'TECH_TreatyName__c' : result[i].TECH_TreatyName__c
                                        , 'Reinsurer__c' : result[i].Reinsurer__c
                                        , 'LeadType__c' : '1'
                                        , 'Treaty__c' : result[i].Treaty__c
                                        , 'Checked' : false
                                        , 'TECH_BrokerName__c' : result[i].TECH_BrokerName__c
                                        , 'WrittenShare__c' : result[i].WrittenShareResponse__c
                                        , 'Broker__c' : result[i].Broker__c
                                        , 'FixedRate__c' :  result[i].FixedRate__c 
                                        , 'MinRate__c' : result[i].MinRate__c
                                        , 'WrittenShareResponse__c' : result[i].WrittenShareResponse__c
                                        , 'CommentsResponse__c' : result[i].CommentsResponse__c
                                        , 'ReinsurerExpenses__c' : result[i].ReinsurerExpenses__c
                                        , 'LossCarryingForward__c' : result[i].LossCarryingForward__c
                                        , 'LossCorridorPart__c' : result[i].LossCorridorPart__c
                                        , 'LossCorridorMaxLR__c' : result[i].LossCorridorMaxLR__c
                                        , 'LossCorridorMinLR__c' : result[i].LossCorridorMinLR__c
                                        , 'NoClaimBonus__c' : result[i].NoClaimBonus__c
                                        , 'NoClaimBonusAmount__c' : result[i].NoClaimBonusAmount__c
                                        , 'ProfitCommission__c' : result[i].ProfitCommission__c
                                        , 'MaxRate__c' : result[i].MaxRate__c
                                        , 'ProvisionalRate__c' : result[i].ProvisionalRate__c
                                        , 'FlatPremium__c' : result[i].FlatPremium__c
                                        , 'FixedCommission__c' : result[i].FixedCommission__c
                                        , 'MinVarCommission__c' : result[i].MinVarCommission__c
                                        , 'MaxVarCommission__c' : result[i].MaxVarCommission__c
                                        , 'ProvisionalCommission__c' : result[i].ProvisionalCommission__c
                                        , 'PerHeadPremium__c' : result[i].PerHeadPremium__c
                                        , 'MinPerHeadAmount__c' : result[i].MinPerHeadAmount__c
                                        , 'MaxPerHeadAmount__c' : result[i].MaxPerHeadAmount__c
                                        , 'ProvisionalPerHeadPremium__c' : result[i].ProvisionalPerHeadPremium__c
                                        , 'EstimatedReinsurancePremium__c' : result[i].EstimatedReinsurancePremium__c
                                        , 'EstimatedInsurancePremium__c' : result[i].EstimatedInsurancePremium__c
                                        , 'BrokerReinsurer' : result[i].Broker__c + '-' + result[i].Reinsurer__c
                    };
                    lstUpdLoadReinsurerFromQuote.push(newsObject);
                }
                lstUpdLoadReinsurerFromQuote = this.getUniqueData(lstUpdLoadReinsurerFromQuote, 'BrokerReinsurer');
                //RRA - ticket 1099 - 09122022
                lstUpdLoadReinsurerFromQuote = lstUpdLoadReinsurerFromQuote.map(row => {
                    if (row.TECH_BrokerName__c !== undefined && row.TECH_ReinsurerName__c !== undefined) {
                        lstOnlyBroker.push({...row }) ;
                    }
                    else if(row.TECH_BrokerName__c === undefined && row.TECH_ReinsurerName__c !== undefined){
                        lstOnlyReinsurer.push({...row}) ;
                    }
                    return {...row }
                });
                console.log('lstUpdLoadReinsurerFromQuote == ', lstUpdLoadReinsurerFromQuote);
                //RRA - ticket 1099 - 09122022
                lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.TECH_BrokerName__c.localeCompare(b.TECH_BrokerName__c)) || (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;

                //this.dataLoadFromQuote = lstUpdLoadReinsurerFromQuote;
                //RRA - ticket 1099 - 09122022
                this.dataLoadFromQuote = lstOnlyBroker.concat(lstOnlyReinsurer);
                this.displaySpinner = false;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }


    renderedCallback()
    {
        if(this.hasRendered)
        {
            console.log(' this.lstLeader == ',  this.lstLeader);
            let lstUpdSelectedLeaderBrokerReinsurer = [];

            for(let i = 0; i < this.lstLeader.length; i++){
                lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
            }
            console.log(' lstUpdSelectedLeaderBrokerReinsurer == ',  lstUpdSelectedLeaderBrokerReinsurer);
            this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
            window.setTimeout(() => { this.displaySpinner = false;}, 2000); //RRA - ticket 1051 08112022 (Make time 2s to Load values)
            this.hasRendered = false;
        }
    }

    handleLoadPopUp(event){
        let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRows.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noBrokerRein, variant: 'error' }),);
        }
        else{
            this.displaySpinner = true;
            let lstUpdLeader = [ ...this.lstLeader ];

            for(let i = 0; i < selectedRows.length; i++){
                let row = { ...selectedRows[i] };
                lstUpdLeader.push(row);
            }
           
            this.lstLeader = this.getUniqueData(lstUpdLeader, 'BrokerReinsurer');
            //console.log('this.lstLeader == ', this.lstLeader    );
            this.titleCountLeader = 'Leader(s) (' + this.lstLeader.length + ')';
            /*let lstUpdSelectedLeaderBrokerReinsurer = [];

            for(let i = 0; i < this.lstLeader.length; i++){
                lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
            }
            console.log('lstUpdSelectedLeaderBrokerReinsurer == ', lstUpdSelectedLeaderBrokerReinsurer);
            this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
            window.setTimeout(() => { this.displaySpinner = false;}, 2000); //RRA - ticket 1051 08112022 (Make time 2s to Load values for 2s)*/
            if(this.lstLeader.length == 0){
                this.disableLeaderSaveBtn = true;
            }
            else{
                this.disableLeaderSaveBtn = false;
            }
            this.hasRendered = true;
            this.handleCloseLoadFromQuoteModal();
        }
    }

    handleCloseLoadFromQuoteModal(){
        this.isOpen = false;
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }
      // sort section by section number
      sortData(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.lstSectionRequestRetainToLead);
        this.lstSectionRequestRetainToLead = sortResult.sort(function(a,b){
                                                        if(a[fieldName] < b[fieldName])
                                                            return sortDirection === 'asc' ? -1 : 1;
                                                        else if(a[fieldName] > b[fieldName])
                                                            return sortDirection === 'asc' ? 1 : -1;
                                                        else{
                                                            return 0;
                                                        }
        })
    }
}