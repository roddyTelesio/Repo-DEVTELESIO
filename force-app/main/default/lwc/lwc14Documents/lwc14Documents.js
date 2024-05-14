/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 23-02-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   19-10-2023   Patrick Randrianarisoa   Initial Version
**/
import {LightningElement, track, wire, api} from 'lwc';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import saveDocuments from '@salesforce/apex/LWC14_Documents.saveDocuments';
import getDocuments from '@salesforce/apex/LWC14_Documents.getDocuments';
import getContentVersionId from '@salesforce/apex/LWC14_Documents.getContentVersionId';
import deleteContentDocument from '@salesforce/apex/LWC14_Documents.deleteContentDocument';
import saveReplaceDocument from '@salesforce/apex/LWC14_Documents.saveReplaceDocument';
import getInitialDocuments from '@salesforce/apex/LWC14_Documents.getInitialDocuments';
import replaceDocuments from '@salesforce/apex/LWC14_Documents.replaceDocuments';
//import getExternalDocuments from '@salesforce/apex/LWC14_Documents.getExternalDocuments'; 
import getExternalDocumentVisibility from '@salesforce/apex/LWC14_Documents.getExternalDocumentVisibility';
import getTHEMISDocuments from '@salesforce/apex/LWC14_Documents.getTHEMISDocuments';
import getCongaDocs from '@salesforce/apex/LWC14_Documents.getCongaDocuments';
import viewOrCreateAgreement from '@salesforce/apex/LWC14_Documents.viewOrCreateAgreement';
import renewAgreement from '@salesforce/apex/LWC14_Documents.renewAgreement';
import getMetadataFieldValue from '@salesforce/apex/LWC14_Documents.getMetadataFieldValue';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';


//import object and fields
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import GROUP_TYPE_FIELD from '@salesforce/schema/ContentVersion.GroupType__c';
import DOCUMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.DocumentType__c';
import PHASE_FIELD from '@salesforce/schema/ContentVersion.Phase__c';
import FILE_EXTENSION_FIELD from '@salesforce/schema/ContentVersion.FileExtension';
import FILE_TYPE_FIELD from '@salesforce/schema/ContentVersion.FileType';
import TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import PATH_ON_CLIENT_FIELD from '@salesforce/schema/ContentVersion.PathOnClient';
import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';

//Custom Label
import DocumentFieldValueMissing from '@salesforce/label/c.DocumentFieldValueMissing';
import NoDocumentAvailable from '@salesforce/label/c.NoDocumentAvailable';
import NoFileIsFound from '@salesforce/label/c.NoFileIsFound';
import DocumentSavedSuccessMsg from '@salesforce/label/c.DocumentSavedSuccessMsg';
import errorMsg from '@salesforce/label/c.errorMsg';

//CLM
import hasCLMPermission from "@salesforce/customPermission/CLM_Access";
import checkAgreementGenerationStatus from '@salesforce/apex/LWC14_Documents.checkAgreementGenerationStatus';

export default class LWC14_Documents extends NavigationMixin(LightningElement) {
    label = {
        DocumentFieldValueMissing,
        NoDocumentAvailable,
        NoFileIsFound,
        DocumentSavedSuccessMsg,
        errorMsg
    }

    @api uwYear;
    @api principalCedingCompany;
    @api valueProgram;
    @api programOptions;
    @track groupTypeOpt = [];
    @track documentTypeOpt = [];
    @track phaseOpt = [];
    @track lstDocuments = [];
    @track lstSelectedDocument = [];
    @track lstSelectedDeleteDocumentId = [];
    @track uploadedReplaceDocId = [];
    @track lstUploadedReplaceDocToDelete = [];
    @track uploadDocumentDelete = [];
    @track lstExternalDocuments = [];
    @track lstTHEMISDocuments = [];
    @track showClmDocuments = false;

    isOpenDocModal = false;
    controlDocumentTypeValues;
    totalDependentDocumentTypeValues = []
    documentNames;
    uploadedDoc;
    fileReader;
    wiredLstDocument;
    isEmpty = true;
    isReplaceButton = false;
    currentContentVersionId;
    uploadedReplaceDoc;
    replaceDocumentId;
    selectedDocumentPicklistValues;
    isDocument = true;
    mapDocType = new Map();
    mapPhase = new Map();
    initialDocs;

    //AzharNahoor - 08/09/2023 - CLM START
    @track lstCongaDocuments = [];
    @api isLoading = false;
    @api disableBtnModal = false;
    @track agreementAlreadyGenerated = false; 
    @track canRenew = false; 
    @track generateNew = false;

    get hasCLMPerm(){
        return hasCLMPermission;
    }

    get hasCongaDocuments(){
        return (this.lstCongaDocuments != null && this.lstCongaDocuments.length > 0)
    }

    @api objectApiName = 'Apttus__APTS_Agreement__c'; // Pass the object API name as a property when using the component
    agreementRtSelected;
    isModalRTOpen = false;
    error;

    openModalRt() {
        console.log('opening RT modal');
        this.isModalRTOpen = true;
    }

    closeModaRt() {
        console.log('Closing RT modal');
        this.agreementRtSelected = null;
        this.isModalRTOpen = false;
    }

    handleRtSelect(event){
        this.agreementRtSelected = event.detail;
        console.log('RT selected event handling: ', event);
    }

