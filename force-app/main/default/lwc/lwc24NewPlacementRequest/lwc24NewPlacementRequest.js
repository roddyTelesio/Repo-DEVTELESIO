import {LightningElement, track, wire, api} from 'lwc';
import {getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getTreaties from '@salesforce/apex/LWC24_NewPlacementRequest.getTreaties';
import getBroker from '@salesforce/apex/LWC21_NewLeadRequest.getBroker';
import getUWYearForOriginalProgram from '@salesforce/apex/LWC24_NewPlacementRequest.getUWYearForOriginalProgram';
import loadPreviousYear from '@salesforce/apex/LWC24_NewPlacementRequest.loadPreviousYear';
import loadReinsurerFromQuote from '@salesforce/apex/LWC24_NewPlacementRequest.loadReinsurerFromQuote';
import savePlacementRequestRecord from '@salesforce/apex/LWC24_NewPlacementRequest.savePlacementRequestRecord';
import filterBrokerReinsAll from '@salesforce/apex/LWC24_NewPlacementRequest.filterBrokerReinsAll';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import QUOTE_FIELD from '@salesforce/schema/Request__c.Quote__c';
import REASONFORREFUSAL_FIELD from '@salesforce/schema/Request__c.ReasonRefusal__c';
import WRITTENSHARE_REQUEST_FIELD from '@salesforce/schema/Request__c.WrittenShare__c';
import LEAD_REQUEST_FIELD from '@salesforce/schema/Request__c.LeadType__c';
import BROKER_REQUEST_FIELD from '@salesforce/schema/Request__c.Broker__c';
import REINSURER_REQUEST_FIELD from '@salesforce/schema/Request__c.Reinsurer__c';
import PROGRAM_REQUEST_FIELD from '@salesforce/schema/Request__c.Program__c';
import TREATY_REQUEST_FIELD from '@salesforce/schema/Request__c.Treaty__c';
import TECHPHASETYPE_REQUEST_FIELD from '@salesforce/schema/Request__c.TECH_PhaseType__c';
import SECTION_OBJECT from '@salesforce/schema/Section__c';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import REINSTATEMENT_FIELD from '@salesforce/schema/Section__c.Reinstatements__c';
import EPINATURE_FIELD from '@salesforce/schema/Section__c.Nature__c';
import REINSURER_STATUS_FIELD from '@salesforce/schema/Request__c.ReinsurerStatus__c';
import checkReinsurerBroker from '@salesforce/apex/LWC24_NewPlacementRequest.checkReinsurerBroker';

import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import placementReqCreated from '@salesforce/label/c.placementReqCreated';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import noTreatyField from '@salesforce/label/c.noTreatyField';
import noRequestAvailable from '@salesforce/label/c.noRequestAvailable';
import noBrokerRein from '@salesforce/label/c.noBrokerRein';
import BRAlreadyExists from '@salesforce/label/c.BRAlreadyExists';
import BRAlreadyExistForTreaty from '@salesforce/label/c.BRAlreadyExistForTreaty';
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsLeader = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
    { label: 'Type', fieldName: 'Type__c' },
    { label: 'Written share', fieldName: 'WrittenShare__c' , type: 'number', cellAttributes: { alignment: 'left' }, typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'}}
];

const columnsLoadFromQuote = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c' },
];

export default class LWC24_NewPlacementRequest extends LightningElement {
    label = {
        DecimalPlacesErrorMessage,
        placementReqCreated,
        FormEntriesInvalid,
        noTreatyField,
        noRequestAvailable,
        noBrokerRein,
        BRAlreadyExists,
        BRAlreadyExistForTreaty,
        errorMsg
    }

    @api valueTreaty;
    @api valueTreatyChange;
    @api lstSelectedLeaderBrokerReinsurer = [];
    @api lstLeadRequestId = [];
    @api programId;
    @track dataLeader = [];
    @track lstLeader = [];
    @track lstSelectedLeader = [];
    @track lstSectionRequestRetainToLead = [];
    @track searchBrokerLookupRecords = [];
    @track lstRequestLoadFromQuote = [];
    @track dataLoadFromQuote = [];
    treatyOptions;
    titleCountFollower = 'Follower(s) (0)';
    columnsLeader = columnsLeader;
    isNewFollowerOpenModal = false;
    disableLeaderSaveBtn = true;
    txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    selectedBrokerText = null;
    selectedBrokerName;
    spinnerLoadPreviousYear = false;
    selectedBrokerId;
    spinnerPlacementRequest = false; // RRA - ticket 1381 - 16122022
    messageFlag = false;
    loadingText = false;
    isTreatyNull = true;
    isOpenConfirmation = false;
    isAcceptButtonSaveClick = false;
    isProgRenewedStandRene = false;
    isLoadFromQuoteModalOpen = false;
    loadFromPrevYrTitle = 'Load from <prev_year>';
    titleLoadFromQuotePrevYr = 'Load from Quote';
    columnsLoadFromQuote = columnsLoadFromQuote;
    isLoadFromQuote = false;
    wiredtreaties;
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

