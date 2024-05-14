import {LightningElement, track, wire, api} from 'lwc';
import getTreaties from '@salesforce/apex/LWC01_Treaties.getTreaties';
import changeStatus from '@salesforce/apex/LWC01_HomePageActions.reactivateDeactivate';
import checkRequestExist from '@salesforce/apex/LWC01_HomePageActions.checkRequestExist'; //RRA - ticket 585 - 22032023
import deleteTreaties from '@salesforce/apex/LWC01_HomePageActions.deleteRecords';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import checkStatusRequestQuoteLead from '@salesforce/apex/LWC01_Sections.checkStatusRequestQuoteLead';
import updateRetainToLeadDeactivation from '@salesforce/apex/LWC01_Sections.updateRetainToLeadDeactivation'; //RRA - ticket 585 - 22032023
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import isProgramEmpty from '@salesforce/apex/LWC01_Treaties.isProgramEmpty';
import getSelectedProgramDetail from '@salesforce/apex/LWC01_Treaties.getSelectedProgramDetail';

//import custom labels
import Treaties from '@salesforce/label/c.Treaties';
import NewTreaty from '@salesforce/label/c.NewTreaty';
import Reactivate from '@salesforce/label/c.Reactivate';
import Deactivate from '@salesforce/label/c.Deactivate';
import Delete from '@salesforce/label/c.Delete';
import Copy from '@salesforce/label/c.Copy';
import Program from '@salesforce/label/c.Program';
import Layer from '@salesforce/label/c.Layer';
import WebXL_Reference from '@salesforce/label/c.WebXL_Reference';
import Name from '@salesforce/label/c.Name';
import Share from '@salesforce/label/c.Share';
import Status from '@salesforce/label/c.Status';
import Type from '@salesforce/label/c.Type';
import Actions from '@salesforce/label/c.Actions';
import Close from '@salesforce/label/c.Close';
import Accept from '@salesforce/label/c.Accept';
import Cancel from '@salesforce/label/c.Cancel';
import AskToReactivateTreaty from '@salesforce/label/c.AskToReactivateTreaty';
import AskToDeactivateTreaty from '@salesforce/label/c.AskToDeactivateTreaty';
import NoTreatiesSelected from '@salesforce/label/c.NoTreatiesSelected';
import AskToDeleteTreaty from '@salesforce/label/c.AskToDeleteTreaty';
import PCCInactiveCopyNotAllowed from '@salesforce/label/c.PCCInactiveCopyNotAllowed';
import errorMsg from '@salesforce/label/c.errorMsg';
import SomeQuoteOrLeadPresentOnTreaty from '@salesforce/label/c.SomeQuoteOrLeadPresentOnTreaty';
import YouCannotDeleteTreatyOnLead from '@salesforce/label/c.YouCannotDeleteTreatyOnLead';
import YouCannotDeleteTreatyAnsweredTwoPhases from '@salesforce/label/c.YouCannotDeleteTreatyAnsweredTwoPhases';
import YouCannotDeleteTreatyOnQuote from '@salesforce/label/c.YouCannotDeleteTreatyOnQuote';

const actions = [
    { label: Copy, name: 'copy'}
];

