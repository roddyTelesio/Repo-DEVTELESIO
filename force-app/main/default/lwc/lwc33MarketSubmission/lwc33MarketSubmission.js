import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import getRequestDetails from '@salesforce/apex/LWC33_MarketSubmission.getRequestDetails';
import getRequestLists from '@salesforce/apex/LWC33_MarketSubmission.getRequestLists';
import connectedUserId from '@salesforce/user/Id';
import saveRequests from '@salesforce/apex/LWC33_MarketSubmission.saveRequests';
import saveSignatories from '@salesforce/apex/LWC33_MarketSubmission.saveSignatories';//MRA 19/05/23 - Contact Signatory Rebuild
import getLookupAccountField from '@salesforce/apex/LWC33_MarketSubmission.getLookupAccountField'; 
import sendMail from '@salesforce/apex/LWC33_MarketSubmission.sendMail'; 
import getSignatories from '@salesforce/apex/LWC33_MarketSubmission.getSignatories';

import BROKER_STATUS_FIELD from '@salesforce/schema/Request__c.BrokerStatus__c';
import LOSS_DEPOSIT_MODE_FIELD from '@salesforce/schema/Request__c.LossDepositMode__c';
import PREMIUM_DEPOSIT_FIELD from '@salesforce/schema/Request__c.PremiumDeposit__c';
import TYPE_OF_CODE_FIELD from '@salesforce/schema/Request__c.Type_of_Code__c';
import PREMIUM_DEPOSIT_MODE_FIELD from '@salesforce/schema/Request__c.PremiumDepositMode__c';
import DESC_REINS_LIMIT_COLL_FIELD from '@salesforce/schema/Request__c.DescriptionReinsurerLimitColl__c';
import SALUTATION_FIELD from '@salesforce/schema/Contact.Salutation';

//import custom labels
import WorkingScope from '@salesforce/label/c.Working_Scope';
import UWYear from '@salesforce/label/c.UWYear';
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import Delete from '@salesforce/label/c.Delete';
import Modify from '@salesforce/label/c.Modify';
import Missing_Order from '@salesforce/label/c.Missing_Order' ;
import ChooseOneUpdate from '@salesforce/label/c.ChooseOneUpdate' ;
import updateContact from '@salesforce/label/c.updateContact' ;
import New from '@salesforce/label/c.New';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import Required_Fields from '@salesforce/label/c.Required_Fields';
import EmailAddressAlreadyExists from '@salesforce/label/c.EmailAddressAlreadyExists';
import EnterValidEmail from '@salesforce/label/c.EnterValidEmail';
import RequestsSavedSuccessfully from '@salesforce/label/c.RequestsSavedSuccessfully';
import SigningSavedSuccessfully from '@salesforce/label/c.SigningSavedSuccessfully';
import MissingRequiredFieldMarketSubmission from '@salesforce/label/c.MissingRequiredFieldMarketSubmission';
import PCCInactive from '@salesforce/label/c.PCCInactive';
import BRInactive from '@salesforce/label/c.BRInactive';
import errorMsg from '@salesforce/label/c.errorMsg';

//MRA 19/05/23 - Contact Signatory Rebuild
const columnSignatories = [
    { label: 'Order of signatories', fieldName: 'OrderOfSignatory__c'},
    { label: 'Civility', fieldName: 'ContactSalutation'},
    { label: 'Last Name', fieldName: 'ContactLastName'},
    { label: 'First Name', fieldName: 'ContactFirstName'},
    { label: 'E-mail address', fieldName: 'ContactEmail', type : 'email'},
    { label: 'Mobile number', fieldName: 'ContactMobilePhone', type : 'phone'}
];


const columnClaimContacts = [
    { label: 'E-mail address', fieldName: 'Email'}
];
 
export default class LWC33_MarketSubmission extends LightningElement {
    label = {
        WorkingScope,
        UWYear,
        PrincipalCedingCompany,
        Missing_Order,
        ChooseOneUpdate,
        updateContact,
        FormEntriesInvalid,
        Required_Fields,
        EmailAddressAlreadyExists,
        EnterValidEmail,
        RequestsSavedSuccessfully,
        SigningSavedSuccessfully,
        MissingRequiredFieldMarketSubmission,
        PCCInactive,
        BRInactive,
        errorMsg
    };

    @api programId;
    @api selectedRequestId;
    @api reinsurerId = '';
    @api brokerId = '';
    @track cedingAccOpt = [];
    @track uwYearOpt = [];
    @track programOptions = [];
    @track brokerStatusOpt = [];
    @track riskCarierOpt = [];
    @track financialEntityOpt = [];
    @track lstRelatedSigningRequests = [];
    @track lossDepositModeOpt = [];
    @track premiumDepositOpt = [];
    @track typeOfCodeOpt = [];
    @track selectedRequest = [];
    @track claimContactData = [];
    @track premiumDeptModeOpt = [];
    @track descCollOpt = [];
    @track signatoriesData = [];
    cedCompany;
    uwYear;
    programName;   
    reinsurerStatusValue;
    brokerStatusValue; 
    riskCarierValue;
    financialEntityValue; 
    brokerName;
    reinsurerName;
    selectedReinsurerId;
    selectedBrokerId// SRA - 1046 - Bug Signing Emma when click on button Open
    columnSignatories = columnSignatories;
    columnClaimContacts = columnClaimContacts;
    access = false;
    selectedRelatedReqId;
    selectedTreatyid;
    openTreatyDetailsModal = false;
    openAddClaimContacts = false;
    openReOrderSignatories = false ;//MRA 19/05/23 - Contact Signatory Rebuild
    countEmail = 0;
    collateralProviderName;
    collateralProviderCity;
    collateralProviderCode;
    txtRiskCarrierLookupClassName;
    txtFinancialEntityLookupClassName;
    error;  
    disablePremiumDeptMode = false;
    titleClaimContacts = 'Claims Contacts';
    invalidEmail = false;
    portalAccess = false;
    agreeCheckboxLabel;
    openAddSignatories = false;
    goReorder = false ;//MRA 19/05/23 - Contact Signatory Rebuild
    countContact = 0;
    get titleSignatories() {//MRA 19/05/23 - Contact Signatory Rebuild
        if(this.signatoriesData.length > 0){
            return ' Signatories (' + this.signatoriesData.length.toString() + ') ';
        }
        return ' Signatories ';
        
      }

