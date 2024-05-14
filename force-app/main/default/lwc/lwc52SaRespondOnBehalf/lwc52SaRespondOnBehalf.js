import {LightningElement, track, wire, api} from 'lwc';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import getRequestDetails from '@salesforce/apex/LWC52_SARespondOnBehalf.getRequestDetails';
import sendRespondOnBehalf from '@salesforce/apex/LWC52_SARespondOnBehalf.sendRespondOnBehalf';
import saveRespondOnBehalf from '@salesforce/apex/LWC52_SARespondOnBehalf.saveRespondOnBehalf';
import checkBroker from '@salesforce/apex/LWC25_PortalFilters.checkBrokerContact';
import getContentVersionId from '@salesforce/apex/LWC47_SpecialAcceptance.getContentVersionId';
import getTypeOfSARecordTypeId from '@salesforce/apex/LWC47_SpecialAcceptance.getTypeOfSARecordTypeId';
import saveDocuments from '@salesforce/apex/LWC52_SARespondOnBehalf.saveDocuments';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';

//import field
import NATURE_FIELD from '@salesforce/schema/ContentVersion.Nature__c';
import SA_ANSWER_FIELD from '@salesforce/schema/Request__c.SpecialAcceptanceAnswer__c';

//import custom labels
import pendingStatus from '@salesforce/label/c.PendingStatus';
import moreInforRequiredStatus from '@salesforce/label/c.MoreInforRequiredStatus';
import notAnsweredStatus from '@salesforce/label/c.NotAnsweredStatus';
import sentStatus from '@salesforce/label/c.SentStatus';
import DocumentSavedSuccessMsg from '@salesforce/label/c.DocumentSavedSuccessMsg';
import RequiredFieldMissingSA from '@salesforce/label/c.RequiredFieldMissingSA';
import RespondOnBehalfSavedSuccessfully from '@salesforce/label/c.RespondOnBehalfSavedSuccessfully';
import RespondOnBehalfSentSuccessfully from '@salesforce/label/c.RespondOnBehalfSentSuccessfully';
import NoFileIsFound from '@salesforce/label/c.NoFileIsFound';
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsSARequest = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
    { label: 'Risk Carrier/Pool', fieldName: 'riskPoolName'}
];

