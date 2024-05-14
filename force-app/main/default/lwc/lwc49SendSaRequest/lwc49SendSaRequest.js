import {
    LightningElement,
    track,
    wire,
    api
} from 'lwc';
import {
    getPicklistValues,
    getPicklistValuesByRecordType
} from 'lightning/uiObjectInfoApi';
import {
    getObjectInfo
} from 'lightning/uiObjectInfoApi';
import {
    NavigationMixin,
    CurrentPageReference
} from 'lightning/navigation';
import {
    registerListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub';
import {
    loadStyle,
    loadScript
} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import getPoolAssignedTo from '@salesforce/apex/LWC18_SendUpdateRemind.getPoolAssignedTo';
import getContact from '@salesforce/apex/LWC18_SendUpdateRemind.getContact';
import getCovCedContact from '@salesforce/apex/LWC49_SendSARequest.getCovCedContact';
import getProgramDetails from '@salesforce/apex/LWC49_SendSARequest.getProgramDetails';
import sendUpdateSaRequest from '@salesforce/apex/LWC49_SendSARequest.sendUpdateSaRequest';
import getDocumentStatus from '@salesforce/apex/LWC49_SendSARequest.getDocumentStatus';
import informCedingCompany from '@salesforce/apex/LWC49_SendSARequest.informCedingCompany';
import getEmailTemplate from '@salesforce/apex/LWC49_SendSARequest.getEmailTemplate';
import checkActiveAccounts from '@salesforce/apex/LWC49_SendSARequest.checkActiveAccounts';//getInfoSA
import getInfoSA from '@salesforce/apex/LWC49_SendSARequest.getInfoSA';
import SPECIAL_ACCEPTANCE_OBJECT from '@salesforce/schema/SpecialAcceptance__c';
import PROPOSEDTOFAC_FIELD from '@salesforce/schema/SpecialAcceptance__c.ProposedToFac__c';

//import custom labels
import NoContactAvailable from '@salesforce/label/c.NoContactAvailable';
import NoCedingContactAvailable from '@salesforce/label/c.NoCedingContactAvailable';
import SASentSuccessfully from '@salesforce/label/c.SASentSuccessfully';
import SARUpdatedSuccessfully from '@salesforce/label/c.SARUpdatedSuccessfully';
import RemindEmailSendSuccessfully from '@salesforce/label/c.RemindEmailSendSuccessfully';
import SARNotifiedSuccessfully from '@salesforce/label/c.SARNotifiedSuccessfully';
import CedingCompanyInformedSuccessfully from '@salesforce/label/c.CedingCompanyInformedSuccessfully';
import errorMsg from '@salesforce/label/c.errorMsg';
import noContactSelected from '@salesforce/label/c.NoContactSelected';


const columnsSARequest = [{
        label: 'Broker',
        fieldName: 'TECH_BrokerName__c'
    },
    {
        label: 'Reinsurer',
        fieldName: 'TECH_ReinsurerName__c'
    },
    {
        label: 'Broker Status',
        fieldName: 'TECH_BrokerStatus__c'
    }
];

const columnsContact = [{
        label: 'Broker / Reinsurer',
        fieldName: 'AccountName'
    },
    {
        label: 'Last Name',
        fieldName: 'ContactLastName'
    },
    {
        label: 'First Name',
        fieldName: 'ContactFirstName'
    },
    {
        label: 'Email address',
        fieldName: 'ContactEmail'
    }
];

const columnsCovCedContact = [{
        label: 'Last Name',
        fieldName: 'ContactLastName'
    },
    {
        label: 'First Name',
        fieldName: 'ContactFirstName'
    },
    {
        label: 'Email address',
        fieldName: 'ContactEmail'
    }
];

// const columnsCovCedContact = [
//     { label: 'Covered Ceding Company', fieldName: 'AccountName' },
//     { label: 'Last Name', fieldName: 'ContactLastName' },
//     { label: 'First Name', fieldName: 'ContactFirstName' },
//     { label: 'Email address', fieldName: 'ContactEmail'}
// ];

export default class Lwc49SendSaRequest extends NavigationMixin(LightningElement) {
    label = {
        NoContactAvailable,
        NoCedingContactAvailable,
        SASentSuccessfully,
        SARUpdatedSuccessfully,
        RemindEmailSendSuccessfully,
        SARNotifiedSuccessfully,
        CedingCompanyInformedSuccessfully,
        errorMsg,
        noContactSelected
    }

    @api programVal;
    @api uwYearVal;
    @api principalCedCompVal;
    @api programNameVal;
    @api saRequest = [];
    @api brokerReinId = [];
    @api lstPublicDocument = [];
    @api programMacroLob;
    @api programNature;
    @api btnAction;
    @api agreedRequest = false;
    @api isSubmission = false ; // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template
    @api refusedRequest = false;
    @api selectedSa;
    @track lstSaApplyToRequest = [];
    @track dataContact = [];
    @track dataCovCedContact = [];
    @track lstPoolsData = [];
    @track lstAssignedUsers = [];
    @track proposedToFacOption = [];
    @track preSelectedContact = []; // MRA W-1230 10/08/2022
    @api contactsOcSelected = [];// MRA W-1230 10/08/2022

    columnsSARequest = columnsSARequest;
    columnsContact = columnsContact;
    columnsCovCedContact = columnsCovCedContact;
    btnNameLabel;
    isContactNull = true;
    poolTitle = 'Pool (0)';
    titleCountDocument = 'Document (0)';
    commentValue = null;
    expectedAnsDateValue = null;
    isRemindNotifyBtn = false;
    isRemindBtn = false;
    isNotifyBtn = false;
    isNotifyInformCedCom = false;
    isInformCedComBtn = false;
    spinnerRequest = false;
    brokerEmailTemplateValue;
    reinsurerEmailTemplateValue;
    poolEmailTemplateValue;
    sendUpdRemindBtn = false;
    wiredContact;
    wiredprograms;
    wiredActive;

    //AMI 16/05/22: W-1101
    //Datatable row checkbox to allow contact selection
    defaultContactSelection = [];
    finalConListToProcess = [];

    @wire(getObjectInfo, {
        objectApiName: SPECIAL_ACCEPTANCE_OBJECT
    })
    objectInfo;

    connectedCallback() {
        this.generatePoolsData();
        this.brokerReinId = [];
        let lstApplyToReq = [];
        let maxExpectedAnswerDate = this.saRequest[0].ExpectedResponseDate__c;
        let idSA = this.saRequest[0].Special_Acceptance__c;
        let sameExpectedAnswerDate = true;
        this.selectedSa = {
            ...this.selectedSa
        };

        //RRA - ticket 1447 - 14032023
        if (this.selectedSa.Type__c == '2' && this.selectedSa.Bound__c == '1'){ //Type = Submission and Bound = yes
            this.isSubmission = false;
        }else if (this.selectedSa.Type__c == '1' ){ // RRA - ticket 1229 - 15032023
            this.isSubmission = false;
        }else{
            this.isSubmission = true;
        }

        console.log('Type == ', this.selectedSa.Type__c);
        console.log('Bound == ', this.selectedSa.Bound__c);
        console.log('isSubmission == ', this.isSubmission);
        
        if (this.agreedRequest == true) {
            if (this.selectedSa.BindRemainingDays__c == '' || this.selectedSa.BindRemainingDays__c == null || this.selectedSa.BindRemainingDays__c == undefined) {
                this.selectedSa['BindRemainingDays__c'] = 60;
            }

            let todayDate = new Date(); //Current date.
            let bindExpAnsDateVal = this.addDays(todayDate, parseInt(this.selectedSa.BindRemainingDays__c));
            let date = bindExpAnsDateVal.getDate();
            let month = bindExpAnsDateVal.getMonth() + 1;
            let year = bindExpAnsDateVal.getFullYear();
            this.selectedSa['BindExpectedAnswerDate__c'] = year + '-' + month + '-' + date;
            this.selectedSa['ProposedToFac__c'] = 'No';
        }

        if (this.btnAction == 'send') {
            this.btnNameLabel = 'Send';
            this.sendUpdRemindBtn = true;
        } else if (this.btnAction == 'update') {
            this.btnNameLabel = 'Update';
            this.sendUpdRemindBtn = true;
        } else if (this.btnAction == 'remind') {
            this.btnNameLabel = 'Remind';
            this.isRemindNotifyBtn = true;
            this.isRemindBtn = true;
            this.sendUpdRemindBtn = true;
        } else if (this.btnAction == 'notify') {
            this.btnNameLabel = 'Notify';
            this.isNotifyBtn = true;
            this.isRemindNotifyBtn = true;
            this.isNotifyInformCedCom = true;
        } else if (this.btnAction == 'informCedingCompany') {
            this.btnNameLabel = 'Send';
            this.isInformCedComBtn = true;
            this.isNotifyInformCedCom = true;
        }

        for (let i = 0; i < this.saRequest.length; i++) {
            let req = {
                ...this.saRequest[i]
            };
            if (req.Pool__c == null || req.Pool__c == undefined) {
                if (req.BrokerStatus__c == '1') {
                    req['TECH_BrokerStatus__c'] = 'Sleeping Partner';
                } else if (req.BrokerStatus__c == '2') {
                    req['TECH_BrokerStatus__c'] = 'Financial Intermediary';
                }
                lstApplyToReq.push(req);
            }

            //SA Req with Broker - if broker status = 'Sleeping Partner' -> sent to Reinsurer contact else sent to Broker contact
            //SA Req with no Broker - sent to Reinsurer contact

            if (req.Broker__c != null) {
                if (req.BrokerStatus__c == '1') {
                    this.brokerReinId.push(req.Reinsurer__c);
                } else {
                    this.brokerReinId.push(req.Broker__c);
                }
            } else {
                this.brokerReinId.push(this.saRequest[i].Reinsurer__c);
            }

            if (this.btnAction == 'update') {
                if (this.saRequest[i].ExpectedResponseDate__c != maxExpectedAnswerDate) {
                    sameExpectedAnswerDate = false;
                }
            }
        }

        if (this.btnAction == 'update') {
            if (this.saRequest.length == 1) {
                //if only one row request is selected -> display Expected Answer Date of that row for update
                this.expectedAnsDateValue = maxExpectedAnswerDate;
            } else if (this.saRequest.length > 1 && sameExpectedAnswerDate == true) {
                //if more than one row request are selected with same Expected Answer Date -> display Expected Answer Date for update
                this.expectedAnsDateValue = maxExpectedAnswerDate;
            } else {
                //if more than one row request are selected with different Expected Answer Date -> Expected Answer Date should be null for update and allow user to add a value
                this.expectedAnsDateValue = null;
            }
        }

        this.lstSaApplyToRequest = lstApplyToReq;
        this.titleCountDocument = 'Documents (' + this.lstPublicDocument.length + ')';
        this.getDocumentStatus();

        if (this.isInformCedComBtn == true) {
            this.getCovCedContact();
        }

        //this.isSubmission=this.selectedSa.Type__c == ''?true:false ; // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template //RRA - ticket 1447 - 15032023

        this.getEmailTemplate();
    }

    addDays(date, days) {
        let result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: PROPOSEDTOFAC_FIELD
    })
    setProposedToFacPicklistOpt({
        error,
        data
    }) {
        if (data) {
            this.proposedToFacOption = data.values;
        } else {
            this.error = error;
        }
    }

    generatePoolsData() {
        let lstUpdSaRequest = [];
        let lstPoolNames = [];

        for (let i = 0; i < this.saRequest.length; i++) {
            let rowSa = {
                ...this.saRequest[i]
            };

            if (rowSa['Pool__r']) {
                let pool = JSON.parse(JSON.stringify(rowSa['Pool__r']));

                if (lstPoolNames.indexOf(pool['Name']) == -1) {
                    lstPoolNames.push(pool['Name']);
                    this.lstPoolsData.push(pool);
                }
            }

            lstUpdSaRequest.push(rowSa);
        }

        this.saRequest = lstUpdSaRequest;
        this.poolTitle = 'Pools (' + this.lstPoolsData.length + ')';
    }

    getDocumentStatus() {
        getDocumentStatus({
                lstSaRequests: this.saRequest,
                lstDocument: this.lstPublicDocument
            })
            .then(result => {
                if (result) {
                    let mapContentVersionStatus = result.mapContentVersionStatus;
                    let lstUpdPublicDocument = [];

                    for (let i = 0; i < this.lstPublicDocument.length; i++) {
                        let row = {
                            ...this.lstPublicDocument[i]
                        };
                        let status = mapContentVersionStatus[row.Id];
                        row['Status__c'] = status;
                        lstUpdPublicDocument.push(row);
                    }

                    this.lstPublicDocument = lstUpdPublicDocument;
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    @wire(getProgramDetails, {
        programId: '$programVal'
    })
    wiredGetPrograms(result) {
        this.wiredprograms = result;
        if (result.data) {
            this.programMacroLob = result.data.lstProgram[0].Macro_L_O_B__c;
            this.programNature = result.data.lstProgram[0].Nature__c;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(checkActiveAccounts, {
        lstAccountId: '$brokerReinId'
    })
    wiredCheckAccounts(result) {
        this.wiredActive = result;
        if (result.data == false) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Info',
                message: 'At least one Broker/Reinsurer selected is inactive',
                variant: 'info'
            }), );
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getContact, {
        lstAccountId: '$brokerReinId',
        macroLOBFromProgram: '$programMacroLob',
        natureFromProgram: '$programNature',
        prinCedComFromProgram: '$principalCedCompVal'
    })
    wiredGetContact(result) {
        this.wiredContact = result;

        if (result.data) {
            if (this.isInformCedComBtn == false) {
                this.dataContact = result.data;
                let lstUpdDataContact = [];

                //AMI 16/05/22: W-1101
                //preset all returned contacts on table
                if (this.dataContact) {
                    this.defaultContactSelection = this.dataContact.map(contactVal => {
                        return contactVal.Id;
                    });
                }

                for (let i = 0; i < this.dataContact.length; i++) {
                    let row = {
                        ...this.dataContact[i]
                    };
                    if (row.Contact != undefined) {
                        if (row.Contact.Email != undefined && row.Contact.Email != null) {
                            //AMI 16/05/22: W-1101
                            //adding contact id attribute to control user selection from datatable
                            row['Id'] = this.dataContact[i].Id
                            row['AccountName'] = row.Account.Name;
                            row['ContactLastName'] = row.Contact.LastName;
                            row['ContactFirstName'] = row.Contact.FirstName;
                            row['ContactEmail'] = row.Contact.Email;
                            lstUpdDataContact.push(row);
                        }
                    }
                }

                this.dataContact = lstUpdDataContact;
                let containPoolReq = false;

                if (this.dataContact.length == 0) {

                    for (let i = 0; i < this.saRequest.length; i++) {
                        if (this.saRequest[i].Pool__c != null && this.saRequest[i].Pool__c != undefined) {
                            containPoolReq = true;
                        }
                    }

                    if (containPoolReq == false) {
                        this.isContactNull = true;
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: this.label.NoContactAvailable,
                            variant: 'error'
                        }), );
                    } else {
                        this.isContactNull = false;
                    }
                } else {
                    this.isContactNull = false;
                }
            }
        } else if (result.error) {
            this.error = result.error;
        }
    }

    // MRA W-1230 10/08/2022 : START 
    getContactSelected(event){
        let currentRowsChecked = event.detail.selectedRows;     
        if (currentRowsChecked != null || currentRowsChecked != undefined){
            this.contactSelected = currentRowsChecked;
        }else {
            this.contactSelected = null;
        }
    }
    // MRA W-1230 10/08/2022 : END
    getCovCedContact() {
        let saObj = {
            ...this.selectedSa
        };
        saObj['BindExpectedAnswerDate__c'] = null;

        getCovCedContact({
                specialAcceptanceObj: saObj
            })
            .then(result => {
                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else {
                    this.dataCovCedContact = result.lstAccountContactRelationsToDisplay;
                    let lstUpdDataCovCedContact = [];
                    let lstIdDataContact = []; // MRA W-1230 10/08/2022

                    for (let i = 0; i < this.dataCovCedContact.length; i++) {
                        let row = {
                            ...this.dataCovCedContact[i]
                        };
                        if (row.Contact != undefined) {
                            if (row.Contact.Email != undefined && row.Contact.Email != null) {
                                row['AccountName'] = row.Account.Name;
                                row['ContactLastName'] = row.Contact.LastName;
                                row['ContactFirstName'] = row.Contact.FirstName;
                                row['ContactEmail'] = row.Contact.Email;
                                lstUpdDataCovCedContact.push(row);
                            }
                        }
                        lstIdDataContact.push(row.Id) ; // MRA W-1230 10/08/2022
                    }
                    this.preSelectedContact = lstIdDataContact ; // MRA W-1230 10/08/2022
                    this.contactSelected = lstUpdDataCovCedContact; // MRA W-1230 10/08/2022
                    this.dataCovCedContact = lstUpdDataCovCedContact;

                    if (this.dataCovCedContact.length == 0) {
                        this.isContactNull = true;
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: this.label.NoCedingContactAvailable,
                            variant: 'error'
                        }), );
                    } else {
                        this.isContactNull = false;
                    }
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    getEmailTemplate() {
        let reqId = this.saRequest[0].Id;
        getEmailTemplate({
                buttonName: this.btnAction,
                saReqId: reqId,
                lstDocument: this.lstPublicDocument
            })
            .then(result => {
                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else {
                    console.log('result getEmailTemplate == ', result)
                    console.log('this.selectedSa.Type__c == ', this.selectedSa.Type__c);
                    console.log('this.btnAction == ', this.btnAction);
                    console.log('this.selectedSa.Bound__c == ', this.selectedSa.Bound__c);
                    //RRA - ticket 1447 - 17032023
                    if (this.selectedSa.Type__c == '1'){
                        if (this.selectedSa.Bound__c == '1' || this.selectedSa.Bound__c == '2'){
                            this.brokerEmailTemplateValue = result.brokerEmailTemplateYes;
                        }else if (this.selectedSa.Bound__c == 'Pending' && this.btnAction == 'informCedingCompany'){
                            this.brokerEmailTemplateValue = result.brokerEmailTemplatePending;
                        }
                    }else if (this.selectedSa.Type__c == '2'){
                        if (this.selectedSa.Bound__c == '1' || this.selectedSa.Bound__c == '2'){
                            this.brokerEmailTemplateValue = result.brokerEmailTemplateYes;
                        }else if (this.selectedSa.Bound__c == 'Pending' && this.btnAction == 'informCedingCompany'){
                            this.brokerEmailTemplateValue = result.brokerEmailTemplatePending;
                        }else if (this.selectedSa.Bound__c == 'Pending' && this.btnAction == 'send'){
                            this.brokerEmailTemplateValue = result.brokerEmailTemplate;
                        }else if (this.selectedSa.Bound__c == 'Pending' && this.btnAction == 'update'){//RRA - ticket 1509 - 17052023
                            this.brokerEmailTemplateValue = result.brokerEmailTemplate;
                        }
                    }
                    //RRA - ticket 1488 - 21042023 - Displaying template broker send Email
                    if (this.btnAction == 'notify'){
                        this.brokerEmailTemplateValue = result.brokerEmailTemplate;
                    }
                    //this.brokerEmailTemplateValue = result.brokerEmailTemplate;
                    console.log('brokerEmailTemplateValue 11== ', this.brokerEmailTemplateValue)
                    this.reinsurerEmailTemplateValue = result.reinsurerEmailTemplate;
                    this.poolEmailTemplateValue = result.poolEmailTemplate;
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    handleOnChangeExpectedAnsDate(event) {
        this.expectedAnsDateValue = event.currentTarget.value;
    }

    handleOnChangeComment(event) {
        this.commentValue = event.currentTarget.value;
    }

    handleOnChangeEmail(event) {}

    handleCloseSendUpdateSaReqModal(event) {
        fireEvent(this.pageRef, 'closeSendSaReqModal', false);
    }

    handleSendUpdateSaRequest(event) {
        this.spinnerRequest = true;
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            if (this.isInformCedComBtn == true) {
                this.informCedingCompany();
            } else if (this.isInformCedComBtn == false) {
                this.sendUpdateSaRequest();
            }
        } else {
            this.spinnerRequest = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please complete required fields, update the invalid form entries and try again.',
                variant: 'error'
            }), );
        }
    }

    sendUpdateSaRequest() {
        let updSaRequest = [];
        let lstPoolIdToEmailStr = [];

        for (let i = 0; i < this.saRequest.length; i++) {
            let row = {
                ...this.saRequest[i]
            };

            if (this.expectedAnsDateValue != null && this.expectedAnsDateValue != '' && this.expectedAnsDateValue != undefined) {
                row.ExpectedResponseDate__c = this.expectedAnsDateValue;
            }

            row.Comments__c = this.commentValue;
            updSaRequest.push(row);
        }

        this.saRequest = updSaRequest;

        for (let i = 0; i < this.lstPoolsData.length; i++) {
            let poolToEmail = this.lstPoolsData[i]['Id'] + '|' + this.lstPoolsData[i]['SA_Email__c'];
            lstPoolIdToEmailStr.push(poolToEmail);
        }

        //AMI 16/05/22: W-1101
        //get all selected contacts to send for processing
        let selectedContactRecords = this.template.querySelector('lightning-datatable[data-id="contactselectionform"]').getSelectedRows();

        //apply filter if selection is made
        if (typeof selectedContactRecords !== undefined && selectedContactRecords.length > 0) {
            this.finalConListToProcess = this.filterOutSelectedContacts(this.dataContact, selectedContactRecords);
        } else {
            //raise error
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: this.label.noContactSelected,
                variant: 'error'
            }), );
            this.spinnerRequest = false;
        }

        console.log('finalConListToProcess == ', this.finalConListToProcess);
        console.log('saRequest == ', this.saRequest);
        sendUpdateSaRequest({
                lstSaRequests: this.saRequest,
                lstAccountContact: this.finalConListToProcess,
                lstPoolIdToEmail: lstPoolIdToEmailStr,
                lstDocument: this.lstPublicDocument,
                buttonAction: this.btnAction
            })
            .then(result => {
                this.spinnerRequest = false;
                fireEvent(this.pageRef, 'closeSendSaReqModal', false);

                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else if (this.btnAction == 'send') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.SASentSuccessfully,
                        variant: 'success'
                    }), );
                } else if (this.btnAction == 'update') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.SARUpdatedSuccessfully,
                        variant: 'success'
                    }), );
                } else if (this.btnAction == 'remind') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.RemindEmailSendSuccessfully,
                        variant: 'success'
                    }), );
                } else if (this.btnAction == 'notify') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.SARNotifiedSuccessfully,
                        variant: 'success'
                    }), );
                }
            })
            .catch(error => {
                this.spinnerRequest = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    informCedingCompany() {
        console.log('lstAccConForSharingSA == ', this.dataCovCedContact);
        let reqId = this.saRequest[0].Id;
        let saObj = {
            ...this.selectedSa
        };
        saObj['BindExpectedAnswerDate__c'] = null;

        if (this.agreedRequest == true) {
            saObj['InternalStatus__c'] = 'Agreed';
        } else if (this.refusedRequest == true) {
            saObj['InternalStatus__c'] = 'Refused';

            if (saObj.Type__c == '2') {
                saObj['Bound__c'] = '2'; //Submission -> Bound = No
            }
        }

        if (saObj.Type__c == '1') {
            saObj['Bound__c'] = '1'; //Declaration -> Bound = Yes
        }

        saObj['Comments__c'] = this.commentValue;
       
        informCedingCompany({
                specialAcceptanceObj: saObj,
                lstAccountContact: this.contactSelected, // MRA W-1230 10/08/2022
                lstAccConForSharingSA : this.dataCovCedContact, // RRA - ticket 1445 - 27032023
                requestId: reqId
            })
            .then(result => {
                this.spinnerRequest = false;
                fireEvent(this.pageRef, 'closeSendSaReqModal', false);
                if (result.hasOwnProperty('Error') && result.Error) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }), );
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.CedingCompanyInformedSuccessfully,
                        variant: 'success'
                    }), );
                }
            })
            .catch(error => {
                this.spinnerRequest = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }), );
            });
    }

    handleOnChangeValue(event) {
        let nameField = event.currentTarget.name;
        let valueField = event.currentTarget.value;
        let typeField = event.currentTarget.type;
        let saObj = {
            ...this.selectedSa
        };

        if (typeField == 'number') {
            saObj[nameField] = parseInt(valueField);
        } else {
            saObj[nameField] = valueField;
        }

        if (nameField == 'BindRemainingDays__c') {
            if (valueField == null || valueField == '') {
                saObj['BindRemainingDays__c'] = 0;
            }

            let todayDate = new Date(); //Current date.
            let bindExpAnsDateVal = this.addDays(todayDate, parseInt(saObj.BindRemainingDays__c));
            let date = bindExpAnsDateVal.getDate();
            let month = bindExpAnsDateVal.getMonth() + 1;
            let year = bindExpAnsDateVal.getFullYear();
            saObj['BindExpectedAnswerDate__c'] = year + '-' + month + '-' + date;
        }

        this.selectedSa = saObj;
    }

    handleOnChangeBroker(event) {
        this.brokerEmailTemplateValue = event.currentTarget.value;
    }

    //AMI 16/05/22: W-1101
    //filter original returned contacts from user selection
    filterOutSelectedContacts(originalList, selectedlist) {
        let finalLstConToProcess = [];

        //loop in selected list
        selectedlist.forEach(ele => {
            //filter original list
            let tempResult = originalList.filter(obj => {
                return ele.Id === obj.Id;
            })

            //add to final list
            if (typeof tempResult !== undefined && tempResult.length > 0) {
                finalLstConToProcess.push(tempResult[0]);
            }
        });

        return finalLstConToProcess;
    }
}