import {LightningElement, track, wire, api} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {registerListener, fireEvent, unregisterListener} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getTreaties from '@salesforce/apex/LWC39_RenewProgram.getTreaties';
import getSections from '@salesforce/apex/LWC39_RenewProgram.getSections';
import saveProgram from '@salesforce/apex/LWC39_RenewProgram.saveProgram';
import checkProgramName from '@salesforce/apex/LWC01_NewProgram.checkProgramName';
import LOB_FIELD from '@salesforce/schema/Section__c.LoB__c';
import SUBLOB_FIELD from '@salesforce/schema/Section__c.SubLoB__c';

//import object
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';

//import custom labels
import ProgName_Unchanged from '@salesforce/label/c.ProgName_Unchanged';
import ProgName_Exists from '@salesforce/label/c.ProgName_Exists';
import ProgramRenewedSuccessfully from '@salesforce/label/c.ProgramRenewedSuccessfully';
import NoTreatySelected from '@salesforce/label/c.NoTreatySelected';
import errorMsg from '@salesforce/label/c.errorMsg';

const columnsTreaty = [
    { label: 'Program', fieldName: 'TECH_ProgramName__c' },
    { label: 'Layer', fieldName: 'Layer__c', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Treaty Ref.', fieldName: 'WebXLReference__c' },
    { label: 'Name', fieldName: 'Name' },
    { label: 'Type', fieldName: 'TypeofTreaty__c'},
    { label: 'Share', fieldName: 'PlacementShare_Perc__c', type: 'number', cellAttributes: { alignment: 'left' }, typeAttributes: { maximumFractionDigits  : 6}},
    { label: 'Status', fieldName: 'Status__c' }
];

const columnsSection = [
    { label: 'Program', fieldName: 'TECH_ProgramName__c' },
    { label: 'Layer', fieldName:'fieldLayer__c', type: 'number', cellAttributes: { alignment: 'left' }}, //RRA - ticket 1326 - 08052023
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Number', fieldName: 'SectionNumber__c' },
    { label: 'Name', fieldName: 'Name' },
    { label: 'Related to', fieldName: 'TECH_RelatedSectionNumber__c'},
    { label: 'L.o.B', fieldName: 'LoB__c' },
    { label: 'Sub L.o.B', fieldName: 'SubLoB__c' },
    { label: 'Retained to Lead', fieldName: 'Retained_to_lead__c' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classRetainToLeadData' }, variant:'bare'}},
    { label: 'Currency', fieldName: 'Currency__c'},
    { label: 'Limit', fieldName: 'fieldLimit__c', type: 'number', cellAttributes: { alignment: 'left' }}, //RRA - ticket 1326 - 08052023
    { label: 'Retention', fieldName: 'fieldRetention__c', type: 'number', cellAttributes: { alignment: 'left' }}, //RRA - ticket 1326 - 08052023
    { label: 'Status', fieldName: 'Status__c'}
];

export default class LWC39_RenewProgram extends NavigationMixin(LightningElement) {
    label = {
        ProgName_Unchanged,
        ProgName_Exists,
        ProgramRenewedSuccessfully,
        NoTreatySelected,
        errorMsg
    }

    @api uwYearOpenModal;
    @api compOpenModal;
    @api selectedProgram;
    @api displayTreatySectionDatatable;
    @api selectedTypeOfRenew;
    @track selectedTreatiesId = [];
    @track selectedSectionsId = [];
    @track preSelectedTreatiesRows = [];
    @track preSelectedSectionsRows = [];
    @track mapSectionOptionBySection = new Map();
    columnsTreaty = columnsTreaty;
    titleCountTreaties = 'Treaties (0)';
    spinnerTreaty = false;
    spinnerSave = false;
    dataTreaties;
    titleCountSections = 'Sections (0)';
    spinnerSection = false;
    dataSections;
    columnsSection = columnsSection;
    selectedProgramId;
    programName;
    expiryDateRenewProgram;
    mapLOb = new Map();
    mapSubLob = new Map();

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        let expiryDate = new Date(this.selectedProgram.Expirydate__c+'T00:00');
        let renewDate = new Date(expiryDate);
        console.log('renewDate av== ', renewDate);
        renewDate.setDate(expiryDate.getDate()+1);
        console.log('renewDate ap== ', renewDate);

        this.expiryDateRenewProgram = renewDate;
        this.uwYearOpenModal = (renewDate.getFullYear()).toString();
        this.selectedProgramId = this.selectedProgram.Id;
        this.programName = this.selectedProgram.Name;
        this.getTreaties();
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOB_FIELD})
    setLOBOptions({error, data}) {
        if(data){
            this.mapLOb = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapLOb.set(data.values[i].value, data.values[i].label);
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SUBLOB_FIELD})
    setSubLOb({error, data}) {
        if(data){
            this.mapSubLob = new Map();
            for(var i = 0; i < data.values.length; i++){
                this.mapSubLob.set(data.values[i].value, data.values[i].label);
            }
        }
        else{
            this.error = error;
        }
    }

    getTreaties(){
        getTreaties({programId: this.selectedProgramId})
        .then(result => {
            this.spinnerTreaty = true;
            this.titleCountTreaties = 'Treaties' + ' (' + result.length + ')';
            this.dataTreaties = result;
            let treatyIds = [];

            for(let i = 0; i < this.dataTreaties.length; i++){
                treatyIds.push(this.dataTreaties[i].Id);
            }

            this.preSelectedTreatiesRows = treatyIds;
            this.selectedTreatiesId = treatyIds;
            this.getSections();
            this.error = undefined;
            this.spinnerTreaty = false;
        })
        .catch(error => {
            this.error = error;
            this.dataTreaties = undefined;
            this.spinnerTreaty = false;
        });
    }

    getSections(){
        getSections({lstSelectedTreaties: this.selectedTreatiesId})
        .then(result => {
            console.log('result Section == ',result);
            this.spinnerSection = true;
            this.titleCountSections = 'Sections' + ' (' + result.length + ')';
            this.dataSections = result;

            let sectionIds = [];
            let dataUpdSections = [];

            for(let i = 0; i < this.dataSections.length; i++){
                let rowSection = { ...this.dataSections[i] };
                sectionIds.push(this.dataSections[i].Id);
                rowSection.LoB__c = this.mapLOb.get(rowSection.LoB__c);
                rowSection.SubLoB__c = this.mapSubLob.get(rowSection.SubLoB__c);

                if(this.dataSections[i].RelatedSection__c != null && this.dataSections[i].RelatedSection__c != undefined){
                    let setSectionOption = [];
                    if(this.mapSectionOptionBySection.has(this.dataSections[i].RelatedSection__c)){
                        setSectionOption = this.mapSectionOptionBySection.get(this.dataSections[i].RelatedSection__c);
                    }
                    setSectionOption.push(this.dataSections[i].Id);
                    this.mapSectionOptionBySection.set(this.dataSections[i].RelatedSection__c, setSectionOption);
                }

                dataUpdSections.push(rowSection);
            }

            this.dataSections = dataUpdSections;

            this.preSelectedSectionsRows = sectionIds;
            this.selectedSectionsId = sectionIds;
            this.error = undefined;
            this.spinnerSection = false;
        })
        .catch(error => {
            this.error = error;
            this.dataSections = undefined;
            this.spinnerSection = false;
        });
    }

    handleCloseRenewProgramModal(){
        fireEvent(this.pageRef, 'closeRenewProgramModal', false);
    }

    handleSaveRenewProgram(){
        this.programName = this.template.querySelector('[data-id="ProgramName"]').value;

        if(this.selectedTreatiesId.length == 0){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.NoTreatySelected, variant: 'error'}),);
        }
        else{
            checkProgramName({ programName : this.programName.trim(), programId : this.selectedProgramId, isProgramCopy : true, valueUWYear : this.uwYearOpenModal})
            .then(result => {
                if(result == true){
                    if(this.selectedProgram.Name.trim() == this.programName.trim()){
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ProgName_Unchanged, variant: 'error'}),);
                    }else{
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.ProgName_Exists, variant: 'error'}),);
                    }
                }else{
                    this.spinnerSave = true;
                    saveProgram({programId : this.selectedProgramId, renewProgramName : this.programName.trim(), uwYear: this.uwYearOpenModal, lstSelectedTreatiesId : this.selectedTreatiesId, lstSelectedSectionsId : this.selectedSectionsId, expiryDate : this.expiryDateRenewProgram, displayTreatySection : this.displayTreatySectionDatatable, typeOfRenew : this.selectedTypeOfRenew})
                    .then(result => {
                        console.log('result.lstDecValue == ', result.lstDecValue);
                        this.handleCloseRenewProgramModal();
                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                        fireEvent(this.pageRef, 'refreshActorRef', 'refresh');
                        this.spinnerSave = false;

                        //AMI 10/06/22 W:0771
                        //notify parent component of successfull renewed program
                        this.notifyParent(result.programRenew);
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
                        this.handleCloseRenewProgramModal();
                        this.spinnerSave = false;
                    });
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }

    handleTreatyRowSelection(event){
        let selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        let treatyIds = [];

        if(selectedTreaties.length > 0){
            selectedTreaties.forEach((treaty)=>treatyIds.push(treaty.Id));
        }

        this.selectedTreatiesId = treatyIds;
        this.getSections();
    }

    handleSectionRowSelection(event){
        let selectedSections = this.template.querySelector('[data-id="sectionDatatable"]').getSelectedRows();

        let sectionIds = [];
        let setSelectedSectionId = new Set();
        let setParentSectionNotSelected = [];

        if(selectedSections.length > 0){
            for(let i = 0; i < selectedSections.length; i++){
                setSelectedSectionId.add(selectedSections[i].Id);
                sectionIds.push(selectedSections[i].Id)
            }
        }

        for(let i = 0; i < this.dataSections.length; i++){
            if(!setSelectedSectionId.has(this.dataSections[i].Id) && (this.dataSections[i].RelatedSection__c == null || this.dataSections[i].RelatedSection__c == undefined)){
                setParentSectionNotSelected.push(this.dataSections[i].Id);
            }
        }

        let setSectionToDisable = new Set();

        for(let i = 0; i < setParentSectionNotSelected.length; i++){
            if(this.mapSectionOptionBySection.has(setParentSectionNotSelected[i])){
                let setOptionsForSection = this.mapSectionOptionBySection.get(setParentSectionNotSelected[i]);
                for(let j = 0; j < setOptionsForSection.length; j++){
                    setSectionToDisable.add(setOptionsForSection[j]);
                }
            }
        }

        let sectionIdToSelect = [];

        for(let i = 0; i < sectionIds.length; i++){
            if(!setSectionToDisable.has(sectionIds[i])){
                sectionIdToSelect.push(sectionIds[i]);
            }
        }

        this.selectedSectionsId = sectionIdToSelect;
        this.preSelectedSectionsRows = sectionIdToSelect;
    }

    //AMI 10/06/22 W:0771
    //notify parent component of successfull renewed program
    notifyParent(renewedProg){
        const progRenewed = new CustomEvent('progrenewed', {
            detail: renewedProg
        });
        this.dispatchEvent(progRenewed);
    }
}