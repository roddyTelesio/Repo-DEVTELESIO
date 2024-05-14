/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   26-10-2023   Patrick Randrianarisoa   Initial Version
**/
import {LightningElement, track, wire, api} from 'lwc';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {registerListener, fireEvent} from 'c/pubSub';
import {refreshApex} from '@salesforce/apex';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import saveDocuments from '@salesforce/apex/LWC28_PortalDocuments.saveDocuments';
import getDocuments from '@salesforce/apex/LWC28_PortalDocuments.getDocuments';
import getContentVersionId from '@salesforce/apex/LWC28_PortalDocuments.getContentVersionId';
import retrieveNameBrokerReinsurer from '@salesforce/apex/LWC28_PortalDocuments.retrieveNameBrokerReinsurer';
import deleteContentDocument from '@salesforce/apex/LWC28_PortalDocuments.deleteContentDocument';
import saveReplaceDocument from '@salesforce/apex/LWC28_PortalDocuments.saveReplaceDocument';
import getInitialDocuments from '@salesforce/apex/LWC28_PortalDocuments.getInitialDocuments';
import replaceDocuments from '@salesforce/apex/LWC28_PortalDocuments.replaceDocuments';
import deleteContentVersionDocument from '@salesforce/apex/LWC28_PortalDocuments.deleteContentVersionDocument';
//import deleteContentVersionDocumentOld from '@salesforce/apex/LWC28_PortalDocuments.deleteContentVersionDocumentOld';
import deleteDocVisibilityDocument from '@salesforce/apex/LWC28_PortalDocuments.deleteDocVisibilityDocument';

//import object and fields
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import GROUP_TYPE_FIELD from '@salesforce/schema/ContentVersion.GroupType__c';
import IS_EXTERNAL_FIELD from '@salesforce/schema/ContentVersion.IsExternal__c';
import DOCUMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.DocumentType__c';
import CONTENT_DOCMENT_ID from '@salesforce/schema/ContentVersion.ContentDocumentId';
import BROKER_TYPE_FIELD from '@salesforce/schema/ContentVersion.Tech_BrokerId__c';
import REINSURER_TYPE_FIELD from '@salesforce/schema/ContentVersion.Tech_ReinsurerId__c';
import BROKER_TYPE_NAME_FIELD from '@salesforce/schema/ContentVersion.Tech_BrokerName__c';
import REINSURER_TYPE_NAME_FIELD from '@salesforce/schema/ContentVersion.Tech_ReinsurerName__c';
//import CREATED_DATE from '@salesforce/schema/ContentVersion.CreatedDate';
import PHASE_FIELD from '@salesforce/schema/ContentVersion.Phase__c';
import FILE_EXTENSION_FIELD from '@salesforce/schema/ContentVersion.FileExtension';
import FILE_TYPE_FIELD from '@salesforce/schema/ContentVersion.FileType';
import TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import PATH_ON_CLIENT_FIELD from '@salesforce/schema/ContentVersion.PathOnClient';
import CREATEDDATE from '@salesforce/schema/ContentVersion.CreatedDate';
import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';

//import custom label
import NoFileIsFound from '@salesforce/label/c.NoFileIsFound';
import DeleteDocumentSucessMsg from '@salesforce/label/c.DeleteDocumentSucessMsg';
import DocumentSavedSuccessMsg from '@salesforce/label/c.DocumentSavedSuccessMsg';

export default class LWC28_PortalDocuments extends NavigationMixin(LightningElement) {

    label = {
        NoFileIsFound,
        DeleteDocumentSucessMsg,
        DocumentSavedSuccessMsg,
    }
    
    @api uwYear;
    @api principalCedingCompany;
    @api valueProgram;
    @api valueReinsurer;
    @api programOptions;
    @api valIsBroker = false;
    @api stage;
    @api flagDoc;
    @api answerPagesSection = false;
    @api disableDocBtns = false;
    @api disableDocNewButton = false;
    @api disableDocDeleteBtn = false;
    @track groupTypeOpt = [];
    @track documentTypeOpt = [];
    @track lstDocuments = [];
    @track lstInitDocuments = [];
    //@track lstDocumentsOld = [];
    @track lstDocumentVisibility = [];
    @track lstDocumentVisibilityOld = [];
    @track lstAXADocuments = [];
    @track lstSelectedDocument = [];
    @track lstSelectedDeleteDocumentId = [];
    //@track lstSelectedDocumentOld = [];
    //@track lstSelectedDeleteDocumentIdOld = [];
    @track lstSelectedDocumentVisibility = [];
    @track lstSelectedDocumentVisibilityOld = [];
    @track lstSelectedDeleteDocumentVisibilityId = [];
    @track lstSelectedDeleteDocumentVisibilityIdOld = [];
    @track uploadedReplaceDocId = [];
    @track lstUploadedReplaceDocToDelete = [];
    @track uploadDocumentDelete = [];
    @api selectedBroker; //SRA - 1046
    @api selectedBrokerId; //SRA - 1046
    @api selectedReinsurerId = null; //SRA - 1046
    @api selectedReinsurer; //SRA - 1046
    @api selectedBrokerName = null; //SRA - 1046
    @api selectedReinsurerName = null; //SRA - 1046
    @api selectedIdRequest = null; //SRA - 1046
    @api selectedPhase = null; //SRA - 939
    @api selectedPhaseSigning = null;
    @api readOnlyCheckbox =false;
    @api selectedProgram = null; 
    @api selectedContentVersionId = null; 
    @api lstUploadFileId = []; 

