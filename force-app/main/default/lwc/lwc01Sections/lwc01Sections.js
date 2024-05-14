import {LightningElement, track, wire, api} from 'lwc';
import getSections from '@salesforce/apex/LWC01_Sections.getSections';
import getCoveredCedingCompanies from '@salesforce/apex/LWC01_Sections.getCoveredCedingCompanies';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate'; 
import checkRequestExist from '@salesforce/apex/LWC01_HomePageActions.checkRequestExist'; //RRA - ticket 585 - 22032023
import deleteSections from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import getSectionNumber from '@salesforce/apex/LWC01_Sections.getSectionNumber';
import checkStatusRequestQuoteLead from '@salesforce/apex/LWC01_Sections.checkStatusRequestQuoteLead';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent } from 'c/pubSub';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import saveRetainedToLeadSection from '@salesforce/apex/LWC01_Sections.saveRetainedToLeadSection';
import getTreatiesForExistedLeadRequest from '@salesforce/apex/LWC01_Sections.getTreatiesForExistedLeadRequest';
import getSelectedTreatyDetail from '@salesforce/apex/LWC01_Sections.getSelectedTreatyDetail';
import updateRetainToLeadDeactivation from '@salesforce/apex/LWC01_Sections.updateRetainToLeadDeactivation'; //RRA - ticket 585 - 22032023
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import LOB_FIELD from '@salesforce/schema/Section__c.LoB__c';
import SUBLOB_FIELD from '@salesforce/schema/Section__c.SubLoB__c';

//import component lwc
import modalPopUpWarningMsgSubSection from 'c/lwc60ModalMsgSubSection'; //RRA - ticket 1533 - 12062023

//import custom labels
import Sections from '@salesforce/label/c.Sections';
import NewSection from '@salesforce/label/c.NewSection';
import Reactivate from '@salesforce/label/c.Reactivate';
import Deactivate from '@salesforce/label/c.Deactivate';
import Delete from '@salesforce/label/c.Delete';
import Copy from '@salesforce/label/c.Copy';
import NewOption from '@salesforce/label/c.NewOption';
import Program from '@salesforce/label/c.Program';
import Treaty from '@salesforce/label/c.Treaty';
import Number from '@salesforce/label/c.Number';
import Name from '@salesforce/label/c.Name';
import Related_to from '@salesforce/label/c.Related_to';
import Sub_LoB from '@salesforce/label/c.Sub_LoB';
import Currency from '@salesforce/label/c.Currency';
import Limit from '@salesforce/label/c.Limit';
import Retention from '@salesforce/label/c.Retention';
import Status from '@salesforce/label/c.Status';
import RetainedToLead from '@salesforce/label/c.RetainedToLead';
import Actions from '@salesforce/label/c.Actions';
import RetainToLeadError from '@salesforce/label/c.RetainToLeadError';
import RetainToLeadSameFamily from '@salesforce/label/c.RetainToLeadSameFamily';
import RetainedToLeadSectionsSuccessfully from '@salesforce/label/c.RetainedToLeadSectionsSuccessfully';
import PCCInactiveCopyNotAllowed from '@salesforce/label/c.PCCInactiveCopyNotAllowed';
import AskToReactivateSection from '@salesforce/label/c.AskToReactivateSection';
import AskToDeactivateSection from '@salesforce/label/c.AskToDeactivateSection';
import CannotCreateNewOption from '@salesforce/label/c.CannotCreateNewOption';
import AskToDeleteSection from '@salesforce/label/c.AskToDeleteSection';
import SomeQuoteOrLeadPresent from '@salesforce/label/c.SomeQuoteOrLeadPresent';
import YouCannotDeleteSectionOnLead from '@salesforce/label/c.YouCannotDeleteSectionOnLead';
import YouCannotDeleteAnsweredTwoPhases from '@salesforce/label/c.YouCannotDeleteAnsweredTwoPhases';
import YouCannotDeleteSectionOnQuote from '@salesforce/label/c.YouCannotDeleteSectionOnQuote';//messageRetainToLead
import messageRetainToLead from '@salesforce/label/c.messageRetainToLead';
import SomeLeadpresent from '@salesforce/label/c.SomeLeadpresent'; 
import SomeLeadpresent2 from '@salesforce/label/c.SomeLeadpresent2'; 
import SomeQuoteOrPlacementpresent from '@salesforce/label/c.SomeQuoteOrPlacementpresent'; 
import SomeSigningpresent from '@salesforce/label/c.SomeSigningpresent';
import SomeSecletedSectionsCancelled from '@salesforce/label/c.SomeSecletedSectionsCancelled';
import errorMsg from '@salesforce/label/c.errorMsg';
import NoSubSectionInSection from '@salesforce/label/c.NoSubSectionInSection';//RRA - ticket 1533 - 13062023

const actions = [
      { label: Copy, name: 'copy'}
  ];