    isDocumentModalOpen = false;
    isStatusSigned = false;
    isStatusTimeout = false;
    disableSignedShare = true;
    isRequiredField = false;
    disableBroker = false;
    displaySpinner = false;
    activeAcc = true;
    isUpdate = false ; //MRA 1103 07/07/2022
    singleContactToUpdate ; //MRA 1103 07/07/2022
    autoOrderValue = 0 ;
    disableBtnSave; //RRA - ticket 585 - 07032023
    
    //MRA 19/05/23 - Contact Signatory Rebuild - START
    get inputVariables() {
        return [
        {
            name: 'AccountID',
            type: 'String',
            value: this.selectedReinsurerId
        },
        {
            name: 'programId',
            type: 'String',
            value: this.programId
        },
        {
            name:'signatories',
            type : 'SObject', 
            value : this.signatoriesData
        },
        {
            name:'goReorder',
            type : 'Boolean', 
            value : this.goReorder
        }
        ];
    }
    get inputVariablesUpdateContact() {
        return [
            {
                name: 'contactToUpdateId',
                type: 'String',
                value: this.singleContactToUpdate
            }
        ]
    }
    //MRA 19/05/23 - Contact Signatory Rebuild - END

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectContactInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSS_DEPOSIT_MODE_FIELD})
    setLossDepositModePicklistOptions({error, data}) {
        if(data){
            this.lossDepositModeOpt = data.values;
            this.getRequestDetails();
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PREMIUM_DEPOSIT_FIELD})
    setPremiumDepositPicklistOptions({error, data}) {
        if(data){
            this.premiumDepositOpt = data.values;
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    connectedCallback(){
        let nameUrl = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(nameUrl != null && nameUrl.includes('portal')){
            //portal/s
            this.portalAccess = true;
        }

        if(this.portalAccess == true){
            this.isRequiredField = true;
        }
        else{
            this.isRequiredField = false;
        }

        let label = 'By submitting this form, I acknowledge that I have read and agreed to the pricing,'
        label += 'terms and conditions on the present form, including the reinsurance agreement (general conditions and special conditions)'
        label += 'and I acknowledge the legal binding effect of this signing with reference to paragraph 3 of the terms of use of ACTOR New Gen'
        this.agreeCheckboxLabel = label;
        this.access = true;
        registerListener('closeTreatyDetailsModal', this.handleCloseTreatyDetailsModal, this);
        registerListener('closeDocumentModal', this.closeDocumentModal, this);
        this.getRequestDetails();
    }

    closeDocumentModal(val){
        this.isDocumentModalOpen = false;
    }

    getRequestDetails(){
        getRequestDetails({requestId: this.selectedRequestId})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                this.selectedRequest = result;
                let request = result;
                if(result['Id'] != undefined || result['Id'] != null){
                    if(this.portalAccess == false){
                        if(result.Program__r.PrincipalCedingCompany__r.IsActive__c == false){
                            this.dispatchEvent(new ShowToastEvent({title: 'Info', message: this.label.PCCInactive, variant: 'info'}),);
                            this.activeAcc = false;
                        }
                        else{
                            if(result.Broker__r != undefined && result.Broker__r != null && result.Reinsurer__r != undefined && result.Reinsurer__r != null){
                                if(result.Broker__r.IsActive__c == false || result.Reinsurer__r.IsActive__c == false){
                                    this.dispatchEvent(new ShowToastEvent({title: 'Info', message: this.label.BRInactive, variant: 'info'}),);
                                    this.activeAcc = false;
                                }
                            }
                            else if(result.Reinsurer__r != undefined && result.Reinsurer__r != null){
                                if(result.Reinsurer__r.IsActive__c == false){
                                    this.dispatchEvent(new ShowToastEvent({title: 'Info', message: this.label.BRInactive, variant: 'info'}),);
                                    this.activeAcc = false;
                                }
                            }
                        }
                    }

                    this.reinsurerStatusValue = request['ReinsurerStatus__c'];
                    if(request['ReinsurerStatus__c'] == 'Setup' && this.portalAccess == false){
                        this.disableSignedShare = false;
                    }
                    if(request['ReinsurerStatus__c'] == 'Signed' && this.portalAccess == true){
                        this.isStatusSigned = true;
                    }
                    if(request['ReinsurerStatus__c'] == 'Timeout' && this.portalAccess == true){
                        this.isStatusTimeout = true;
                        this.isStatusSigned = true;
                        this.disableBroker = true;
                    }
                    this.programName = request['Program__r']['Name'];
                    this.uwYear = request['Program__r']['UwYear__c'];
                    this.cedCompany = request['Program__r']['PrincipalCedingCompany__r']['Name'];
                    if( request['Broker__c'] != undefined){
                        this.brokerName = request['Broker__r']['Name'];
                        this.selectedBrokerId = request['Broker__c']; // SRA - 1046 - Bug Signing Emma when click on button Open
                    }
                    else{
                        this.disableBroker = true;
                    }
                    if(request['Reinsurer__c'] != undefined){
                        this.reinsurerName = request['Reinsurer__r']['Name'];
                        this.selectedReinsurerId = request['Reinsurer__c'];
                    }
                    
                    if(request['Claims_contact__c'] != null || request['Claims_contact__c'] != undefined){
                        let lstClaimContacts = request['Claims_contact__c'].split(';')
                        let lstContactData = [];
                        for(let i = 0; i <  lstClaimContacts.length; i ++){
                            let obj = {};
                            obj['Email'] = lstClaimContacts[i];
                            this.countEmail = this.countEmail + 1;
                            obj['id'] = this.countEmail.toString();
                            lstContactData.push(obj);
                        }
                        this.claimContactData = lstContactData;
                        if(lstContactData.length > 0){
                            this.titleClaimContacts ='Claims Contacts (' + lstContactData.length.toString() + ')';
                        }
                    }
                    let opt = {};
                    if(request['BrokerStatus__c'] != undefined || request['BrokerStatus__c'] != null){
                        this.brokerStatusValue = request['BrokerStatus__c'];
                    }
                    if(request['RiskCarrier__c']!= undefined || request['RiskCarrier__c'] != null){
                        this.selectedRequest['RiskCarrierName'] = request['RiskCarrier__r']['Name'];
                    }
                    
                    //RRA - ticket 1632 - 04102023
                    if(request['PremiumDeposit__c'] == '2'){
                        this.selectedRequest['PremiumDepositMode__c'] = null;
                    }
                    
                    if(request['FinancialEntity__c'] != undefined || request['FinancialEntity__c'] != null){
                        this.selectedRequest['FinancialName'] = request['FinancialEntity__r']['Name'];
                    }
                    opt.label = this.programName;
                    opt.value = this.programName;
                    this.programOptions.push(opt);
    
                    opt = {};
                    opt.label = this.uwYear;
                    opt.value = this.uwYear;
                    this.uwYearOpt.push(opt);
    
                    opt = {};
                    opt.label = this.cedCompany;
                    opt.value = this.cedCompany;
                    this.cedingAccOpt.push(opt);
                    this.getSignatories();
                    this.getListRequests();
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: 'Failed to retrieve request data', variant: 'error' }),);
                }
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        });
    }

    getListRequests(){
        getRequestLists({programId: this.programId, reinsurerId: this.selectedReinsurerId, portalAccess : this.portalAccess})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                let isDeactivatedProg = result.isDeactivatedProg; //RRA - ticket 585 - 07032023
              
                let lstReq =  result.Success;
                let lstUpdReq = [];

                //Program / Treaty / Section RRA - ticket 585 - 07032023
                if (isDeactivatedProg){
                    this.disableBtnSave = true;
                    this.isStatusSigned = true;
                }
                
                for(let i = 0; i < lstReq.length; i++){
                    let rowReq = lstReq[i];

                    //NBI - 07/10/20
                    rowReq['WrittenShareVal'] = parseFloat(rowReq.WrittenShare__c).toFixed(6).replace('.',',');
                    rowReq['SignedShareVal'] = parseFloat(rowReq.SignedShare__c).toFixed(6).replace('.',',');

                    //added on 24/08
                    let lossDepositModeReqOpt;
                    if(rowReq.Program__r.LossDepositLevel__c != undefined){
                        if(rowReq.Program__r.LossDepositLevel__c == 'Program'){
                            lossDepositModeReqOpt = rowReq.Program__r.LossDepositMode__c;
                        }
                        else if(rowReq.Program__r.LossDepositLevel__c == 'Treaty'){
                            lossDepositModeReqOpt = rowReq.Treaty__r.LossDepositMode__c;                
                        }
                    }

                    if(lossDepositModeReqOpt != undefined){
                        let lossDepositModeExisted = lossDepositModeReqOpt.split(';');
                        let lossDepositModeReqUpd = [];

                        for(let i = 0; i < lossDepositModeExisted.length; i++){
                            for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                let row = { ...this.lossDepositModeOpt[j] };
                                if(row.value == lossDepositModeExisted[i]){
                                    lossDepositModeReqUpd.push(row);
                                }
                            }
                        }

                        rowReq['lossDeptModeOpt'] = lossDepositModeReqUpd;
                    }

                    if(this.isStatusTimeout == true){
                        lstReq[i]['disableLossDepModeOpt'] == true;
                        lstReq[i]['isPremiumDisable'] = true;
                        lstReq[i]['disablePremiumDeptMode'] = true;
                        lstReq[i]['disableBrokerRef'] = true;
                    }
                    else{
                        let lossDepositModeReqOpt;
                        if(lstReq[i]['Program__r']['LossDeposit__c'] == '2'){
                           
                            //RRA - ticket 1866 - 11012023 
                            if ( lstReq[i]['TECH_isAdmin__c']){ 
                                lossDepositModeReqOpt = lstReq[i]['LossDepositMode__c'];
                                lstReq[i]['lossDeptValue'] = 'Yes';
                            }else{
                                lstReq[i]['lossDeptValue'] = 'No';
                            }
                            lstReq[i]['disableLossDepModeOpt'] = true;  
                        }

                        if(lstReq[i]['Program__r']['LossDepositLevel__c'] != undefined){
                            if(lstReq[i]['Program__r']['LossDepositLevel__c'] == 'Program'){
                                
                                //lossDepositModeReqOpt = lstReq[i]['Program__r']['LossDepositMode__c'];

                                //RRA - ticket 1421 - 26072023 => bug displaying loss deposit value on market submission 
                                if(lstReq[i]['Program__r']['LossDepositLevel__c'] == '2'){
                                    //RRA - ticket 1866 - 11012023 
                                    if ( lstReq[i]['TECH_isAdmin__c']){ 
                                        lossDepositModeReqOpt = lstReq[i]['LossDepositMode__c'];
                                        lstReq[i]['lossDeptValue'] = 'Yes';
                                    }else{
                                        lstReq[i]['lossDeptValue'] = 'No';
                                    }
                                    lstReq[i]['disableLossDepModeOpt'] = true;
                                    //lstReq[i]['lossDeptValue'] = 'No';
                                }
                                else{
                                    lstReq[i]['lossDeptValue'] = 'Yes';
                                }
                                console.log('TECH_isAdmin__c == ', lstReq[i]['TECH_isAdmin__c']);
                                //RRA - ticket 1421 - 31082023
                                if (lstReq[i]['TECH_isAdmin__c']){
                                    if (lstReq[i]['Program__r']['LossDepositMode__c'].includes(lstReq[i]['LossDepositMode__c'])){
                                        lossDepositModeReqOpt = lstReq[i]['Program__r']['LossDepositMode__c']; // Keep data on LossDepositMode__c from program if value exists in conditions
                                    }else{
                                        lossDepositModeReqOpt = lstReq[i]['LossDepositMode__c'] + ';' + lstReq[i]['Program__r']['LossDepositMode__c']; // Keep data on LossDepositMode__c from request if value not exists in conditions
                                    }
                                }else{
                                    lossDepositModeReqOpt = lstReq[i]['Program__r']['LossDepositMode__c']; // Keep data on LossDepositMode__c from conditions
                                }
                                
                                console.log('lossDepositModeReqOpt == ', lossDepositModeReqOpt);
                                //lstReq[i]['lossDeptValue'] = 'Yes';
                            }
                            else if(lstReq[i]['Program__r']['LossDepositLevel__c'] == 'Treaty'){
                                if(lstReq[i]['Treaty__r']['LossDeposit__c'] == '2'){
                                    //RRA - ticket 1866 - 11012023 
                                    if ( lstReq[i]['TECH_isAdmin__c']){ 
                                        lossDepositModeReqOpt = lstReq[i]['LossDepositMode__c'];
                                        lstReq[i]['lossDeptValue'] = 'Yes';
                                    }else{
                                        lstReq[i]['lossDeptValue'] = 'No';
                                    }
                                    lstReq[i]['disableLossDepModeOpt'] = true;
                                    //lstReq[i]['lossDeptValue'] = 'No';
                                }
                                else{
                                    lstReq[i]['lossDeptValue'] = 'Yes';
                                }
                                
                                  //RRA - ticket 1421 - 31082023
                                  if (lstReq[i]['TECH_isAdmin__c']){
                                    if (lstReq[i]['Treaty__r']['LossDepositMode__c'].includes(lstReq[i]['LossDepositMode__c'])){
                                        lossDepositModeReqOpt = lstReq[i]['Treaty__r']['LossDepositMode__c']; // Keep data on LossDepositMode__c from program if value exists in conditions
                                    }else{
                                        lossDepositModeReqOpt = lstReq[i]['LossDepositMode__c'] + ';' + lstReq[i]['Treaty__r']['LossDepositMode__c'] // Keep data on LossDepositMode__c from request if value not exists in conditions
                                    }
                                }else{
                                    lossDepositModeReqOpt = lstReq[i]['Treaty__r']['LossDepositMode__c']; // Keep data on LossDepositMode__c from conditions
                                }
                                //lossDepositModeReqOpt = lstReq[i]['Treaty__r']['LossDepositMode__c'];
                            }
                        }
                        
                        if(lossDepositModeReqOpt != undefined){
                            let lossDepositModeExisted = lossDepositModeReqOpt.split(';');
                            let lossDepositModeReqUpd = [];
    
                            for(let i = 0; i < lossDepositModeExisted.length; i++){
                                for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                    let row = { ...this.lossDepositModeOpt[j] };
                                    if(row.value == lossDepositModeExisted[i]){
                                        lossDepositModeReqUpd.push(row);
                                    }
                                }
                            }
    
                            rowReq['lossDeptModeOpt'] = lossDepositModeReqUpd;
                        }
                        

                        //MBE --24/09 
                        //Premium Deposit - Editable if Type of Treaty QS-3 or Surplus-4 and Premium Deposit of Treaty = 'Yes'
                        if((lstReq[i].Treaty__r.TypeofTreaty__c == '3' || lstReq[i].Treaty__r.TypeofTreaty__c == '4') && (lstReq[i].Treaty__r.PremiumDeposit__c == 'Yes')){
                            lstReq[i]['isPremiumDisable'] = false;
                        }
                        else{
                            lstReq[i]['isPremiumDisable'] = true;
                        }

                        if(lstReq[i].Treaty__r.Deductions__c == '2'){
                            lstReq[i]['disableDeduction'] = true;
                        }
                        else{
                            lstReq[i]['disableDeduction'] = false;
                        }

                        if(lstReq[i]['PremiumDeposit__c'] == '2'){
                            lstReq[i]['disablePremiumDeptMode'] = true;
                        }
                        else if(lstReq[i]['Treaty__r']['TypeofTreaty__c'] == '1' || lstReq[i]['Treaty__r']['TypeofTreaty__c'] == '2'){
                            lstReq[i]['disablePremiumDeptMode'] = true;
                        }
                    }
                    //disable broker Ref
                    if(lstReq[i]['TECH_IsBrokerPresent__c'] == false){
                        lstReq[i]['disableBrokerRef'] = true;
                    }
                    //disable retro Brokerage
                    if(this.portalAccess == true){
                        lstReq[i]['disableRetroBrokerage'] = true;
                    }
                    else if(lstReq[i]['Broker__c'] == null && this.portalAccess == false){
                        lstReq[i]['disableRetroBrokerage'] = true;
                    }
                    else{
                        lstReq[i]['disableRetroBrokerage'] = false;
                    }
                    lstReq[i]['index'] = i;
                    lstUpdReq.push(lstReq[i]);
                }
                this.lstRelatedSigningRequests = lstUpdReq;
                this.sortData('TECH_Layer__c', 'TECH_TreatyName__c' , 'asc'); //MBE - 24/09
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        });

    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BROKER_STATUS_FIELD})
    setBrokerStatusPicklistOptions({error, data}) {
        if(data){
            this.brokerStatusOpt = data.values;
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_OF_CODE_FIELD})
    setTypeOfCodePicklistOptions({error, data}) {
        if(data){
            this.typeOfCodeOpt = data.values;
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PREMIUM_DEPOSIT_MODE_FIELD})
    setPremiumDepositModeOptPicklistOptions({error, data}) {
        if(data){
            this.premiumDeptModeOpt = data.values;
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DESC_REINS_LIMIT_COLL_FIELD})
    setDescCollPicklistOptions({error, data}) {
        if(data){
            this.descCollOpt = data.values;
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        }
    }

    handleCloseMarketSubModal(){
        fireEvent(this.pageRef, 'closeMarketSubModal');
    }

    handleOpenTreatyDetailsModal(event){
        this.selectedRelatedReqId = event.target.dataset.id;
        this.selectedTreatyid = event.currentTarget.dataset.value;
        this.openTreatyDetailsModal = true;
    }

    handleCloseTreatyDetailsModal(){
        this.openTreatyDetailsModal = false;
    }

    handleOpenAddClaimContacts(){
        this.openAddClaimContacts = true;
    }

    handleCloseAddClaimsContacts(){
        this.openAddClaimContacts = false;
    }

    handleAddClaimContact(){
        const emailValid = [...this.template.querySelectorAll('[data-id="newEmailId"]')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        this.invalidEmail = false;
        let currentEmail = this.template.querySelector('[data-id="newEmailId"]').value;
        if(currentEmail.includes('@')){
            let emailArr = currentEmail.split('@');
            if(!emailArr[1].includes('.')){
                this.invalidEmail = true;
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EnterValidEmail, variant: 'error'}), );
            }
        }

        if(this.invalidEmail == false){
            if(emailValid){
                let obj = {};
                let duplicateEmail = false;
                obj['Email'] = this.template.querySelector('[data-id="newEmailId"]').value;
                this.countEmail = this.countEmail + 1;
                obj['id'] = this.countEmail.toString();
                let updClaimContactData = [];
                if(this.claimContactData.length > 0){
                    for(let i = 0; i < this.claimContactData.length; i++){
                        let row = { ...this.claimContactData[i] };
                        duplicateEmail = (row['Email'] == obj['Email'])? true : false;
                        updClaimContactData.push(row);
                    }
                }
                if(duplicateEmail == true){
                    this.claimContactData = updClaimContactData;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EmailAddressAlreadyExists, variant: 'error'}), );
                }
                else{
                    updClaimContactData.push(obj);
                    this.claimContactData = updClaimContactData;
                    if(updClaimContactData.length > 0){
                        this.titleClaimContacts ='Claims Contacts (' + updClaimContactData.length.toString() + ')';
                    }
                    this.openAddClaimContacts = false;
                }
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EnterValidEmail, variant: 'error'}), );
            }
        }
    }

    handleDeleteClaimContact(){
        let selectedContacts = this.template.querySelector('[data-id="claimsContacts"]').getSelectedRows();
        if(selectedContacts.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select Claims Contact(s) to delete',
                    variant: 'error',
                }),
            );
        }
        else{
            let lstSelectedContactsId = [];
            for(let i = 0; i < selectedContacts.length; i ++){
                let idValue = selectedContacts[i]['id'];
                lstSelectedContactsId.push(idValue);
            }
            let lstUpdtClaimsContacts = [];
            for(let j = 0; j < this.claimContactData.length; j++){
                let row = { ...this.claimContactData[j] };
                if(lstSelectedContactsId.includes(row['id']) == false){
                    lstUpdtClaimsContacts.push(row);
                }
            }
            if(lstUpdtClaimsContacts.length > 0){
                this.titleClaimContacts ='Claims Contacts (' + lstUpdtClaimsContacts.length.toString() + ')';
            }
            else{
                this.titleClaimContacts ='Claims Contacts';
            }
            this.claimContactData = lstUpdtClaimsContacts;
        }
    }

    handleOnchangeBrokerRef(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['Broker_s_Ref__c'] = event.target.value;
    }

    handleOnchangeReinsurerRef(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['Reinsurer_s_Ref__c'] = event.target.value;
    }

    handleOnchangeLossDept(event){
        let index = event.currentTarget.dataset.value;
        console.log('index == ', index);
        this.lstRelatedSigningRequests[index]['LossDepositMode__c'] = event.target.value;
        
        console.log('lstRelatedSigningRequests == ', this.lstRelatedSigningRequests[index]['LossDepositMode__c']);
        let lstUpdRelatedSigningRequests = [];
        let selectedSigningReq = {...this.lstRelatedSigningRequests[index]};
        console.log('selectedSigningReq == ', selectedSigningReq);
        let brokerVal = null;
        let reinVal = null;

        if(selectedSigningReq.Broker__c != undefined && selectedSigningReq.Broker__c != null){
            brokerVal = selectedSigningReq.Broker__c;
        }

        if(selectedSigningReq.Reinsurer__c != undefined && selectedSigningReq.Reinsurer__c != null){
            reinVal = selectedSigningReq.Reinsurer__c;
        }

        console.log('brokerVal == ', brokerVal);
        console.log('reinVal == ', reinVal);
        console.log('lstRelatedSigningRequests @@@@@@@ == ', this.lstRelatedSigningRequests);
        
        //RRA - ticket 1421 - 08092023
        if(selectedSigningReq.TECH_isAdmin__c == false){
            for(let i = 0; i < this.lstRelatedSigningRequests.length; i++){
                let relatedSigningReq = {...this.lstRelatedSigningRequests[i]};
                console.log('relatedSigningReq == ', relatedSigningReq);
                if(relatedSigningReq.Broker__c != undefined && relatedSigningReq.Broker__c != null
                    && relatedSigningReq.Reinsurer__c != undefined && relatedSigningReq.Reinsurer__c != null
                    && brokerVal != null && reinVal != null
                    && relatedSigningReq.Broker__c == brokerVal && relatedSigningReq.Reinsurer__c == reinVal){
                        relatedSigningReq['LossDepositMode__c'] = event.target.value;
                }
                else if((relatedSigningReq.Broker__c == undefined || relatedSigningReq.Broker__c == null)
                    && (relatedSigningReq.Reinsurer__c != undefined && relatedSigningReq.Reinsurer__c != null)
                    && brokerVal == null && reinVal != null
                    && relatedSigningReq.Reinsurer__c == reinVal){
                         relatedSigningReq['LossDepositMode__c'] = event.target.value;
                    }
                    console.log('relatedSigningReq[LossDepositMode__c] == ', relatedSigningReq);
                    
                lstUpdRelatedSigningRequests.push(relatedSigningReq);
                console.log('lstUpdRelatedSigningRequests ', lstUpdRelatedSigningRequests);
            }
    
            this.lstRelatedSigningRequests = lstUpdRelatedSigningRequests;
        } 
        
    }

    handleOnchangePremiumDept(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['PremiumDeposit__c'] = event.target.value;
        if(event.target.value == '2'){
            this.lstRelatedSigningRequests[index]['disablePremiumDeptMode'] = true;
            this.lstRelatedSigningRequests[index]['PremiumDepositMode__c'] = null;
        }
        else{
            this.lstRelatedSigningRequests[index]['disablePremiumDeptMode'] = false;
        }
    }

    handleOnchangePremiumDeptMode(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['PremiumDepositMode__c'] = event.target.value;
    }

    handleSaveRequest(event){
        let btnName = event.currentTarget.name;
        let claimContactsValue = '';
        this.displaySpinner = true;
        for(let i = 0; i < this.claimContactData.length; i++){
           if( i != this.claimContactData.length - 1){
            claimContactsValue = claimContactsValue + this.claimContactData[i]['Email'] + ';';
           }else{
            claimContactsValue = claimContactsValue + this.claimContactData[i]['Email'] ;
           }
        }

        for(let i = 0; i < this.lstRelatedSigningRequests.length; i ++){
            let request = this.lstRelatedSigningRequests[i];
                request['BrokerStatus__c'] = this.template.querySelector('[data-id="brokerStatus"]').value;;
                request['Collateral_Provider_City__c'] = this.template.querySelector('[data-id="providerCity"]').value;
                request['Collateral_provider_Code__c'] = this.template.querySelector('[data-id="providerCode"]').value;
                request['Collateral_provider_Name__c'] = this.template.querySelector('[data-id="providerName"]').value;
                request['Type_of_Code__c'] = this.template.querySelector('[data-id="typeCode"]').value;
                request['Claims_contact__c'] = claimContactsValue;
                request['FinancialEntity__c'] = this.selectedRequest['FinancialEntity__c'];
                request['RiskCarrier__c'] = this.selectedRequest['RiskCarrier__c'];
                request['DescriptionReinsurerLimitColl__c'] = this.template.querySelector('[data-id="DescCollValue"]').value;
            if(request['PremiumDeposit__c'] == '2'){
                request['PremiumDepositMode__c'] = '';
            }
            request['Accept__c'] = this.selectedRequest['Accept__c'];
        }
            if(btnName == 'Send'){
                const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
                    .reduce((validSoFar, inputCmp) => {
                                inputCmp.reportValidity();
                                return validSoFar && inputCmp.checkValidity();
                    }, true);
                if(allValid) {
                    saveRequests({lstRequests: this.lstRelatedSigningRequests, buttonName:btnName, reinsurerId: this.selectedReinsurerId, isPortal: this.portalAccess})//MRA 19/05/23 - Contact Signatory Rebuild
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                            this.displaySpinner = false;
                        }
                        else{
                            if(this.portalAccess == true){
                                if(btnName == 'Send'){
                                    this.isStatusSigned = true;
                                    this.sendMail();
                                }
                                else{
                                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RequestsSavedSuccessfully, variant: 'success' }),);
                                    this.displaySpinner = false;
                                }
                            }
                            else{
                                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SigningSavedSuccessfully, variant: 'success' }),);
                                this.displaySpinner = false;
                                fireEvent(this.pageRef, 'closeMarketSubModal');
                            }
                        }
                    })
                    .catch(error => {
                      this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
                      this.displaySpinner =  false;
                    });
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.MissingRequiredFieldMarketSubmission, variant: 'error' }),);
                    this.displaySpinner = false;
                }
            }
            else{
                saveRequests({lstRequests: this.lstRelatedSigningRequests, buttonName:btnName, reinsurerId: this.selectedReinsurerId, isPortal: this.portalAccess, idProgram: this.programId})//MRA 19/05/23 - Contact Signatory Rebuild
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                        this.displaySpinner = false;
                    }
                    else{
                        if(this.portalAccess == true){
                            if(btnName == 'Send'){
                                this.isStatusSigned = true;
                                this.sendMail();
                            }
                            else{
                                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RequestsSavedSuccessfully, variant: 'success' }),);
                                this.displaySpinner = false;
                            }
                        }
                        else{
                            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.SigningSavedSuccessfully, variant: 'success' }),);
                            this.displaySpinner = false;
                            fireEvent(this.pageRef, 'closeMarketSubModal');
                        }
                    }
                })
                .catch(error => {
                  this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
                  this.displaySpinner = false;
                });
            }
            this.saveSignatories() ;//MRA 19/05/23 - Contact Signatory Rebuild
    }
    saveSignatories(){//MRA 19/05/23 - Contact Signatory Rebuild
        saveSignatories({lstContacts: this.signatoriesData,reinsurerId: this.selectedReinsurerId,idProgram:this.programId})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                this.getSignatories() ;
            }
        }) ;
    }

    getSignatories(){
        getSignatories({reinsurerId : this.selectedReinsurerId, programId : this.programId})
        .then(result => {
            console.log('### resultresult = ' , JSON.stringify(result))            
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{//MRA 19/05/23 - Contact Signatory Rebuild
                if(result['Success'].length>0){
                console.log('### resultSuccess = ' , result['Success']);
                this.signatoriesData = result['Success'].map(row => {
                    if (row.ContactId__r != undefined) {
                        const ContactSalutation = row.ContactId__r.Salutation;
                        const ContactLastName = row.ContactId__r.LastName;
                        const ContactFirstName = row.ContactId__r.FirstName;
                        const ContactEmail = row.ContactId__r.Email;
                        const ContactMobilePhone = row.ContactId__r.MobilePhone;
                   return {...row ,ContactSalutation, ContactLastName, ContactFirstName, ContactEmail,ContactMobilePhone};
                    }
                  }) ;
                }
                this.countContact = result['Success'].length;
            }
        })
        .catch(error => {
        console.log('### error = ' + JSON.stringify(error.message))            
          this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        });
    }

    searchRiskCarrierLookUpField(event){
        let currentText = event.target.value;

        getLookupAccountField({value: currentText, requestId : this.selectedRequestId, lookupName: 'RiskCarrier'})
        .then(result => {
            this.txtRiskCarrierLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            this.selectedRequest['loadingTextRisk'] = false;
            this.selectedRequest['searchLookupRecordsRisk'] = result;
            this.selectedRequest['displayRiskCarrierInfo'] = true;
            this.selectedRequest['RiskCarrierName'] = null;
            if(currentText.length > 0 && result.length == 0) {
                this.selectedRequest['messageFlagRisk'] = true;
            }
            else {
                this.selectedRequest['messageFlagRisk'] = false;
            }
        })
        .catch(error => {
           this.error = error;
           this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        });
    }

    setSelectedRiskCarrierLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let lstUpdRelatedSigningRequests = [];

        this.txtRiskCarrierLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.isValueChange = true;
        this.selectedRequest['RiskCarrier__c'] = recId;
        this.selectedRequest['RiskCarrierName'] = selectName;

        for(let i = 0; i < this.lstRelatedSigningRequests.length; i++){
            let rowReq = { ...this.lstRelatedSigningRequests[i] };
            rowReq['RiskCarrier__c'] = recId;
            lstUpdRelatedSigningRequests.push(rowReq);
        }
        let reinsurerValues = this.selectedReinsurerId + '-' + recId + '-' + selectName + '-Risk';
        fireEvent(this.pageRef, 'updateRequestReinsurer', reinsurerValues);
    }

    searchFinancialEntityLookUpField(event){
        let currentText = event.target.value;
        let eventId = event.target.id;

        getLookupAccountField({value: currentText, requestId : this.selectedRequestId, lookupName: 'FinancialEntity'})
        .then(result => {
            this.txtFinancialEntityLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            this.selectedRequest['loadingTextFinancial'] = false;
            this.selectedRequest['searchLookupRecordsFinancial'] = result;
            this.selectedRequest['displayFinancialInfo'] = true;
            this.selectedRequest['FinancialName'] = null;
            if(currentText.length > 0 && result.length == 0) {
                this.selectedRequest['messageFlagFinancial'] = true;
            }
            else {
                this.selectedRequest['messageFlagFinancial'] = false;
            }
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error' }),);
        });
    }

    setSelectedFinancialEntityLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let lstUpdRelatedSigningRequests = [];

        this.txtFinancialEntityLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.isValueChange = true;
        this.selectedRequest['FinancialEntity__c'] = recId;
        this.selectedRequest['FinancialName'] = selectName;

        for(let i = 0; i < this.lstRelatedSigningRequests.length; i++){
            let rowReq = { ...this.lstRelatedSigningRequests[i] };
            rowReq['FinancialEntity__c'] = recId;
            lstUpdRelatedSigningRequests.push(rowReq);
        }
        let reinsurerValues = this.selectedReinsurerId + '-' + recId + '-' + selectName + '-Financial';
        fireEvent(this.pageRef, 'updateRequestReinsurer', reinsurerValues);
    }

    sendMail(){
        sendMail({parentRequest : this.selectedRequest, lstRelatedRequests : this.lstRelatedSigningRequests})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.displaySpinner = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                         title: 'Success',
                         message: 'Email sent successfully.',
                         variant: 'success',
                    }),
                );
                this.displaySpinner = false;
            }
        })
        .catch(error => {
            this.error = error;
            this.displaySpinner = false;
        });
    }

    handleCheckboxAccept(event){
        this.selectedRequest['Accept__c'] = event.target.checked;
    }

    handleOnchangeDeductions(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['Deductions__c'] = parseFloat(event.target.value);
    }

    handleOnchangeSignedShare(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['SignedShare__c'] = parseFloat(event.target.value);
    }

    handleOnchangeRetroBroker(event){
        let index = event.currentTarget.dataset.value;
        this.lstRelatedSigningRequests[index]['RetrocessionBrokerage__c'] = parseFloat(event.target.value);
    }

    //MRA 19/05/23 - Contact Signatory Rebuild - START
    handleStatusChange(event) {
        try {
        if(event.detail.status === 'FINISHED'){
            this.openAddSignatories = false ;
            const outputVariables = event.detail.outputVariables;
            var tempSelected = []  ;
            for(let i = 0; i < outputVariables.length; i++) {
                const outputVar = outputVariables[i];
                if(outputVar.name == 'lastContactListOrdered'){
                        tempSelected = outputVar.value;
                } 
           }
           if (tempSelected) {
            this.signatoriesData = tempSelected.map(row => {
                return {...row};
              }) ;
           }
            this.saveSignatories() ;  
            }
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
            }
            }

    handleStatusChangeUpdateFlow(event) {
        try {
        if(event.detail.status === 'FINISHED'){
            this.isUpdate = false ; 
            this.getSignatories() ;
        }
    } catch (error) {
        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
    }
    }

    handleOpenSignatories(){
            this.goReorder = false ; 
            this.openAddSignatories = true;
    }
    
    handleCloseSignatories(){
        this.openAddSignatories = false;
    }

    handleOpenReorderSignatories(){
        this.goReorder = true ; 
        this.openAddSignatories = true;
    }
    handleCloseReorderSignatories(){
        this.openReOrderSignatories = false ; 
    }
    //MRA 1103 07/07/2022 START
    handleCloseUpdateSignatory(){
        this.isUpdate = false;
    }
    //MRA 1103 07/07/2022 END
    //MRA 19/05/23 - Contact Signatory Rebuild - END

    //RRA - 1103 07/07/2022
    /**
     * 
     * @param {Order_of_signatories__c} fieldName 
     * @param {updSignatoriesData} lstData 
     * @param {asc} sortDirection 
     * @returns 
     */
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
    //MRA 1103 07/07/2022 : START
    handleOpenUpdateSignatory(){
        let selectedContactToUpdate = this.template.querySelector('[data-id="signatoriesContact"]').getSelectedRows();
        if(selectedContactToUpdate.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.updateContact, variant: 'error'}), );
        }
        else if(selectedContactToUpdate.length > 1){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.ChooseOneUpdate, variant: 'error'}), );
        }
        else{
        this.singleContactToUpdate = selectedContactToUpdate[0].ContactId__c ;
        this.isUpdate = true ; 
        } 
    }
    //MRA 1103 07/07/2022 : END
    handleDeleteSignatories(){
        let selectedContacts = this.template.querySelector('[data-id="signatoriesContact"]').getSelectedRows();
        if(selectedContacts.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select Signatory Contact(s) to delete',
                    variant: 'error',
                }),
            );
        }
        else{
            //MRA 19/05/23 - Contact Signatory Rebuild - START
            try {
            var lstUpdtSignatories = this.signatoriesData;
            for(let i = 0; i < selectedContacts.length; i ++){
                lstUpdtSignatories = lstUpdtSignatories.filter(item => item['OrderOfSignatory__c'] !== selectedContacts[i].OrderOfSignatory__c);
            }
            // Reorder the remaining rows
            for(let i = 0; i < lstUpdtSignatories.length; i++) {
                lstUpdtSignatories[i].OrderOfSignatory__c = i + 1;
                lstUpdtSignatories[i].index = i + 1;
            }
            this.signatoriesData = lstUpdtSignatories;
            this.saveSignatories() ;
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}),);
            }
            //MRA 19/05/23 - Contact Signatory Rebuild - END
        }
    }

    handleOpenDocuments(){
        this.isDocumentModalOpen = true;
    }

    handleCloseModal(){
        this.isDocumentModalOpen = false;
    }
    
    sortData(fieldName,fieldName2, sortDirection) {
        let sortResult = Object.assign([], this.lstRelatedSigningRequests);
        this.lstRelatedSigningRequests = sortResult.sort(function(a,b){
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

        for(let i = 0; i < this.lstRelatedSigningRequests.length; i++){
            this.lstRelatedSigningRequests[i]['index'] = i;
        }
    }
}