    isOpenDocModal = false;
    phaseOpt;
    documentNames;
    spinner = false;
    uploadedDoc;
    isEmpty = true;
    currentContentVersionId;
    uploadedReplaceDoc;
    replaceDocumentId;
    selectedDocumentPicklistValues;
    disableDeleteBtn = true;
    initialDocs;
    phaseValue = null;
    mapPhase = new Map();
    controlDocumentTypeValues;
    totalDependentDocumentTypeValues = [];
    fileReader;
    wiredLstDocument;
    lstReqId = [];

    //AMI 18/07/22: W-0951 Portail - transversal - Possibilité de télécharger tous les documents AXA à la fois"
    //              Exposed properties to enable/disable download button
    disableDownloadAll = true;

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
        objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        let url = this.pageRef.state;
        let param = 'c__details';
        let paramValue = null;

        if(url != undefined && url != null){
            paramValue = url[param];
        }
        if(paramValue != null){
            let parameters = paramValue.split("-");
            this.selectedProgram = parameters[0];
            
            // SRA - 1046 - Bug Signing when click on button Open
            if (paramValue.includes('Signing')){
                if(parameters[1] != 'null' && parameters[1] != 'undefined'){
                    this.selectedIdRequest = parameters[1];
                }
                if(parameters[2] != 'null' && parameters[2] != 'undefined'){
                    this.selectedPhaseSigning = parameters[2];
                }
            }   
             else if (paramValue.includes('Quote') || paramValue.includes('Lead') || paramValue.includes('Placement')){
                if(parameters[1] != 'null' && parameters[1] != 'undefined'){
                    this.selectedReinsurer = parameters[1];
                }else{
                    this.selectedReinsurer = null;
                }
                if(parameters[2] != 'null' && parameters[2] != 'undefined'){
                    this.selectedBroker = parameters[2];
                }else{
                    this.selectedBroker = null;
                }

                if(parameters[3] != 'null' && parameters[3] != 'undefined'){
                    this.selectedPhase = parameters[3];
                }
                if(parameters[4] != 'null' && parameters[4] != 'undefined'){
                    this.selectedIdRequest = parameters[4];
                }
            }
        }

        getInitialDocuments({programId : this.valueProgram})
        .then(result => {
            this.initialDocs = result;
        })
        .catch(error => {
           
        });

        /*getNameBrokerReinsurer({programId : this.valueProgram, idBroker : this.selectedBroker, IdReinsurer : this.selectedReinsurer})
        .then(result => { 
            this.selectedBrokerName = result[0].broker;
            this.selectedReinsurerName = result[0].reinsurer;
            this.selectedBrokerId = result[0].brokerId;
            console.log('this.resultNameBrokerReinsurer222222 == ', result);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });ù*/
    

        if(this.disableDocDeleteBtn == true){
            this.disableDeleteBtn = true;
        }

        registerListener('filterProgram', this.getProgram, this);
        