    submitDetailsRT(){
        console.log('submit RT selection');
        this.disableBtnModal = true;
        this.handleViewProgram();
        this.closeModaRt();
    }
    //AzharNahoor - 08/09/2023 -CLM END


    @wire(getMetadataFieldValue, { metadataType: 'CLMSettings__mdt', fieldDeveloperName: 'ShowClmButtons' })
    wiredFieldValue({ error, data }) {
        if (data) {
            // Update showClmButtons based on the metadata value
            console.log('setting showClmButtons ' , data);
            this.showClmButtons = data.toLowerCase() === 'true';
        } else if (error) {
            // Handle error if needed
            console.error('Error fetching metadata field value', error);
        }
    }

    getAgreementGenerationStatus(){
        checkAgreementGenerationStatus({ programId : this.valueProgram})
        .then(result =>{
            if (result) {
                // Update showClmButtons based on the metadata value
                console.log('checkAgreementGenerationStatus ' , result);
                if(result.agreementGenerated == true){
                    this.agreementAlreadyGenerated = true;
                }else if(result.canRenew == true){
                    this.canRenew = true; 
                }else{
                    this.generateNew = true;
                }
                // this.showClmButtons = data.toLowerCase() === 'true';
            }else{
                console.log('no result ');
            }
        })
        .catch(error=>{
            console.error('Error checkAgreementGenerationStatus', error);
        });
    }



    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
        objectInfo;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        getInitialDocuments({programId : this.valueProgram})
        .then(result => {
            this.initialDocs = result;
        })
        .catch(error => {
            this.error = error;
        });
        this.getExternalDocumentVisibility();
        this.getTHEMISDocuments();
        this.getCongaDocuments();
        this.getAgreementGenerationStatus();
        registerListener('filterProgram', this.getProgram, this);
    }

    getProgram(val){
        if(val != null){
            this.valueProgram = val.Id;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: DOCUMENT_TYPE_FIELD})
    setDocumentTypePicklistOptions({error, data}) {
        if(data){
            this.mapDocType = new Map();

            for(var i = 0; i < data.values.length; i++){
                this.mapDocType.set(data.values[i].value, data.values[i].label);
            }

            this.getDocumentValue();

        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValuesByRecordType, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: CONTENT_VERSION_OBJECT})
    getGroupTypePicklistOpt({error, data}) {
        if(data){
            let groupTypeOptions = [{label:'--None--', value:'--None--'}];

            data.picklistFieldValues.GroupType__c.values.forEach(key => {
                groupTypeOptions.push({
                    label : key.label,
                    value: key.value
                })
            });

            this.groupTypeOpt = groupTypeOptions;
            let documentTypeOptions = [{label:'--None--', value:'--None--'}];
            this.controlDocumentTypeValues = data.picklistFieldValues.DocumentType__c.controllerValues;
            this.totalDependentDocumentTypeValues = data.picklistFieldValues.DocumentType__c.values;

            this.totalDependentDocumentTypeValues.forEach(key => {
                documentTypeOptions.push({
                    label : key.label,
                    value: key.value
                })
            });

            this.documentTypeOpt = documentTypeOptions;
            this.getDocumentValue();
        }
        else{
            this.error = error;
        }
    }

    handleChangeGroupType(event){
        let dependValues = [];
        var groupTypeVal = event.currentTarget.value;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.GroupType = groupTypeVal;
                document.DocumentType = null;
                document.DocumentType__c = null;
                if(groupTypeVal){
                    if(groupTypeVal == '--None--'){
                        this.isEmpty = true;
                        dependValues = [{label:'--None--', value:'--None--'}];
                        document.GroupType = null;
                        document.DocumentType = null;
                        document.isGroupEmpty = true;
                        return;
                    }

                    this.totalDependentDocumentTypeValues.forEach(groupTypeVal => {
                        if(groupTypeVal.validFor[0] === this.controlDocumentTypeValues[document.GroupType]){
                            dependValues.push({
                                label : groupTypeVal.label,
                                value : groupTypeVal.value
                            })
                        }
                    })
                    document.DocumentTypeOpt = dependValues;
                    document.isGroupEmpty = false;
                }
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
    }

    handleDependentGroupType(event){
        this.isEmpty = false;
        let dependValues = [];
        this.doc.GroupType = event.Target.value;

        if(groupType){
            if(groupType == '--None--'){
                this.isEmpty = true;
                dependValues = [{label:'--None--', value:'--None--'}];
                this.doc.GroupType = null;
                this.doc.DocumentType = null;
                return;
            }
            this.totalDependentDocumentTypeValues.forEach(groupTypeValues => {
                if(groupTypeValues.validFor[0] === this.controlDocumentTypeValues[this.doc.GroupType]){
                    dependValues.push({
                        label : groupTypeValues.label,
                        value : groupTypeValues.value
                    })
                }
            })
            this.documentTypeOpt = dependValues;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PHASE_FIELD})
    setPhasePicklistOptions({error, data}) {
        if(data){
            this.phaseOpt = data.values;
            this.mapPhase = new Map();

            for(var i = 0; i < data.values.length; i++){
                this.mapPhase.set(data.values[i].value, data.values[i].label);
            }

            this.getDocumentValue();
        }
        else{
            this.error = error;
        }
    }

    handleOpenNewDocumentModal(){
        this.isOpenDocModal = true;
        this.isReplaceButton = false;
        this.documentNames = null;
    }

    handleCloseUploadModal() {
        this.isOpenDocModal = false;
        var lstDeleteDocument = [];

        if(this.isReplaceButton == true){

            for(var i = 0; i < this.uploadedReplaceDoc.length; i++){
                lstDeleteDocument.push(this.uploadedReplaceDoc[i].documentId);

            }

        }
        else{

            for(var i = 0; i < this.uploadedDoc.length; i++){
                lstDeleteDocument.push(this.uploadedDoc[i].documentId);
            }

        }

        deleteContentDocument({ lstDocumentId : lstDeleteDocument})
        .then(result => {
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );        });

        this.uploadedDoc = [];
        this.uploadedReplaceDoc = [];
        this.isReplaceButton = false;
    }

    handleUploadFinished(event){
        this.documentNames = null;
        this.uploadedDoc = event.detail.files;

        for(var i = 0; i < this.uploadedDoc.length; i++){
            if(this.documentNames == null){
                this.documentNames = this.uploadedDoc[i].name + ';';
            }
            else{
                this.documentNames += this.uploadedDoc[i].name + ';';
            }
        }

    }

    handleFilesChange(event){
        if(event.target.files.length > 0) {
            this.uploadedDoc = event.target.files;
            this.documentNames = null;

            for(var i = 0; i < this.uploadedDoc.length; i++){
                if(this.documentNames == null){
                    this.documentNames = this.uploadedDoc[i].name + ';';
                }
                else{
                    this.documentNames += this.uploadedDoc[i].name + ';';
                }
            }

        }
    }
    //MRA W-951 Control on document Name
    checkDocNameIllegalCharacter(lstDoc){
        let lstTitle = [];
        let charIllegal = [];
        let isSpecChar = false;
        let splChars = "*|,\":<>[]{}'\';@&$#%éàè°+=~²§%ù£";
 
        if ( lstDoc.length > 0 ){
            for(let i = 0; i < lstDoc.length; i++){
                let rowData = { ...lstDoc[i]};
                lstTitle.push(rowData.name);
            }

            console.log('lstTitle = ' + lstTitle) ;

            for (let i = 0; i < lstTitle.length; i++) {
                for (let j = 0; j < lstTitle[i].length; j++) {
                    if (splChars.indexOf(lstTitle[i].charAt(j)) != -1) {
                        charIllegal.push(lstTitle[i]);
                        isSpecChar = true;
                    }
                }
            }

            console.log('isSpecChar = ' + isSpecChar) ;

            if (isSpecChar){
                this.dispatchEvent(new ShowToastEvent({mode: 'sticky',title: 'Error name', message: 'Your document uploaded contains at least one of the following characters in its name: *|,":<>[];@&$#%éàè°+=~²§%ù£. Please avoid them otherwise your documents in the Zip file for Reinsurers/Brokers will have technical ID names.', variant: 'error'}), );
            }
            return isSpecChar ;        
        }
    }
    //MRA W-951 Control on document Name
    handleSaveUploadDoc(){
        if(this.isReplaceButton == true){
            if(this.uploadedReplaceDoc.length > 0){
            if (!this.checkDocNameIllegalCharacter(this.uploadedReplaceDoc)) {    //MRA W-951 Control on document Name
                saveReplaceDocument({ documentIdReplace : this.replaceDocumentId, selectedRowContentVersionId : this.currentContentVersionId, selectedDocPicklist : this.selectedDocumentPicklistValues})
                .then(result => {
                    this.isOpenDocModal = false;
                    this.isReplaceButton = false;
                    this.uploadedReplaceDoc = [];

                    var document = {};
                    document['Name'] = result.ContentVersionReplace.Title;
                    document['GroupType'] = result.ContentVersionReplace.GroupType__c;
                    document['DocumentType'] = result.ContentVersionReplace.DocumentType__c;
                    document['Phase'] = result.ContentVersionReplace.Phase__c;
                    document['Checked'] = false;
                    document['Id'] = result.ContentVersionReplace.Id;

                    if(this.phaseOpt != undefined){
                        document['PhaseOptions'] = this.phaseOpt.map(row => {
                        let selected;
                        if(result.ContentVersionReplace.Phase__c != undefined){
                            if(result.ContentVersionReplace.Phase__c.includes(row.value)){
                                selected = true;
                            }
                        }
                        return {...row , selected}});
                    }
                    let dependValues = [];
                    var groupTypeVal = result.ContentVersionReplace.GroupType__c;

                    if(groupTypeVal){

                        this.totalDependentDocumentTypeValues.forEach(groupTypeVal => {
                            if(groupTypeVal.validFor[0] === this.controlDocumentTypeValues[result.ContentVersionReplace.GroupType__c]){
                                dependValues.push({
                                    label : groupTypeVal.label,
                                    value : groupTypeVal.value
                                })
                            }
                        })

                        document['DocumentTypeOpt'] = dependValues;
                    }

                    if(result.ContentVersionReplace.GroupType__c == undefined){
                        document['isGroupEmpty'] = true;
                        document['DocumentTypeOpt'] = [];
                    }
                    else{
                        document['isGroupEmpty'] = false;
                    }
                    this.lstDocuments.push(document);

                    var lstNewDocument = [];

                    for(var i = 0; i < this.lstDocuments.length; i ++){
                        if(this.lstDocuments[i].Id != this.currentContentVersionId){
                            lstNewDocument.push(this.lstDocuments[i]);
                        }
                    }

                    this.lstDocuments = lstNewDocument;
                    this.lstUploadedReplaceDocToDelete.push(result.ContentVersionReplace.ContentDocumentId);
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );              
                });
            }                
            }
        }
        else{
            if(this.uploadedDoc.length > 0){
                if (!this.checkDocNameIllegalCharacter(this.uploadedDoc)) {    //MRA W-951 Control on document Name
                this.uploadHelper();
                }
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Error',mode:'sticky', message:this.label.NoFileIsFound, variant: 'error'}), );
            }
        }
    }

    uploadHelper(){

        for(var i = 0; i < this.uploadedDoc.length; i++){
            this.uploadDocumentDelete.push(this.uploadedDoc[i].documentId);

            getContentVersionId({contentDocumentId : this.uploadedDoc[i].documentId})
            .then(result => {
                var document = {};
                document['Name'] = result.Title;
                document['GroupType'] = '2';
                document['DocumentType'] = '';
                document['Phase'] = '5';
                document['PhaseOptions'] = this.phaseOpt;
                document['Checked'] = false;
                document['Id'] = result.Id;
                document['DocumentTypeOpt'] = [];
                document['isGroupEmpty'] = true;
                document['Viewable'] = true;

                let groupTypeVal = '2';
                let dependValues = [];

                if(groupTypeVal){
                    this.totalDependentDocumentTypeValues.forEach(groupTypeVal => {
                        if(groupTypeVal.validFor[0] === this.controlDocumentTypeValues[document.GroupType]){
                            dependValues.push({
                                label : groupTypeVal.label,
                                value : groupTypeVal.value
                            })
                        }
                    })
                    document.DocumentTypeOpt = dependValues;
                    document.isGroupEmpty = false;
                }
                this.lstDocuments.push(document);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            });

        }

        this.isOpenDocModal = false;
        this.isReplaceButton = false;
        this.uploadedDoc = [];
    }

    handleDeleteDocument(){
        for(var i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Checked == true){
                this.lstSelectedDocument.push(this.lstDocuments[i]);
                this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
            }
        }

        this.lstDocuments = this.lstDocuments.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocument);
    }

    handleCloseDocumentModal(){
        deleteContentDocument({ lstDocumentId : this.uploadDocumentDelete})
        .then(result => {
            this.getDocumentValue();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });

        replaceDocuments({ mapOldDocumentVersion : this.initialDocs, programId : this.valueProgram })
        .then(result => {
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
        fireEvent(this.pageRef, 'closeDocumentModal', false);
    }

    handleSaveDocument(){
        if(this.lstDocuments != undefined){
            var lstSaveDocument = [];

            for (var i = 0; i < this.lstDocuments.length; i++){
                var objDocument = {
                    DocumentType__c : DOCUMENT_TYPE_FIELD,
                    GroupType__c : GROUP_TYPE_FIELD,
                    Phase__c : PHASE_FIELD,
                    Title : TITLE_FIELD,
                    PathOnClient : PATH_ON_CLIENT_FIELD
                }
                objDocument.DocumentType__c = this.lstDocuments[i].DocumentType;
                objDocument.GroupType__c = this.lstDocuments[i].GroupType;
                objDocument.Phase__c = this.lstDocuments[i].Phase;
                objDocument.Title = this.lstDocuments[i].Name;
                objDocument.Id = this.lstDocuments[i].Id;
                objDocument.PathOnClient = this.lstDocuments[i].Name;

                lstSaveDocument.push(objDocument);
            }
            const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);

            if(allValid) {
                saveDocuments({lstContentVersion : lstSaveDocument, programId : this.valueProgram, lstDeletedDocument : this.lstSelectedDeleteDocumentId})
                .then(result => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
                    fireEvent(this.pageRef, 'closeDocumentModal', false);
                    fireEvent(this.pageRef, 'refreshSigningData', false);
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                });
            }
            else{
                //At least one of the field "Group type", "Document type" or "Phase" has not be filled. Please fill it in order to save".
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.DocumentFieldValueMissing, variant: 'error'}),);
            } 
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.NoDocumentAvailable, variant: 'error'}),);
        }
    }

    handleChangeDocumentType(event){
        var documentTypeVal = event.currentTarget.value;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.DocumentType = documentTypeVal;
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
    }

    handleChangePhase(event){
        var phaseVal = event.currentTarget.value;
        var docNameVal = event.currentTarget.name;

        var lstUpdatedDoc = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Phase = phaseVal;
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
    }

    handleChangeDocCheckbox(event){
        var checkboxChecked = event.currentTarget.checked;
        var docNameVal = event.currentTarget.name;

        var lstUpdatedDoc = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Checked = checkboxChecked;
            }
             lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;
    }

    handleOnclickReplace(event){
        this.isReplaceButton = true;
        this.isOpenDocModal = true;
        this.documentNames = '';
        this.currentContentVersionId = event.target.name;

        for(var i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Id == this.currentContentVersionId){
                this.selectedDocumentPicklistValues = this.lstDocuments[i].GroupType + '//' + this.lstDocuments[i].DocumentType + '//' + this.lstDocuments[i].Phase;
            }
        }
    }

    handleUploadReplaceFinished(event){
        this.uploadedReplaceDoc = event.detail.files;
        this.replaceDocumentId = this.uploadedReplaceDoc[0].documentId;
        this.documentNames = this.uploadedReplaceDoc[0].name;
    }


    /*getExternalDocuments(){
        getExternalDocuments({programId : this.valueProgram})
        .then(result => {
             getReinsurerStatusFromRequest({Idprogram : this.valueProgram})
            .then(resultReinsStatus => {
                console.log('lstReinsSta==' , resultReinsStatus);
                this.lstExternalDocuments = [];
                var lstExternalProgramDocuments = result;
                var lstNewDocuments = [];
                this.error = undefined;
                let isAnweredOrRefused=false;


               for(var i = 0; i < resultReinsStatus.length; i++){
                    if (resultReinsStatus[i] == 'Answered' || resultReinsStatus[i] == 'Refused'){
                        isAnweredOrRefused = true;
                    }else {
                        this.lstExternalDocuments = null;
                        console.log('STOP==');
                    }
                
                }

                if (isAnweredOrRefused == true){
                    for(var i = 0; i < lstExternalProgramDocuments.length; i++){
                        console.log('OK ==');
                        let dependValues = [];
                        var document = {};
                        document['Name'] = lstExternalProgramDocuments[i].title;
                        document['Id'] = lstExternalProgramDocuments[i].Id;
                        document['Phase'] = lstExternalProgramDocuments[i].phase;
                        document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ lstExternalProgramDocuments[i].contentDocId+"?operationContext=S1";
                        document['Viewable'] = true;
                        document['FileContent'] = lstExternalProgramDocuments[i].versData;
                        document['ContentDocumentId'] = lstExternalProgramDocuments[i].contentDocId;
                        document['NameBroker'] = lstExternalProgramDocuments[i].broker; //SRA - 1046
                        document['NameReinsurer'] = lstExternalProgramDocuments[i].reinsurer; //SRA - 1046
                        document['CreatedDate'] = lstExternalProgramDocuments[i].dateConv;
                        document['phaseNumber'] = lstExternalProgramDocuments[i].phaseNumber;
                        lstNewDocuments.push(document);
                    }
        
                    this.lstExternalDocuments = lstNewDocuments;
                    console.log('lstExternalDocuments ==' , this.lstExternalDocuments);
        
                    this.sortDataField('NameBroker', 'asc'); //SRA - 1046
                    this.sortDataField('NameReinsurer', 'asc') //SRA - 1046
                    
        
                    if(this.lstExternalDocuments.length > 0){
                        let signingExtDoc = [];
                        let placementExtDoc = [];
                        let leadExtDoc = [];
                        let quoteExtDoc = []
                        let allExtDoc = [];
        
                        for(let i = 0; i < this.lstExternalDocuments.length; i++){
                            let rowDoc = { ...this.lstExternalDocuments[i] };
                            if(rowDoc.Phase == 'Signing'){
                                signingExtDoc.push(rowDoc);
                            }
                            else if(rowDoc.Phase == 'Placement'){
                                placementExtDoc.push(rowDoc);
                            }
                            else if(rowDoc.Phase == 'Lead'){
                                leadExtDoc.push(rowDoc);
                            }
                            else if(rowDoc.Phase == 'Quote'){
                                quoteExtDoc.push(rowDoc);
                            }
                            else if(rowDoc.Phase == 'All'){
                                allExtDoc.push(rowDoc);
                            }         
                        }
        
                        console.log('quoteExtDoc == ', quoteExtDoc);
                        let updSortedLstDoc = [];
        
                        if(signingExtDoc.length > 0){
                            updSortedLstDoc = updSortedLstDoc.concat(signingExtDoc);
                        }
        
                        if(placementExtDoc.length > 0){
                            updSortedLstDoc = updSortedLstDoc.concat(placementExtDoc);
                        }
        
                        if(leadExtDoc.length > 0){
                            updSortedLstDoc = updSortedLstDoc.concat(leadExtDoc);
                        }
        
                        if(quoteExtDoc.length > 0){
                            updSortedLstDoc = updSortedLstDoc.concat(quoteExtDoc);
                        }
        
                        if(allExtDoc.length > 0){
                            updSortedLstDoc = updSortedLstDoc.concat(allExtDoc);
                        }
                        console.log('updSortedLstDocQuote == ', updSortedLstDoc);
        
                        this.lstExternalDocuments = updSortedLstDoc;
                    }
                }
                

        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });

    }*/



    getExternalDocumentVisibility(){
        getExternalDocumentVisibility({programId : this.valueProgram})
        .then(result => {
            this.lstExternalDocument = [];
                var lstExternalProgramDocumentVisibility = result;
                var lstNewDocumentVisibility = [];
                this.error = undefined;
                for(var i = 0; i < lstExternalProgramDocumentVisibility.length; i++){
                    var document = {};
                    document['Name'] =  lstExternalProgramDocumentVisibility[i].Tech_Title__c;
                    document['Id'] = lstExternalProgramDocumentVisibility[i].Id;
                    document['Phase'] = lstExternalProgramDocumentVisibility[i].Tech_LabelPhase__c;
                    document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ lstExternalProgramDocumentVisibility[i].Tech_ContentDocumentId__c+"?operationContext=S1";
                    document['Viewable'] = true;
                    document['ContentDocumentId'] = lstExternalProgramDocumentVisibility[i].Tech_ContentDocumentId__c;
                    document['NameBroker'] = lstExternalProgramDocumentVisibility[i].Tech_BrokerName__c; //SRA - 1046
                    document['NameReinsurer'] = lstExternalProgramDocumentVisibility[i].Tech_ReinsurerName__c; //SRA - 1046
                    document['CreatedDate'] = lstExternalProgramDocumentVisibility[i].Tech_Date__c;
                    document['phaseNumber'] = lstExternalProgramDocumentVisibility[i].Tech_NumberPhase__c;
                    lstNewDocumentVisibility.push(document);
                   
                }
        

                this.lstExternalDocuments = lstNewDocumentVisibility;

                this.sortDataField('NameBroker', 'asc'); //SRA - 1046
                this.sortDataField('NameReinsurer', 'asc') //SRA - 1046

                if(this.lstExternalDocuments.length > 0){
                    let signingExtDoc = [];
                    let placementExtDoc = [];
                    let leadExtDoc = [];
                    let quoteExtDoc = []
                    let allExtDoc = [];
                    for(let i = 0; i < this.lstExternalDocuments.length; i++){
                        let rowDoc = { ...this.lstExternalDocuments[i] };
                        if(rowDoc.Phase == 'Signing'){
                            signingExtDoc.push(rowDoc);
                        }
                        else if(rowDoc.Phase == 'Placement'){
                            placementExtDoc.push(rowDoc);
                        }
                        else if(rowDoc.Phase == 'Lead'){
                            leadExtDoc.push(rowDoc);
                        }
                        else if(rowDoc.Phase == 'Quote'){
                            quoteExtDoc.push(rowDoc);
                        }
                        else if(rowDoc.Phase == 'All'){
                            allExtDoc.push(rowDoc);
                        }             
                    }
    
                    let updSortedLstDoc = [];
    
                    if(signingExtDoc.length > 0){
                        updSortedLstDoc = updSortedLstDoc.concat(signingExtDoc);
                    }
    
                    if(placementExtDoc.length > 0){
                        updSortedLstDoc = updSortedLstDoc.concat(placementExtDoc);
                    }
    
                    if(leadExtDoc.length > 0){
                        updSortedLstDoc = updSortedLstDoc.concat(leadExtDoc);
                    }
    
                    if(quoteExtDoc.length > 0){
                        updSortedLstDoc = updSortedLstDoc.concat(quoteExtDoc);
                    }
    
                    if(allExtDoc.length > 0){
                        updSortedLstDoc = updSortedLstDoc.concat(allExtDoc);
                    }
                    this.lstExternalDocuments = updSortedLstDoc;
                }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });

    }

    // Sort by name Broker / Reinsurer //SRA - 1046
    sortDataField(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.lstExternalDocuments);
        this.lstExternalDocuments = sortResult.sort(function(a,b){
                                        if(a[fieldName] < b[fieldName])
                                            return sortDirection === 'asc' ? -1 : 1;
                                        else if(a[fieldName] > b[fieldName])
                                            return sortDirection === 'asc' ? 1 : -1;
                                        else{
                                            return 0;
                                        }
        })
    }

    //AGRE-CLM : AzharNahoor - 10/07/2023 

    handleViewProgram(){
        this.isLoading = true;
        console.log('handleViewProgram START')
        viewOrCreateAgreement({programId : this.valueProgram, recordTypeId: this.agreementRtSelected})
        .then(result => {
            console.log('handleViewProgram result ', result);
            if(result.isSuccess && result.value != 'createNew'){
                this.isLoading = false;
                this[NavigationMixin.GenerateUrl]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: result.value,
                        actionName: 'view'
                    }
                }).then(url => {
                    window.open(url, "_blank");
                });         
            }
            else if(result.isSuccess && result.value == 'createNew'){
                this.isLoading = false;
                this.openModalRt();
            }
            else{
                console.log('handleViewProgram error ', result.value);
            }
            this.disableBtnModal = false ;
        })
        .catch(error => {
            console.log('handleViewProgram error: ',  error);
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.disableBtnModal = false ;
        });
    }

    handleRenew(){
        this.isLoading = true;
        console.log('handleRenew START')
        renewAgreement({programId : this.valueProgram})
        .then(result => {
            console.log('handleRenew result ', result);
            if(result.isSuccess && result.value != 'NoAgreement'){
                window.open(result.value, "_blank");       
            }
            else if(result.isSuccess && result.value == 'createNew'){
                this.isLoading = false;
                this.openModalRt();
            }
            else{
                console.log('handleRenew error ', result.value);
            }
        })
        .catch(error => {
            console.log('handleRenew error: ',  error);
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }


    inputVariables(){
        console.log('valueprogram : ' , this.valueProgram);
        return [{
            name : "programId",
            type : "String", 
            value : this.valueProgram
        }];
    }


    handleFlowStatusChange(){
        console.log('handleFlowStatusChange: Start');

        console.log('handleFlowStatusChange: End');
    }

    getCongaDocuments(){
        this.isLoading = true;
        getCongaDocs({programId : this.valueProgram})
        .then(result => {
            if(result){
                this.lstCongaDocuments = [];
                var lstCongaProgramDocuments = result;
                var lstNewDocuments = [];
                this.error = undefined;
    
                console.log('getCongaDocuments results ', result);
    
                for(var i = 0; i < lstCongaProgramDocuments.length; i++){
                    var document = {};
                    document['Name'] = lstCongaProgramDocuments[i].Title;
                    document['Id'] = lstCongaProgramDocuments[i].Id;
                    document['GroupType'] = lstCongaProgramDocuments[i].GroupType__c;
                    document['DocType'] = ''; //lstCongaProgramDocuments[i].FileType;
                    document['Phase'] = lstCongaProgramDocuments[i].Phase__c;
                    document['Version'] = lstCongaProgramDocuments[i].TECH_OldVersionNumber__c;
                    document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ lstCongaProgramDocuments[i].ContentDocumentId+"?operationContext=S1";
                    document['Viewable'] = true;
                    document['FileContent'] = lstCongaProgramDocuments[i].VersionData;
                    document['ContentDocumentId'] = lstCongaProgramDocuments[i].ContentDocumentId;
    
                    lstNewDocuments.push(document);
                }
    
                if(lstNewDocuments.length > 0){
                    this.lstCongaDocuments = lstNewDocuments;
                }
                console.log('getCongaDocuments lstCongaDocuments ', this.lstCongaDocuments);
            }

            this.isLoading = false;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            this.isLoading = false;
        });
    }

    getTHEMISDocuments(){
        getTHEMISDocuments({programId : this.valueProgram})
        .then(result => {
            this.lstTHEMISDocuments = [];
            var lstTHEMISProgramDocuments = result;
            var lstNewDocuments = [];
            this.error = undefined;

            for(var i = 0; i < lstTHEMISProgramDocuments.length; i++){
                var document = {};
                document['Name'] = lstTHEMISProgramDocuments[i].Title;
                document['Id'] = lstTHEMISProgramDocuments[i].Id;
                document['GroupType'] = lstTHEMISProgramDocuments[i].GroupType__c;
                document['DocType'] = ''; //lstTHEMISProgramDocuments[i].DocumentType__c;
                document['Phase'] = lstTHEMISProgramDocuments[i].Phase__c;
                document['Version'] = lstTHEMISProgramDocuments[i].Version__c;
                document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ lstTHEMISProgramDocuments[i].ContentDocumentId+"?operationContext=S1";
                document['Viewable'] = true;
                document['FileContent'] = lstTHEMISProgramDocuments[i].VersionData;
                document['ContentDocumentId'] = lstTHEMISProgramDocuments[i].ContentDocumentId;

                lstNewDocuments.push(document);
            }

            this.lstTHEMISDocuments = lstNewDocuments;

            if(this.lstTHEMISDocuments.length > 0){
                let signingExtDoc = [];
                let placementExtDoc = [];
                let leadExtDoc = [];
                let quoteExtDoc = []
                let allExtDoc = [];

                for(let i = 0; i < this.lstTHEMISDocuments.length; i++){
                    let rowDoc = { ...this.lstTHEMISDocuments[i] };
                    if(rowDoc.Phase == 'Signing'){
                        signingExtDoc.push(rowDoc);
                    }
                    else if(rowDoc.Phase == 'Placement'){
                        placementExtDoc.push(rowDoc);
                    }
                    else if(rowDoc.Phase == 'Lead'){
                        leadExtDoc.push(rowDoc);
                    }
                    else if(rowDoc.Phase == 'Quote'){
                        quoteExtDoc.push(rowDoc);
                    }
                    else if(rowDoc.Phase == 'All'){
                        allExtDoc.push(rowDoc);
                    }
                }               

                let updSortedLstDoc = [];

                if(signingExtDoc.length > 0){
                    updSortedLstDoc = updSortedLstDoc.concat(signingExtDoc);
                }

                if(placementExtDoc.length > 0){
                    updSortedLstDoc = updSortedLstDoc.concat(placementExtDoc);
                }

                if(leadExtDoc.length > 0){
                    updSortedLstDoc = updSortedLstDoc.concat(leadExtDoc);
                }

                if(quoteExtDoc.length > 0){
                    updSortedLstDoc = updSortedLstDoc.concat(quoteExtDoc);
                }

                if(allExtDoc.length > 0){
                    updSortedLstDoc = updSortedLstDoc.concat(allExtDoc);
                }
                
                this.lstTHEMISDocuments = updSortedLstDoc;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });

    }

    navigateToFiles(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId:event.currentTarget.dataset.id
            }
          })
    }

    getDocumentValue(){
        getDocuments({programId : this.valueProgram})
        .then(result => {
            this.lstDocuments = [];
            var lstProgramDocuments = result;
            this.error = undefined;
            var lstNewDocuments = [];

            var hostname = window.location.hostname;
            var arr = hostname.split(".");
            var instance = arr[0];


            for(var i = 0; i < lstProgramDocuments.length; i++){
                let dependValues = [];
                var document = {};
                document['Name'] = lstProgramDocuments[i].Title;
                document['Id'] = lstProgramDocuments[i].Id;
                document['GroupType'] = lstProgramDocuments[i].GroupType__c;
                document['DocumentType'] = lstProgramDocuments[i].DocumentType__c;
                document['DocumentTypeLabel'] = this.mapDocType.get(lstProgramDocuments[i].DocumentType__c);
                document['Phase'] = lstProgramDocuments[i].Phase__c;
                document['DocumentUrl'] = "/sfc/servlet.shepherd/document/download/"+ lstProgramDocuments[i].ContentDocumentId+"?operationContext=S1";


                document['Viewable'] = true;
                if(this.phaseOpt != undefined){
                    document['PhaseOptions'] = this.phaseOpt.map(row => {
                    let selected;
                    if(lstProgramDocuments[i].Phase__c != undefined){
                        if(lstProgramDocuments[i].Phase__c.includes(row.value)){
                            selected = true;
                        }
                    }
                    return {...row , selected}});
                }
                document['FileContent'] = lstProgramDocuments[i].VersionData;
                document['Checked'] = false;
                var groupTypeVal = lstProgramDocuments[i].GroupType__c;

                if(groupTypeVal){
                    this.totalDependentDocumentTypeValues.forEach(groupTypeVal => {
                        if(groupTypeVal.validFor[0] === this.controlDocumentTypeValues[lstProgramDocuments[i].GroupType__c]){
                            dependValues.push({
                                label : groupTypeVal.label,
                                value : groupTypeVal.value
                            })
                        }
                    })
                    document['DocumentTypeOpt'] = dependValues;
                }

                if(lstProgramDocuments[i].GroupType__c == undefined){
                    document['isGroupEmpty'] = true;
                }
                else{
                    document['isGroupEmpty'] = false;
                }
                lstNewDocuments.push(document);
            }
            this.lstDocuments = lstNewDocuments;

            let lstContractualDoc = [];
            let lstRenewalDoc = [];
            let lstUpdSortedDoc = [];

            for(let i = 0; i < this.lstDocuments.length; i++){
                let rowDoc = { ...this.lstDocuments[i] };
                if(rowDoc.GroupType == '1'){
                    lstContractualDoc.push(rowDoc);
                }
                else if(rowDoc.GroupType == '2'){
                    lstRenewalDoc.push(rowDoc);
                }
            }

            if(lstContractualDoc.length > 0){
                let signingIntDoc = [];
                let placementIntDoc = [];
                let leadIntDoc = [];
                let quoteIntDoc = []
                let allIntDoc = [];

                for(let i = 0; i < lstContractualDoc.length; i++){
                    let rowConDoc = { ...lstContractualDoc[i] };
                    if(rowConDoc.Phase == '4'){
                        signingIntDoc.push(rowConDoc);
                    }
                    else if(rowConDoc.Phase == '2'){
                        placementIntDoc.push(rowConDoc);
                    }
                    else if(rowConDoc.Phase == '3'){
                        leadIntDoc.push(rowConDoc);
                    }
                    else if(rowConDoc.Phase == '1'){
                        quoteIntDoc.push(rowConDoc);
                    }
                    else if(rowConDoc.Phase == '5'){
                        allIntDoc.push(rowConDoc);
                    }         
                }

                let updLstConDoc = [];

                if(signingIntDoc.length > 0){
                    updLstConDoc = updLstConDoc.concat(signingIntDoc);
                }

                if(placementIntDoc.length > 0){
                    updLstConDoc = updLstConDoc.concat(placementIntDoc);
                }

                if(leadIntDoc.length > 0){
                    updLstConDoc = updLstConDoc.concat(leadIntDoc);
                }

                if(quoteIntDoc.length > 0){
                    updLstConDoc = updLstConDoc.concat(quoteIntDoc);
                }

                if(allIntDoc.length > 0){
                    updLstConDoc = updLstConDoc.concat(allIntDoc);
                }

                lstUpdSortedDoc = lstUpdSortedDoc.concat(updLstConDoc);
            }

            if(lstRenewalDoc.length > 0){
                lstRenewalDoc = this.sortData('DocumentTypeLabel', 'asc', lstRenewalDoc);
                lstUpdSortedDoc = lstUpdSortedDoc.concat(lstRenewalDoc);
            }

            this.lstDocuments = lstUpdSortedDoc;
            
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    handleOnItemSelected (event) {
        let closestTr = event.target.closest('tr');
        let trId = closestTr.id;
        let trArr = trId.split('-');
        let selectedPhases = '';

        if (event.detail) {
            this.yourSelectedValues = '';
            let self = this;

            event.detail.forEach (function (eachItem) {
                selectedPhases += eachItem.value + ';';
            });

            var lstUpdatedDoc = [];

            for(var i = 0; i < this.lstDocuments.length; i++){
                var document = this.lstDocuments[i];
                if(this.lstDocuments[i].Id == trArr[0]){
                    document.Phase = selectedPhases;
                }
                lstUpdatedDoc.push(document);
            }

            this.lstDocuments = lstUpdatedDoc;
        }
    }

    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        lstData = sortResult.sort(function(a,b){
            let fieldA = a[fieldName].toLowerCase();
            let fieldB = b[fieldName].toLowerCase();
            if(fieldA < fieldB)
                return sortDirection === 'asc' ? -1 : 1;
            else if(fieldA > fieldB)
                return sortDirection === 'asc' ? 1 : -1;
            else{
                return 0;
            }
        })
        return lstData;
    }

}