        getUWYearForOriginalProgram({ progId: this.programId })
        .then(result => {
            this.isProgRenewedStandRene = result.isProgRenewedStandRene;
            let uwYearOriginalProgram = result.uwYearOriginalProgram;
            this.loadFromPrevYrTitle = 'Load from ' + uwYearOriginalProgram;
        })
        .catch(error => {
            this.error = error;
        });
    }

    closeNewReinsurerLeaderModal(val){
        this.isNewFollowerOpenModal = val;
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
        if(data){//AMI 02/06/22 W0868
            let wireResults = data.values !== undefined ? data.values : [];
            let unsortedCurList = [];
            let sortedCurList = [];

            if(wireResults.length > 0){
                //get all picklist options first
                wireResults.forEach(ele => {
                    unsortedCurList.push({'label':ele.label,'value':ele.value});
                });
               
                //sort retrived options
                sortedCurList = unsortedCurList.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));

                //move eur
                let eurObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'EUR'), 1)[0];
                sortedCurList.splice(0, 0, eurObj);

                //move usd
                let usdObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'USD'), 1)[0];
                sortedCurList.splice(1, 0, usdObj);

                //move gbp
                let gbpObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'GBP'), 1)[0];
                sortedCurList.splice(2, 0, gbpObj);

                //set display prop
                this.currencyOpt = sortedCurList;
            }
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

    @wire(getTreaties, {selectedProgramId: '$programId'})
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
            this.valueTreaty = 'All';
            this.valueTreatyChange = 'All';
            this.isTreatyNull = false;
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
        let brokerName = '';
        let treatyName = '';
        this.txtBrokerLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.selectedBrokerText = selectName;
        this.selectedBrokerName = selectName;
        this.selectedBrokerId = recId;
    }

    getUpdatedListReinsurer(val){
        let updLstLeader = val;
        let arr1 = [];
        let lstBrokerReins = [];
        let lstUpdSelectedLeaderBrokerReinsurer = [];

        if(this.valueTreaty == 'All'){
            for(var key in updLstLeader){
                let ele = updLstLeader[key];
                lstBrokerReins.push(ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c);
            }

            filterBrokerReinsAll({ lstIds : lstBrokerReins, programId : this.programId})
            .then(result => {

                if(result.length == 0){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.BRAlreadyExists, variant: 'error'}), );
                }
                else{
                    for(var key in updLstLeader){
                        for(let i = 0; i < result.length; i++){
                            let ele = updLstLeader[key];
                            let brokerReinsStr = ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c;
                            if(result[i] == brokerReinsStr){
                                lstUpdSelectedLeaderBrokerReinsurer.push(ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c);
                                let newsObject = { 'recId' : ele.Reinsurer__c
                                                      ,'recName' : ele.TECH_ReinsurerName__c
                                                      , 'TECH_ReinsurerName__c' : ele.TECH_ReinsurerName__c
                                                      , 'TECH_TreatyName__c' : ele.TECH_TreatyName__c
                                                      , 'Reinsurer__c' : ele.Reinsurer__c
                                                      , 'Type__c' : null
                                                      , 'Treaty__c' : ele.Treaty__c
                                                      , 'Checked' : false
                                                      , 'TECH_BrokerName__c' : ele.TECH_BrokerName__c
                                                      , 'WrittenShare__c' : null
                                                      , 'Broker__c' : ele.Broker__c
                                                      , 'BrokerReinsurer' : ele.Broker__c + '-' + ele.Reinsurer__c
                                                      , 'TreatyBrokerReinsurer' : ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c
                                };
                                arr1.push(newsObject);
                            }
                        }
                    }

                    this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
                }

                this.lstLeader = arr1;
                this.titleCountFollower = 'Follower(s) (' + this.lstLeader.length + ')';
                if(this.lstLeader.length == 0){
                    this.disableLeaderSaveBtn = true;
                }
                else{
                    this.disableLeaderSaveBtn = false;
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });
        }
        else{
            for(var key in updLstLeader){
                let ele = updLstLeader[key];
                lstUpdSelectedLeaderBrokerReinsurer.push(ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c);
                let newsObject = { 'recId' : ele.Reinsurer__c
                                    ,'recName' : ele.TECH_ReinsurerName__c
                                    , 'TECH_ReinsurerName__c' : ele.TECH_ReinsurerName__c
                                    , 'TECH_TreatyName__c' : ele.TECH_TreatyName__c
                                    , 'Reinsurer__c' : ele.Reinsurer__c
                                    , 'Type__c' : null
                                    , 'Treaty__c' : ele.Treaty__c
                                    , 'Checked' : false
                                    , 'TECH_BrokerName__c' : ele.TECH_BrokerName__c
                                    , 'WrittenShare__c' : null
                                    , 'Broker__c' : ele.Broker__c
                                    , 'BrokerReinsurer' : ele.Broker__c + '-' + ele.Reinsurer__c
                                    , 'TreatyBrokerReinsurer' : ele.Treaty__c + '-' + ele.Broker__c + '-' + ele.Reinsurer__c
                };
                arr1.push(newsObject);
            }

            this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
            this.lstLeader = arr1;
            this.titleCountFollower = 'Follower(s) (' + this.lstLeader.length + ')';
            if(this.lstLeader.length == 0){
                this.disableLeaderSaveBtn = true;
            }
            else{
                this.disableLeaderSaveBtn = false;
            }
        }
    }

    handleSavePlacementRequest(){
        this.spinnerLeadRequest = true; // RRA - ticket 1381 - 16122022
        this.disableLeaderSaveBtn = true; // RRA - ticket 1381 - 16122022
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if(allValid) {
            let lstPlacementRequestToInsert = [];
            let lstReinsurerBroker = [];

            for(let i = 0; i < this.lstLeader.length; i++){
                let objPlacementLeadRequest = {
                    Reinsurer__c : REINSURER_REQUEST_FIELD,
                    Broker__c : BROKER_REQUEST_FIELD,
                    WrittenShare__c : WRITTENSHARE_REQUEST_FIELD,
                    TECH_PhaseType__c : TECHPHASETYPE_REQUEST_FIELD,
                    Program__c : PROGRAM_REQUEST_FIELD,
                    Treaty__c : TREATY_REQUEST_FIELD,
                    ReinsurerStatus__c : REINSURER_STATUS_FIELD
                }

                if(this.lstLeader[i].Broker__c == null || this.lstLeader[i].Broker__c == undefined){
                    lstReinsurerBroker.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Reinsurer__c);
                }
                else{
                    lstReinsurerBroker.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
                }

                objPlacementLeadRequest.Reinsurer__c = this.lstLeader[i].Reinsurer__c;
                objPlacementLeadRequest.Broker__c = this.lstLeader[i].Broker__c;
                objPlacementLeadRequest.WrittenShare__c = parseFloat(this.lstLeader[i].WrittenShare__c);
                objPlacementLeadRequest.Program__c = this.programId;
                objPlacementLeadRequest.Treaty__c = this.lstLeader[i].Treaty__c;
                objPlacementLeadRequest.TECH_PhaseType__c = '5';
                objPlacementLeadRequest.ReinsurerStatus__c = 'Setup';
                lstPlacementRequestToInsert.push(objPlacementLeadRequest);
            }

            checkReinsurerBroker({ lstIds : lstReinsurerBroker, programId : this.programId, recordTypeName : 'Placement'})
            .then(result => {
                if(result == true){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.BRAlreadyExistForTreaty, variant: 'error'}), );
                }
                else{
                    savePlacementRequestRecord({ lstPlacementLeadRequest : lstPlacementRequestToInsert})
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                        }
                        else{
                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.placementReqCreated, variant: 'success' }),);
                            if(this.isAcceptButtonSaveClick == true){
                               this.isOpenConfirmation = false;
                               this.isAcceptButtonSaveClick = false;
                               this.lstLeader = [];
                               this.titleCountFollower = 'Follower(s) (0)';
                               this.valueTreaty = this.valueTreatyChange;
                               this.disableLeaderSaveBtn = true;
                            }
                            else{
                                this.handleCloseNewPlacementRequestModal();
                            }
                            fireEvent(this.pageRef, 'refreshBrokerFilters', '');
                            fireEvent(this.pageRef, 'refreshReinsurerFilters', '');
                        }
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                    });
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });

        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
        }
        this.spinnerLeadRequest = false; // RRA - ticket 1381 - 16122022
    }

    handleCloseNewPlacementRequestModal(){
        fireEvent(this.pageRef, 'refreshReq', 'refresh');
        fireEvent(this.pageRef, 'closeNewPlacementRequestModal', false);
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
            this.titleCountFollower = 'Follower(s) (0)';
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
        this.titleCountFollower = 'Follower(s) (0)';
        this.valueTreaty = this.valueTreatyChange;
    }

    acceptSavePlacementRequestBeforeTreatyChange(){
        this.isAcceptButtonSaveClick = true;
        this.handleSavePlacementRequest();
    }

    refreshDataRequest(){
        return refreshApex(this.wiredRequestDetails);
    }

    handleOpenNewFollowerModal(){
        this.isNewFollowerOpenModal = true;
    }

    handleCloseNewLeaderModal(){
        this.isNewFollowerOpenModal = false;
    }

    handleChangeType(event){
        let typeVal = event.currentTarget.value;
        let selectedIdVal = event.currentTarget.name;
        let lstUpdatedLeader = [];

        for(let i = 0; i < this.lstLeader.length; i++){
            let leader = { ...this.lstLeader[i] };
            if(this.lstLeader[i].TreatyBrokerReinsurer == selectedIdVal){
                leader.Type__c = typeVal;
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
            if(this.lstLeader[i].TreatyBrokerReinsurer == selectedIdVal){
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
            if(this.lstLeader[i].TreatyBrokerReinsurer == selectedIdVal){
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
            lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
        }

        this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
        this.titleCountFollower = 'Follower(s) (' + this.lstLeader.length + ')';

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

        if(fieldName == 'OrUnlimited__c'){
           value = event.currentTarget.checked;
        }

        for(let j = 0; j < this.lstSectionRequestRetainToLead.length; j++){
            let rowSection = { ...this.lstSectionRequestRetainToLead[j] };
            let rowRequest = {};
            if(this.lstSectionRequestRetainToLead[j].Id == sectionId){
                rowRequest = { ...this.lstSectionRequestRetainToLead[j].request };
                rowRequest[fieldName] = value;
                rowSection['request'] = rowRequest;
            }
            else{
                rowRequest = { ...this.lstSectionRequestRetainToLead[j].request };
            }
            lstUpdSectionRequestRetainToLead.push(rowSection);
        }

        this.lstSectionRequestRetainToLead = lstUpdSectionRequestRetainToLead;
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    loadFromPrevYearBtn(){
        if(this.valueTreaty == undefined || this.valueTreaty == null){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noTreatyField, variant: 'error' }),);
        }
        else{
            this.spinnerLoadPreviousYear = true;  //RRA - ticket 1299 18/11/2022 
            this.isLoadFromQuote = false;
            console.log('programId == ', this.programId);
            loadPreviousYear({selectedProgram: this.programId})
            .then(result => {
                console.log('result == ', result);
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                }
                else if(result.length == 0){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noRequestAvailable, variant: 'error' }),);
                }
                else{
                    this.isLoadFromQuoteModalOpen = true;
                    this.titleLoadFromQuotePrevYr = this.loadFromPrevYrTitle;

                    this.error = undefined;
                    let lstLoadPrevQuoteRequest = [];
                    let treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);
                    let lstOnlyBroker = [];
                    let lstOnlyReinsurer = [];

                    for(let i = 0; i < result.length; i++){
                        let newsObject = { 'recId' : result[i].Reinsurer__c
                                            ,'recName' : result[i].TECH_ReinsurerName__c
                                            , 'TECH_ReinsurerName__c' : result[i].TECH_ReinsurerName__c
                                            , 'TECH_BrokerName__c' : result[i].TECH_BrokerName__c
                                            , 'TECH_TreatyName__c' : treatyName
                                            , 'Reinsurer__c' : result[i].Reinsurer__c
                                            , 'Broker__c' : result[i].Broker__c
                                            , 'Treaty__c' : this.valueTreaty
                                            , 'Checked' : false
                                            , 'Program__c' : this.programId
                                            , 'BrokerReinsurer' : result[i].Broker__c + '-' + result[i].Reinsurer__c
                                            , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + result[i].Broker__c + '-' + result[i].Reinsurer__c
                        };
                        lstLoadPrevQuoteRequest.push(newsObject);
                    }

                    let lstFilterLoadedPrevRequest = this.getUniqueData(lstLoadPrevQuoteRequest, 'TreatyBrokerReinsurer');
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

                    //this.dataLoadFromQuote = lstFilterLoadedPrevRequest;
                    //RRA - ticket 1099 - 09122022
                    this.dataLoadFromQuote = lstOnlyBroker.concat(lstOnlyReinsurer);
                    let lstUpdateReinsurerFromQuote = this.getUniqueData(this.dataLoadFromQuote, 'BrokerReinsurer'); //RRA - ticket 1571 - 11102023
                    console.log('lstUpdateReinsurerFromQuote == ', lstUpdateReinsurerFromQuote);
                    this.dataLoadFromQuote = lstUpdateReinsurerFromQuote;
                }
                this.spinnerLoadPreviousYear = false;  //RRA - ticket 1299 18/11/2022 
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }

    getPicklistLabel(picklistOptions, selectedPicklistOpt){
        for(let i = 0; i < picklistOptions.length; i++){
            if(picklistOptions[i].value == selectedPicklistOpt){
                return picklistOptions[i].label;
            }
        }
    }

    loadFromQuoteBtn(){
        let lstAvailableTreaty = [];
        this.titleLoadFromQuotePrevYr = 'Load From Quote';

        if(this.valueTreaty == 'All'){
            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                lstAvailableTreaty.push(this.treatyOptions[i].value);
            }
        }
        else{
            lstAvailableTreaty.push(this.valueTreaty);
        }
        
        console.log('lstAvailableTreaty == ', lstAvailableTreaty);

        loadReinsurerFromQuote({lstTreatyId: lstAvailableTreaty})
        .then(result => {
            console.log('result loadReinsurerFromQuote == ', result);
            this.lstRequestLoadFromQuote = result;
            if(this.lstRequestLoadFromQuote.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noRequestAvailable, variant: 'error' }),);
            }
            else{
                this.isLoadFromQuote = true;
                this.isLoadFromQuoteModalOpen = true;
                let lstUpdLoadReinsurerFromQuote = [];
                let lstOnlyBroker = [];
                let lstOnlyReinsurer = [];

                for(let i = 0; i < result.length; i++){
                    let newsObject = { 'recId' : result[i].Reinsurer__c
                                        ,'recName' : result[i].TECH_ReinsurerName__c
                                        , 'TECH_ReinsurerName__c' : result[i].TECH_ReinsurerName__c
                                        , 'TECH_TreatyName__c' : result[i].TECH_TreatyName__c
                                        , 'Reinsurer__c' : result[i].Reinsurer__c
                                        , 'Treaty__c' : result[i].Treaty__c
                                        , 'Checked' : false
                                        , 'TECH_BrokerName__c' : result[i].TECH_BrokerName__c
                                        , 'WrittenShare__c' : null
                                        , 'Broker__c' : result[i].Broker__c
                                        , 'BrokerReinsurer' : result[i].Broker__c + '-' + result[i].Reinsurer__c
                                        , 'TreatyBrokerReinsurer' : result[i].Treaty__c + '-' + result[i].Broker__c + '-' + result[i].Reinsurer__c
                    };
                    lstUpdLoadReinsurerFromQuote.push(newsObject);
                }
                console.log('result lstUpdLoadReinsurerFromQuote == ', lstUpdLoadReinsurerFromQuote);
                lstUpdLoadReinsurerFromQuote = this.getUniqueData(lstUpdLoadReinsurerFromQuote, 'TreatyBrokerReinsurer');
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
                //RRA - ticket 1099 - 09122022
                lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.TECH_BrokerName__c.localeCompare(b.TECH_BrokerName__c)) || (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
                
                //this.dataLoadFromQuote = lstUpdLoadReinsurerFromQuote;
                //RRA - ticket 1099 - 09122022
                this.dataLoadFromQuote = lstOnlyBroker.concat(lstOnlyReinsurer);
                let lstUpdateReinsurerFromQuote = this.getUniqueData(this.dataLoadFromQuote, 'BrokerReinsurer'); //RRA - ticket 1571 - 11102023
                console.log('lstUpdateReinsurerFromQuote == ', lstUpdateReinsurerFromQuote);
                this.dataLoadFromQuote = lstUpdateReinsurerFromQuote;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    handleLoadPopUp(event){
        let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedRows.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.noBrokerRein, variant: 'error' }),);
        }
        else if(this.isLoadFromQuote == false){
            //load from previous year
            let lstAvailableTreaty = [];

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                if(this.valueTreaty == 'All' || this.valueTreaty == this.treatyOptions[i].value){
                    lstAvailableTreaty.push(this.treatyOptions[i].value + '-' + this.treatyOptions[i].label);
                }
            }
            console.log('result  lstAvailableTreaty  other quote== ',  lstAvailableTreaty );
            let lstUpdLeader = [ ...this.lstLeader ];

            for(let i = 0; i < lstAvailableTreaty.length; i++){
                let treatyValue = lstAvailableTreaty[i].split('-')[0];
                let treatyLabel = lstAvailableTreaty[i].split('-')[1];
                for(let j = 0; j < selectedRows.length; j++){
                    let row = { ...selectedRows[j] };
                    row['Treaty__c'] = treatyValue;
                    row['TECH_TreatyName__c'] = treatyLabel;
                    row['TreatyBrokerReinsurer'] = treatyValue + '-' + row.Broker__c + '-' + row.Reinsurer__c;
                    lstUpdLeader.push(row);
                }
            }
            console.log('lstUpdLeader  other quote== ',  lstUpdLeader );
            this.lstLeader = this.getUniqueData(lstUpdLeader, 'TreatyBrokerReinsurer');
            this.titleCountFollower = 'Leader(s) (' + this.lstLeader.length + ')';
            let lstUpdSelectedLeaderBrokerReinsurer = [];

            for(let i = 0; i < this.lstLeader.length; i++){
                lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
            }
            console.log('lstUpdSelectedLeaderBrokerReinsurer  other quote== ',  lstUpdSelectedLeaderBrokerReinsurer );
            this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
            if(this.lstLeader.length == 0){
                this.disableLeaderSaveBtn = true;
            }
            else{
                this.disableLeaderSaveBtn = false;
            }
            this.handleCloseLoadFromQuoteModal();
    
        }
        else{
            //load from Quote
            //RRA - ticket 1571 - 20092023
            let lstAvailableTreaty = [];

            for(let i = 0; i < this.treatyOptions.length - 1; i++){
                if(this.valueTreaty == 'All' || this.valueTreaty == this.treatyOptions[i].value){
                    lstAvailableTreaty.push(this.treatyOptions[i].value + '-' + this.treatyOptions[i].label);
                }
            }
            let lstUpdLeader = [ ...this.lstLeader ];

            //RRA - ticket 1571 - 20092023
            for(let i = 0; i < lstAvailableTreaty.length; i++){
                let treatyValue = lstAvailableTreaty[i].split('-')[0];
                let treatyLabel = lstAvailableTreaty[i].split('-')[1];
                for(let j = 0; j < selectedRows.length; j++){
                    let row = { ...selectedRows[j] };
                    row['Treaty__c'] = treatyValue;
                    row['TECH_TreatyName__c'] = treatyLabel;
                    row['TreatyBrokerReinsurer'] = treatyValue + '-' + row.Broker__c + '-' + row.Reinsurer__c;
                    lstUpdLeader.push(row);
                }
            }
            
            /*for(let i = 0; i < selectedRows.length; i++){
                let row = { ...selectedRows[i] };
                lstUpdLeader.push(row);
            }*/
            console.log('result  lstUpdLeader  == ',  lstUpdLeader );
            this.lstLeader = this.getUniqueData(lstUpdLeader, 'TreatyBrokerReinsurer');
            console.log('result  this.lstLeader  == ',  this.lstLeader );
            this.titleCountFollower = 'Leader(s) (' + this.lstLeader.length + ')';
            let lstUpdSelectedLeaderBrokerReinsurer = [];

            for(let i = 0; i < this.lstLeader.length; i++){
                lstUpdSelectedLeaderBrokerReinsurer.push(this.lstLeader[i].Treaty__c + '-' + this.lstLeader[i].Broker__c + '-' + this.lstLeader[i].Reinsurer__c);
            }
            
            console.log('result lstUpdSelectedLeaderBrokerReinsurer == ', lstUpdSelectedLeaderBrokerReinsurer);

            this.lstSelectedLeaderBrokerReinsurer = lstUpdSelectedLeaderBrokerReinsurer;
            if(this.lstLeader.length == 0){
                this.disableLeaderSaveBtn = true;
            }
            else{
                this.disableLeaderSaveBtn = false;
            }
            this.handleCloseLoadFromQuoteModal();
        }
    }

    handleCloseLoadFromQuoteModal(){
        this.isLoadFromQuoteModalOpen = false;
    }
}