        //this.updateDocumentValue();
        //this.getNameBrokerReinsurer();
        console.log('PRA here');
        this.getDocumentValue();
    }

    getProgram(val){
        if(val != null){
            this.valueProgram = val.Id;
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
        var lstUpdatedDocFile = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.GroupType = groupTypeVal;
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


        for(var i = 0; i < this.uploadedDoc.length; i++){
            var document = this.uploadedDoc[i];
            if(this.uploadedDoc[i].Id == docNameVal){
                document.GroupType = groupTypeVal;
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
            lstUpdatedDocFile.push(document);
        }

        this.uploadedDoc = lstUpdatedDocFile
        

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
        this.documentNames = null;
    }

    handleCloseUploadModal() {
        this.isOpenDocModal = false;
        var lstDeleteDocument = [];

        if(this.uploadedReplaceDoc.length > 0){
            for(var i = 0; i < this.uploadedDoc.length; i++){
                lstDeleteDocument.push(this.uploadedDoc[i].documentId);
            }
        }

        deleteContentDocument({ lstDocumentId : lstDeleteDocument})
        .then(result => {
            //Delete Successful
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });

        this.uploadedDoc = [];
        this.uploadedReplaceDoc = [];
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

    handleSaveUploadDoc(){
        if(this.uploadedDoc.length > 0){
            this.uploadHelper();
        }
        else{
            this.dispatchEvent(new ShowToastEvent({title: 'Error OO', message:this.label.NoFileIsFound, variant: 'error'}), );
        }
    }

    uploadHelper(){
        let lstUploadedDocId = [];
        let lstUploadedDocCVId = [];
        for(var i = 0; i < this.uploadedDoc.length; i++){
            lstUploadedDocId.push(this.uploadedDoc[i].documentId);
            lstUploadedDocCVId.push(this.uploadedDoc[i].contentVersionId)
            this.selectedContentVersionId = lstUploadedDocCVId;
        }


        if(this.stage == 'Quote'){
            this.phaseValue = '1';
        }
        else if(this.stage == 'Placement'){
            this.phaseValue = '2';
        }
        else if(this.stage == 'Lead'){
            this.phaseValue = '3';
        }
        else if(this.stage == 'Signing'){
            this.phaseValue = '4';
        }

        //SRA - 1046
        retrieveNameBrokerReinsurer({idRequest : this.selectedIdRequest})
        .then(result => { 
            /*this.selectedBrokerName = result[0].broker;
            this.selectedReinsurerName = result[0].reinsurer;
            this.selectedBrokerId = result[0].brokerId;*/
            this.selectedBrokerId = result.nameBroId;
            this.selectedReinsurerId = result.nameReinsId;
            this.selectedReinsurer = result.nameReinsId;
            this.selectedBrokerName = result.nameBro;
            this.selectedReinsurerName = result.nameReins;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });
    

        getContentVersionId({lstContentDocumentId : lstUploadedDocId})
        .then(result => {
            let lstUploadedContentVersion = result;
            for(let i = 0; i < result.length; i++){
                //this.selectedCreatedDate = result[i].CreatedDate;
                var document = {};
                document['Name'] = result[i].Title;
                //document['Broker'] =  this.selectedBroker;
                //document['Reinsurer'] = this.selectedReinsurer;
                document['BrokerName'] =  this.selectedBrokerName; //SRA - 1046
                document['ReinsurerName'] = this.selectedReinsurerName; //SRA - 1046
                document['ContentDocumentId'] = result[i].ContentDocumentId;
                document['GroupType'] = '';
                document['DocumentType'] = '';
                document['Phase'] = this.phaseValue;
                document['PhaseOptions'] = this.phaseOpt;
                document['Checked'] = false;
                document['Id'] = result[i].Id;
                document['DocumentTypeOpt'] = [];
                document['isGroupEmpty'] = true;
                document['Viewable'] = true;
                document['DocumentUrl']="../s/contentdocument/"+ result[i].ContentDocumentId;
                this.lstDocuments.push(document);
            }
            this.handleSaveDocument();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });

        this.isOpenDocModal = false;
        //this.uploadedDoc = [];
    }

    handleDeleteDocument(){
        let selectedDocumentToDelete = [];
        let selectedDocumentToDeleteOld = [];
        let selectedDocumentToDeleteInit = [];
        let selectedDocumentVisibilityToDelete = [];
        let selectedDocumentVisibilityToDeleteOld = [];
        this.disableDeleteBtn = true;
        for(var i = 0; i < this.lstDocuments.length; i++){
            if(this.lstDocuments[i].Checked == true){
                this.lstSelectedDocument.push(this.lstDocuments[i]);
                this.lstSelectedDeleteDocumentId.push(this.lstDocuments[i].Id);
                selectedDocumentToDelete.push(this.lstDocuments[i].Id);
            }
        }
        this.lstDocuments = this.lstDocuments.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocument);

        /*for(var i = 0; i < this.lstDocumentsOld.length; i++){
            if(this.lstDocumentsOld[i].Checked == true){
                this.lstSelectedDocumentOld.push(this.lstDocumentsOld[i]);
                this.lstSelectedDeleteDocumentIdOld.push(this.lstDocumentsOld[i].Id);
                selectedDocumentToDeleteOld.push(this.lstDocumentsOld[i].Id);
            }
        }

        this.lstDocumentsOld = this.lstDocumentsOld.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocumentOld)*/


        // 1045 - manage to delete docvisibility
        for(var i = 0; i < this.lstDocumentVisibility.length; i++){
            if(this.lstDocumentVisibility[i].Checked == true){
                this.lstSelectedDocumentVisibility.push(this.lstDocumentVisibility[i]);
                this.lstSelectedDeleteDocumentVisibilityId.push(this.lstDocumentVisibility[i].Id);
                selectedDocumentVisibilityToDelete.push(this.lstDocumentVisibility[i].Id);
            }
        }
        this.lstDocumentVisibility = this.lstDocumentVisibility.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocumentVisibility); // 1045 - delete docvisibility

        // Old DocumentVisibility
        for(var i = 0; i < this.lstDocumentVisibilityOld.length; i++){
            if(this.lstDocumentVisibilityOld[i].Checked == true){
                this.lstSelectedDocumentVisibilityOld.push(this.lstDocumentVisibilityOld[i]);
                this.lstSelectedDeleteDocumentVisibilityIdOld.push(this.lstDocumentVisibilityOld[i].Id);
                selectedDocumentVisibilityToDeleteOld.push(this.lstDocumentVisibilityOld[i].Id);
            }
        }
        this.lstDocumentVisibilityOld = this.lstDocumentVisibilityOld.filter( function(e) { return this.indexOf(e) < 0; }, this.lstSelectedDocumentVisibilityOld);

        deleteContentVersionDocument({ lstDeletedDocument : selectedDocumentToDelete})
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DeleteDocumentSucessMsg, variant: 'success' }),);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });


        // Manage to delete Old Documents - 1046        
        /*deleteContentVersionDocumentOld({ lstDeletedDocumentOld : selectedDocumentToDeleteOld})
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DeleteDocumentSucessMsg, variant: 'success' }),);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });*/

        // Manage Document visibility 1045
       deleteDocVisibilityDocument({ lstDeletedDocument : selectedDocumentVisibilityToDelete, ProgramId : this.valueProgram})
        .then(result => {
            //this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Doc Visibility Deleted', variant: 'success' }),);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });

        deleteDocVisibilityDocumentOld({ lstDeletedDocumentOld : selectedDocumentVisibilityToDeleteOld, ProgramId : this.valueProgram})
        .then(result => {
            //this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Doc Visibility Deleted', variant: 'success' }),);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });
    }

    handleCloseDocumentModal(){
        deleteContentDocument({ lstDocumentId : this.uploadDocumentDelete})
        .then(result => {
            this.getDocumentValue();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });

        replaceDocuments({ mapOldDocumentVersion : this.initialDocs, programId : this.valueProgram })
        .then(result => {
            //Replace Document Successful
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });

        fireEvent(this.pageRef, 'closeDocumentModal', false);
    }

    handleSaveDocument(){
        if(this.uploadedDoc != undefined){

        retrieveNameBrokerReinsurer({idRequest : this.selectedIdRequest})
        .then(result => { 
            this.selectedBrokerId = result.nameBroId;
            this.selectedReinsurerId = result.nameReinsId;
            this.selectedBrokerName = result.nameBro;
            this.selectedReinsurerName = result.nameReins;

            var lstSaveDocument = [];
            for (var i = 0; i < this.uploadedDoc.length; i++){
                var objDocument = {
                    DocumentType__c : DOCUMENT_TYPE_FIELD,
                    ContentDocumentId : CONTENT_DOCMENT_ID,
                    Tech_BrokerId__c : BROKER_TYPE_FIELD,
                    Tech_ReinsurerId__c : REINSURER_TYPE_FIELD,
                    Tech_BrokerName__c : BROKER_TYPE_NAME_FIELD,
                    Tech_ReinsurerName__c : REINSURER_TYPE_NAME_FIELD,
                    GroupType__c : GROUP_TYPE_FIELD,
                    Phase__c : PHASE_FIELD,
                    Title : TITLE_FIELD,
                    IsExternal__c : IS_EXTERNAL_FIELD,
                    PathOnClient : PATH_ON_CLIENT_FIELD,
                    CreatedDate : CREATEDDATE
                }

                objDocument.DocumentType__c = this.uploadedDoc[i].DocumentType__c;
                objDocument.ContentDocumentId = this.uploadedDoc[i].documentId;
                objDocument.GroupType__c =this.uploadedDoc[i].GroupType__c;;
                objDocument.Phase__c = this.phaseValue;
                objDocument.Title = this.uploadedDoc[i].name;
                objDocument.Id = this.uploadedDoc[i].contentVersionId;
                objDocument.Tech_BrokerId__c =  this.selectedBrokerId; 
                objDocument.Tech_ReinsurerId__c = this.selectedReinsurerId;
                objDocument.Tech_BrokerName__c =  this.selectedBrokerName; 
                objDocument.Tech_ReinsurerName__c = this.selectedReinsurerName;
                objDocument.IsExternal__c = true;
                objDocument.PathOnClient = this.uploadedDoc[i].name;
                objDocument.CreatedDate = this.lstDocuments[i].CreatedDate;
                lstSaveDocument.push(objDocument);
                
            }
            saveDocuments({lstContentVersion : lstSaveDocument, programId : this.selectedProgram})
            .then(result => {
                if (result.Success = 'Success'){
                    //this.updateDocumentValue();                     
                    this.getDocumentValue(); //SRA - 1046 get list doc with updated with name broker and reisurer
                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
                }            
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR SAVE' , message: error.message, variant: 'error'}),);
            });

        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error NAME BROKE REINSURER', message: error.message, variant: 'error'}), );
        });

           
        }
    }

    //SRA - 1046
    /*updateDocumentValue() {
        getNameBrokerReinsurer({programId : this.valueProgram, idBroker : this.selectedBroker, IdReinsurer : this.selectedReinsurer})
        .then(result => { 
            this.selectedBrokerId = result[0].brokerId;
            console.log('selectedContentVersionId== ',this.selectedContentVersionId)
            updateIdNameBrokerReinsurer({lstContenVersonId: this.selectedContentVersionId, programId : this.valueProgram, idBroker : this.selectedBrokerId, IdReinsurer : this.selectedReinsurer})
            .then(result => { 
                //this.dispatchEvent(new ShowToastEvent({title: 'Update Success', message: this.label.DocumentSavedSuccessMsg, variant: 'success' }),);
                console.log('UpdateDocument===', result);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error update', message: error.message, variant: 'error'}), );
            });

        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );
        });
        
    }*/

    handleChangeDocumentType(event){
        var documentTypeVal = event.currentTarget.value;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];
        var lstUpdatedDocFile = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.DocumentType = documentTypeVal;
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;

        for(var i = 0; i < this.uploadedDoc.length; i++){
            var document = this.uploadedDoc[i];
            if(this.uploadedDoc[i].Id == docNameVal){
                document.DocumentType = documentTypeVal;
            }
            lstUpdatedDocFile.push(document);
        }

        this.uploadedDoc = lstUpdatedDocFile;
    }

    handleChangePhase(event){
        var phaseVal = event.currentTarget.value;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];
        var lstUpdatedDocFile = [];

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Phase = phaseVal;
            }
            lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;

        for(var i = 0; i < this.uploadedDoc.length; i++){
            var document = this.uploadedDoc[i];
            if(this.uploadedDoc[i].Id == docNameVal){
                document.Phase = phaseVal;
            }
            lstUpdatedDocFile.push(document);
        }

        this.uploadedDoc = lstUpdatedDoc;
    }

    handleChangeDocCheckbox(event){
        var checkboxChecked = event.currentTarget.checked;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];
        var lstUpdatedDocFile = [];
        var numOfDocChecked = 0;

        for(var i = 0; i < this.lstDocuments.length; i++){
            var document = this.lstDocuments[i];
            if(this.lstDocuments[i].Id == docNameVal){
                document.Checked = checkboxChecked;
                if(document.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
             lstUpdatedDoc.push(document);
        }

        this.lstDocuments = lstUpdatedDoc;


        for(var i = 0; i < this.uploadedDoc.length; i++){
            var document = this.uploadedDoc[i];
            if(this.uploadedDoc[i].Id == docNameVal){
                document.Checked = checkboxChecked;
                if(document.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
            lstUpdatedDocFile.push(document);
        }

        this.uploadedDoc = lstUpdatedDocFile;

        if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
        }
    }

    handleChangeDocVsibilityCheckbox(event){
        var checkboxChecked = event.currentTarget.checked;
        var docNameVal = event.currentTarget.name;
        var lstUpdatedDoc = [];
        var numOfDocChecked = 0;

        for(var i = 0; i < this.lstDocumentVisibility.length; i++){
            var document = this.lstDocumentVisibility[i];
            if(this.lstDocumentVisibility[i].Id == docNameVal){
                document.Checked = checkboxChecked;
                if(document.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
             lstUpdatedDoc.push(document);
        }

        this.lstDocumentVisibility = lstUpdatedDoc;

        if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
        }
    }
    
    //Checkbox checked or no for Old Doc visibility file
    handleChangeDocVsibilityCheckboxOld(event){
        var checkboxChecked = event.currentTarget.checked;
        var docNameValOld = event.currentTarget.name;
        var lstUpdatedDocOld = [];
        var numOfDocChecked = 0;

        for(var i = 0; i < this.lstDocumentVisibilityOld.length; i++){
            var documentOld = this.lstDocumentVisibilityOld[i];
            if(this.lstDocumentVisibilityOld[i].Id == docNameValOld){
                documentOld.Checked = checkboxChecked;
                if(documentOld.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
            lstUpdatedDocOld.push(documentOld);
        }

        this.lstDocumentVisibilityOld = lstUpdatedDocOld;

        if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
        }
    }

    //Checkbox checked or no for Old Doc file  - 1046
    /*handleChangeDocOldCheckbox(event){
        var checkboxChecked = event.currentTarget.checked;
        var docNameValOld = event.currentTarget.name;
        var lstUpdatedDocOld = [];
        var numOfDocChecked = 0;

        for(var i = 0; i < this.lstDocumentsOld.length; i++){
            var documentOld = this.lstDocumentsOld[i];
            if(this.lstDocumentsOld[i].Id == docNameValOld){
                documentOld.Checked = checkboxChecked;
                if(documentOld.Checked == true){
                    numOfDocChecked = numOfDocChecked + 1;
                }
            }
            lstUpdatedDocOld.push(documentOld);
        }

        this.lstDocumentsOld = lstUpdatedDocOld;

        if(numOfDocChecked > 0){
            this.disableDeleteBtn = false;
        }
        else{
            this.disableDeleteBtn = true;
        }
    }*/
    
    callGetDocumentValue(){
       
}

    getDocumentValue(){  
            //****************************************************************/
             // Get name broker and Reinsurer for Quote/Lead/Placement/Signing
             //***************************************************************/
            let value;
            let brokerExist = this.selectedBroker;
             retrieveNameBrokerReinsurer({idRequest : this.selectedIdRequest})
             .then(result => {
                let value = this.selectedBroker;
                 this.selectedBrokerId = result.nameBroId;
                 this.selectedReinsurer = result.nameReinsId;

                 this.selectedBrokerId  = (this.selectedBrokerId == 'undefined' || this.selectedBrokerId == undefined) ? this.selectedBroker  :  this.selectedBrokerId;
                 this.selectedReinsurer = (this.selectedReinsurer == 'undefined' || this.selectedReinsurer == undefined) ? this.valueReinsurer :  this.selectedReinsurer;

                getDocuments({ programId : this.valueProgram, reinsurerId : this.valueReinsurer, idBroker : this.selectedBrokerId, IdReinsurer : this.selectedReinsurer})
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error Result',
                                message: result.Error,
                                variant: 'error'
                            }),
                        );
                    }
                    else{
                        this.spinner = true;   
                        this.flagDoc=false; 
                        let lstContentVersionIntern = result.lstConvInternal;
                        let test = result.lstVisibilityDocument;
                        let mapDocumentDateByContentVersionId = [];
                        mapDocumentDateByContentVersionId = result.mapDocumentDateByContentVersionId;
            
                        let mapCreatedDateContentVersionId = [];
                        mapCreatedDateContentVersionId = result.mapCreatedDateContentVersionId;
            
                        //let mapCreatedDateContentVersionOldId = [];
                        //mapCreatedDateContentVersionOldId = result.mapCreatedDateContentVersionOldId;
            
                        if(result.lstConvInternal != undefined){
                            let lstProgramDocumentsInternal = result.lstConvInternal;
                            let lstNewDocumentsInternal = [];
                            console.log('PRA lstProgramDocumentsInternal'+lstProgramDocumentsInternal);
                            console.log('PRA lstProgramDocumentsInternal length'+lstProgramDocumentsInternal.length);
                            for(let i = 0; i < lstProgramDocumentsInternal.length; i++){
                                    let document = { ...lstProgramDocumentsInternal[i] };
                                    document['DocumentUrl']="../sfc/servlet.shepherd/version/download/"+ lstProgramDocumentsInternal[i].Id+"?operationContext=S1";
                                    document['Viewable'] = true;
                                    document['FileContent'] = lstProgramDocumentsInternal[i].VersionData;
                                    document['Name'] = lstProgramDocumentsInternal[i].CLM_Name__c ? lstProgramDocumentsInternal[i].CLM_Name__c : lstProgramDocumentsInternal[i].Title;
                                    document['Phase'] = this.mapPhase.get(lstProgramDocumentsInternal[i].Phase__c);
                
                                    if(mapDocumentDateByContentVersionId != undefined && mapDocumentDateByContentVersionId != null){
                                        if(mapDocumentDateByContentVersionId[document.Id] != undefined){
                                            document['LastUpdatedDate'] = mapDocumentDateByContentVersionId[document.Id];
                                        }
                                    }
                                    lstNewDocumentsInternal.push(document);
                                
                            }
            
                            this.lstAXADocuments = [...lstNewDocumentsInternal];
                            
                            console.log('PRA this.lstAXADocuments ',this.lstAXADocuments.length);
                            let signingIntDoc = [];
                            let placementIntDoc = [];
                            let leadIntDoc = [];
                            let quoteIntDoc = []
                            let allIntDoc = [];
            
                            for(let i = 0; i < this.lstAXADocuments.length; i++){
                                let rowDoc = { ... this.lstAXADocuments[i] };
                                console.log('PRA rowDoc.Phase ',rowDoc.Phase);
                                if(rowDoc.Phase == 'Signing'){
                                    signingIntDoc.push(rowDoc);
                                }
                                else if(rowDoc.Phase == 'Placement'){
                                    placementIntDoc.push(rowDoc);
                                }
                                else if(rowDoc.Phase == 'Lead'){
                                    leadIntDoc.push(rowDoc);
                                }
                                else if(rowDoc.Phase == 'Quote'){
                                    quoteIntDoc.push(rowDoc);
                                }
                                else if(rowDoc.Phase == 'All'){
                                    allIntDoc.push(rowDoc);
                                }         
                            }
            
                            let updLstAXADoc = [];
            
                            if(signingIntDoc.length > 0){
                                signingIntDoc = this.sortData('LastUpdatedDate', 'desc', signingIntDoc);
                                updLstAXADoc = updLstAXADoc.concat(signingIntDoc);
                            }
            
                            if(placementIntDoc.length > 0){
                                placementIntDoc = this.sortData('LastUpdatedDate', 'desc', placementIntDoc);
                                updLstAXADoc = updLstAXADoc.concat(placementIntDoc);
                            }
            
                            if(leadIntDoc.length > 0){
                                leadIntDoc = this.sortData('LastUpdatedDate', 'desc', leadIntDoc);
                                updLstAXADoc = updLstAXADoc.concat(leadIntDoc);
                            }
            
                            if(quoteIntDoc.length > 0){
                                quoteIntDoc = this.sortData('LastUpdatedDate', 'desc', quoteIntDoc);
                                updLstAXADoc = updLstAXADoc.concat(quoteIntDoc);
                            }
            
                            if(allIntDoc.length > 0){
                                allIntDoc = this.sortData('LastUpdatedDate', 'desc', allIntDoc);
                                updLstAXADoc = updLstAXADoc.concat(allIntDoc);
                            }
                
                            this.lstAXADocuments = updLstAXADoc;
                            console.log('PRA this.lstAXADocuments aFTER',this.lstAXADocuments.length);
                        }
                        
                        // SRA - ticket 1045
                        if (result.setReinsurerAttached != undefined ||  result.setRelatedBroker != undefined){
                            if(result.lstVisibilityDocument != undefined){
                                let lstNewDocumentVisibility = [];
                                let lstProgramDocumentVisibilityExternal = result.lstVisibilityDocument;
                                let setRelatedBroker = result.setRelatedBroker;
                                let setReinsurerAttached = result.setReinsurerAttached;
                                for(let i = 0; i < lstProgramDocumentVisibilityExternal.length; i++){
                                    let document = {};
                                    document['Name'] = lstProgramDocumentVisibilityExternal[i].Tech_Title__c;
                                    document['Id'] = lstProgramDocumentVisibilityExternal[i].Id;
                                    document['PhaseLabel'] =  this.mapPhase.get(lstProgramDocumentVisibilityExternal[i].Tech_Phase__c);//lstProgramDocumentVisibilityExternal[i].Tech_Phase__c;
                                    document['DocumentUrl']="../sfc/servlet.shepherd/version/download/"+ lstProgramDocumentVisibilityExternal[i].ContentVersionId__c+"?operationContext=S1";
                                    document['BrokerName'] = lstProgramDocumentVisibilityExternal[i].Tech_BrokerName__c;
                                    document['ReinsurerName'] = lstProgramDocumentVisibilityExternal[i].Tech_ReinsurerName__c;
                                    document['Checked'] = false;
                                    document['Viewable'] = true;
                                    document['CreatedDate'] = lstProgramDocumentVisibilityExternal[i].Tech_Date__c;
                                    document['ContentDocumentId'] = lstProgramDocumentVisibilityExternal[i].Tech_ContentDocumentId__c;

                                    if (this.selectedPhase == this.mapPhase.get(lstProgramDocumentVisibilityExternal[i].Tech_Phase__c)){
                                        document['readOnlyCheckbox'] = false;  //RRA - 939
                                    } else if (this.selectedPhaseSigning == this.mapPhase.get(lstProgramDocumentVisibilityExternal[i].Tech_Phase__c)) {
                                        document['readOnlyCheckbox'] = false;  //RRA - 939
                                    } else {
                                        document['readOnlyCheckbox'] = true;  //RRA - 939
                                    }
                                    lstNewDocumentVisibility.push(document);
                                }
                                this.lstDocumentVisibility = [...lstNewDocumentVisibility];
                            }
                        }

                        //old files for documents visibility
                        if(result.lstVisibilityDocumentOld != undefined){
                            let lstOldDocumentVisibility = [];
                            let lstProgramDocumentVisibilityExternalOld = result.lstVisibilityDocumentOld;
                            for(let i = 0; i < lstProgramDocumentVisibilityExternalOld.length; i++){
                                let document = {};
                                document['Name'] = lstProgramDocumentVisibilityExternalOld[i].Tech_Title__c;
                                document['Id'] = lstProgramDocumentVisibilityExternalOld[i].Id;
                                document['PhaseLabel'] =  this.mapPhase.get(lstProgramDocumentVisibilityExternalOld[i].Tech_Phase__c);//lstProgramDocumentVisibilityExternal[i].Tech_Phase__c;
                                document['DocumentUrl']="../sfc/servlet.shepherd/version/download/"+ lstProgramDocumentVisibilityExternalOld[i].ContentVersionId__c+"?operationContext=S1";
                                document['Checked'] = false;
                                document['Viewable'] = true;
                                document['CreatedDate'] = lstProgramDocumentVisibilityExternalOld[i].Tech_Date__c;
                                document['ContentDocumentId'] = lstProgramDocumentVisibilityExternalOld[i].Tech_ContentDocumentId__c;

                               
                                if (this.selectedPhase == this.mapPhase.get(lstProgramDocumentVisibilityExternalOld[i].Tech_Phase__c)){
                                    document['readOnlyCheckbox'] = false; 
                                } else if (this.selectedPhaseSigning == this.mapPhase.get(lstProgramDocumentVisibilityExternalOld[i].Tech_Phase__c)) {
                                    document['readOnlyCheckbox'] = false; 
                                }
                                else {
                                    document['readOnlyCheckbox'] = true; 
                                }
                                lstOldDocumentVisibility.push(document);
                            }
                            this.lstDocumentVisibilityOld = [...lstOldDocumentVisibility];
                        }
            
                        // Display the old doc file existing in the database without broker and reinsurer updated - 1046
                        /*if(result.lstContentVersionExternalOld != undefined){
                            let lstProgramDocumentExternalOld = result.lstContentVersionExternalOld;
                            let lstNewDocumentsExternalOld = [];
                            console.log('lstProgramDocumentExternalOld==', lstProgramDocumentExternalOld);
                            for(let i = 0; i < lstProgramDocumentExternalOld.length; i++){
                               // if (lstProgramDocumentExternalOld[i].DocumentType__c!=null && lstProgramDocumentExternalOld[i].GroupType__c!=null){
                                if (lstProgramDocumentExternalOld[i].IsExternal__c == false){
                                    
                                }else {
                                    let documentOld = {};
                                    documentOld['Name'] = lstProgramDocumentExternalOld[i].Title;
                                    documentOld['Id'] = lstProgramDocumentExternalOld[i].Id;
                                    documentOld['PhaseLabel'] = this.mapPhase.get(lstProgramDocumentExternalOld[i].Phase__c);
                                    documentOld['DocumentUrl']="../sfc/servlet.shepherd/version/download/"+ lstProgramDocumentExternalOld[i].Id+"?operationContext=S1";
                                    documentOld['Viewable'] = true;
                                    documentOld['Checked'] = false;
                                    if(mapCreatedDateContentVersionOldId != undefined && mapCreatedDateContentVersionOldId != null){
                                        if(mapCreatedDateContentVersionOldId[documentOld.Id] != undefined){
                                            documentOld['CreatedDate'] = mapCreatedDateContentVersionOldId[documentOld.Id];
                                        }
                                    }

                                    if (this.selectedPhase == this.mapPhase.get(lstProgramDocumentExternalOld[i].Phase__c)){
                                        //this.readOnlyCheckbox = disabled;
                                        documentOld['readOnlyCheckbox'] = false;
                                    }else {
                                        documentOld['readOnlyCheckbox'] = true;
                                    }
                                    lstNewDocumentsExternalOld.push(documentOld);
                                }
                                this.lstDocumentsOld = [...lstNewDocumentsExternalOld];
                                console.log('lstDocumentsOld = ', this.lstDocumentsOld);
                                }
                        }*/
            
                        // Display the new doc file created recently or in progress with broker and reinsurer updated - 1046
                        if(result.lstContentVersionExternal != undefined){
                            let lstProgramDocumentsExternal = result.lstContentVersionExternal;
                            let lstNewDocumentsExternal = [];
            
                            var hostname = window.location.hostname;
                            var arr = hostname.split(".");
                            var instance = arr[0];        
            
                            for(let i = 0; i < lstProgramDocumentsExternal.length; i++){
                                let dependValues = [];
                                let document = {};
                                document['Name'] = lstProgramDocumentsExternal[i].Title;
                                document['Id'] = lstProgramDocumentsExternal[i].Id;
                                document['GroupType'] = lstProgramDocumentsExternal[i].GroupType__c;
                                document['DocumentType'] = lstProgramDocumentsExternal[i].DocumentType__c;
                                document['Phase'] = lstProgramDocumentsExternal[i].Phase__c;
                                document['PhaseLabel'] = this.mapPhase.get(lstProgramDocumentsExternal[i].Phase__c);
                                document['DocumentUrl']="../sfc/servlet.shepherd/version/download/"+ lstProgramDocumentsExternal[i].Id+"?operationContext=S1";
                                document['BrokerName'] = lstProgramDocumentsExternal[i].Tech_BrokerName__c; // SRA - 1046
                                document['ReinsurerName'] = lstProgramDocumentsExternal[i].Tech_ReinsurerName__c; // SRA - 1046
                                document['Viewable'] = true;
                                document['Checked'] = false;

                                if (this.selectedPhase == this.mapPhase.get(lstProgramDocumentsExternal[i].Phase__c)){
                                    document['readOnlyCheckbox'] = false;  //RRA - 939 
                                } else if (this.selectedPhaseSigning == this.mapPhase.get(lstProgramDocumentsExternal[i].Phase__c)) {
                                    document['readOnlyCheckbox'] = false;  //RRA - 939 
                                }
                                else{
                                    document['readOnlyCheckbox'] = true;  //RRA - 939
                                }

                                //document['CreatedDate'] = lstProgramDocumentsExternal[i].CreatedDate;
                                //SRA 1046
                                if(mapCreatedDateContentVersionId != undefined && mapCreatedDateContentVersionId != null){
                                    if(mapCreatedDateContentVersionId[document.Id] != undefined){
                                        document['CreatedDate'] = mapCreatedDateContentVersionId[document.Id];
                                    }
                                }
                                if(this.phaseOpt != undefined){
                                    document['PhaseOptions'] = this.phaseOpt.map(row => {
                                    let selected;
                                    if(lstProgramDocumentsExternal[i].Phase__c != undefined){
                                        if(lstProgramDocumentsExternal[i].Phase__c.includes(row.value)){
                                            selected = true;
                                        }
                                    }
                                    return {...row , selected}});
                                }
            
                                document['FileContent'] = lstProgramDocumentsExternal[i].VersionData;
                                document['Checked'] = false;
                                var groupTypeVal = lstProgramDocumentsExternal[i].GroupType__c;
            
                                if(groupTypeVal){
                                    this.totalDependentDocumentTypeValues.forEach(groupTypeVal => {
                                        if(groupTypeVal.validFor[0] === this.controlDocumentTypeValues[lstProgramDocumentsExternal[i].GroupType__c]){
                                            dependValues.push({
                                                label : groupTypeVal.label,
                                                value : groupTypeVal.value
                                            })
                                        }
                                    })
                                    document['DocumentTypeOpt'] = dependValues;
                                }
            
                                if(lstProgramDocumentsExternal[i].GroupType__c == undefined){
                                    document['isGroupEmpty'] = true;
                                }
                                else{
                                    document['isGroupEmpty'] = false;
                                }
                                lstNewDocumentsExternal.push(document);
                            }
            
                            this.lstDocuments = [...lstNewDocumentsExternal];
            
                            let signingExtDoc = [];
                            let placementExtDoc = [];
                            let leadExtDoc = [];
                            let quoteExtDoc = []
            
                            for(let i = 0; i < this.lstDocuments.length; i++){
                                let rowDoc = { ... this.lstDocuments[i] };
                                if(rowDoc.PhaseLabel == 'Signing'){
                                    signingExtDoc.push(rowDoc);
                                }
                                else if(rowDoc.PhaseLabel == 'Placement'){
                                    placementExtDoc.push(rowDoc);
                                }
                                else if(rowDoc.PhaseLabel == 'Lead'){
                                    leadExtDoc.push(rowDoc);
                                }
                                else if(rowDoc.PhaseLabel == 'Quote'){
                                    quoteExtDoc.push(rowDoc);
                                }
                            }
            
                            let updLstExtDoc = [];
            
                            if(signingExtDoc.length > 0){
                                updLstExtDoc = updLstExtDoc.concat(signingExtDoc);
                            }
            
                            if(placementExtDoc.length > 0){
                                updLstExtDoc = updLstExtDoc.concat(placementExtDoc);
                            }
            
                            if(leadExtDoc.length > 0){
                                updLstExtDoc = updLstExtDoc.concat(leadExtDoc);
                            }
            
                            if(quoteExtDoc.length > 0){
                                updLstExtDoc = updLstExtDoc.concat(quoteExtDoc);
                            }
                
                            this.lstDocuments = updLstExtDoc;
                            
                        }
                    //AMI 18/07/22: W-0951 Portail - transversal - Possibilité de télécharger tous les documents AXA à la fois"
                        //              Exposed properties to enable/disable download button
                        this.disableDownloadAll = this.lstAXADocuments.length > 0 ? false :true;
                        this.spinner = false;    
                    }

            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error get document 222', message: error.message, variant: 'error'}), );
            });

        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error name Brokerand Reinsurer', message: error.message, variant: 'error'}), );
        });
    }

    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        lstData = sortResult.sort(function(a,b){
            if(a[fieldName] > b[fieldName])
                return sortDirection === 'desc' ? -1 : 1;
            else if(a[fieldName] < b[fieldName])
                return sortDirection === 'desc' ? 1 : -1;
            else{
                return 0;
            }
        })
        return lstData;
    }

    //AMI 18/07/22: W-0951 Portail - transversal - Possibilité de télécharger tous les documents AXA à la fois"
    //              handler to download all axa doc in one go
    downlaodAllAxaDocs(){
        //link to downlaod all possible docs
        let axaDocsUrl = '../sfc/servlet.shepherd/version/download';

        //loop in retrieved and updated axa docs
        this.lstAXADocuments.map(ele => {
            //build new doc url to enable mass download
            axaDocsUrl = axaDocsUrl.concat('/',ele.Id);
        });

        //add context after successfull url build
        axaDocsUrl = axaDocsUrl.concat('?operationContext=S1');

        //enable download
        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: axaDocsUrl
                }
            }, false 
        );
        
    }
}