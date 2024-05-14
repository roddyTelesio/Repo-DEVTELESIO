import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import {
    getObjectInfo,
    getPicklistValues
} from 'lightning/uiObjectInfoApi';
import {
    LightningElement,
    track,
    wire,
    api
} from 'lwc';
// all apex actions
import fetchPrograms from '@salesforce/apex/CreateClasseurs.fetchPrograms';
import fetchTreatys from '@salesforce/apex/CreateClasseurs.fetchTreatys';
import fetchSections from '@salesforce/apex/CreateClasseurs.fetchSections';
import insertClasseurs from '@salesforce/apex/CreateClasseurs.insertClasseurs';
import fetchClasseur from '@salesforce/apex/CreateClasseurs.fetchClasseur';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import {
    CurrentPageReference,
    NavigationMixin
} from 'lightning/navigation';
import sfpegJsonUtl from 'c/sfpegJsonUtl';
//labels 
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import QuoteTableUniqueTabName from '@salesforce/label/c.QuoteTableUniqueTabName';
import QuoteTableApexError from '@salesforce/label/c.QuoteTableApexError';
import QuoteTableNewSheet from '@salesforce/label/c.QuoteTableNewSheet';
import QuoteTableUwYear from '@salesforce/label/c.QuoteTableUwYear';
import QuoteTableTemplateSheetType from '@salesforce/label/c.QuoteTableTemplateSheetType';
//platform event subscriptions
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';

export default class CreateClasseurLwc extends NavigationMixin(LightningElement) {

    /**main info variables **/
    readOnlyMode = false; 
    quotationtablename;         // name of excel added by user
    selectedcomp = null;        // principal ceding company selected by user
    selecteduwyear = QuoteTableUwYear;    // Default UW year 
    uwYearOpt;          // Underwriting year option selected by user
    cedingAccOpt;       // List of available PCC for selection
    sheet = null;       // Currently selected sheet for selection
    optionsDisabled = true; // Disables selection of section/optionn if there are no sections to be selected
    type;
    allSections;            // all sections allowed for selection for the user
    allSectionDetails;      // all section with record details 
    mapSections;            // Map of sectionId:sectionData to easily get section details 
    //program variables 
    @track programs = [];   // list of programs available for selection
    @track programselected; // program currently selected
    // treaty variables
    @track Alltreatys = [];     // list of all treatys that are available for the user for selected program and ceding company 
    @track treatyDisplayed = [];// list of treatys displayed on the UI
    treaty;                     // treaty selected by the user (filtering)
    label = {   
        PrincipalCedingCompany,  // label for principal ceding company combobox
        QuoteTableUniqueTabName,
        QuoteTableApexError,
        QuoteTableNewSheet,
        QuoteTableTemplateSheetType
    };
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    @track loading = false;             // background operation in progress and displays a spinner
    @track selectedTabType = 'XLSL_DYN';// default selected tab type in "New modal" popup
    @track selectedSections = {};       // selected section per tab
    @track sectionsUnselectedDisplayed = [];    // List of sections available to display at a particular instance
    @track tabs = [];   // tabs created by user 
    @track sectionsSelectedDisplayed = []; // sections that are available to be displayed
    @track selectedSheetDisplayed = "name"; // selected sheet data displayed. Changed by checkbox on the datatable
    @track inputTabName = ''; // Tab name entered by the user in popup
    // Platform event subsriptions
    subscription = {};
    channelName = '/event/QuoteTableResponse__e';
    // platform event subscription end
    classeurId; // Id of the classeur__c record created for current QuoteTable
    // list of options available for tab selection in "New Tab" modal
    get tabTypes() {
        return [{
                label: 'XL/SL tableaux dynamiques',
                value: 'XLSL_DYN'
            },
            {
                label: 'XL/SL Comparaison ex-1',
                value: 'XLSL_COMP'
            },
            {
                label: 'QS/SP Tableaux dynamiques',
                value: 'QSSP_DYN'
            },
            {
                label: 'QS/SP Comparaison ex-1',
                value: 'QSSP_COMP'
            }
        ];
    }

