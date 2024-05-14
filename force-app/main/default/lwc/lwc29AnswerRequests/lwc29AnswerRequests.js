import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import slds from '@salesforce/resourceUrl/SLDS';
import getRequestDetails from '@salesforce/apex/LWC29_AnswerRequests.getRequestDetails'
import saveRequestRecord from '@salesforce/apex/LWC29_AnswerRequests.saveRequestRecord';
import sendMail from '@salesforce/apex/LWC29_AnswerRequests.sendMail';
import getPlacementRequestRecordTypeId from '@salesforce/apex/LWC29_AnswerRequests.getPlacementRequestRecordTypeId';
import Id from '@salesforce/user/Id';

//import field
import SECTION_OBJECT from '@salesforce/schema/Section__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import EPINATURE_FIELD from '@salesforce/schema/Section__c.Nature__c';
import QUOTE_FIELD from '@salesforce/schema/Request__c.Quote__c';
import REASONFORREFUSAL_FIELD from '@salesforce/schema/Request__c.ReasonRefusal__c';
import PLACEMENT_PARTICIPATION_FIELD from '@salesforce/schema/Request__c.PlacementParticipation__c';

//import custom label
import DecimalPlacesErrorMessage from '@salesforce/label/c.DecimalPlacesErrorMessage';
import NumberErrorMessage from '@salesforce/label/c.NumberErrorMessage';
import twoDpErrorMessage from '@salesforce/label/c.twoDpErrorMessage';
import maxHundredErrorMessage from '@salesforce/label/c.maxHundredErrorMessage';
import minHundredErrorMessage from '@salesforce/label/c.minHundredErrorMessage';
import maxThousandErrorMessage from '@salesforce/label/c.maxThousandErrorMessage';
import ExpectedAnswerDateReached from '@salesforce/label/c.ExpectedAnswerDateReached';
import RequestSavedSuccessfully from '@salesforce/label/c.RequestSavedSuccessfully';
import EmailSentSuccessfully from '@salesforce/label/c.EmailSentSuccessfully';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC29_AnswerRequests extends NavigationMixin(LightningElement) {

    label = {
        DecimalPlacesErrorMessage,
        NumberErrorMessage,
        twoDpErrorMessage,
        maxHundredErrorMessage,
        minHundredErrorMessage,
        maxThousandErrorMessage,
        ExpectedAnswerDateReached,
        RequestSavedSuccessfully,
        EmailSentSuccessfully,
        FormEntriesInvalid,
        errorMsg
    }

    @api programId;
    @api reinsurerId;
    @api brokerId;
    @api stageName;
    @api placementRecordTypeId;
    @track lstUpdParentLeadRequest = [];
    @track lstTreaties = [];
    @track lstSectionRequestByTreatyId = [];
    @track mapParentRequestByTreaty = [];
    @track lstParentLeadRequest = [];
    @track lstUpdatedValue = [];
    @track lstAllRequestSection = [];
    @track leaderTypeOpt = [];
    wiredRequestDetails;

    programNameValue;
    inceptionDateValue;
    expiryDateValue;
    isTreatyIdMatch = false;
    currencyOpt;
    reinstatementOpt;
    natureOpt;
    quoteOpt;
    reasonForRefusalOpt;
    disableSaveBtn = false; //to disable the save button, set it true
    phaseType;
    isPhaseTypeLead = false;
    isPhaseTypeQuote = false;
    isPhaseTypePlacement = false;
    programNameValue;
    inceptionDateValue;
    expiryDateValue;
    placementParticipationOpt;
    agreeCheckboxLabel;
    disableSaveBtn = false;
    allowDocumentPortalAccess = false;
    isDocumentModalOpen = false;
    answerPage = true;
    disableAllBtns = true;
    requestMsg = '';
    allowAccess = true;
    sendBtnClick = false;
    saveAllBtnClick = false;
    displaySpinner = false;
    containQuoteReqInfo = false;
    quoteDeadline; //RRA - ticket 1541 - 06072023
    currentSelectedIdReq;//RRA - ticket 1541 - 06072023
    isChangedDateValidity = false; //RRA - ticket 1574 - 06102023
    selectIdRequest; //RRA - ticket 1574 - 24102023
    portalAccess = false; //RRA - ticket 1574 - 24102023

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              Exposed properties to show refuse all modal
    showRefuseAll = false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('isChangedDate', this.getIsChangedDateValidity, this); //RRA - ticket 1574 - 06102023
        loadStyle(this, slds + '/slds/styles/salesforce-lightning-design-system.css');
        // RRA - 1162 - 17/06/2022
        let label = 'Accept';
        let nameUrl = null;
        //label = label + 'on the present form, including the reinsurance agreement (general conditions and special conditions) and ';
        //label = label + 'I acknowledge that the legal binding effect of this signing with reference to paragraph 3 of the terms of use of ACTOR New Gen';
        this.agreeCheckboxLabel = label;
        this.getRequestDetails();
        registerListener('closeDocumentModal', this.closeDocumentModal, this);
        
        //RRA - ticket 1574 - 24102023
        let currentUrl = this.pageRef.state;
        console.log('currentUrl == ' , currentUrl);
        let param = 'c__details';
        let paramValue = currentUrl[param];       
        console.log('paramValue == ' , paramValue);
        
        if(paramValue != null){
            let parameters = paramValue.split("-");
            if(parameters[4] != undefined){
                this.selectIdRequest = parameters[4];
            }
        }
        console.log('selectIdRequest == ' , this.selectIdRequest);
        
        
        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }
        console.log('nameUrl == ' , nameUrl);
        
        if(nameUrl == 'portal_request__c'){
            //portal/s
            this.portalAccess = true;
        }
        
        console.log('portalAccess == ' , this.portalAccess);
    }
    
     //RRA - ticket 1574 - 06102023
     getIsChangedDateValidity(val){
        this.isChangedDateValidity = val;
    }

    closeDocumentModal(val){
        this.isDocumentModalOpen = false;
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfoRequest;

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: PLACEMENT_PARTICIPATION_FIELD})
    setPlacementParticipationPicklistOpt({error, data}) {
        if(data){
            this.placementParticipationOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CURRENCY_FIELD})
    setCurrencyPicklistOpt({error, data}) {
        if(data){
            this.currencyOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: EPINATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: QUOTE_FIELD})
    setQuotePicklistOpt({error, data}) {
        if(data){
            this.quoteOpt = data.values;
        }else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$placementRecordTypeId', fieldApiName: REASONFORREFUSAL_FIELD})
    setReasonForRefusalPicklistOpt({error, data}) {
        if(data){
            this.reasonForRefusalOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    getRequestDetails(){
        getRequestDetails({progId: this.programId, reinId: this.reinsurerId, brokId: this.brokerId, requestPhaseType: this.stageName})
        .then(result => {
            this.lstSectionRequestByTreatyId = [];
            this.lstAllRequestSection = result.lstRequestAll;
            let reinsName = result.reinsName ;//MRA W-0953 8/09/2022 
            let isDeactivatedProg = result.isDeactivatedProg; //RRA - ticket 585 - 07032023
            
            this.lstTreaties = this.getUniqueData(result.lstTreaties, 'value');
            let mapSectionReqByTreaty = result.mapSectionRequestByTreatyId;
            this.mapParentRequestByTreaty = result.mapParentRequestByTreatyId;
            this.lstParentLeadRequest = result.lstParentLeadRequest;
            let checkboxes = this.template.querySelectorAll('[data-id="AcceptLeadCheckbox"]');

            for(let i = 0; i < this.lstParentLeadRequest.length; i++) {
                for(let j = 0; j < checkboxes.length; j++) {
                    if(this.lstParentLeadRequest[i] == checkboxes[j].id.split("-")[0]){
                        checkboxes[j].checked = this.lstParentLeadRequest[i].Accept__c;
                    }
                }
            }

            if(result.lstRequestAll.length > 0){
                this.selectedProgramId = result.lstRequestAll[0].Program__c;
                this.selectedPrincipleCedingCom = result.lstRequestAll[0].Program__r.PrincipalCedingCompany__c;
                this.selectedUWYear = result.lstRequestAll[0].Program__r.UwYear__c;
                this.selectedStatus = result.lstRequestAll[0].Program__r.TECH_StageName__c;
                this.allowAccess = true;
            }
            else{
                this.allowAccess = false;
            }
            this.phaseType = result.requestPhaseType;

            if(this.phaseType == 'Lead'){
                this.isPhaseTypeLead = true;
                this.isPhaseTypeQuote = false;
                this.isPhaseTypePlacement = false;
            }
            else if(this.phaseType == 'Quote'){
                this.isPhaseTypeQuote = true;
                this.isPhaseTypeLead = false;
                this.isPhaseTypePlacement = false;
                //The expected answer date has been reached. Please get in touch with your contact.
                this.requestMsg = this.label.ExpectedAnswerDateReached;
            }
            else if(this.phaseType == 'Placement'){
                this.isPhaseTypePlacement = true;
                this.isPhaseTypeLead = false;
                this.isPhaseTypeQuote = false;
                //The expected answer date has been reached. Please get in touch with your contact.
                this.requestMsg = this.label.ExpectedAnswerDateReached;
            }

            getPlacementRequestRecordTypeId({phase : this.phaseType})
                                            .then(result => {
                                                this.placementRecordTypeId = result;
                                            })
                                            .catch(error => {
                                                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                                            });

            let lstUpdReq = [];
            let latestResponseDate;

            for(let key in mapSectionReqByTreaty){
                for(let i = 0; i < this.lstTreaties.length; i++){
                    if(this.lstTreaties[i].value == key){
                        let lstSectionRequest = mapSectionReqByTreaty[key];
                        let lstUpdSectionsRequest = [];

                        for(let j = 0; j < lstSectionRequest.length; j++){
                            let rowSection = { ...lstSectionRequest[j] };
                            let today = new Date();
                            let dd = String(today.getDate()).padStart(2, '0');
                            let mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
                            let yyyy = today.getFullYear();
                            today = yyyy + '-' + mm + '-' + dd; //2020-07-10

                            if(rowSection.ReinsurerStatus__c == 'Timeout' || (rowSection.ReinsurerStatus__c == 'Answered' && today > rowSection.ExpectedResponseDate__c) || (rowSection.ReinsurerStatus__c == 'Refused' && today > rowSection.ExpectedResponseDate__c) || (rowSection.ReinsurerStatus__c == 'Sent' && rowSection.QuoteType__c == '2')){
                                rowSection['disableQuoteRequestInfo'] = true;
                            }
                            else{
                                rowSection['disableQuoteRequestInfo'] = false;
                            }
                            rowSection['SectionNumber'] =  rowSection['Section__r']['SectionNumber__c'];
                            rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' - ' + rowSection['Section__r']['Name'];
                            rowSection = this.setTypeOfTreatyQuoteValue(rowSection);
                            lstUpdSectionsRequest.push(rowSection);
                        }
                        
                        lstUpdSectionsRequest = this.sortData('SectionNumber', 'asc', lstUpdSectionsRequest);

                        if(this.isPhaseTypeQuote == true){
                            let rowTreaty = {};
                            console.log('lstSectionRequest == ', lstSectionRequest);
                            console.log('lstSectionRequestSIZE == ', lstSectionRequest.length);
                            if(lstSectionRequest.length > 0){
                                rowTreaty['Deductions_Perc__c'] = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                                rowTreaty['PremiumDeposit__c'] = lstSectionRequest[0].Treaty__r.PremiumDeposit__c;
                                rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Treaty__r.LossDeposit__c;
                                
                                //RRA - ticket 1541 - 06072023 - Edit Quote Validity
                                for (let i=0;i<lstSectionRequest.length;i++){
                                    if (lstSectionRequest[i].QuoteDeadline__c != null || lstSectionRequest[i].QuoteDeadline__c != undefined){
                                        this.quoteDeadline = lstSectionRequest[i].QuoteDeadline__c;
                                    }else{
                                        this.quoteDeadline = null;
                                    }
                                }
                            }
                            let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                            let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                            this.lstTreaties[i]['label'] = newLabel;
                            this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: 'parent1', treatyDetail : rowTreaty, treatyName: this.lstTreaties[i].label, treatyLayer: treatyLayer });
                        }
                        else if(this.isPhaseTypeLead == true){
                            let rowTreaty = {};
                            if(lstSectionRequest.length > 0){
                                rowTreaty['Deductions_Perc__c'] = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                                rowTreaty['PremiumDeposit__c'] = lstSectionRequest[0].Treaty__r.PremiumDeposit__c;
                                rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Treaty__r.LossDeposit__c;
                            }
                            if(this.mapParentRequestByTreaty[key] != undefined){
                                let leadParentReq = {...this.mapParentRequestByTreaty[key]};

                                if(leadParentReq.ResponseDate__c != undefined){
                                    if(latestResponseDate == undefined){
                                        latestResponseDate = leadParentReq.ResponseDate__c;
                                    }
                                    else{
                                        if(latestResponseDate < leadParentReq.ResponseDate__c){
                                            latestResponseDate = leadParentReq.ResponseDate__c
                                        }
                                    }
                                }

                                if(leadParentReq.ReinsurerStatus__c == 'Timeout' || leadParentReq.ReinsurerStatus__c == 'Answered' || leadParentReq.ReinsurerStatus__c == 'Refused'){
                                    leadParentReq['disableParentInfo'] = true;
                                }
                                else{
                                    leadParentReq['disableParentInfo'] = false;
                                }
                                let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                                let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                                this.lstTreaties[i]['label'] = newLabel;
                                this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: leadParentReq, treatyDetail : rowTreaty, treatyName: this.lstTreaties[i].label, treatyLayer: treatyLayer});
                            }
                        }
                        else if(this.isPhaseTypePlacement == true){
                            let rowTreaty = {};
                            if(lstSectionRequest.length > 0){
                                rowTreaty['Deductions_Perc__c'] = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                                rowTreaty['PremiumDeposit__c'] = lstSectionRequest[0].Treaty__r.PremiumDeposit__c;
                                rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Treaty__r.LossDeposit__c;
                            }

                            if(this.mapParentRequestByTreaty[key] != undefined){
                                let placementRequest = { ...this.mapParentRequestByTreaty[key] };

                                if(placementRequest.PlacementParticipation__c == '1'){
                                    placementRequest['writtenSharePlacementRequired'] = true;
                                    placementRequest['reasonForRefusalDisable'] = true;
                                    placementRequest['reasonForRefusalRequired'] = false;

                                }
                                else if(placementRequest.PlacementParticipation__c == '2'){
                                    placementRequest['writtenSharePlacementRequired'] = false;
                                    placementRequest['reasonForRefusalDisable'] = false;
                                    placementRequest['reasonForRefusalRequired'] = true;
                                }
                                else{
                                    placementRequest['writtenSharePlacementRequired'] = false;
                                    placementRequest['reasonForRefusalDisable'] = true;
                                    placementRequest['reasonForRefusalRequired'] = true; //disable WrittenShare
                                }

                                let reasonForRefusalParentId = 'ReasonForRefusal' + '-' + placementRequest.Id;
                                let writtenShareParentId = 'WrittenShare' + '-' + placementRequest.Id;
                                placementRequest['reasonForRefusalParentId'] = reasonForRefusalParentId;
                                placementRequest['writtenShareParentId'] = writtenShareParentId;

                                let todayDate = new Date();
                                let dd = String(todayDate.getDate()).padStart(2, '0');
                                let mm = String(todayDate.getMonth() + 1).padStart(2, '0'); //January is 0!
                                let yyyy = todayDate.getFullYear();

                                todayDate = yyyy + '-' + mm + '-' + dd; //2020-07-10

                                //to disable buttons + field if timeout or (answered and today > expected answered)
                                if(placementRequest.ReinsurerStatus__c == 'Timeout' || (placementRequest.ReinsurerStatus__c == 'Answered' && todayDate > placementRequest.ExpectedResponseDate__c)){
                                    placementRequest['disableParentInfo'] = true;
                                }
                                else{
                                    placementRequest['disableParentInfo'] = false;
                                }

                                let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];
                                let newLabel = treatyLayer + ' - ' + this.lstTreaties[i]['label'];
                                this.lstTreaties[i]['label'] = newLabel;
                                this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: placementRequest, treatyDetail : rowTreaty, treatyName: this.lstTreaties[i].label, treatyLayer: treatyLayer});
                            }
                        }
                    }
                }
            }

            for(let i = 0; i < this.lstAllRequestSection.length; i++){
                let rowReqSection = { ...this.lstAllRequestSection[i] };
                rowReqSection['checkIfPercentbadInput'] = false;
                lstUpdReq.push(rowReqSection);
            }

            if(this.lstAllRequestSection.length > 0){
                if(this.lstAllRequestSection[0].Program__r != undefined){
                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : START
                    if (this.isPhaseTypeLead || this.isPhaseTypePlacement) {
                        this.programNameValue = this.lstAllRequestSection[0].Program__r.Name+ ' - ' + reinsName; 
                    }
                    else{
                        if(this.lstAllRequestSection[0].TECH_ReinsurerName__c !== undefined)
                        this.programNameValue = this.lstAllRequestSection[0].Program__r.Name+ ' - ' + this.lstAllRequestSection[0].TECH_ReinsurerName__c; 
                        else
                        this.programNameValue = this.lstAllRequestSection[0].Program__r.Name
                    }
                    //MRA W-0953 8/09/2022 Transversal - Nom du réassureur à ajouter sur la page de réponse réassureur/courtier et le respond on behalf : END
                    this.inceptionDateValue = this.lstAllRequestSection[0].Program__r.InceptionDate__c;
                    this.expiryDateValue = this.lstAllRequestSection[0].Program__r.Expirydate__c;

                    if(this.inceptionDateValue != undefined){
                        let incepDate = new Date(this.inceptionDateValue+'T00:00').getDate();
                        if(incepDate < 10){
                           incepDate = '0'+incepDate;
                        }

                        let incepMonth = new Date(this.inceptionDateValue+'T00:00').getMonth() + 1;
                        if(incepMonth < 10){
                           incepMonth = '0'+incepMonth;
                        }

                        this.inceptionDateValue = incepDate + '/' + incepMonth + '/' + new Date(this.inceptionDateValue+'T00:00').getFullYear();
                    }

                    if(this.expiryDateValue != undefined){
                        let expDate = new Date(this.expiryDateValue+'T00:00').getDate();
                        if(expDate < 10){
                           expDate = '0'+expDate;
                        }

                        let expMonth = new Date(this.expiryDateValue+'T00:00').getMonth() + 1;
                        if(expMonth < 10){
                           expMonth = '0'+expMonth;
                        }

                        this.expiryDateValue = expDate + '/' + expMonth + '/' + new Date(this.expiryDateValue+'T00:00').getFullYear();
                    }
                }
            }

            this.lstAllRequestSection = lstUpdReq;

            let sendRequestAvailable = false;
            this.containQuoteReqInfo = false;
            //if 1 Request having ReinsurerStatus__c = Sent, display buttons + fields editable
            //else disable all buttons and fields read only

            for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
                let result = this.lstSectionRequestByTreatyId[i];
                if(this.isPhaseTypeQuote == true){
                    let lstRequest = result['value'];

                    for(let j = 0; j < lstRequest.length; j++){
                        if(lstRequest[j].disableQuoteRequestInfo == false){
                            sendRequestAvailable = true;
                        }

                        if(lstRequest[j].QuoteType__c == '2'){
                            this.containQuoteReqInfo = true;
                        }                        
                    }

                }
                else if(this.isPhaseTypeLead == true){
                    let parentRequest = result['parentRequest'];
                    if(parentRequest.disableParentInfo == false){
                        //If Parent Request has no ReinsurerStatus = Timeout/Answered/Refused
                        sendRequestAvailable = true;
                    }
                }
                else if(this.isPhaseTypePlacement == true){
                    let parentRequest = result['parentRequest'];
                    if(parentRequest.disableParentInfo == false){
                        //If Parent Request has no ReinsurerStatus = Timeout/Answered/Refused
                        sendRequestAvailable = true;
                    }
                }
            }

            if(this.phaseType == 'Lead'){
                if(latestResponseDate != undefined){
                    this.requestMsg = 'The lead request has been answered on ' +latestResponseDate+ '.';
                }
                else{
                    this.requestMsg = 'The lead request has been answered.';
                }
            }

            if(sendRequestAvailable == true){
                this.disableAllBtns = false;
            }
            else{
                this.disableAllBtns = true;
            }

            this.lstSectionRequestByTreatyId = this.sortData('treatyLayer', 'asc', this.lstSectionRequestByTreatyId);
            
            if(this.sendBtnClick == true){ 
                this.sendMail();
            }

            //Program RRA - ticket 585 - 07032023
            if (isDeactivatedProg){
                this.disableSaveBtn = true;
            }else{
                this.disableSaveBtn = false;
            }

            if(this.lstAllRequestSection.length == 0){
                this.disableSaveBtn = true;
            }
        })
        .catch(error => {
            this.displaySpinner = false;
            this.error = error;
        });
    }

    setTypeOfTreatyQuoteValue(rowSection){
        let typeOfTreaty;
        let typeOfQuote;
        let ltaProgram;

        if(rowSection.Quote__c == '1' || rowSection.disableQuoteRequestInfo == true){
            rowSection['isQuoteYes'] = true;
            rowSection['isQuoteNo'] = false;
            rowSection['ReasonRefusal__c'] = '';
        }
        else if(rowSection.Quote__c == '2'){
            rowSection['isQuoteYes'] = false;
            rowSection['isQuoteNo'] = true;
        }

        if(rowSection.disableQuoteRequestInfo == true || rowSection.OrUnlimited__c == true){
            rowSection['disableLossCarryingForward'] = true;
        }
        else{
            rowSection['disableLossCarryingForward'] = false;
        }

        if(rowSection.disableQuoteRequestInfo == true){
            rowSection['disableNoClaimBonusPerc'] = true;
        }
        else{
            if(rowSection.NoClaimBonusAmount__c == null || rowSection.NoClaimBonusAmount__c == '' || rowSection.NoClaimBonusAmount__c == undefined){
                rowSection['disableNoClaimBonusPerc'] = false;
            }
            else{
                rowSection['disableNoClaimBonusPerc'] = true;
            }
        }

        if(rowSection.disableQuoteRequestInfo == true){
            rowSection['disableNoClaimBonusAmount'] = true;
        }
        else{
            if(rowSection.NoClaimBonus__c == null || rowSection.NoClaimBonus__c == '' || rowSection.NoClaimBonus__c == undefined){
                rowSection['disableNoClaimBonusAmount'] = false;
            }
            else{
                rowSection['disableNoClaimBonusAmount'] = true;
            }
        }

        if((rowSection.DepoPremium__c == null || rowSection.DepoPremium__c == '' || rowSection.DepoPremium__c == undefined) && (rowSection.MinPremium__c == null || rowSection.MinPremium__c == '' || rowSection.MinPremium__c == undefined)){
            rowSection['disableMDP'] = false;
        }
        else{
            rowSection['disableMDP'] = false;
        }

        if(rowSection.MDP__c == null || rowSection.MDP__c == '' || rowSection.MDP__c == undefined){
            rowSection['disableMinPremium'] = false;
            rowSection['disableDepoPremium'] = false;
        }
        else{
            rowSection['disableMinPremium'] = true;
            rowSection['disableDepoPremium'] = true;
        }

        if(rowSection.Treaty__r != undefined){
           typeOfTreaty = rowSection.Treaty__r.TypeofTreaty__c;
        }

        if(rowSection.Section__r != undefined){
            typeOfQuote = rowSection.Section__r.QuoteType__c;
        }

        if(rowSection.Section__r != undefined){
            ltaProgram = rowSection.Program__r.LTA__c;
        }

        if(typeOfTreaty == '3'){
            rowSection['isTreatyTypeQS'] = true;
            rowSection['isTreatyTypeAXAXLQS'] = false; /*1966*/
            rowSection['disableEstReinsurance'] = true;
        }
        /*1966*/
        else if(typeOfTreaty == '5'){
            rowSection['isTreatyTypeAXAXLQS'] = true;
            rowSection['isTreatyTypeQS'] = false;
            rowSection['disableEstInsurance'] = true;
        }
        else if(typeOfTreaty == '4'){
            rowSection['isTreatyTypeSurplus'] = true;
            rowSection['disableEstInsurance'] = true;
        }
        else if(typeOfTreaty == '2'){
            rowSection['isTreatyTypeXL'] = true;
        }
        else if(typeOfTreaty == '1'){
            rowSection['isTreatyTypeSL'] = true;
        }
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
        else if(typeOfQuote == '7'){
            rowSection['isQuoteTypePerHead'] = true;
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

        if(ltaProgram == '1'){
            rowSection['LTAProgramYes'] = true;
        }
        else{
            rowSection['LTAProgramYes'] = false;
        }

        if(rowSection.disableQuoteRequestInfo == true){
            rowSection['disableEstInsurance'] = true;
            rowSection['disableEstReinsurance'] = true;
        }

        if(this.isPhaseTypeLead == true){
            if(rowSection.OverridingCommission__c == null || rowSection.OverridingCommission__c == ''){
                rowSection['OverridingCommission__c'] = 0;
            }

            //QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
            if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;
                let cessionPerc = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.Section__r.Cession_Perc__c != undefined){
                    cessionPerc = rowSection.Section__r.Cession_Perc__c;
                }

                let cededPremiumValue = totalEPI * (cessionPerc / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(QS or Surplus) + PerHead
            else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                let totalEPI = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
            else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FixedRate
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                let totalEPI = 0;
                let fixedRate = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                if(rowSection.FixedRate__c != undefined){
                    fixedRate = rowSection.FixedRate__c;
                }

                let cededPremiumValue = totalEPI * (fixedRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FlatPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                let flatPremium = 0;

                if(rowSection.FlatPremium__c != undefined){
                    flatPremium = rowSection.FlatPremium__c;
                }

                let cededPremiumValue = flatPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + MDP
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                let MDP = 0;

                if(rowSection.MDP__c != undefined){
                    MDP = rowSection.MDP__c;
                }

                let cededPremiumValue = MDP;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + VariableRate
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                let totalEPI = 0;
                let minRate = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                if(rowSection.MinRate__c != undefined){
                    minRate = rowSection.MinRate__c;
                }

                let cededPremiumValue = totalEPI * (minRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                let totalEPI = 0;
                let perHeadPremium = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                if(rowSection.PerHeadPremium__c != undefined){
                    perHeadPremium = rowSection.PerHeadPremium__c;
                }

                let cededPremiumValue = totalEPI * perHeadPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadVariable
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                let totalEPI = 0;
                let minPerHeadAmount = 0;

                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }

                if(rowSection.MinPerHeadAmount__c != undefined){
                    minPerHeadAmount = rowSection.MinPerHeadAmount__c;
                }

                let cededPremiumValue = totalEPI * minPerHeadAmount;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }
        }

        if(rowSection.Section__r != undefined){
            //Build list since Section__r cannot be retrieved in html
            rowSection['Section__r.Name'] = rowSection.Section__r.Name;
            rowSection['Section__r.Currency__c'] = rowSection.Section__r.Currency__c;
            rowSection['Section__r.CapacityPerRisk__c'] = rowSection.Section__r.CapacityPerRisk__c;
            rowSection['Section__r.Unlimited__c'] = rowSection.Section__r.Unlimited__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;
            rowSection['Section__r.Retention__c'] = rowSection.Section__r.Retention__c;
            rowSection['Section__r.CessionAmount__c'] = rowSection.Section__r.CessionAmount__c;
            rowSection['Section__r.RetentionAmount__c'] = rowSection.Section__r.RetentionAmount__c;
            rowSection['Section__r.TotalEPI__c'] = rowSection.Section__r.TotalEPI__c;
            rowSection['Section__r.Nature__c'] = rowSection.Section__r.Nature__c;
            rowSection['Section__r.LineAmount__c'] = rowSection.Section__r.LineAmount__c;
            rowSection['Section__r.CededLines__c'] = rowSection.Section__r.CededLines__c;
            rowSection['Section__r.RetentionLine__c'] = rowSection.Section__r.RetentionLine__c;
            rowSection['Section__r.Capacity__c'] = rowSection.Section__r.Capacity__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.AAD__c'] = rowSection.Section__r.AAD__c;
            rowSection['Section__r.AAL__c'] = rowSection.Section__r.AAL__c;
            rowSection['Section__r.TAL__c'] = rowSection.Section__r.TAL__c;
            rowSection['Section__r.ExpectedDP__c'] = rowSection.Section__r.ExpectedDP__c;
            rowSection['Section__r.ExpectedMDP__c'] = rowSection.Section__r.ExpectedMDP__c;
            rowSection['Section__r.ExpectedMP__c'] = rowSection.Section__r.ExpectedMP__c;
            rowSection['Section__r.LimitPercent__c'] = rowSection.Section__r.LimitPercent__c;
            rowSection['Section__r.DeductiblePercent__c'] = rowSection.Section__r.DeductiblePercent__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.MaxLimitAmount__c'] = rowSection.Section__r.MaxLimitAmount__c;
            rowSection['Section__r.MinLimitAmount__c'] = rowSection.Section__r.MinLimitAmount__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;

            if(rowSection.Section__r.Reinstatements__c != undefined){
                if(rowSection.Section__r.Reinstatements__c == '1'){
                    rowSection['ReinstatementStr'] = 'None';
                }
                else if(rowSection.Section__r.Reinstatements__c == '2'){
                    rowSection['ReinstatementStr'] = 'Free and Unlimited';
                }
                else if(rowSection.Section__r.Reinstatements__c == '3'){
                    //Other
                    if(rowSection.Section__r.TECH_Reinstatement__c != undefined){
                        rowSection['ReinstatementStr'] = rowSection.Section__r.TECH_Reinstatement__c;
                    }
                }
            }
        }
        return rowSection;
    }

    handleSaveAll(event){      
        let phaseTypeRequest = null;
        let mapDataInput = [];
        let mapParentRequestDataInput = [];
        let lstUpdParentLeadRequest = [];
        let btnName = event.currentTarget.name;
        this.displaySpinner = true;

        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if(allValid) {
            if(this.isPhaseTypeQuote == true){
                phaseTypeRequest = 'Quote';
                let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != ''){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;

                        if (input.type == 'checkbox'){
                            mapDataInput.push({key:nameId, value:input.checked});
                        }
                        else{
                            mapDataInput.push({key:nameId, value:input.value});
                        }
                    }
                }
            }
            else if(this.isPhaseTypeLead == true){
                phaseTypeRequest = 'Lead';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != '' && input.name != 'Type__c'){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;

                        if(input.name == 'Accept__c'){
                            mapParentRequestDataInput.push({key:nameId, value:input.checked});
                        }
                        else if(input.name == 'WrittenShare__c'){
                            let writtenShareVal = parseFloat(input.value);
                            mapParentRequestDataInput.push({key:nameId, value:writtenShareVal});
                        }
                        else if(input.name == 'CommentsResponse__c'){
                            mapParentRequestDataInput.push({key:nameId, value:input.value});
                        }
                        else if(input.name == 'CommentsReinsurerBroker__c'){ // RRA 1095
                            mapParentRequestDataInput.push({key:nameId, value:input.value});
                        }
                        else if(input.type == 'checkbox'){
                            mapDataInput.push({key:nameId, value:input.checked});
                        }
                        else{
                            mapDataInput.push({key:nameId, value:input.value});
                        }
                    }
                }

                for(let i = 0; i < this.lstParentLeadRequest.length; i++){
                    let rowParentRequest = { ...this.lstParentLeadRequest[i] };
                    for(let j = 0; j < mapParentRequestDataInput.length; j++){
                        let parentRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                        let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                        let dataInputValue = mapParentRequestDataInput[j].value;

                        if(this.lstParentLeadRequest[i].Id == parentRequestId){
                            rowParentRequest[dataInputName] = dataInputValue;
                        }
                    }
                    lstUpdParentLeadRequest.push(rowParentRequest);
                }

                console.log('lstUpdParentLeadRequestLead== ', lstUpdParentLeadRequest);
            }
            else if(this.isPhaseTypePlacement == true){
                phaseTypeRequest = 'Placement';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
                let lstPlacementRequest = [];

                for(let input of inputs){
                    if((input.id != '') && (input.name == 'PlacementParticipation__c' || input.name == 'ReasonRefusal__cPlacement' || input.name == 'WrittenShare__cPlacement' || input.name == 'CommentsResponse__cPlacement' || input.name == 'CommentsReinsurerBroker__cPlacement')){ //RRA 1095
                        let id = input.id.split("-")[0];
                        let name;
                        let val;

                        if(input.name == 'PlacementParticipation__c'){
                            name = input.name;
                        }
                        else{
                            name = input.name.split("Placement")[0];
                        }

                        if(input.name == 'WrittenShare__cPlacement'){
                            val = parseFloat(input.value);
                        }
                        else{
                            val = input.value;
                        }

                        let nameId = id + '-' + name + '-' + input.type;
                        mapParentRequestDataInput.push({key:nameId, value:val});
                    }
                }

                for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
                    let placementRequest = { ...this.lstSectionRequestByTreatyId[i].parentRequest };

                    for(let j = 0; j < mapParentRequestDataInput.length; j++){
                        let placementRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                        let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                        let dataInputValue = mapParentRequestDataInput[j].value;

                        if(placementRequest.Id == placementRequestId){
                            placementRequest[dataInputName] = dataInputValue;
                        }
                    }

                    lstPlacementRequest.push(placementRequest);
                }
                lstUpdParentLeadRequest = lstPlacementRequest;
            }

            let lstUpdAllRequest = [];
            let dataNotValid = false;

            for(let i = 0; i < this.lstAllRequestSection.length; i++){
                let rowRequest = { ...this.lstAllRequestSection[i] };
                if(rowRequest.checkIfPercentbadInput == true){
                    dataNotValid = true;
                }

                for(let j = 0; j < mapDataInput.length; j++){
                    let requestId = mapDataInput[j].key.split('-')[0];
                    let dataInputName = mapDataInput[j].key.split('-')[1];
                    let dataInputValue = mapDataInput[j].value;
                    let dataInputType = mapDataInput[j].key.split('-')[2];

                    if(this.lstAllRequestSection[i].Id == requestId){
                        if(dataInputType == 'number'){
                            rowRequest[dataInputName] =  parseFloat(dataInputValue);
                        }
                        else{
                            rowRequest[dataInputName] = dataInputValue;
                        }
                    }
                }
                lstUpdAllRequest.push(rowRequest);
            }
            console.log('quoteDeadline 22= ',this.quoteDeadline);
            console.log('isChangedDateValidity = ',this.isChangedDateValidity);
            console.log('btnName = ',btnName);
            saveRequestRecord({ lstRequest : lstUpdAllRequest, phaseType : phaseTypeRequest, lstParentRequest : lstUpdParentLeadRequest, btnName : btnName, quotedeadline : this.quoteDeadline, isChangedDateQuote : this.isChangedDateValidity, idRequestSelected : this.selectIdRequest, isPortalAccess : this.portalAccess}) //RRA - ticket 1541 - 06072023
            .then(result => {
                console.log('result == ', result);
                this.lstUpdParentLeadRequest = result.lstParentRequest;

                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Errorapex', message: result.Error, variant: 'error' }),);
                    this.displaySpinner = false;
                }
                else{
                    if(btnName == 'Send'){
                        this.sendBtnClick = true;
                        this.getRequestDetails();
                    }
                    else{
                        this.saveAllBtnClick = true;
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RequestSavedSuccessfully, variant: 'success' }),);
                        this.displaySpinner = false;
                        this.getRequestDetails();
                    }
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                this.displaySpinner = false;
            });
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
            this.displaySpinner = false;
        }
    }

    handleSave(event){
        let selectedRequestId = event.currentTarget.name;
        let phaseTypeRequest = null;
        let mapDataInput = [];
        let mapParentRequestDataInput = [];
        let lstUpdParentLeadRequest = [];
        let setLeadRequestId = new Set();
        this.displaySpinner = true;

        if(this.isPhaseTypeLead == true){
            //get all child request id and parent request id of the selected save button for lead
            let selectedRequestRecord = event.currentTarget.name;
            let parentRequest = selectedRequestRecord.parentRequest;
            let value = [ ...selectedRequestRecord.value ];
            setLeadRequestId.add(parentRequest.Id);

            for(let i = 0; i < value.length; i++){
                setLeadRequestId.add(value[i].Id);
            }
        }

        let allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                let inputId = inputCmp.id.split("-")[0];
                if(this.isPhaseTypeLead == true){
                    if(setLeadRequestId.has(inputId)){
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }
                    else{
                        return validSoFar && true;
                    }
                }
                else{
                    if(inputId == selectedRequestId){
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }
                    else{
                        return validSoFar && true;
                    }
                }

            }, true);

        if(allValid) {
            if(this.isPhaseTypeQuote == true){
                phaseTypeRequest = 'Quote';
                let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != ''){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;
                        if(id == selectedRequestId){
                            if (input.type == 'checkbox'){
                                mapDataInput.push({key:nameId, value:input.checked});
                            }
                            else{
                                mapDataInput.push({key:nameId, value:input.value});
                            }
                        }
                    }
                }
            }
            else if(this.isPhaseTypeLead == true){
                let requestRecord = event.currentTarget.name;
                phaseTypeRequest = 'Lead';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

                for(let input of inputs){
                    if(input.id != ''  && input.name != 'Type__c'){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name + '-' + input.type;

                        if(setLeadRequestId.has(id)){
                            if(input.name == 'Accept__c'){
                                mapParentRequestDataInput.push({key:nameId, value:input.checked});
                            }
                            else if(input.name == 'WrittenShare__c'){
                                let writtenShareVal = parseFloat(input.value);
                                mapParentRequestDataInput.push({key:nameId, value:writtenShareVal});
                            }
                            else if(input.name == 'CommentsResponse__c'){
                                mapParentRequestDataInput.push({key:nameId, value:input.value});
                            }
                            else if(input.name == 'CommentsReinsurerBroker__c'){ // RRA 1095
                                mapParentRequestDataInput.push({key:nameId, value:input.value});
                            }
                            else if(input.type == 'checkbox'){
                                mapDataInput.push({key:nameId, value:input.checked});
                            }
                            else{
                                mapDataInput.push({key:nameId, value:input.value});
                            }
                        }
                    }
                }

                for(let i = 0; i < this.lstParentLeadRequest.length; i++){
                    let rowParentRequest = { ...this.lstParentLeadRequest[i] };
                    if(setLeadRequestId.has(rowParentRequest.Id)){
                        for(let j = 0; j < mapParentRequestDataInput.length; j++){
                            let parentRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                            let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                            let dataInputValue = mapParentRequestDataInput[j].value;

                            if(this.lstParentLeadRequest[i].Id == parentRequestId){
                                rowParentRequest[dataInputName] = dataInputValue;
                            }
                        }

                        lstUpdParentLeadRequest.push(rowParentRequest);
                    }
                }
            }
            else if(this.isPhaseTypePlacement == true){
                phaseTypeRequest = 'Placement';
                let inputs= this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
                let lstPlacementRequest = [];

                for(let input of inputs){
                    if((input.id != '') && (input.name == 'PlacementParticipation__c' || input.name == 'ReasonRefusal__cPlacement' || input.name == 'WrittenShare__cPlacement' || input.name == 'CommentsResponse__cPlacement' || input.name == 'CommentsReinsurerBroker__cPlacement')){ //RRA 1095
                        let id = input.id.split("-")[0];

                        if(id == selectedRequestId){
                            let name;
                            let val;
                            if(input.name == 'PlacementParticipation__c'){
                                name = input.name;
                            }
                            else{
                                name = input.name.split("Placement")[0];
                            }

                            if(input.name == 'WrittenShare__cPlacement'){
                                val = parseFloat(input.value);
                            }
                            else{
                                val = input.value;
                            }

                            let nameId = id + '-' + name + '-' + input.type;
                            mapParentRequestDataInput.push({key:nameId, value:val});
                        }
                    }
                }

                let parentPlacementId = event.currentTarget.name;

                for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
                    let placementRequest = { ...this.lstSectionRequestByTreatyId[i].parentRequest };

                    if(placementRequest.Id == parentPlacementId){
                        for(let j = 0; j < mapParentRequestDataInput.length; j++){
                            let placementRequestId = mapParentRequestDataInput[j].key.split('-')[0];
                            let dataInputName = mapParentRequestDataInput[j].key.split('-')[1];
                            let dataInputValue = mapParentRequestDataInput[j].value;

                            if(placementRequest.Id == placementRequestId){
                                placementRequest[dataInputName] = dataInputValue;
                            }
                        }

                        lstPlacementRequest.push(placementRequest);
                    }
                }
                lstUpdParentLeadRequest = lstPlacementRequest;
            }

            let lstUpdAllRequest = [];
            let dataNotValid = false;

            for(let i = 0; i < this.lstAllRequestSection.length; i++){
                let rowRequest = { ...this.lstAllRequestSection[i] };

                if((this.isPhaseTypeLead == true && setLeadRequestId.has(rowRequest.Id)) || (this.isPhaseTypeLead == false && rowRequest.Id == selectedRequestId)){
                    if(rowRequest.checkIfPercentbadInput == true){
                        dataNotValid = true;
                    }

                    for(let j = 0; j < mapDataInput.length; j++){
                        let requestId = mapDataInput[j].key.split('-')[0];
                        let dataInputName = mapDataInput[j].key.split('-')[1];
                        let dataInputValue = mapDataInput[j].value;
                        let dataInputType = mapDataInput[j].key.split('-')[2];

                        if(this.lstAllRequestSection[i].Id == requestId){
                            if(dataInputType == 'number'){
                                rowRequest[dataInputName] =  parseFloat(dataInputValue);
                            }
                            else{
                                rowRequest[dataInputName] = dataInputValue;
                            }
                        }
                    }
                    lstUpdAllRequest.push(rowRequest);
                }
            }

            saveRequestRecord({ lstRequest : lstUpdAllRequest, phaseType : phaseTypeRequest, lstParentRequest : lstUpdParentLeadRequest, btnName : 'Save', quotedeadline : this.quoteDeadline, isChangedDateQuote : this.isChangedDateValidity, idRequestSelected : this.selectIdRequest, isPortalAccess : this.portalAccess})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                    this.displaySpinner = false;
                }
                else{
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RequestSavedSuccessfully, variant: 'success' }),);
                    this.displaySpinner = false;
                    this.saveAllBtnClick = true;
                    this.getRequestDetails();
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                this.displaySpinner = false;
            });
        }
        else{
            this.displaySpinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.FormEntriesInvalid, variant: 'error'}), );
        }
    }

    handleQuoteChange(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let quoteValue = event.currentTarget.value;
        let lstUpdSectionRequestByTreatyId = [];

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    if(quoteValue == '1' || rowSectionRequest.disableQuoteRequestInfo == true){
                        rowSectionRequest['isQuoteYes'] = true;
                        rowSectionRequest['isQuoteNo'] = false;
                        rowSectionRequest['ReasonRefusal__c'] = '';
                    }
                    else if(quoteValue == '2'){
                        rowSectionRequest['isQuoteYes'] = false;
                        rowSectionRequest['isQuoteNo'] = true;
                        rowSectionRequest['ReasonRefusal__c'] = rowSectionRequest.ReasonRefusal__c;
                    }
                }
                lstUpdSectionsRequest.push(rowSectionRequest);
            }
            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }
        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    handleOnChangeInputValue(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    if(fieldName == 'OrUnlimited__c'){
                        let orUnlimitedCheck = event.currentTarget.checked;
                        if(orUnlimitedCheck == true || rowSectionRequest.dirsableQuoteRequestInfo == true){
                            rowSectionRequest['disableLossCarryingForward'] = true;
                            rowSectionRequest['LossCarryingForward__c'] = '';

                            let inputs = this.template.querySelectorAll('[data-id='+requestId+']');
                            for(let i = 0; i < inputs.length; i++) {
                                inputs[i].value = '';
                            }
                        }
                        else{
                            rowSectionRequest['disableLossCarryingForward'] = false;
                        }
                    }
                    else if(fieldName == 'NoClaimBonusAmount__c'){
                        let noClaimBonusAmountValue = event.currentTarget.value;
                        if((rowSectionRequest.isTreatyTypeQS == true || rowSectionRequest.isTreatyTypeAXAXLQS == true) && rowSectionRequest.isQuoteTypeFlatCommission == true){
                            rowSectionRequest['disableNoClaimBonusPerc'] = true;
                        }
                        else{
                            if(rowSectionRequest.disableQuoteRequestInfo == true){
                                rowSectionRequest['disableNoClaimBonusPerc'] = true;
                            }
                            else{
                                if(noClaimBonusAmountValue == null || noClaimBonusAmountValue == ''){
                                    rowSectionRequest['disableNoClaimBonusPerc'] = false;
                                }
                                else{
                                    rowSectionRequest['disableNoClaimBonusPerc'] = true;
                                }
                            }
                        }

                    }
                    else if(fieldName == 'NoClaimBonus__c'){
                        let noClaimBonusValue = event.currentTarget.value;
                        if(rowSectionRequest.disableQuoteRequestInfo == true){
                            rowSectionRequest['disableNoClaimBonusAmount'] = true;
                        }
                        else{
                            if(noClaimBonusValue == null || noClaimBonusValue == ''){
                                rowSectionRequest['disableNoClaimBonusAmount'] = false;
                            }
                            else{
                                rowSectionRequest['disableNoClaimBonusAmount'] = true;
                            }
                        }
                    }
                    else if(fieldName == 'MDP__c'){
                        let MDPValue = event.currentTarget.value;
                        if(MDPValue == null || MDPValue == ''){
                            rowSectionRequest['disableMinPremium'] = false;
                            rowSectionRequest['disableDepoPremium'] = false;
                        }
                        else{
                            rowSectionRequest['disableMinPremium'] = true;
                            rowSectionRequest['disableDepoPremium'] = true;
                        }
                    }
                    else if(fieldName == 'DepoPremium__c' || fieldName == 'MinPremium__c'){
                        let depoPremiumVal = event.currentTarget.value;
                        if(depoPremiumVal == null || depoPremiumVal == ''){
                            rowSectionRequest['disableMDP'] = false;
                        }
                        else{
                            rowSectionRequest['disableMDP'] = true;
                        }
                    }
                }
                lstUpdSectionsRequest.push(rowSectionRequest);
            }
            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }
        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    handleChangeLeadRequest(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        if(value == '' || value == null){
            value = 0;
        }

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let parentUpdRequest = this.lstSectionRequestByTreatyId[i].parentRequest;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;

            for(let j = 0; j < lstSectionRequests.length; j++){
                let rowSectionRequest = { ...lstSectionRequests[j] };
                if(rowSectionRequest.Id == requestId){
                    let typeOfTreaty = rowSectionRequest.Treaty__r.TypeofTreaty__c;
                    let typeOfQuote = rowSectionRequest.Section__r.QuoteType__c;

                    if(fieldName == 'FixedRate__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '1'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            let cededPremiumValue = totalEPI * (value / 100);
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        }
                    }
                    else if(fieldName == 'FlatPremium__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                            rowSectionRequest['CededPremium__c'] = Math.round(value);
                        }
                    }
                    else if(fieldName == 'MDP__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                            rowSectionRequest['CededPremium__c'] = Math.round(value);
                        }
                    }
                    else if(fieldName == 'MinRate__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            let cededPremiumValue = totalEPI * (value / 100);
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        }
                    }
                    else if(fieldName == 'PerHeadPremium__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            let cededPremiumValue = totalEPI * (value / 100);
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        }
                    }
                    else if(fieldName == 'MinPerHeadAmount__c'){
                        if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                            let totalEPI = 0;
                            if(rowSectionRequest.Section__r.TotalEPI__c != undefined){
                                totalEPI = rowSectionRequest.Section__r.TotalEPI__c;
                            }
                            let cededPremiumValue = totalEPI * value;
                            rowSectionRequest['CededPremium__c'] = Math.round(cededPremiumValue);
                        }
                    }
                }
                lstUpdSectionsRequest.push(rowSectionRequest);
            }
            lstUpdSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:lstTreatyId, parentRequest: parentUpdRequest, treatyDetail : rowTreatyDetail });
        }
        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    handleChangePlacementRequest(event){
        let eventId = event.currentTarget.id;
        let requestId = eventId.split('-')[0];
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;
        let lstUpdSectionRequestByTreatyId = [];

        if(value == '' || value == null){
            value = null;
        }

        for(let i = 0; i < this.lstSectionRequestByTreatyId.length; i++){
            let lstUpdSectionsRequest = [];
            let lstSectionRequests = this.lstSectionRequestByTreatyId[i].value;
            let lstTreatyId = this.lstSectionRequestByTreatyId[i].key;
            let rowTreatyDetail = this.lstSectionRequestByTreatyId[i].treatyDetail;
            let placementRequest = { ...this.lstSectionRequestByTreatyId[i].parentRequest };
            if(placementRequest.Id == requestId){
                if(value == '1'){
                    placementRequest['writtenSharePlacementRequired'] = true;
                    placementRequest['reasonForRefusalDisable'] = true;
                    placementRequest['reasonForRefusalRequired'] = false;
                    placementRequest['PlacementParticipation__c'] = value;
                    placementRequest['ReasonRefusal__c'] = null;
                    //to set ReasonForRefusal to null in screen
                    let dataId = '[data-id=ReasonForRefusal-'+requestId+']';

                    if(this.template.querySelector(dataId) != undefined){
                        this.template.querySelector(dataId).value = '';
                    }

                }
                else if(value == '2'){
                    placementRequest['writtenSharePlacementRequired'] = false;
                    placementRequest['reasonForRefusalDisable'] = false;
                    placementRequest['reasonForRefusalRequired'] = true;
                    placementRequest['PlacementParticipation__c'] = value;
                    placementRequest['WrittenShare__c'] = null;
                    //to set WrittenShare to null in screen
                    let dataId = '[data-id=WrittenShare-'+requestId+']';

                    if(this.template.querySelector(dataId) != undefined){
                        this.template.querySelector(dataId).value = '';
                    }
                }
            }

            lstUpdSectionRequestByTreatyId.push({value:lstSectionRequests, key:lstTreatyId, parentRequest: placementRequest, treatyDetail : rowTreatyDetail });
        }

        this.lstSectionRequestByTreatyId = lstUpdSectionRequestByTreatyId;
    }

    sendMail(){
        this.sendBtnClick = false;
        this.displaySpinner = true;

        let parentReq = {};
        if(this.stageName != 'Quote'){
            for(let key in this.mapParentRequestByTreaty) {
                parentReq = this.mapParentRequestByTreaty[key];
            }
        }

        //Note For Placement
        //this.lstAllRequestSection -> List of Lead Request displayed 
        //parentReq -> Placement Request

        sendMail({lstRequest : this.lstAllRequestSection, stage : this.stageName, parentRequest : parentReq, reinId: this.reinsurerId, brokId: this.brokerId, lstParentRequest : this.lstUpdParentLeadRequest})
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
               this.getRequestDetails();
               this.dispatchEvent(
                   new ShowToastEvent({
                        title: 'Success',
                        message: this.label.EmailSentSuccessfully,
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

    handleOpenDocuments(){
        this.isDocumentModalOpen = true;
    }

    handleCloseModal(){
        this.isDocumentModalOpen = false;
    }

    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        let lstSortedLstData = sortResult.sort(function(a,b){
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
        return lstSortedLstData;
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              getter to determine when to show refuse all modal
    get showRefuseAllModal(){
        return (this.phaseType === 'Quote' || this.phaseType === 'Placement');
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              handler to show refuse all modal
    showRefuseAllHandler(){
        //set property to true to render refuse all template
        this.showRefuseAll = true;
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              handler to close refuse all modal
    closeRefuseAllHandler(){
        //set property to true to render refuse all template
        this.showRefuseAll = false;
    }

    //AMI 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
    //              handler to reexecute send mail method for refuse all modal
    reSendMailHandler(event){
        this.lstUpdParentLeadRequest = event.detail.lstParentRequest;
        this.sendBtnClick = true;
        this.getRequestDetails();
    }
    
    //RRA - ticket 1541 - 06072023
    handleChangeQuoteDeadline(event){
        this.quoteDeadline = event.detail.value;
        fireEvent(this.pageRef, 'isChangedDate', true); //RRA - ticket 1574 - 24102023
        console.log('this.quoteDeadline 11 == ', this.quoteDeadline);
    }
}