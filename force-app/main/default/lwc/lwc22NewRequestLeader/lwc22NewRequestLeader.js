import {LightningElement, track, wire, api} from 'lwc';
import {getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getReinsurer from '@salesforce/apex/LWC22_NewRequestLeader.getReinsurer';
import getAccountBroker from '@salesforce/apex/LWC22_NewRequestLeader.getAccountBroker';
import isBrokerReinPresent from '@salesforce/apex/LWC22_NewRequestLeader.isBrokerReinPresent';
import getAllLeadRequests from '@salesforce/apex/LWC22_NewRequestLeader.getAllLeadRequests';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC22_NewRequestLeader extends LightningElement {
    label = {
        errorMsg
    }

    @api objectName = 'Account';
    @api fieldName = 'Name';
    @api valueTreaty;
    @api treatyOptions;
    @api lstLeaderReinsurerOld;
    @api brokerId;
    @api phaseType;
    @api progId;
    @track selectedRecords = [];
    @track searchReinsurerLookupRecords = [];
    @track selectedRein = [];
    disableConfirmLeaderBtn = true;
    txtReinsurerLookUpclassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    searchText;
    loadingText = false;
    messageFlag = false;
    iconName = 'standard:account';
    disableConfirmReinsurerBtn = true;
    brokerOptions;
    wiredAccountBroker;
    setTreatyBrokerReinLeadReq = new Set();

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        this.getAllLeadRequests();
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

    searchReinsurerLookupField(event){
        let currentText = event.target.value;
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.loadingText = true;

        getReinsurer({ ObjectName: this.objectName, fieldName: this.fieldName, value: currentText, selectedRecId : selectRecId, treatyValue : this.valueTreaty, brokerValue : this.brokerId})
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
        let brokerName = this.getPicklistLabel(this.brokerOptions, this.brokerId);
        let reinsurerObj = {  'recId' : recId ,'recName' : selectName };
        this.selectedRein.push(reinsurerObj);

        if(this.phaseType == 'Placement'){
            if(this.valueTreaty == 'All'){
                for(let i = 0; i < this.treatyOptions.length - 1; i++){
                    treatyName = this.getPicklistLabel(this.treatyOptions, this.treatyOptions[i].value);

                    let newsObject = { 'recId' : recId ,'recName' : selectName
                                       , 'TECH_ReinsurerName__c' : selectName
                                       , 'TECH_TreatyName__c' : treatyName
                                       , 'Reinsurer__c' : recId
                                       , 'LeadType__c' : '1'
                                       , 'Treaty__c' : this.treatyOptions[i].value
                                       , 'Checked' : false
                                       , 'TECH_BrokerName__c' : brokerName
                                       , 'WrittenShare__c' : null
                                       , 'Broker__c' : this.brokerId
                                       , 'BrokerReinsurer' : this.brokerId + '-' + recId
                                       , 'TreatyBrokerReinsurer' : this.treatyOptions[i].value + '-' + this.brokerId + '-' + recId
                    };
                    this.selectedRecords.push(newsObject);
                }
            }
            else{
                treatyName = this.getPicklistLabel(this.treatyOptions, this.valueTreaty);

                let newsObject = { 'recId' : recId ,'recName' : selectName
                                   , 'TECH_ReinsurerName__c' : selectName
                                   , 'TECH_TreatyName__c' : treatyName
                                   , 'Reinsurer__c' : recId
                                   , 'LeadType__c' : '1'
                                   , 'Treaty__c' : this.valueTreaty
                                   , 'Checked' : false
                                   , 'TECH_BrokerName__c' : brokerName
                                   , 'WrittenShare__c' : null
                                   , 'Broker__c' : this.brokerId
                                   , 'BrokerReinsurer' : this.brokerId + '-' + recId
                                   , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + this.brokerId + '-' + recId
                };

                this.selectedRecords.push(newsObject);
            }
        }
        else{
            let newsObject = { 'recId' : recId ,'recName' : selectName
                               , 'TECH_ReinsurerName__c' : selectName
                               , 'TECH_TreatyName__c' : treatyName
                               , 'Reinsurer__c' : recId
                               , 'LeadType__c' : '1'
                               , 'Treaty__c' : this.valueTreaty
                               , 'Checked' : false
                               , 'TECH_BrokerName__c' : brokerName
                               , 'WrittenShare__c' : null
                               , 'Broker__c' : this.brokerId
                               , 'BrokerReinsurer' : this.brokerId + '-' + recId
                               , 'TreatyBrokerReinsurer' : this.valueTreaty + '-' + this.brokerId + '-' + recId
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

    handleConfirmReinsurerLeader(){
        if(this.lstLeaderReinsurerOld != undefined){
            for(let j = 0; j < this.lstLeaderReinsurerOld.length; j++){
                this.selectedRecords.push(this.lstLeaderReinsurerOld[j]);
            }
        }

        if(this.phaseType == 'Placement'){
            //filter from existing Placement Request
            this.lstLeaderReinsurerOld = this.getUniqueData(this.selectedRecords, 'TreatyBrokerReinsurer');
            let lstLeaderReinsurerUpd = [];

            //filter from existing Lead Request
            for(let i = 0; i < this.lstLeaderReinsurerOld.length; i++){
                if(!this.setTreatyBrokerReinLeadReq.has(this.lstLeaderReinsurerOld[i].TreatyBrokerReinsurer)){
                    lstLeaderReinsurerUpd.push(this.lstLeaderReinsurerOld[i]);
                }
            }

            this.lstLeaderReinsurerOld = lstLeaderReinsurerUpd;
        }
        else{
            this.lstLeaderReinsurerOld = this.getUniqueData(this.selectedRecords, 'BrokerReinsurer');
        }

        fireEvent(this.pageRef, 'updatedListReinsurer', this.lstLeaderReinsurerOld);

        this.selectedRecords = [];
        this.selectedRein = [];
        this.lstLeaderReinsurerOld = [];
        this.isNewReinsurerOpenModal = false;
        this.disableQuoteReqSaveBtn = false;
        this.handleCloseNewReinsurerLeaderModal();
    }

    handleCloseNewReinsurerLeaderModal(){
        fireEvent(this.pageRef, 'isNewReinsurerLeaderOpenModal', false);
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

    getAllLeadRequests(){
        getAllLeadRequests({ programId : this.progId})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                let lstLeadRequest = result;

                for(let i = 0; i < lstLeadRequest.length; i++){
                    let treatyBrokerRein = lstLeadRequest[i].Treaty__c + '-' + lstLeadRequest[i].Broker__c + '-' + lstLeadRequest[i].Reinsurer__c;
                    this.setTreatyBrokerReinLeadReq.add(treatyBrokerRein);
                }
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }
}