    // navigation methods
    currentPageReference = null;
    urlStateParameters = null;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('this.urlStateParameters', this.urlStateParameters);
        }
    }
    connectedCallback() {
        console.log('connectedCallback: start');
        console.log('connectedCallback: this.urlStateParameters', this.urlStateParameters);
        if(this.urlStateParameters.c__id){this.initWithId();}
        console.log('connectedCallback: end');
    }

    // currently not used, kept for fture evolutions.
    // Case where the createClasseur has to be prefilled with existing classeur
    initWithId() {
        this.readOnlyMode = true;
        console.log('initWithId : Start Id ', Id);
        fetchClasseur({
                Id: Id
            })
            .then(result => {
                if (result) {
                    console.log('initWithId : result', result);
                    this.initComponentDomElements(result);
                } else {
                    this.message = "No Records Found for '" + Id + "'";
                    console.log('initWithId this.message ', this.message);
                }
            }).catch(error => {
                console.log(error);
            });
        console.log('initWithId : End');
    }

    /* 
        Initialises a classeur with prefilled values. Not used currently
    */
    initComponentDomElements(result) {
        console.log('initComponentDomElements : START');
        this.quotationtablename = result.classeur.Name;
        this.selecteduwyear = result.classeur.Exercise__c;
        this.selectedcomp = result.classeur.Cedente__c;
        this.fetchProgramRecords();
        this.programselected = result.classeur.Program__c;
        this.fetchTreatyRecords();
        this.fetchSectionRecords();
        this.selectedSections = result.mapSelectedSections;
        this.tabs = result.tabs;
        console.log('initComponentDomElements : END');
    }

    /***
    * @description	Method that handles change in section selection on dual listbox
    * @param        e, default event variable
    * @exception	None special (all catched and logged).
    ***/
    handleChangeSection(e) {
        let selectedSection = e.detail.value;
        console.log('handleChangeSection e : ', e);
        // update master object to set the approrpiate values
        this.selectedSections[this.selectedSheetDisplayed].sectionsSelected = selectedSection;
        this.sectionsSelectedDisplayed = selectedSection;
        console.log('handleChangeSection e : ', this.selectedSections[this.selectedSheetDisplayed].sectionsSelected);
        console.log('handleChangeSection : this.sectionsUnselectedDisplayed  ', this.sectionsUnselectedDisplayed);
    }

    /***
    * @description  When a tab is selected, the view is rendered to contain the appropriate sections/options selected by the user previously
    * @param        e, default event variable
    * @exception	None special (all catched and logged).
    ***/
    handleCheckboxClicked(e) {

        this.sheet = e.target.dataset.id;
        this.treaty = 'All';

        console.log('handleCheckboxClicked clicked: ', e);
        console.log('handleCheckboxClicked : e ', e.target.dataset.id);
        console.log('handleCheckboxClicked : tabs ', this.tabs);

        let selectedTabType = this.tabs.filter(row => {
            return row.name == this.sheet
        });
        var sheetType = selectedTabType[0].type;
        // deselect all other 
        console.log("handleCheckboxClicked : all sheets ", this.sections);
        console.log("handleCheckboxClicked : this.selectedSections ", this.selectedSections);
        console.log("handleCheckboxClicked : this.selectedSections[sheet] ", this.selectedSections[this.sheet]);
        console.log('handleCheckboxClicked : this.allSections', this.allSections);
        console.log('handleCheckboxClicked : sheetType', sheetType);

        // filtering to display only sections that match the type of tabs the user selected
        this.sectionsUnselectedDisplayed = this.allSections.data.filter(
            row => {

                if (sheetType == 'XLSL_DYN' || sheetType == 'XLSL_COMP') {
                    return (row.type == '1' || row.type == '2');
                } else {
                    return (row.type == '3' || row.type == '4');
                }
            }
        );
        
        // filtering to display only treaties that match the type of tabs the user selected
        this.treatyDisplayed = this.Alltreatys.filter(
            row => {
                if (sheetType == 'XLSL_DYN' || sheetType == 'XLSL_COMP') {
                    return (row.type == '1' || row.type == '2' || row.label == 'All')
                } else {
                    return (row.type == '3' || row.type == '4' || row.label == 'All')
                }
            }
        );
        // this.treaty = this.selectedSections[sheet].treatySelected; 
        this.sectionsSelectedDisplayed = this.selectedSections[this.sheet].sectionsSelected;
        this.selectedSheetDisplayed = this.sheet;
        this.optionsDisabled = false;
        this.setBoxes(e);
    }

    /***
    * @description  Initialises a new tab for the user and creates a new entry in the wrapper variable
    * @exception	None special (all catched and logged).
    ***/
    handleAddTab() {
        console.log('handleAddTab Start');
        console.log('handleAddTab : inputTabName ', this.inputTabName);
        console.log('handleAddTab : selectedTabType ', this.selectedTabType);
        this.inputTabName = this.inputTabName.replace(/\s/g, ''); 
        if(this.isNewTabInputValid() && this.isNewTabNameUnique()){
            // capture user input
            let input = {
                name: this.inputTabName,
                type: this.selectedTabType,
                selected: false
            }
            // maintain wrapper
            this.tabs = [...this.tabs, input];
            this.selectedSections[this.inputTabName] = {
                treatySelected: "",
                sectionsUnselected: [],
                sectionsSelected: []
            }
            // maintain wrapper end
            this.selectedSections[this.inputTabName].type = this.selectedTabType;
            console.log('handleAddTab : selected Sections ', this.selectedSections.toString());
            console.log('handleAddTab : input ', input);
            console.log('handleAddTab : tabs ', this.tabs);
            console.log('handleAddTab : End');
            this.closeModal();
        }
    }
    // sections mangement end

    /***
    * @description  Handles rendering of sections and treaties when user changes the program of the excel file
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeProgram(event) {
        console.log('handleChangeProgram Start');
        this.programselected = event.detail.value;
        console.log('handleChangeProgram : this.programselected ', this.programselected);
        this.fetchTreatyRecords();
        this.fetchSectionRecords();
        this.resetTabs();
        console.log('handleChangeProgram End');
    }

    /***
    * @description  Handles rendering when underwriting year is changed
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeUWYr(event) {
        console.log('handleChangeUWYr : Start');
        this.selecteduwyear = event.detail.value;
        this.fetchProgramRecords();
        this.fetchSectionRecords();
        this.resetTabs();
        console.log('handleChangeUWYr : End');
    }
    /***
    * @description  Handles rerender when PCC is changed
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleCedingCompanySet(event) {
        console.log("handleCedingCompanySet start");
        this.selectedcomp = event.detail;
        this.fetchProgramRecords();
        this.resetTabs();
        console.log("handleCedingCompanySet end");
    }
    /***
    * @description  maintains variable when tab is changed in popup
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeTabType(event) {
        console.log('handleChangeTabType : Start');
        console.log('handleChangeTabType : event ', event.detail.value);
        this.selectedTabType = event.detail.value;
        console.log('handleChangeTabType : End');
    }
    /***
    * @description  handles deletion of an excel sheet.
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleDeleteTab(event) {
        console.log('handleDeleteTab: Start');
        console.log('handleDeleteTab : event ', event.target.dataset.id);
        // remove tab from list
        this.tabs = this.tabs.filter(row => {
            return row.name != event.target.dataset.id;
        });
        delete this.selectedSections[event.target.dataset.id];

        if (event.target.dataset.id == this.sheet) {
            this.optionsDisabled = true;
        }
        console.log('handleDeleteTab: End');
    }
    /***
    * @description  Handles changing of tab name on popup
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    tabNameChanged(event) {
        console.log('tabNameChanged : Start');
        this.inputTabName = event.detail.value;
        console.log('tabNameChanged : End');
    }
    /***
    * @description  Handles change in treaty in UI and displays list of selection the user has already selected
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangetreaty(event) {
        console.log('handleChangetreaty : Start');
        this.treaty = event.detail.value;
        this.setSelectedSections();
        console.log('handleChangetreaty : End');
    }

    /***
    * @description  Sets the list of options that must be available for display to the user when a specific treaty is selected
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    setSelectedSections() {
        let sheet = this.selectedSheetDisplayed;
        let sectionsSelected = this.selectedSections[sheet].sectionsSelected;
        // filter with criteria. Treaty selected only
        let searchResult = [];
        if (this.treaty != 'All') {
            searchResult = this.allSections.data.filter(row => {
                console.log('row.treaty ', row.treatyId);
                console.log('this.treaty ', this.treaty);
                return row.treatyId == this.treaty
            });
            console.log('searchResult #1 : ', searchResult);
            console.log("sectionsSelected : ", sectionsSelected);
            // add selected options to the list
            for (var i = 0; i < sectionsSelected.length; i++) {
                // verify if the section is not already present
                if (searchResult.filter(r => {
                        r.value == sectionsSelected[i]
                    }).length == 0) {
                    console.log('this.sectionMap ', this.sectionMap);
                    console.log('sectionsSelected[i] ', sectionsSelected[i]);
                    let obj = JSON.parse(JSON.stringify(this.mapSections[sectionsSelected[i]]));
                    searchResult.push(obj);
                }
            }
            console.log('searchResult: #2', searchResult);
        } else {
            searchResult = this.allSections.data;
        }
        this.sectionsUnselectedDisplayed = searchResult;
    }
    /***
    * @description  Handles classeur name change
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeName(event) {
        console.log('handleChangeName : START');
        this.classeurName = event.detail.value;
        console.log('handleChangeName : END');
    }
    /***
    * @description  Handles change in quote table name
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeQuoteTableName(event) {
        console.log('handleChangeQuoteTableName : START');
        this.quotationtablename = event.detail.value;
        console.log('handleChangeQuoteTableName : END');
    }
    /***
    * @description  Retrieves program records that are available for the user for a specific UW year and Ceding company
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    fetchProgramRecords() {

        console.log('fetchProgramRecords : Start');
        fetchPrograms({
                accountId: this.selectedcomp,
                uwYear: this.selecteduwyear
            })
            .then(result => {
                if (result && result.length > 0) {
                    this.programs = result;
                    console.log('fetchProgramRecords : programsList: ', this.recordsList);

                } else {
                    this.message = "fetchProgramRecords No Records Found for '" + this.selectedcomp + "'";
                    this.programs = [];
                    console.log('fetchProgramRecords: this.message ', this.message);
                }
            }).catch(error => {
                console.log(error);
            })
        console.log('fetchProgramRecords : End');
    }
    /***
    * @description  Retrieves a list of section records that are available for a specific program, account and year
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    fetchSectionRecords() {
        console.log('fetchSectionRecords: Start');
        fetchSections({
                programId: this.programselected,
                accountId: this.selectedcomp,
                uwYear: this.selecteduwyear
            })
            .then(result => {

                console.log('fetchSectionRecords : result', result);
                if (result) {

                    this.allSections = result;
                    this.allSectionDetails = result.data;
                    this.mapSections = result.mapSections;
                } else {

                    this.sectionsUnselectedDisplayed = [];
                    this.sectionsSelectedDisplayed = '';

                    this.message = "No Records Found for fetchSectionRecords '" + this.programselected + "'";
                    console.log('fetchSectionRecords this.message ', this.message);
                }
            }).catch(error => {
                console.log(error);
            })
        console.log('fetchSectionRecords: End');
    }
    /***
    * @description  Retrieves a list of treaty records that are available for a specific program
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    fetchTreatyRecords() {

        console.log('fetchTreatyRecords: Start');


        fetchTreatys({
                programId: this.programselected
            })
            .then(result => {
                if (result && result.length > 0) {
                    this.Alltreatys = [{
                        label: "All",
                        value: "All"
                    }];
                    this.Alltreatys.push(...result);
                    console.log('this.Alltreatys: ', this.Alltreatys);
                } else {
                    this.message = "No Records Found for '" + this.programselected + "'";
                    console.log('fetchProgramRecords this.message ', this.message);
                }
            }).catch(error => {
                console.log(error);
            })

        console.log('fetchTreatyRecords: End');
    }
    /***
    * @description  Program Metadata retrieval
    * @exception	None special (all catched and logged).
    ***/
    @wire(getObjectInfo, {
        objectApiName: PROGRAM_OBJECT
    })
    objectInfo;
    /***
    * @description  retrieve picklist values for UW year
    * @exception	None special (all catched and logged).
    ***/
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: UWYEAR_FIELD
    })
    setPicklistOptions({
        error,
        data
    }) {
        if (data) {
            this.uwYearOpt = data.values;
        } else {
            this.error = error;
        }
    }
    /***
    * @description  Retrieves list of account available for the user
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    @wire(getAcc)
    setAccPicklistOptions({
        error,
        data
    }) {
        if (data) {
            this.cedingAccOpt = data;
        } else {
            this.error = error;
        }
    }
    /***
    * @description  Helper method to set the checkbox on UI
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    // onclick event handler
    setBoxes(event) {

        let boxes = this.template.querySelectorAll('lightning-input');
        let currentBox = event.target.name;
        const boxArray = Array.from(boxes);
        for (let i = 0; i < boxes.length; i++) {
            let box = boxes[i];
            console.log(box.name);
            console.log(box.checked);
            if (box.name !== currentBox && box.checked) {
                box.checked = false;
                console.log(box.checked);
            }
            if (box.name === currentBox) {
                box.checked = true;
            }
        }
    }
    /***
    * @description  Handles event when user clicks on add New tab
    * @exception	None special (all catched and logged).
    ***/
    handleNewTabClicked() {
        this.selectedTabType = '';
        this.inputTabName = '';
        this.openModal();
    }
    /***
    * @description  Open new tab modal
    * @exception	None special (all catched and logged).
    ***/
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.inputTabName = 'Sheet1';

        console.log('Tabs: ' , this.tabs);
        if(this.tabs.length != 0){
            let sheet1Exists = this.tabs.filter(tab=>{
                return tab.name == "Sheet1"
            });

            if(sheet1Exists.length != 0){
                this.inputTabName = "Sheet2"; 
            }
        }
        this.selectedTabType = ''; 
        this.isModalOpen = true;
    }
    /***
    * @description  Closes new tab modal
    * @exception	None special (all catched and logged).
    ***/
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    /***
    * @description  Resets all UI elements
    * @exception	None special (all catched and logged).
    ***/
    resetTabs() {
        console.log('resetTabs: start');
        this.tabs = [];
        this.selectedTabType = '';
        this.selectedSections = {}
        this.sectionsUnselectedDisplayed = [];
        this.sectionsSelectedDisplayed = [];
        this.selectedSheetDisplayed = "";
        this.inputTabName = '';
        console.log('resetTabs: end');
    }  

    /***
    * @description  Creates a new classeur when user clicks on save button on UI
    * @exception	None special (all catched and logged).
    ***/
    createClasseur() {
        console.log('createClasseur: Start');
        let inputJson = {
            name: this.quotationtablename,
            principalCedingCompany: this.selectedcomp,
            uwYear: this.selecteduwyear,
            program: this.programselected
        };

        console.log();

        let param = {
            basic: JSON.stringify(inputJson),
            tabs: JSON.stringify(this.selectedSections),
            tabDetails: JSON.stringify(this.tabs)
        };

        console.log('createClasseur: param ', param);
        if(this.isInputValid()){
            
            this.loading = true; 
            insertClasseurs(param)
            .then(result => {

                // Classeur created successfully
                console.log('result: ', result);
                let recordId = result.classeur.Id; 
                this.classeurId = recordId;
                console.log('recordId : ' , recordId);
                // @Todo: With regards to response of data factory, determine whether to do sync or asych monitoring of the status
                // placeholder, redirecting to record page of the classeur generated
                
                this.handleSubscribe(recordId);
            }).catch(error => {
                console.log(error);
                sfpegJsonUtl.sfpegJsonUtl.showToast(this, {
                    mode : 'sticky', 
                    variant : 'error', 
                    message: this.label.QuoteTableApexError,
                    title: 'Error'
                });
                this.loading = false; 
            })
        }else{
            console.log('createClasseur : validation Error');
        } 
        
        console.log('createClasseur: End');
    }

    /***
    * @description  Handles event where the user changes the principal ceding company
    * @param        event
    * @exception	None special (all catched and logged).
    ***/
    handleChangeCedingComp(event) {
        console.log('handleChangeCedingComp: Start');
        this.selectedcomp = event.detail.value;
        console.log(this.selectedcomp);
        this.fetchProgramRecords();
        this.resetTabs();
        console.log('handleChangeCedingComp : this.valuePrincipalCedComp ', this.valuePrincipalCedComp);
        console.log('handleChangeCedingComp: End');
    }
    /***
    * @description  Opens classeur record (standard lightning page)
    * @param        id :  Record id (classeurId)
    * @exception	None special (all catched and logged).
    ***/
    openRecord(id) {
        console.log('openRecord: start'); 
        console.log('openRecord: Id ' , id); 
        let THEURL= '/lightning/r/Classeur__c/'+id + '/view';
        window.open(THEURL, '_top')
    }   


    /* 
    *   This method is used to check if all the input fields 
    *   for new tab is filled correctly (name is required)
    */
    isNewTabInputValid() {
        let isValid = true;
        
        let inputFields = this.template.querySelectorAll('.validate-new-tab');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });

        return isValid; 
    }

    /* 
    *   Checks if the new tab name entered is unique. Only 1 tab per name is allowed
    */
    isNewTabNameUnique(){
        let isValid = true; 

        let result = []; 

        result = this.tabs.filter(row =>{
            return row.name == this.inputTabName
        });

        if(result.length != 0){
            isValid = false; 
            sfpegJsonUtl.sfpegJsonUtl.showToast(this, {
                mode : 'sticky', 
                variant : 'error', 
                message: this.label.QuoteTableUniqueTabName,
                title: 'Input Error!'
            });
        }

        console.log('isNewTabNameUnique returning' + isValid);
        return isValid;
    }

    /* 
    *   This method is used to check if all the input fields 
    *   that we need to validate are valid or not. We're also going
    *   to populate our contact object so that it can be sent to apex
    *   in order to save the details in salesforce
    */
    isInputValid() {
        let isValid = true;
        var tabs = this.selectedSections;
        console.log('this.selectedSections : ' , this.selectedSections);
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        console.log('isInputValid : Tabs ', tabs);
        if(tabs == null || Object.keys(tabs).length == 0){
            isValid = false; 
            console.log('isInputValid : Tabs not valid, not tabs found');
            this.showErrorNoTabs();
            
        }
        for(let i in tabs){
            if(tabs[i].sectionsSelected.length == 0){
                console.log('isInputValid : Tabs not valid, tabs without section found');
                isValid = false; 
                this.showErrorNoTabs();
                
            }
        }
        return isValid;
    }

    /***
    * @description  Displays a toast with error message when tabs have not been configured by the user.
    * @exception	None special (all catched and logged).
    ***/
    showErrorNoTabs(){
        sfpegJsonUtl.sfpegJsonUtl.showToast(this, {
            mode : 'sticky', 
            variant : 'error', 
            message: 'Tabs have not been configured. All tabs must have at least 1 section.' ,
            title: 'Input Error!'
        });
    }

    /***
    * @description  Platform event subscription. The event is triggered whenever a message is posted in the QuoteTableResponse__e channel
    * @param        currentRecordId : The classeur record Id
    * @exception	None special (all catched and logged).
    ***/
    // Handles subscribe button click
    handleSubscribe(currentRecordId) {
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('handleSubscribe : New message received: ', JSON.stringify(response));
            console.log('handleSubscribe this.classeurId : ', this.classeurId);
            console.log('handleSubscribe response.data.payload.classeurId__c : ', response.data.payload.classeurId__c);
            if(currentRecordId == response.data.payload.classeurId__c){
                console.log("handleSubscribe : Success");
                console.log("handleSubscribe : response.data.payload.classeurId__c ", response.data.payload.classeurId__c );
                // let THEURL= '/lightning/r/Classeur__c/'+response.data.payload.classeurId__c + '/view';
                // window.open(THEURL, '_top')

                setTimeout(function () {
                    console.log("handleSubscribe: opening quote table");
                    let THEURL= '/lightning/n/Quote_Table?c__tab=quotetablelist';
                    window.open(THEURL, '_top');

                }, 2000);

                window.open('/sfc/servlet.shepherd/version/download/'+response.data.payload.FileUrl__c, '_blank').focus();
                console.log("handleSubscribe : redirected");
            }else{
                console.log("handleSubscribe : Error");
                sfpegJsonUtl.sfpegJsonUtl.showToast(this, {
                    mode : 'sticky', 
                    variant : 'error', 
                    message: this.label.QuoteTableApexError ,
                    title: 'Error'
                });
            }
            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );

            console.log(
                'Subscription response ',
                JSON.stringify(response)
            );
            
            
            this.subscription = response;
        });
    }
}