const columnsSARequestBRPortal = [
    { label: 'Role', fieldName: 'SA_Type__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Broker Status', fieldName: 'BrokerStatus__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
    { label: 'Last send date', fieldName: 'LastSentDate__c'},
    { label: 'Expected answer date', fieldName: 'ExpectedResponseDate__c'},
    { label: 'Response date', fieldName: 'ResponseDate__c'},
    { label: 'Status', fieldName: 'saStatus'}
];

export default class Lwc52SaRespondOnBehalf extends NavigationMixin(LightningElement){
    label = {
        pendingStatus,
        moreInforRequiredStatus,
        notAnsweredStatus,
        sentStatus,
        DocumentSavedSuccessMsg,
        RequiredFieldMissingSA,
        RespondOnBehalfSavedSuccessfully,
        RespondOnBehalfSentSuccessfully,
        NoFileIsFound,
        errorMsg
    }

    @api selectedSpecialAcceptance;
    @api valueUwYear;
    @api valuePrincipalCedComp;
    @api selectedProgram;
    @api brokerId;
    @api reinsurerId;
    @api poolId;
    @api isUgp;
    @api selectedPoolPicklistFromUgp;
    @api selectedSAR;
    @api displayAutoFacFormVal = false;
    @api displayPCFormVal = false;
    @api displayLifeFormVal = false;
    @api covCedComOption;
    @api typeOfSARecordTypeId;
    @track isPortalBR = false;  
    @track lstSaApplyToRequest = [];
    @track lstOriginalSaRequest = [];
    @track saAnswerOpt = [];
    @track lstDocuments = [];
    @track lstAXADocuments = [];
    @track lstSelectedDocument = [];
    @track lstSelectedDeleteDocumentId = [];
    @track specialAcceptanceObj = {};
    columnsSARequest = columnsSARequest;
    columnsSARequestBRPortal = columnsSARequestBRPortal;
    commentsResponseVal;
    saAnswerVal;
    saReqStatus;
    errorMsg;
    displayErrorMsg = false;
    spinnerRespondOnBehalf = false;
    reinsurerName;
    brokerName;
    pccName;
    isBroker = false;
    isRespondOnBehalfReadOnly = false;
    isCommentRequired = false;
    pageTitle = 'Respond on behalf';
    titleCountMyDocument = 'My Documents (0)';
    titleCountAXADocument = 'AXA Documents (0)';
    disableDeleteBtn = true;
    natureOpt;
    isOpenDocModal = false;
    documentNames;
    uploadedDoc;
    disableAddDocBtn = false;
    selectedProgramName;
    selectedProgramNature;
    saType = null;
    macroLobFromProgram;
    selectedSubLOB;
    disableField = false;
    
    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    objectInfoRequest;

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    objectInfoContentVersion;

    connectedCallback(){
        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let currentUrl = this.pageRef.state;
        let nameUrl = null;

        if(this.pageRef.attributes.apiName != null && this.pageRef.attributes.apiName != undefined){
            nameUrl = this.pageRef.attributes.apiName;
        }
        else if(this.pageRef.attributes.name != null && this.pageRef.attributes.name != undefined){
            nameUrl = this.pageRef.attributes.name;
        }

        if(nameUrl == 'SARespondOnBehalf' || nameUrl == 'SARespondOnBehalf__c'){
            //currentUrl.includes('lightning/n/SARespondOnBehalf') || currentUrl.includes('/portal/s/SARespondOnBehalf')
            let param = 's__id';
            let paramValue = null;

            if(currentUrl != undefined && currentUrl != null){
                paramValue = currentUrl[param];
            }

            if(paramValue != null){
                let parameters = paramValue.split("-");

                if(parameters[0] != undefined){
                    this.selectedSpecialAcceptance = parameters[0];
                }

                if(parameters[1] != undefined){
                    this.valueUwYear = parameters[1];
                }

                if(parameters[2] != undefined){
                    this.valuePrincipalCedComp = parameters[2];
                }

                if(parameters[3] != undefined){
                    this.selectedProgram = parameters[3];
                }

                if(parameters[4] != undefined){
                    this.brokerId = parameters[4];
                }

                if(parameters[5] != undefined){
                    this.reinsurerId = parameters[5];
                }

                if(parameters[6] != undefined){
                    this.poolId = parameters[6];
                }

                if(parameters[7] != undefined){
                    if(parameters[7] == 'ugp'){
                        this.isUgp = true;
                    }
                    else if(parameters[7] == 'portalBR'){
                        this.isPortalBR = true;
                        this.pageTitle = 'SA Request Answer Page';
                    }
                }

                if(parameters[8] != undefined){
                    this.selectedPoolPicklistFromUgp = parameters[8];
                }

                if(parameters[9] != undefined){
                    this.selectedSAR = parameters[9];
                }
            }

            this.getRequestDetails();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoRequest.data.defaultRecordTypeId', fieldApiName: SA_ANSWER_FIELD})
    setSaAnswerPicklistOpt({error, data}) {
        if(data){
            this.saAnswerOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfoContentVersion.data.defaultRecordTypeId', fieldApiName: NATURE_FIELD})
    setNaturePicklistOpt({error, data}) {
        if(data){
            this.natureOpt = data.values;
        }
        else{
            this.error = error;
        }
    }

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

    getRequestDetails(){
        getRequestDetails({saId : this.selectedSpecialAcceptance, reqBrokerId : this.brokerId, reqReinsurerId : this.reinsurerId, reqPoolId : this.poolId, reqId : this.selectedSAR, isUserBR: this.isPortalBR})
        .then(result => {
            this.lstSaApplyToRequest = result.lstSaRequest;
            this.lstOriginalSaRequest = result.lstOriginalSaRequest;
            this.lstDocuments = result.lstContentVersionExternal;
            this.titleCountMyDocument = 'My Documents (' + this.lstDocuments.length + ')';
            this.lstAXADocuments = result.lstContentVersionInternal;
            this.titleCountAXADocument = 'AXA Documents (' + this.lstAXADocuments.length + ')';

            if(result.lstSpecialAcceptance != undefined){
                let saObj = { ...result.lstSpecialAcceptance[0] };
                this.selectedSubLOB = saObj.SubLoB__c;
                this.covCedComOption = result.lstCedingComp;
                let reasonStr = saObj.Reason__c;

                if(reasonStr != undefined){
                    saObj['Reason__c'] = reasonStr.split(';');
                }

                this.specialAcceptanceObj = saObj;
                let programObj = { ...result.program };
                this.selectedProgramNature = programObj.Nature__c;
                this.macroLobFromProgram = programObj.Macro_L_O_B__c;
                this.selectedProgramName = programObj.Name;

                // If the Nature of the program = P&C & PCC =! AXA FAC IARD 🡪 P&C form
                // If the Nature of the program = Life & PCC =! AXA FAC IARD  🡪 Life form
                // If the PCC == AXA FAC IARD 🡪 Auto FAC form

                if(programObj.PrincipalCedingCompany__r != undefined && programObj.PrincipalCedingCompany__r.Name == 'AXA FAC IARD /FR (P)'){
                    this.displayAutoFacFormVal = true;
                    this.saType = 'Autofac';
                }
                else if(programObj.Nature__c == 'P&C'){
                    this.displayPCFormVal = true;
                    this.saType = 'PC';
                }
                else if(programObj.Nature__c == 'Life'){
                    this.displayLifeFormVal = true;
                    this.saType = 'Life';
                }

                getTypeOfSARecordTypeId({typeOfSA : this.saType})
                .then(result => {
                    this.typeOfSARecordTypeId = result;
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
            }

            for(let i = 0; i < this.lstDocuments.length; i++){
                this.lstDocuments[i]['Name'] = this.lstDocuments[i].Title;
                this.lstDocuments[i]['Checked'] = false;
                this.lstDocuments[i]['Id'] = this.lstDocuments[i].Id;
                this.lstDocuments[i]['Viewable'] = true;
                this.lstDocuments[i]['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ this.lstDocuments[i].Id+"?operationContext=S1";
                this.lstDocuments[i]['SpecialAcceptance__c'] = null;
            }

            for(let i = 0; i < this.lstAXADocuments.length; i++){
                this.lstAXADocuments[i]['Name'] = this.lstAXADocuments[i].Title;
                this.lstAXADocuments[i]['Id'] = this.lstAXADocuments[i].Id;
                this.lstAXADocuments[i]['Viewable'] = true;
                this.lstAXADocuments[i]['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ this.lstAXADocuments[i].Id+"?operationContext=S1";
            }

            this.lstSaApplyToRequest = this.lstSaApplyToRequest.map(row => {
                let riskPoolName;
                let saStatus;

                if(row.Pool__c != undefined){
                    riskPoolName = row.Pool__r.Name;
                }
                else if(row.RiskCarrier__c != undefined){
                    riskPoolName = row.RiskCarrier__r.Name;
                }

                this.saAnswerVal = row.SpecialAcceptanceAnswer__c;
                this.commentsResponseVal = row.CommentsResponse__c;
   
                if(this.isPortalBR == true || this.isUgp == true){ 
                    if(this.isPortalBR == true){
                        if(this.saAnswerVal == 'Need more information/Subjectivities'){
                            this.isCommentRequired = true;
                        }
                        else{
                            this.isCommentRequired = false;
                        }
                    }

                    if(row.SA_Request_Status__c == this.label.sentStatus){
                        saStatus = this.label.notAnsweredStatus;
                    }
                    else if(row.SA_Request_Status__c == this.label.moreInforRequiredStatus){
                        saStatus = this.label.pendingStatus;
                    }
                    else{
                        saStatus = row.SA_Request_Status__c;
                    }
                }

                this.reinsurerName = row.TECH_ReinsurerName__c;
                this.brokerName = row.TECH_BrokerName__c;
                this.pccName = row.PrincipalCedingCompany__c;
                this.saReqStatus = row.SA_Request_Status__c;
                return {...row, riskPoolName, saStatus}
            });

            this.lstOriginalSaRequest = this.lstOriginalSaRequest.map(row => {
                let today = new Date();
                let dd = String(today.getDate()).padStart(2, '0');
                let mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
                let yyyy = today.getFullYear();
                today = yyyy + '-' + mm + '-' + dd; //2021-01-09

                // Type = '1' -> Declaration
                // Type = '2' -> Submission
                
                if(row.SA_Request_Status__c == 'Setup'){
                    this.isRespondOnBehalfReadOnly = true;    
                    this.displayErrorMsg = true;
                    this.errorMsg = 'Respond on Behalf is not available because this Special Acceptance Request is in status ' + row.SA_Request_Status__c;
                }
                else if(row.SA_Type__c == 'Follower' || row.Special_Acceptance__r.Type__c == '1'){
                    this.isRespondOnBehalfReadOnly = true;    
                    this.displayErrorMsg = true;

                    if(row.SA_Type__c == 'Follower'){
                        this.errorMsg = 'Respond on Behalf is not available because this Special Acceptance Request has role "Follower".';
                    }
                    else{
                        this.errorMsg = 'Respond on Behalf is not available because this Special Acceptance has Type Declaration';
                    }
                }
                else if(row.SA_Request_Status__c == 'Agreed'){
                    this.disableField = true;
                }
                else if(row.SA_Request_Status__c == 'Timeout'){
                    this.isRespondOnBehalfReadOnly = true;   
                    this.displayErrorMsg = true; 
                    this.errorMsg = 'Respond on Behalf is not available because this Special Acceptance Request is in status ' + row.SA_Request_Status__c;
                }
                else if(row.ExpectedResponseDate__c != null && row.ExpectedResponseDate__c != undefined && today > row.ExpectedResponseDate__c){
                    this.isRespondOnBehalfReadOnly = true;    
                    this.displayErrorMsg = true;
                    this.errorMsg = 'The expected answer date has been reached. Please get in touch with your contact.';
                }

                if(row.SA_Request_Status__c == 'Timeout' || this.isRespondOnBehalfReadOnly == true){
                    this.disableAddDocBtn = true;
                    this.disableDeleteBtn = true;
                }

                return {...row}
            });
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleCloseRespondOnBehalfModal(){
        let urlPage;
        if(this.isUgp == true){
            urlPage = '../n/SpecialAcceptanceGroupCover?s__id='+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram+'-'+this.selectedPoolPicklistFromUgp;
            window.open(urlPage, "_self");//RRA - 1459 - 30032023
        }
        else if(this.isPortalBR == true){
            urlPage = '/portal/s/specialAcceptance?s__id='+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.reinsurerId;
            setTimeout(function() {
                window.open(urlPage, "_self");//RRA - 1459 - 30032023
            }, 2000);
        }
        else{
            urlPage = '../n/LoadSARequest?s__id='+this.selectedSpecialAcceptance+'-'+this.valueUwYear+'-'+this.valuePrincipalCedComp+'-'+this.selectedProgram+'-undefined-undefined';
            window.open(urlPage, "_self");//RRA - 1459 - 30032023
        }

        /*this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {url: urlPage, target: '_self'}
        })*/
    }     

    handleOnChangeValue(event){
        let value = event.currentTarget.value;
        let fieldName = event.currentTarget.name;

        if(fieldName == 'CommentsResponse__c'){
            this.commentsResponseVal = value;
        }
        else if(fieldName == 'SpecialAcceptanceAnswer__c'){
            this.saAnswerVal = value;

            if(this.saAnswerVal == 'Need more information/Subjectivities'){
                this.isCommentRequired = true;
            }
            else{
                this.isCommentRequired = false;
            }
        }
    }

    handleOpenNewDocumentModal(event){
        this.isOpenDocModal = true;
        this.documentNames = null;
    }

    handleCloseUploadModal(event){
        this.isOpenDocModal = false;
    }

    handleUploadFinished(event){
        this.documentNames = null;
        this.uploadedDoc = event.detail.files;

        for(let i = 0; i < this.uploadedDoc.length; i++){
            if(this.documentNames == null){
                this.documentNames = this.uploadedDoc[i].name + ';';
            }
            else{
                this.documentNames += this.uploadedDoc[i].name + ';';
            }
        }
    }

    handleSaveUploadDoc(event){
        if(this.uploadedDoc.length > 0){
            this.uploadHelper();
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message:this.label.NoFileIsFound, variant: 'error'}), );
        }
    }

    uploadHelper(){
        let lstUploadedDocId = [];

        for(let i = 0; i < this.uploadedDoc.length; i++){
            lstUploadedDocId.push(this.uploadedDoc[i].documentId);
        }

        getContentVersionId({lstContentDocumentId : lstUploadedDocId})
        .then(result => {

            for(let i = 0; i < result.length; i++){
                let document = {};
                document['Name'] = result[i].Title;
                document['Nature__c'] = 'Private';
                document['Checked'] = false;
                document['Id'] = result[i].Id;
                document['Viewable'] = true;
                document['DocumentUrl'] = "../sfc/servlet.shepherd/version/download/"+ result[i].Id+"?operationContext=S1";
                document['SpecialAcceptance__c'] = null;
                document['ContentDocumentId'] = result[i].ContentDocumentId;
                this.lstDocuments.push(document);
            }

            this.titleCountMyDocument = 'My Documents ('+ this.lstDocuments.length +')';
            this.handleSaveDocument();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });

        this.isOpenDocModal = false;
        this.uploadedDoc = [];
    }

    handleSaveDocument(){
        if(this.lstDocuments != undefined){
            let lstSaveDocument = [];

            for (let i = 0; i < this.lstDocuments.length; i++){
                let objDocument = {};
                objDocument.Nature__c = this.lstDocuments[i].Nature__c;
                objDocument.Title = this.lstDocuments[i].Name;
                objDocument.Id = this.lstDocuments[i].Id;
                objDocument.SpecialAcceptance__c = null;
                objDocument.PathOnClient = this.lstDocuments[i].Name;
                objDocument.ContentDocumentId = this.lstDocuments[i].ContentDocumentId;
                objDocument.IsExternal__c = true;
                lstSaveDocument.push(objDocument);
            }

            saveDocuments({lstContentVersion : lstSaveDocument})
            .then(result => {
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
                
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }

    handleChangeDocCheckbox(event){
        let checkboxChecked = event.currentTarget.checked;
        let docNameVal = event.currentTarget.name;
        let lstUpdatedDoc = [];
        let numOfDocChecked = 0;

        for(let i = 0; i < this.lstDocuments.length; i++){
            let document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Checked = checkboxChecked;
                if(document.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
            else if(document.Checked == true){
                numOfDocChecked = numOfDocChecked + 1;
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
        this.titleCountMyDocument = 'My Documents ('+ this.lstDocuments.length +')';

        if(this.isRespondOnBehalfReadOnly == true){
            this.disableDeleteBtn = true;
        }
        else if(this.disableAddDocBtn == false){
            if(numOfDocChecked > 0){
                this.disableDeleteBtn = false;
            }
            else{
                this.disableDeleteBtn = true;
            }
        }
    }

    handleDeleteDocument(event){
        this.disableDeleteBtn = true;

        for(let i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Checked == true){
                this.lstSelectedDocument.push(this.lstDocuments[i]);
                this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
            }
        }

        this.lstDocuments = this.lstDocuments.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocument);
        this.titleCountMyDocument = 'My Documents ('+ this.lstDocuments.length +')';
    }

    handleSaveSendRespondOnBehalf(event){
        this.spinnerRespondOnBehalf = true;
        let buttonName = event.currentTarget.name;

        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);

        if(allValid){
            let lstSaRequestId = [];

            for(let i = 0; i < this.lstSaApplyToRequest.length; i++){
                lstSaRequestId.push(this.lstSaApplyToRequest[i].Id);
            }

            let lstAllDocument = [];

            for(let i = 0; i < this.lstDocuments.length; i++){
                let doc = {...this.lstDocuments[i]};
                lstAllDocument.push(doc);
            }

            if(buttonName == 'Send'){
                sendRespondOnBehalf({commentValue : this.commentsResponseVal, responseValue : this.saAnswerVal, lstRequestId : lstSaRequestId, isExtPortalBR : this.isPortalBR, saId : this.selectedSpecialAcceptance, lstDocumentToUpdate: lstAllDocument, lstDeletedDocument : this.lstSelectedDeleteDocumentId, isExtPortalUGP : this.isUgp, reqBrokerId : this.brokerId, reqReinsurerId : this.reinsurerId})
                .then(result => {
                    this.handleCloseRespondOnBehalfModal();
                    this.spinnerRespondOnBehalf = false;
                    if(this.isPortalBR == true){
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Email sent successfully.', variant: 'success' }),);     
                    }
                    else{
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RespondOnBehalfSentSuccessfully, variant: 'success' }),);     
                    }
                })
                .catch(error => {
                    this.spinnerRespondOnBehalf = false;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
            }
            else if(buttonName == 'Save'){
                saveRespondOnBehalf({commentValue : this.commentsResponseVal, responseValue : this.saAnswerVal, lstRequestId : lstSaRequestId, isExtPortalUGP : this.isUgp, saId : this.selectedSpecialAcceptance, lstDocumentToUpdate: lstAllDocument, lstDeletedDocument : this.lstSelectedDeleteDocumentId, reqBrokerId : this.brokerId, reqReinsurerId : this.reinsurerId})
                .then(result => {
                    this.handleCloseRespondOnBehalfModal();
                    this.spinnerRespondOnBehalf = false;
                    if(this.isPortalBR == true){
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Request saved successfully.', variant: 'success' }),);     
                    }
                    else{
                        this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RespondOnBehalfSavedSuccessfully, variant: 'success' }),);     
                    }
                })
                .catch(error => {
                    this.spinnerRespondOnBehalf = false;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
            }
        }
        else{
            this.spinnerRespondOnBehalf = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RequiredFieldMissingSA, variant: 'error'}), );
        }
    }
}