const columnsRetainedtoLead = [
    { label: Program, fieldName: 'TECH_ProgramName__c' },
    { label: Treaty, fieldName: 'TECH_TreatyName__c' },
    { label: Number, fieldName: 'SectionNumber__c' },
    { label: Name, fieldName: 'Name'},
    { label: Related_to, fieldName: 'TECH_RelatedSectionNumber__c'},
    { label: Sub_LoB, fieldName: 'SubLoB__c' },
    { label: RetainedToLead, fieldName: 'Retained_to_lead__c' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classRetainToLead' }, variant:'bare'}},
    { label: Currency, fieldName: 'Currency__c'},
    { label: Limit, fieldName: 'fieldLimit__c', type: 'number', cellAttributes: { alignment: 'left' }}, //fieldLimitRetain RRA - ticket 1245 21112022
    { label: Retention, fieldName: 'fieldRetention__c', type: 'number', cellAttributes: { alignment: 'left' }}, //fieldRetentionRetain RRA - ticket 1245 21112022
    { label: Status, fieldName: 'Status__c'}
];

//RRA - ticket 1533- 12062023
const columnSections = [
    { label: 'Layer Number', fieldName: 'Layer', type: 'number', cellAttributes: { alignment: 'left' }}, 
    { label: 'Treaty Name', fieldName: 'TECH_TreatyName__c' },
    { label: 'Section Number', fieldName: 'SectionNumber__c' },
    { label: 'Section Name', fieldName: 'Name'},
];

export default class LWC01_Sections extends NavigationMixin(LightningElement) {
    label = {
        Sections,
        NewSection,
        Reactivate,
        Deactivate,
        Delete,
        Copy,
        NewOption,
        Program,
        Treaty,
        Number,
        Name,
        Related_to,
        Sub_LoB,
        Currency,
        Limit,
        Retention,
        Status,
        RetainedToLead,
        RetainToLeadError,
        RetainToLeadSameFamily,
        RetainedToLeadSectionsSuccessfully,
        PCCInactiveCopyNotAllowed,
        AskToReactivateSection,
        AskToDeactivateSection,
        CannotCreateNewOption,
        AskToDeleteSection,
        errorMsg,
        SomeQuoteOrLeadPresent,
        YouCannotDeleteSectionOnLead,
        YouCannotDeleteAnsweredTwoPhases,
        YouCannotDeleteSectionOnQuote,
        messageRetainToLead,
        SomeLeadpresent,
        SomeLeadpresent2,
        SomeQuoteOrPlacementpresent,
        SomeSigningpresent,
        SomeSecletedSectionsCancelled,
        NoSubSectionInSection //RRA - ticket 1533 - 13062023
    }

    @api mySelectedTreaties;
    @api recordId;
    @api conditionPage = false;
    @api allReadOnly = false;
    @track selectedSectionCopy = [];
    @track dataCoveredCedingCompany = [];
    @track preSelectedRetainedToLead = [];
    @track lstSectionNumberRetainToLeadTrue = [];
    // MRA W-0804 09/09/2022  
    @track isDialogVisible = false;
    confirmMessage = '' ;
    yesForDelete = false ;
    data;
    columns;
    dataRetainedtoLead;
    columnsRetainedtoLead = columnsRetainedtoLead;
    refreshTable;
    error;
    titleCountSections = this.label.Sections + ' (0)';
    isOpenModal = false;
    isOpenConfirmation = false;
    uwYear;
    comp;
    statusModalTitle;
    selectedRowSection; //RRA - ticket 585 -15032023
    status;
    disableNewSectionBtn = true;
    selectedProgram;
    isCopy = false;
    isNewOption = false;
    mapLOb = new Map();
    mapSubLob = new Map();
    isDeleteOpen = false;
    delMsgTitle;
    delMessage;
    spinnerSection = false;
    NewSectionNumber;
    openRetainedToLeadModal = false;
    disableRetainToLeadBtn = true;
    disableSendToLeadBtn = true;
    disableSectionBtns = true;
    actions2;
    displayErrorMsg = false;
    setTreatiesForExistedLeadRequest = new Set();
    columnSections = columnSections; //RRA - ticket 1533 - 12062023
    consDataSection;//RRA - ticket 1533 - 12062023

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('year', this.getYear, this);
        registerListener('comp', this.getComp, this);
        registerListener('selectedTreaties', this.getSelectedTreaties, this);
        registerListener('hideSectionBtn', this.toggleSectionBtns, this);
        registerListener('refreshSection', this.refreshDataSections, this);
        registerListener('closeSectionModal', this.setIsOpenModalFalse, this);
        registerListener('selectedProgram', this.getSelectedProgram, this);
    }

    constructor() {
        super();
        this.columns = [
            { label: Program, fieldName: 'TECH_ProgramName__c' },
            { label: 'Layer', fieldName:'Layer', type: 'number', cellAttributes: { alignment: 'left' }},
            { label: Treaty, fieldName: 'TECH_TreatyName__c' },
            { label: Number, fieldName: 'SectionNumber__c' },
            { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_self'}},
            {label : 'Number of Subsections',fieldName: 'Number_of_subsections__c',initialWidth: 150},
            { label: Related_to, fieldName: 'TECH_RelatedSectionNumber__c'},
            { label: 'L.o.B', fieldName: 'LoB__c' },
            { label: Sub_LoB, fieldName: 'SubLoB__c' },
            { label: RetainedToLead, fieldName: 'Retained_to_lead__c' , type: 'button-icon', typeAttributes: { iconName: 'utility:record', iconClass: { fieldName: 'classRetainToLeadData' }, variant:'bare'}},
            { label: Currency, fieldName: 'Currency__c'},
            { label: Limit, fieldName: 'fieldLimit__c', type: 'number', cellAttributes: { alignment: 'left' }}, // RRA - ticket 1275  21112022
            { label: Retention, fieldName: 'fieldRetention__c', type: 'number', cellAttributes: { alignment: 'left' }}, // RRA - ticket 1275  21112022
            { label: Status, fieldName: 'Status__c'},
            { label: Actions, type: 'action', fixedWidth: 70, typeAttributes: {rowActions: this.getRowActions, menuAlignment:'auto'}}
        ];
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        actions.push({
            'label': 'Copy',
            'name': 'copy'
        });
            if(row['TECH_RelatedSectionNumber__c'] == null) {
                actions.push({
                    'label': 'New Option',
                    'name': 'newOption'
                });
            }
            setTimeout(() => {
                doneCallback(actions);
            });
    }

    getSelectedProgram(val){
        this.selectedProgram = val;
    }

    toggleSectionBtns(val){
        this.disableSectionBtns = val;
    }

    getYear(val){
        this.uwYear = val;
    }

    getComp(val){
        this.comp = val;
    }

    setIsOpenModalFalse(val){
        this.isOpenModal = val;
    }

    refreshDataSections(){
        this.populateSections();
    }

    getSelectedTreaties(selectedTreaties){
        this.spinnerSection = true;
        this.mySelectedTreaties = selectedTreaties;

        if(this.mySelectedTreaties.length == 1 && this.disableSectionBtns == false){
            this.disableNewSectionBtn = false;
        }
        else{
            this.disableNewSectionBtn = true;
        }

        this.spinnerSection = false;
        this.populateSections();
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

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            this.uwYear = data.values[data.values.length - 1].value;
        }
        else{
            this.error = error;
        }
    }

    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
            if(this.comp == null){
                this.comp = data[0].value;
            }
        }
        else{
            this.error = error;
        }
    }

    populateSections(){
        getSections({lstSelectedTreaties: this.mySelectedTreaties})
        .then(result => {
            this.titleCountSections= this.label.Sections + ' (' + result.length + ')';
            var newResult = [];
            for(var i = 0; i < result.length; i++){
                let row = Object.assign({}, result[i]);
                if(row.LoB__c != undefined || row.LoB__c != null){
                    Object.defineProperty( row, 'LoB__c', {
                        value: this.mapLOb.get(row.LoB__c),
                        writable: true,
                        enumerable: true,
                        configurable: true
                    });
                }
                if(row.SubLoB__c != undefined || row.SubLoB__c != null){
                    Object.defineProperty( row, 'SubLoB__c', {
                        value: this.mapSubLob.get(row.SubLoB__c),
                        writable: true,
                        enumerable: true,
                        configurable: true
                    });
                }
                newResult.push(row);
            }

            // QS = 3
            // SL = 1
            // Surplus = 4
            // XL = 2

            let nameUrl;
            let classRetainToLeadData;
            let fieldLimit;
            let fieldRetention;
            let pcc;
            this.data = newResult.map(row => {
                nameUrl = '../r/Section__c/'+row.Id+'/edit';
                if(row.Retained_to_lead__c == true){
                    classRetainToLeadData = 'slds-icon slds-icon-text-success slds-icon_x-small'; // RRA - 1045
                }
                else{
                    classRetainToLeadData = 'slds-icon slds-icon-text-default slds-icon_x-small'; // RRA - 1045
                }

                //RRA - ticket 1275 - 21112022 => this line is replaced by field formalula fieldRetention__c and fieldLimit__c
                /*if(row.TECH_TypeofTreaty__c == '3'){
                    fieldLimit = row.Cession_Perc__c;
                    fieldRetention = row.Retention__c;
                }
                else if(row.TECH_TypeofTreaty__c == '1'){
                    fieldLimit = row.LimitPercent__c;
                    fieldRetention = row.DeductiblePercent__c;
                }
                else if(row.TECH_TypeofTreaty__c == '4'){
                    fieldLimit = row.CessionAmount__c;
                    fieldRetention = row.RetentionAmount__c;
                }
                else if(row.TECH_TypeofTreaty__c == '2'){
                    fieldLimit = row.Limit__c;
                    fieldRetention = row.Deductible__c;
                }*/
                pcc = this.comp;

                return {...row , nameUrl, fieldLimit, fieldRetention, classRetainToLeadData, pcc}
            });
            
            for(let i = 0; i < this.data.length; i++){
                let sectionNum = this.data[i].SectionNumber__c;
                let sectionNumberStr = this.data[i].Treaty__c + '-' + sectionNum.split(".")[0];
                if(this.data[i].Retained_to_lead__c == true){
                    this.lstSectionNumberRetainToLeadTrue.push(sectionNumberStr);
                }
                this.data[i]['Layer'] = this.data[i].Treaty__r.Layer__c;
            }

            let retainToLead = false;
            let sectionNumber;
            let iconNameRetainToLead;
            let classRetainToLead;
            let retainToLeadValue = false;

            this.dataRetainedtoLead = this.data.map(row => {
                let sectionNum = row.SectionNumber__c;
                sectionNumber = row.Treaty__c + '-' +sectionNum.split(".")[0];

                if(this.lstSectionNumberRetainToLeadTrue.includes(sectionNumber)){
                    retainToLeadValue = true;
                }
                else{
                    retainToLeadValue = false;
                }
                console.log('retail to leeeead = =' ,row.Retained_to_lead__c);
                if(row.Retained_to_lead__c == true){
                    retainToLead = false;
                    classRetainToLead = 'slds-icon slds-icon-text-success slds-icon_x-small'; // RRA - 1045
                }
                else{
                    retainToLead = false;
                    classRetainToLead = 'slds-icon slds-icon-text-default slds-icon_x-small'; // RRA - 1045
                } 

                console.log('classRetainToLead = =' ,classRetainToLead);

                 //RRA - ticket 1275 - 24112022 => this line is replaced by field formalula fieldRetention__c and fieldLimit__c
                /*if(row.TECH_TypeofTreaty__c == '3'){
                    fieldLimitRetain = row.Cession_Perc__c;
                    fieldRetentionRetain = row.Retention__c;
                }
                else if(row.TECH_TypeofTreaty__c == '1'){
                    fieldLimitRetain = row.LimitPercent__c;
                    fieldRetentionRetain = row.DeductiblePercent__c;
                }
                else if(row.TECH_TypeofTreaty__c == '4'){
                    fieldLimitRetain = row.CessionAmount__c;
                    fieldRetentionRetain = row.RetentionAmount__c;
                }
                else if(row.TECH_TypeofTreaty__c == '2'){
                    fieldLimitRetain = row.Limit__c;
                    fieldRetentionRetain = row.Deductible__c;
                }*/

                pcc = this.comp;

                return {...row , retainToLead, sectionNumber, iconNameRetainToLead, classRetainToLead, retainToLeadValue, pcc}
            });
            //this.sortData(this.dataRetainedtoLead, 'TECH_TreatyName__c','Layer','Sort_SectionNumber__c','','asc'); // RRA - ticket 1357 - 08122022
            if(this.dataRetainedtoLead.length > 0 && this.disableSectionBtns == false){
                this.disableRetainToLeadBtn = false;
            }
            else{
                this.disableRetainToLeadBtn = true;
            }

            
            //RRA - ticket 1399 + Correction Tri - 27012023
            //this.sortData(this.data, 'TECH_TreatyName__c','Sort_SectionNumber__c','Name','','asc'); 
            //this.sortData(this.dataRetainedtoLead, 'TECH_TreatyName__c','Sort_SectionNumber__c','Name','','asc'); 

            this.getTreatiesForExistedLeadRequest();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
            this.error = result.error;
            this.data = undefined;
        });
    }

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

    // RRA 1083 - Change tri SectionNumber__c by add ID__c and  
    sortData(lstData, fieldName,fieldName2, fieldName4, fieldName5,sortDirection) {
        let sortResult = Object.assign([], lstData);
        lstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                if(a[fieldName2] < b[fieldName2])
                    return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])
                    return sortDirection === 'asc' ? 1 : -1;
                else{
                    /*if(a[fieldName3] < b[fieldName3])
                        return sortDirection === 'asc' ? -1 : 1;
                    else if(a[fieldName3] > b[fieldName3])
                        return sortDirection === 'asc' ? 1 : -1;*/
                    // else{
                        if(a[fieldName4] < b[fieldName4])
                            return sortDirection === 'asc' ? -1 : 1;
                        else if(a[fieldName4] > b[fieldName4])
                            return sortDirection === 'asc' ? 1 : -1;
                        else{
                            if(a[fieldName5] < b[fieldName5])
                                return sortDirection === 'asc' ? -1 : 1;
                            else if(a[fieldName5] > b[fieldName5])
                                return sortDirection === 'asc' ? 1 : -1;
                            else
                                return 0;
                        }
                   // }
                }
            }
        })
    }

    getTreatiesForExistedLeadRequest(){
        getTreatiesForExistedLeadRequest({lstProgramId: this.selectedProgram})
        .then(result => {
            this.setTreatiesForExistedLeadRequest = new Set(result);
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleOpenModal() {
        this.recordId = this.mySelectedTreaties[0];

        getSelectedTreatyDetail({treatyId : this.recordId})
        .then(result => {
            if(result.Program__r.RenewedFromProgram__c != null && result.Program__r.RenewedFromProgram__c != undefined && (result.Program__r.TypeOfRenew__c == 'LTA/TR Identical Renew')){
                this.displayErrorMsg = true;
                this.isOpenModal = true;
            }
            else{
                getSectionNumber()
                .then(result => {
                    this.NewSectionNumber = result;
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
                });
                this.isOpenModal = true;
                this.isCopy = false;
                this.isNewOption = false;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    handleCloseModal() {
        this.isOpenModal = false;
        this.isOpenConfirmation = false;
        this.isDeleteOpen = false;
        this.displayErrorMsg = false;
    }

    reactivateBtn(){
        var selectedPrograms = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedPrograms.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Section selected',
                    variant: 'error',
                }),
            );
        }
        else{
            this.statusModalTitle = 'Reactivate Section';
            //You are going to reactivate the selected Section(s). Do you want to continue?
            this.status = this.label.AskToReactivateSection;
            this.statusFunction = 'reactivate';
            this.isOpenConfirmation = true;
        }
    }

    deactivateBtn(){
        this.spinnerSection = true;
        let lstIsRetainTOLead = [];
        var selectedSections = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedSections  == ', selectedSections);
        let isRetainLeadExists = false;
        if(selectedSections.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Section selected',
                    variant: 'error',
                }),
            );
            this.spinnerSection = false;
        } else{
            //RRA - ticket 585 - 21032023 => Don't applicate fields below on request SOQL from getSections (Remove field marked with toLabel in the SoQL query)
            for (var key in selectedSections) {
                var obj = selectedSections[key];
                delete obj.SubLoB__c;
                delete obj.LoB__c;
                delete obj.Currency__c;
            }
            // RRA - ticket - 1317 15112022
            for (let i=0;i<selectedSections.length;i++){
                lstIsRetainTOLead.push(selectedSections[i].Retained_to_lead__c);
            }
            if (lstIsRetainTOLead != null || lstIsRetainTOLead != undefined){
                lstIsRetainTOLead.forEach(item => {
                    if (item === true){
                        isRetainLeadExists = true;
                    }
                });
            }
            checkRequestExist({lstRecords: selectedSections, objectName: 'Section', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerSection = false;
                    }
                    else{
                        console.log('result changeStatus Section == ', result);
                        console.log('result isRetainLeadExists Section 22 == ', isRetainLeadExists);
                        //RRA - ticket 585 - 01032023
                        if (result.numbLeadRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeLeadpresent2,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerSection = false;
                        }else if (result.numbPlacementRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeQuoteOrPlacementpresent,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerSection = false;
                        }else if (result.numbSigningRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeSigningpresent,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerSection = false;
                        }else {
                            this.statusModalTitle = 'Deactivate Section';
                            this.status = this.label.AskToDeactivateSection;
                            this.statusFunction = 'deactivate';
                            this.isOpenConfirmation = true;
                            this.spinnerSection = false;
                        }
                    }
                })
                .catch(error => {
                    this.error = error;
                    this.spinnerSection = false;
                });
            }
        }

    acceptStatusChange(){
        this.spinnerSection = true;
        //let lstIsRetainTOLead = [];
        var selectedSections = this.template.querySelector('lightning-datatable').getSelectedRows();
        let lstIdSections = [];
        //let isRetainLeadExists = false;

        //RRA - ticket 585 - 23032023 
        for (let i=0;i<selectedSections.length;i++){
                lstIdSections.push(selectedSections[i].Id);
        }
        if(selectedSections.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Sections selected',
                    variant: 'error',
                }),
            );
        }
        else{
            for (var key in selectedSections) {
                var obj = selectedSections[key];
                delete obj.SubLoB__c;
                delete obj.LoB__c;
                delete obj.Currency__c;
            }

            //Get Section with retain to lead is true
            /*for (let i=0;i<selectedSections.length;i++){
                lstIsRetainTOLead.push(selectedSections[i].Retained_to_lead__c);
            }
            if (lstIsRetainTOLead != null || lstIsRetainTOLead != undefined){
                lstIsRetainTOLead.forEach(item => {
                    if (item === true){
                        isRetainLeadExists = true;
                    }
                });
            }*/

            if(this.statusFunction == 'reactivate'){
                changeStatus({lstRecords: selectedSections, objectName: 'Section', status: '1', isButtonActDeact : false}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                 title: 'Success',
                                 message: result.Success,
                                 variant: 'success',
                             }),
                        );
                        fireEvent(this.pageRef, 'refreshSection', 'refresh' );
                        this.spinnerSection = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
            else if(this.statusFunction == 'deactivate'){
                //Update the status Section to cancelled 
                changeStatus({lstRecords: selectedSections, objectName: 'Section', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerSection = false;
                    }
                    else{
                        //if (isRetainLeadExists){
                        this.spinnerSection = true;
                        //Update the retain to lead field to false if Status is cancelled
                        console.log('result section update == ', result);
                        updateRetainToLeadDeactivation({lstIds: lstIdSections, objectName: 'Section'}) //RRA - ticket 585 23032023
                        .then(result => {
                            if(result.hasOwnProperty('Error') && result.Error){
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: result.Error,
                                        variant: 'error',
                                    }),
                                );
                                this.spinnerSection = false;
                            }
                            else{
                                if(result == 'Updated successfully'){
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh' );
                                }else if (result == null){
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh' );
                                }else{
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Error',
                                            message: result,
                                            variant: 'error',
                                        }),
                                    );
                                    this.spinnerSection = false;
                                }
                            }
                        })
                        .catch(error => {
                            this.error = error;
                        });
                        //}

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result.Success,
                                variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshProgram', 'refresh');
                        fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                        fireEvent(this.pageRef, 'refreshSection', 'refresh');
                        console.log('Accept section ok');
                        this.spinnerSection = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                    this.spinnerSection = false;
                });
            }
        }
        this.isOpenConfirmation = false;
    }
    
    handleRowAction(event){
        var actionName = event.detail.action.name;
        this.selectedSectionCopy = event.detail.row;
        this.uwYear = this.selectedSectionCopy.Program__r.UwYear__c
        switch (actionName) {
            case 'copy':
                this.copySectionDetail();
                break;
            case 'newOption':
                this.newOptionSection();
                break;
        }
    }

    copySectionDetail(){
         if(this.disableSectionBtns == true || this.allReadOnly == true){
             this.dispatchEvent(new ShowToastEvent({title: 'Info',
                                     message: this.label.PCCInactiveCopyNotAllowed,
                                     variant: 'info',
                                 }),);
         }
         else{
             this.isOpenModal = true;
             this.recordId = this.mySelectedTreaties[0];
             this.isCopy = true;
             this.isNewOption = false;
         }

    }

    newOptionSection(){
        if(this.disableSectionBtns == true || this.allReadOnly == true){
            this.dispatchEvent(new ShowToastEvent({title: 'Info',
                                                     message: 'The Principal Ceding Company is inactive. Cannot create New Option.',
                                                     variant: 'info',
                                                 }),);
        }
        else{
            if(this.selectedSectionCopy.RelatedSection__c != null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.label.CannotCreateNewOption,
                        variant: 'error',
                    }),
                );
            }else{
                this.isOpenModal = true;
                this.recordId = this.mySelectedTreaties[0];
                this.isNewOption = true;
                this.isCopy = false;
            }
        }
    }

    deleteBtn(){
        //let lstIsRetainTOLead = [];
        let lstIdSection = [];
        let isRetainLeadExists = false;
        let selectedSections = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedSections == ', selectedSections);
        console.log('selectedProgram == ', this.selectedProgram);
        console.log('mySelectedTreaties == ', this.mySelectedTreaties);

        if(selectedSections.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Sections selected',
                    variant: 'error',
                }),
            );
        }
        else{

            // RRA - ticket - 1347 24112022
            for (let i=0;i<selectedSections.length;i++){
                lstIdSection.push(selectedSections[i].Id);
            }
            console.log('lstIdSection == ', lstIdSection);
            checkStatusRequestQuoteLead({lstSectionId: lstIdSection, lstTreatyId : null})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                }
                else{
                    let quoteLeadSetup = result.setCombSetup;
                    let quoteLeadSent = result.setCombSent;
                    let quoteLeadSetupSent = result.setCombSetupSent;
                    let quoteLeadSetupAnswered = result.setCombSetupAnswered;
                    let quoteLeadSetupTimeout = result.setCombSetupTimeout;
                    let quoteLeadSentSetup = result.setCombSentSetup;
                    let quoteLeadAnswered = result.setCombAnswered;
                    let quoteLeadTimeout = result.setCombTimeout;
                    let quoteLeadSentAnswered = result.setCombSentAnswered;
                    let quoteRefused = result.setCombQuoteRefused;
                    let quoteLeadSentTimeout = result.setCombSentTimeout;
                    let quoteLeadAnsweredSetup = result.setCombAnsweredSetup;
                    let quoteLeadAnsweredSent = result.setCombAnsweredSent;
                    let quoteLeadAnsweredAnswered = result.setCombAnsweredAnswered;
                    let quoteLeadAnsweredTimeout = result.setCombAnsweredTimeout;
                    let quoteLeadRefusedSetup = result.setCombRefusedSetup;
                    let quoteLeadRefusedSent = result.setCombRefusedSent;
                    let quoteLeadRefusedAnswered = result.setCombRefusedAnswered;
                    let quoteLeadRefusedTimeout = result.setCombRefusedTimeout;
                    let quoteLeadTimeoutSetup = result.setCombTimeoutSetup;
                    let quoteLeadTimeoutSent = result.setCombTimeoutSent;
                    let quoteLeadTimeoutAnswered = result.setCombTimeoutAnswered;
                    let quoteLeadTimeoutTimeout = result.setCombTimeoutTimeout;

                    let quoteLeadOnlyTimeout = result.setCombQuoteOnlyTimeout;
                    //let quoteLeadRefused = result.setCombQuoteRefused;
                    let quoteAnswered = result.setCombAnsweredQuoteOnly;   
                    let quoteSetup = result.setCombQuoteSetup; 
                    let quoteSent = result.setCombQuoteSent; 

                    let leadOnlyTimeout = result.setCombLeadOnlyTimeout;
                    let leadAnswered = result.setCombLeadAnswered;   
                    let leadSetup = result.setCombLeadSetup; 
                    let leadSent = result.setCombLeadSent;
                    //let isDeleteSection = result.isDeleteSection;


                    console.log('leadAnswered == ', leadAnswered);
                    console.log('quoteLeadSetup == ', quoteLeadSetup);
                    console.log('quoteLeadSent == ', quoteLeadSent);
                    console.log('quoteLeadSetupSent == ', quoteLeadSetupSent);
                    console.log('quoteLeadSetupAnswered == ', quoteLeadSetupAnswered);
                    console.log('quoteLeadSetupTimeout == ', quoteLeadSetupTimeout);
                    console.log('quoteLeadSentSetup == ', quoteLeadSentSetup);
                    console.log('quoteLeadAnswered == ', quoteLeadAnswered);
                    console.log('quoteLeadTimeout == ', quoteLeadTimeout);
                    console.log('quoteLeadSentAnswered == ', quoteLeadSentAnswered);
                    console.log('quoteRefused == ', quoteRefused);

                    console.log('quoteAnswered == ', quoteAnswered);
                    console.log('quoteLeadSentTimeout == ', quoteLeadSentTimeout);
                    console.log('quoteLeadAnsweredSetup == ', quoteLeadAnsweredSetup);
                    console.log('quoteLeadAnsweredSent == ', quoteLeadAnsweredSent);
                    console.log('quoteLeadAnsweredAnswered == ', quoteLeadAnsweredAnswered);
                    console.log('quoteLeadAnsweredTimeout == ', quoteLeadAnsweredTimeout);
                    console.log('quoteLeadRefusedSetup == ', quoteLeadRefusedSetup);
                    console.log('quoteLeadRefusedSent == ', quoteLeadRefusedSent);
                    console.log('quoteLeadRefusedAnswered == ', quoteLeadRefusedAnswered);
                    console.log('quoteLeadRefusedTimeout == ', quoteLeadRefusedTimeout);
                    console.log('quoteLeadTimeoutSetup == ', quoteLeadTimeoutSetup);
                    console.log('quoteLeadTimeoutSent == ', quoteLeadTimeoutSent);
                    console.log('quoteLeadTimeoutAnswered == ', quoteLeadTimeoutAnswered);
                    console.log('quoteLeadTimeoutTimeout == ', quoteLeadTimeoutTimeout);

                    if (quoteLeadSetup.includes('Quote_Setup', 'Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadSent.includes('Quote_Sent','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadSetupSent.includes('Quote_Setup','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadSetupAnswered.includes('Quote_Setup','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnLead,variant: 'error',}),)
                    }else if(quoteLeadSetupTimeout.includes('Quote_Setup','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadSentSetup.includes('Quote_Sent','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadAnswered.includes('Quote_Answered','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadTimeout.includes('Quote_Timeout','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadSentAnswered.includes('Quote_Sent','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnLead,variant: 'error',}),)
                    }else if(quoteRefused =='Quote_Refused' || quoteAnswered == 'Quote_Answered'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadSentTimeout.includes('Quote_Sent','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadAnsweredSetup.includes('Quote_Answered','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadAnsweredSent.includes('Quote_Answered','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadAnsweredAnswered.includes('Quote_Answered','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadAnsweredTimeout.includes('Quote_Answered','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedSetup.includes('Quote_Refused','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedSent.includes('Quote_Refused','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedAnswered.includes('Quote_Refused','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadRefusedTimeout.includes('Quote_Refused','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnQuote,variant: 'error',}),)
                    }else if(quoteLeadTimeoutSetup.includes('Quote_Timeout','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadTimeoutSent.includes('Quote_Timeout','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if(quoteLeadTimeoutAnswered.includes('Quote_Timeout','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnLead,variant: 'error',}),)
                    }else if(quoteLeadTimeoutTimeout.includes('Quote_Timeout','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (quoteSetup == 'Quote_Setup'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (quoteSent == 'Quote_Sent'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (quoteLeadOnlyTimeout == 'Quote_Timeout'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (leadSetup == 'Lead_Setup'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (leadSent == 'Lead_Sent'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (leadOnlyTimeout == 'Lead_Timeout'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresent,variant: 'error',}),)
                    }else if (leadAnswered == 'Lead_Answered'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteSectionOnLead,variant: 'error',}),)
                    }else{
                        this.delMsgTitle = 'Delete Section';
                        //You are going to delete the selected Section(s). Do you want to continue?
                        this.delMessage = this.label.AskToDeleteSection;
                        this.isDeleteOpen = true;
                    }
                }
            })
            .catch(error => {
                this.error = error;
                this.spinnerSection = false;
            });

        }
    }

    acceptDelete(){
        this.spinnerSection = true;
        var selectedSections = this.template.querySelector('lightning-datatable').getSelectedRows();
        // MRA W-0804 09/09/2022 : START
        
        let concatSectionNumberValue = '' ;
        selectedSections.forEach(element => {
            let currentItem = this.data.find(item => (item.TECH_RelatedSectionNumber__c === element.SectionNumber__c));
            if (currentItem !== undefined && !concatSectionNumberValue.includes(element.SectionNumber__c)) {
                concatSectionNumberValue = concatSectionNumberValue +'/'+ element.SectionNumber__c
            }
        });
        concatSectionNumberValue = concatSectionNumberValue.substring(1) ;
        if ( concatSectionNumberValue !== '' && this.yesForDelete === false) {
            this.spinnerSection = false;
            this.isDeleteOpen = false ;
            this.isDialogVisible = true ; 
            this.confirmMessage = 'You are going to delete the following sections “('+concatSectionNumberValue+')”. Your action will also delete all the options relative to those sections. Are you sure you want to delete those sections and all related options?' ;
        }
        else{        
            this.isDialogVisible = false ;
            this.spinnerSection = true;
            deleteSections({lstRecords: selectedSections, objectName: 'Section__c'})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                    this.spinnerSection = false;
                }
                else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result.Success,
                            variant: 'success',
                        }),
                    );
                    this.yesForDelete = false ;  
                    fireEvent(this.pageRef, 'refreshSection', 'refresh');
                    this.spinnerSection = false;
                }
            })
            .catch(error => {
                this.error = error;
            });
            this.isDeleteOpen = false;
        }
    }
    handleConfirmationModal(event){
        if(event.target.name === 'confirmModal'){
            if(event.detail !== 1){
                if(event.detail.status === 'confirm') {
                    this.yesForDelete = true ;  
                    this.acceptDelete() ;
                }
                else if(event.detail.status === 'cancel'){
                    this.isDialogVisible = false ;
                }    
            }
            else{
                this.displaySpinner = false;
            }
        }
    }
    // MRA W-0804 09/09/2022 : END


    handleOpenRetainedToLeadModal(){
        let selectedSections = this.template.querySelector('lightning-datatable').getSelectedRows();
        //RRA - ticket 585 - 09032023
        console.log('selectedSections == ', selectedSections);
        //console.log('dataRetainedtoLead == ', this.dataRetainedtoLead);
        let isStatusCancelledRet = false;
        if (selectedSections.length > 0){
            for (let i=0; i<selectedSections.length; i++){
                console.log('Status__c == ', selectedSections[i].Status__c);
                if (selectedSections[i].Status__c == 'Cancelled'){
                    isStatusCancelledRet = true;
                }
            }
        }
        
        console.log('isStatusCancelledRet == ', isStatusCancelledRet);
        if (isStatusCancelledRet){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SomeSecletedSectionsCancelled, variant: 'error'}),);
        }else{
            this.openRetainedToLeadModal = true;
            this.disableSendToLeadBtn = true // RRA - ticket 1399 - 30012023
        }
        
    }

    handleCloseRetainedToLeadModal(){
        this.openRetainedToLeadModal = false;
    }

    handleRetainedToLeadRowSelection(event){
        let selectedSectionsRow = event.detail.selectedRows;
        this.selectedRowSection = event.detail.selectedRows;
        let selectedSectionsRowId = [];
        let updDataRetainedToLead = [];
        let lstSectionNumbers = [];;
        //for each selected sections, add section id to list selectedSectionsRowId
        //selectedSectionsRowId = List of SectionId for selected row ['a','b','c']
        if(selectedSectionsRow.length > 0){
//           selectedSectionsRow.forEach((section)=>selectedSectionsRowId.push(section.Id));
           for(let i = 0; i < selectedSectionsRow.length; i++){
               let section = selectedSectionsRow[i];
               selectedSectionsRowId.push(section.Id);
               lstSectionNumbers.push(section.Treaty__c + '-' + section.SectionNumber__c);

               if(section.RelatedSection__r != undefined){
                   lstSectionNumbers.push(section.Treaty__c + '-' + section.RelatedSection__r.SectionNumber__c);
               }
            }
        }

        let hasNoDupl = lstSectionNumbers.every(num => lstSectionNumbers.indexOf(num) === lstSectionNumbers.lastIndexOf(num));
        console.log('hasNoDupl == ', hasNoDupl);
        if(hasNoDupl == false && selectedSectionsRow.length == this.dataRetainedtoLead.length){
            this.template.querySelector('[data-id="tableId"]').selectedRows = []; //RRA - ticket 1399 - 27012023
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RetainToLeadSameFamily, variant: 'error'}),);
            this.disableSendToLeadBtn = true; //RRA - ticket 1399 - 24012023
            return false;
        }else if (hasNoDupl == false && selectedSectionsRow.length >= 2){ //RRA - ticket 1399 - 27012023
            this.disableSendToLeadBtn = false; //RRA - ticket 1399 - 24012023
        }else if (hasNoDupl == false){ //RRA - ticket 1399 - 24012023
            this.disableSendToLeadBtn = true; //RRA - ticket 1399 - 24012023
        }else {
            this.disableSendToLeadBtn = false; //RRA - ticket 1399 - 24012023
        }

        //for each row in existing list dataRetainedtoLead, add section id to selectedSectionsRowIdRetainToLead if retainToLead is true
        //selectedSectionsRowIdRetainToLead = List of SectionId for previous selection row where retainToLead = true ['a', 'b']
        let selectedSectionsRowIdRetainToLead = [];
        for(let i = 0; i < this.dataRetainedtoLead.length; i++){
            if(this.dataRetainedtoLead[i].retainToLead == true){
                selectedSectionsRowIdRetainToLead.push(this.dataRetainedtoLead[i].Id);
            }
        }

        //get the actual row that has been checked since 'event.detail.selectedRows' returns a list of selected rows
        //if the user has checked a value, the length list of selected rows would be greater than that of existing list
        //selectedRowCheckSectionId = SectionId for new['a', 'b', 'c'] - old ['a', 'b'] = different['c']
        let selectedRowCheckSectionId = [];
        if(selectedSectionsRowId.length > selectedSectionsRowIdRetainToLead.length){
            for(let i = 0; i < selectedSectionsRowId.length; i++){
                if(!selectedSectionsRowIdRetainToLead.includes(selectedSectionsRowId[i])){
                    selectedRowCheckSectionId.push(selectedSectionsRowId[i]);
                }
            }
        }
        if(selectedSectionsRowIdRetainToLead.length > selectedSectionsRowId.length){
            for(let i = 0; i < selectedSectionsRowIdRetainToLead.length; i++){
                if(!selectedSectionsRowId.includes(selectedSectionsRowIdRetainToLead[i])){
                    selectedRowCheckSectionId.push(selectedSectionsRowIdRetainToLead[i]);
                }
            }
        }
        let selectedRowCheckSection = [];
        for(let i = 0; i < selectedSectionsRow.length; i++){
            if(selectedRowCheckSectionId.includes(selectedSectionsRow[i].Id)){
                selectedRowCheckSection.push(selectedSectionsRow[i].sectionNumber);
            }
        }

        for(let i = 0; i < this.dataRetainedtoLead.length; i++){
            let row = this.dataRetainedtoLead[i];

            if(selectedRowCheckSectionId.includes(row.Id)){
                if(this.setTreatiesForExistedLeadRequest.has(row.Treaty__c)){
                    row.retainToLead = false;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.RetainToLeadError, variant: 'error'}),);
                }
                else{
                    if(row.retainToLead == true){
                        row.retainToLead = false;
                    }
                    else{
                        row.retainToLead = true;
                    }
                }
            }
            else if(selectedRowCheckSection.includes(row.sectionNumber)){
                row.retainToLead = false;
            }

            updDataRetainedToLead.push(row);
        }

        this.dataRetainedtoLead = updDataRetainedToLead;

        let lstRetainToLeadId = [];

        //Add section Id to list lstRetainToLeadId where retainToLead is true
        for(let j = 0; j < this.dataRetainedtoLead.length; j++){
            if(this.dataRetainedtoLead[j].retainToLead == true){
                lstRetainToLeadId.push(this.dataRetainedtoLead[j].Id)
            }
        }

        //if length of list lstRetainToLeadId is 0, disable send button or else, enable the send button
        if(lstRetainToLeadId.length == 0 || selectedSectionsRow.length == 0){
            this.disableSendToLeadBtn = true;
        }
        else {
            //this.disableSendToLeadBtn = false;
        }

        //set pre selected row values for retained to lead
        this.preSelectedRetainedToLead = lstRetainToLeadId;
    }

    //RRA - ticket 1533 - 12062023
   handleSaveRetainedToLead(){
        let lstSec = [];
        console.log('selectedRowSection == ', this.selectedRowSection);
        let isStatusCancelledRet = false;
        if (this.selectedRowSection.length > 0){
            for (let i=0; i<this.selectedRowSection.length; i++){
                if (this.selectedRowSection[i].Number_of_subsections__c == 0 && this.selectedRowSection[i].Program__r.Macro_L_O_B__c == '25002' &&  this.selectedRowSection[i].isNoSubSection__c == false){ //RRA - ticket 1802 - 15122023
                    lstSec.push(this.selectedRowSection[i]);
                }
                console.log('Status__c == ', this.selectedRowSection[i].Status__c);
                if (this.selectedRowSection[i].Status__c == 'Cancelled'){
                    isStatusCancelledRet = true;
                }
            }
            console.log('lstSec Section== ', lstSec);
        }
        
         //RRA - ticket 1533 - 15062023
         if (lstSec.length>0){
            this.sortData(lstSec, 'fieldLayer__c','Sort_SectionNumber__c','','','asc'); 
            const result = modalPopUpWarningMsgSubSection.open({
                label: this.label.NoSubSectionInSection,
                size: 'large',
                columnSections: [...this.columnSections],
                //isDisableBtn : true,
                someDataSection : [...lstSec]
            });
        }
         
        if (isStatusCancelledRet){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.SomeSecletedSectionsCancelled, variant: 'error'}),);
        }else{
            saveRetainedToLeadSection({lstSectionId : this.preSelectedRetainedToLead, lstSelectedTreaties: this.mySelectedTreaties})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                }
                else{
                    this.titleCountSections= this.label.Sections + ' (' + result.lstSections.length + ')';
                    var newResult = [];
                    for(var i = 0; i < result.lstSections.length; i++){
                        let row = Object.assign({}, result.lstSections[i]);
                        if(row.LoB__c != undefined || row.LoB__c != null){
                            Object.defineProperty( row, 'LoB__c', {
                                value: this.mapLOb.get(row.LoB__c),
                                writable: true,
                                enumerable: true,
                                configurable: true
                            });
                        }
                        if(row.SubLoB__c != undefined || row.SubLoB__c != null){
                            Object.defineProperty( row, 'SubLoB__c', {
                                value: this.mapSubLob.get(row.SubLoB__c),
                                writable: true,
                                enumerable: true,
                                configurable: true
                            });
                        }
                        newResult.push(row);
                    }

                    let nameUrl;
                    let classRetainToLeadData;
                    this.data = newResult.map(row => {
                        nameUrl = '../r/Section__c/'+row.Id+'/edit';
                        if(row.Retained_to_lead__c == true){
                            classRetainToLeadData = 'slds-icon slds-icon-text-success slds-icon_x-small'; // RRA - 1045
                        }
                        else{
                            classRetainToLeadData = 'slds-icon slds-icon-text-default slds-icon_x-small'; // RRA - 1045
                        }
                        return {...row , nameUrl, classRetainToLeadData}
                    });

                    //RRA - ticket 1365 - 08122022 (Displaying Layer)
                    for(let i = 0; i < this.data.length; i++){
                        this.data[i]['Layer'] = this.data[i].Treaty__r.Layer__c;
                    }

                    for(let i = 0; i < this.data.length; i++){
                        let sectionNum = this.data[i].SectionNumber__c;
                        let sectionNumberStr = this.data[i].Treaty__c + '-' +sectionNum.split(".")[0];
                        if(this.data[i].Retained_to_lead__c == true){
                            this.lstSectionNumberRetainToLeadTrue.push(sectionNumberStr);
                        }
                    }

                    let retainToLead = false;
                    let sectionNumber;
                    let iconNameRetainToLead;
                    let classRetainToLead;
                    let retainToLeadValue = false; 

                    this.dataRetainedtoLead = this.data.map(row => {
                        console.log('Layer retain == ', row.Treaty__r.Layer__c);
                        let sectionNum = row.SectionNumber__c;
                        sectionNumber =  row.Treaty__c + '-' +sectionNum.split(".")[0];

                        if(this.lstSectionNumberRetainToLeadTrue.includes(sectionNumber)){
                            retainToLeadValue = true;
                        }
                        else{
                            retainToLeadValue = false;
                        }

                        if(row.Retained_to_lead__c == true){
                            retainToLead = false;
                            classRetainToLead = 'slds-icon slds-icon-text-success slds-icon_x-small'; // RRA - 1045
                        }
                        else{
                            retainToLead = false;
                            classRetainToLead = 'slds-icon slds-icon-text-default slds-icon_x-small'; // RRA - 1045
                        }
                        return {...row , retainToLead, sectionNumber, iconNameRetainToLead, classRetainToLead, retainToLeadValue}
                    });

                    if(this.dataRetainedtoLead.length > 0){
                        this.disableRetainToLeadBtn = false;
                    }
                    else{
                        this.disableRetainToLeadBtn = true;
                    }
                    this.preSelectedRetainedToLead = [];

                    this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.RetainedToLeadSectionsSuccessfully, variant: 'success' }),);
                    this.handleCloseRetainedToLeadModal();
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
            });
        }
    }
}