const columns = [
    { label: Program, fieldName: 'TECH_ProgramName__c' },
    { label: Layer, fieldName: 'Layer__c', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Treaty Ref.', fieldName: 'WebXLReference__c' },
    { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_self'} },
    { label: Type, fieldName: 'TypeofTreaty__c'},
    { label: 'Placement Share', fieldName: 'placementShare', cellAttributes: { alignment: 'left' }},
    { label: 'Cession Share', fieldName: 'cessionShare', cellAttributes: { alignment: 'left' }},//RRA - ticket 1966 - 17032023
    { label: Status, fieldName: 'Status__c' },
    { label: Actions, type: 'action', fixedWidth: 70, typeAttributes: {rowActions: actions, menuAlignment:'auto'}}
];

export default class LWC01_Treaties extends NavigationMixin(LightningElement) {
    label = {
        Treaties,
        NewTreaty,
        Reactivate,
        Deactivate,
        Delete,
        Copy,
        Program,
        Layer,
        WebXL_Reference,
        Name,
        Share,
        Status,
        Type,
        Close,
        Accept,
        Cancel,
        AskToReactivateTreaty,
        AskToDeactivateTreaty,
        NoTreatiesSelected,
        AskToDeleteTreaty,
        PCCInactiveCopyNotAllowed,
        errorMsg,
        SomeQuoteOrLeadPresentOnTreaty,
        YouCannotDeleteTreatyOnLead,
        YouCannotDeleteTreatyAnsweredTwoPhases,
        YouCannotDeleteTreatyOnQuote,
    }

    @api mySelectedPrograms;
    @api programRecordId;
    @api conditionPage = false;
    @api allReadOnly = false;
    @track selectedTreaty = [];
    @track lstSortedProgNames = [];
    wiredTreaties;
    error;
    dataTreaties;
    columns = columns;
    mySelectedTreaties = null;
    myProgram = null;
    titleCountTreaties = this.label.Treaties + ' (0)';
    isOpenModal = false;
    isOpenConfirmation = false;
    uwYear;
    comp;
    disableNewTreatyBtn = true;
    hideButtons = true;
    statusModalTitle;
    status;
    statusFunction;
    isCopy = false;
    isDeleteOpen = false;
    delMsgTitle;
    delMessage;
    spinnerTreaty = false;
    displayErrorMsg = false;

    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        if(this.conditionPage && this.mySelectedPrograms != null){
            this.disableNewTreatyBtn = false;
        }

        if(this.conditionPage){
            this.hideButtons = false;
        }
        registerListener('selectedPrograms', this.getSelectedPrograms, this);
        registerListener('hideBtns', this.toggleBtn, this);
        registerListener('year', this.getYear, this);
        registerListener('comp', this.getComp, this);
        registerListener('closeTreatyModal', this.setIsOpenModalFalse, this);
        registerListener('refreshTreaties', this.refreshDataTreaties, this);
        registerListener('treatiesCreated', this.refAfterNew,this);
        registerListener('filterProgram', this.getProgram, this);
    }

    getProgram(val){
        if(val != null){
            let progId = [];
            progId.push(val.Id);
            this.mySelectedPrograms = progId;
        }
    }

    setIsOpenModalFalse(val){
        this.isOpenModal = val;
    }

    toggleBtn(val){
        this.hideButtons = val;
    }

    getYear(val){
        this.uwYear = val;
        if(this.conditionPage){
            this.dataTreaties = undefined;
            this.titleCountTreaties = this.label.Treaties + ' (0)';
        }
    }

    getComp(val){
        this.comp = val;
        if(this.conditionPage){
            this.dataTreaties = undefined;
            this.titleCountTreaties = this.label.Treaties + ' (0)';
        }
    }

    getSelectedPrograms(selectedPrograms){
        if(this.conditionPage){
        }
        else{
            this.spinnerTreaty = true;
            this.mySelectedPrograms = selectedPrograms;
            if(this.mySelectedPrograms.length == 1 && this.hideButtons == false){
                this.disableNewTreatyBtn = false;
            }
            else{
                this.disableNewTreatyBtn = true;
            }
            this.spinnerTreaty = false;
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
            this.comp = data[0].value;
        }
        else{
            this.error = error;
        }
    }

    @wire(getTreaties, {lstSelectedPrograms: '$mySelectedPrograms'})
    wiredGetTreaties(result){
        this.spinnerTreaty = true;
        this.wiredTreaties = result;
        if(result.data){
            this.titleCountTreaties = this.label.Treaties + ' (' + result.data.length + ')';
            let nameUrl;
            let placementShare;
            let cessionShare;//RRA - ticket 1966 - 17032024

            if(result.data.length > 0){
                this.dataTreaties = result.data.map(row => {
                    nameUrl = '../r/Treaty__c/'+row.Id+'/edit';
                    placementShare = (row.PlacementShare_Perc__c != undefined || !isNaN(row.PlacementShare_Perc__c)) ? parseFloat(row.PlacementShare_Perc__c).toFixed(6).replace('.',',') : null;//RRA - ticket 1966 - 17032024
                    cessionShare = (row.CessionShare__c != undefined || !isNaN(row.CessionShare__c)) ? parseFloat(row.CessionShare__c).toFixed(6).replace('.',',') : null;//RRA - ticket 1966 - 17032024
                    return {...row , nameUrl, placementShare, cessionShare}
                });
            }
            else{
                this.dataTreaties = result.data;
            }

            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
            this.dataTreaties = undefined;
        }

        this.sortData('TECH_ProgramName__c', 'Layer__c', 'asc');
        this.spinnerTreaty = false;
    }

    handleRowSelection(event) {
        let selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        let treatyIds = [];

        if(selectedTreaties.length > 0){
            selectedTreaties.forEach((treaty)=>treatyIds.push(treaty.Id));
        }
        fireEvent(this.pageRef, 'hideSectionBtn', this.hideButtons);
        fireEvent(this.pageRef, 'selectedTreaties', treatyIds);
        fireEvent(this.pageRef, 'selectedProgram', this.mySelectedPrograms);//fire event-- Section listen to event

    }

    refreshDataTreaties(){
        return refreshApex(this.wiredTreaties);
    }

    sortData(fieldName,fieldName2, sortDirection) {
        let sortResult = Object.assign([], this.dataTreaties);
        this.dataTreaties = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                if(a[fieldName2] < b[fieldName2])
                    return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])
                    return sortDirection === 'asc' ? 1 : -1;
                else
                    return 0;
            }
        })
    }

    reactivateBtn(){
        this.spinnerTreaty = true;
        var selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedTreaties.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoTreatiesSelected,
                    variant: 'error',
                }),
            );
            this.spinnerTreaty = false;
        }
        else{
            this.statusModalTitle = 'Reactivate Treaty';
            //You are going to reactivate the selected Treaty(ies). Do you want to continue?
            this.status = this.label.AskToReactivateTreaty;
            this.statusFunction = 'reactivate';
            this.isOpenConfirmation = true;
            this.spinnerTreaty = false;
        }
    }

    deactivateBtn(){
        this.spinnerTreaty = true;
        var selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedTreaties.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoTreatiesSelected,
                    variant: 'error',
                }),
            );
            this.spinnerTreaty = false;
        }
        else{
             //RRA - ticket 585 - 21032023 => Don't applicate fields below on request SOQL from getTreaties (Remove field marked with toLabel in the SoQL query)
            for (var key in selectedTreaties) {
                var obj = selectedTreaties[key];
                delete obj.TypeofTreaty__c;
            }
            checkRequestExist({lstRecords: selectedTreaties, objectName: 'Treaty', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                             new ShowToastEvent({
                                 title: 'Error',
                                 message: result.Error,
                                 variant: 'error',
                             }),
                       );
                        this.spinnerTreaty = false;
                    }
                    else{

                        console.log('result Treaty == ', result);
                        //RRA - ticket 585 - 01032023
                        if (result.numbLeadRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeLeadpresent,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerTreaty = false;
                        }else if (result.numbPlacementRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeQuoteOrPlacementpresent,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerTreaty = false;
                        }else if (result.numbSigningRequest > 0){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: this.label.SomeSigningpresent,
                                    variant: 'error',
                                }),
                            );
                            this.spinnerTreaty = false;
                        }else{
                            this.statusModalTitle = 'Deactivate Treaty';
                            //You are going to deactivate the selected Treaty(ies). Do you want to continue?
                            this.status = this.label.AskToDeactivateTreaty;
                            this.statusFunction = 'deactivate';
                            this.isOpenConfirmation = true;
                            console.log('Accept ok');
                            this.spinnerTreaty = false;
                        }
                        
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            this.spinnerTreaty = false;
        }
    }

    acceptStatusChange(){
        this.spinnerTreaty = true;
        let lstIdTreaties = [];
        //let lstIdTreatiesConvert = [];
        var selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        //RRA - ticket 585 - 23032023 
        for (let i=0;i<selectedTreaties.length;i++){
            lstIdTreaties.push(selectedTreaties[i].Id);
        }
        //lstIdTreatiesConvert = JSON.parse(JSON.stringify(lstIdTreaties));
        console.log('lstIdTreaties == ', lstIdTreaties);
        if(selectedTreaties.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoTreatiesSelected,
                    variant: 'error',
                }),
            );
            this.spinnerTreaty = false;
        }
        else{
            for (var key in selectedTreaties) {
                var obj = selectedTreaties[key];
                delete obj.TypeofTreaty__c;
            }

            if(this.statusFunction == 'reactivate'){
                changeStatus({lstRecords: selectedTreaties, objectName: 'Treaty', status: '1', isButtonActDeact : false}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error',
                            }),
                        );
                        this.spinnerTreaty = false;
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result.Success,
                                variant: 'success',
                            }),
                        );
                        fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                        fireEvent(this.pageRef, 'refreshSection', 'refresh');
                        this.spinnerTreaty = false;
                    }

                })
                .catch(error => {
                    this.error = error;
                });
            }
            else if(this.statusFunction == 'deactivate'){
                changeStatus({lstRecords: selectedTreaties, objectName: 'Treaty', status: '2', isButtonActDeact : true}) //RRA - ticket 585 13032023
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                             new ShowToastEvent({
                                 title: 'Error',
                                 message: result.Error,
                                 variant: 'error',
                             }),
                       );
                        this.spinnerTreaty = false;
                    }
                    else{
                        console.log('lstIdTreaties 22== ', lstIdTreaties);
                        //RRA - ticket 585 - 23032023
                        //Update the retain to lead field to false if Status is cancelled
                        updateRetainToLeadDeactivation({lstIds: lstIdTreaties, objectName: 'Treaty'}) //RRA - ticket 585 23032023
                        .then(result => {
                            console.log('result treaty update == ', result);
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
                                    fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh');
                                }else if (result == null){
                                    fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                                    fireEvent(this.pageRef, 'refreshSection', 'refresh');
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

                        //RRA - ticket 585 - 21032023
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
                        console.log('Accept treaty ok');
                        this.spinnerTreaty = false;
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }
        }
        this.isOpenConfirmation = false;
    }

    handleOpenModal() {
        this.programRecordId = this.mySelectedPrograms[0];

        getSelectedProgramDetail({programId : this.programRecordId})
        .then(result => {
            if(result.RenewedFromProgram__c != null && result.RenewedFromProgram__c != undefined && (result.TypeOfRenew__c == 'LTA/TR Identical Renew')){
                this.displayErrorMsg = true;
                this.isOpenModal = true;
            }
            else{
                this.displayErrorMsg = false;
                this.isOpenModal = true;
                this.isCopy = false;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

    handleCloseModal(){
        this.isOpenModal = false;
        this.isCopy = false;
        this.isOpenConfirmation = false;
        this.isDeleteOpen = false;
        this.spinnerTreaty = false;
    }

    handleRowAction(event){
        var actionName = event.detail.action.name;
        this.selectedTreaty = event.detail.row;
        switch (actionName) {
            case 'copy':
                this.copyTreatyDetail();
                break;
        }
    }

    copyTreatyDetail(){
        if(this.hideButtons == true || this.allReadOnly == true){
            this.dispatchEvent(new ShowToastEvent({title: 'Info',
                                                     message: this.label.PCCInactiveCopyNotAllowed,
                                                     variant: 'info',
                                                 }),);
        }
        else{
            this.isOpenModal = true;
            this.programRecordId = this.mySelectedPrograms[0];
            this.isCopy = true;
        }
    }

    async deleteBtn(){
        let lstIdTreaty = [];
        var selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();
        if(selectedTreaties.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.NoTreatiesSelected,
                    variant: 'error',
                }),
            );
        }
        else{

            // RRA - ticket - 1413 27012023
            for (let i=0;i<selectedTreaties.length;i++){
                lstIdTreaty.push(selectedTreaties[i].Id);
            }
            console.log('lstIdTreaty == ', lstIdTreaty);
            await checkStatusRequestQuoteLead({lstSectionId: null, lstTreatyId : lstIdTreaty})
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
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadSent.includes('Quote_Sent','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadSetupSent.includes('Quote_Setup','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadSetupAnswered.includes('Quote_Setup','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnLead,variant: 'error',}),)
                    }else if(quoteLeadSetupTimeout.includes('Quote_Setup','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadSentSetup.includes('Quote_Sent','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadAnswered.includes('Quote_Answered','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadTimeout.includes('Quote_Timeout','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadSentAnswered.includes('Quote_Sent','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnLead,variant: 'error',}),)
                    }else if(quoteLeadSentTimeout.includes('Quote_Sent','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadAnsweredSetup.includes('Quote_Answered','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadAnsweredSent.includes('Quote_Answered','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadAnsweredAnswered.includes('Quote_Answered','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadAnsweredTimeout.includes('Quote_Answered','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedSetup.includes('Quote_Refused','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedSent.includes('Quote_Refused','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadRefusedAnswered.includes('Quote_Refused','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyAnsweredTwoPhases,variant: 'error',}),)
                    }else if(quoteLeadRefusedTimeout.includes('Quote_Refused','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if(quoteLeadTimeoutSetup.includes('Quote_Timeout','Lead_Setup')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadTimeoutSent.includes('Quote_Timeout','Lead_Sent')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if(quoteLeadTimeoutAnswered.includes('Quote_Timeout','Lead_Answered')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnLead,variant: 'error',}),)
                    }else if(quoteLeadTimeoutTimeout.includes('Quote_Timeout','Lead_Timeout')){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (quoteSetup == 'Quote_Setup'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (quoteSent == 'Quote_Sent'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (quoteLeadOnlyTimeout == 'Quote_Timeout'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (quoteRefused == 'Quote_Refused'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if (quoteAnswered == 'Quote_Answered'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnQuote,variant: 'error',}),)
                    }else if (leadSetup == 'Lead_Setup'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (leadSent == 'Lead_Sent'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (leadOnlyTimeout == 'Lead_Timeout'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.SomeQuoteOrLeadPresentOnTreaty,variant: 'error',}),)
                    }else if (leadAnswered == 'Lead_Answered'){
                        this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.YouCannotDeleteTreatyOnLead,variant: 'error',}),)
                    }else{
                        this.delMsgTitle = 'Delete Treaty';
                        //You are going to delete the selected Treaty(ies). Do you want to continue?
                        this.delMessage = this.label.AskToDeleteTreaty;
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
        this.spinnerTreaty = true;
        var selectedTreaties = this.template.querySelector('lightning-datatable').getSelectedRows();

        for (var key in selectedTreaties) {
            var obj = selectedTreaties[key];
            delete obj.TypeofTreaty__c;
        }

        deleteTreaties({lstRecords: selectedTreaties, objectName: 'Treaty__c'})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.spinnerTreaty = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result.Success,
                        variant: 'success',
                    }),
                );
                fireEvent(this.pageRef, 'refreshTreaties', 'refresh');
                fireEvent(this.pageRef, 'refreshSection', 'refresh');
                fireEvent(this.pageRef, 'evaluateNature', true); // MRA W-0779 18/08/2022
                this.spinnerTreaty = false;
            }
        })
        .catch(error => {
            this.error = error;
        });
        this.isDeleteOpen = false;
    }

    checkIfProgramEmptyOnChangeValue(){
        isProgramEmpty({ uwYear : this.uwYear, principalCedingCompany : this.comp})
        .then(result => {
            if(result == true){
                this.dataTreaties = undefined;
                this.titleCountTreaties = this.label.Treaties + ' (0)';
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }

}