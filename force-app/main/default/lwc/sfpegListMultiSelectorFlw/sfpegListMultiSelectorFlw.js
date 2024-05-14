/***
* @author P-E GROS
* @date   Feb. 2021
* @description LWC Component for Flows enabling to display a set of records and select one of them.
*              Multiple display modes are available for the set of records to display from.
*              It is also possible to provide a first selected record at initialisation.
*
* Legal Notice
* 
* MIT License
* 
* Copyright (c) 2021 pegros
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
***/

import { LightningElement, wire , api, track} from 'lwc';
import getFieldSetDesc from '@salesforce/apex/sfpegGetFieldSet_CTL.getFieldSetDesc';

import LOCALE       from '@salesforce/i18n/locale';
import CURRENCY     from '@salesforce/i18n/currency';
import NUMBER       from '@salesforce/i18n/number.numberFormat';
import PERCENT      from '@salesforce/i18n/number.percentFormat';
import ALL_LABEL    from '@salesforce/label/c.sfpegListMultiSelectorAll';
import SELECT_LABEL from '@salesforce/label/c.sfpegListMultiSelectorHeader';
import SEARCH_LABEL from '@salesforce/label/c.sfpegListMultiSelectorSearchHeader';
import SEARCH_PLACEHOLDER from '@salesforce/label/c.sfpegListMultiSelectorSearchPlaceholder';
import LIST_LABEL   from '@salesforce/label/c.sfpegListMultiSelectorListHeader';
import SORT_LABEL   from '@salesforce/label/c.sfpegListMultiSelectorSortAction';

    // Internal constants
    const CURRENCY_FMT = new Intl.NumberFormat(LOCALE, {
        style: 'currency',
        currency: CURRENCY,
        currencyDisplay: 'symbol'
    });
    const PERCENT_FMT = new Intl.NumberFormat(LOCALE, {style:'percent'});
    const NUMBER_FMT = new Intl.NumberFormat(LOCALE,  {style:"decimal"});

export default class SfpegListMultiSelectorFlw extends LightningElement {

    // Configuration fields - Main Container Display
    @api cardTitle;                 // Title of the wrapping Card
    @api cardIcon;                  // Icon of the wrapping Card
    @api cardClass;                 // CSS Classes for the wrapping card div
    @api displayMode    = 'tiles';  // selected display mode (list, tiles, table)
    @api tileSize       = 4;        // tile size (in tiles or table mode)
    @api searchHeight   = 0;        // Height (in px) of the Search list display area (0 : no scroll)

    // Configuration fields - Selection Record List 
    @api nameLabel      = 'Title';  // Label of the field to be used as title for each record
    @api nameField      = 'Name';   // API name of the field to be used as title for each record
    @api keyField       = 'Id';     // Record single identification key (usually Salesforce Id)
    @api selectName     = false;    // Flag to tell whether title field should be selected as search option by default
    @api fieldSetName   = null;     // fieldset for additional info in tiles
    @api recordList     = [];       // input record list to display
    @api selectionList  = [];       // output selected record list
    @api preselectionList  = [];    // input preselected record list
    @api lstUnSelectRecords = [];   // output list unselect records HB //RRA - 1665 - 14122023
    @api lstUnSelectRecPS = [];     // output list unselect records PS//RRA - 1665 - 14122023
    @api isSingleSelectInAllSelection = false;   // RRA - Neree - 29/07/2022 Boolean to know the difference between Selection Unique Or SelectionAll

    // Configuration fields - Options selection
    @api isDebug = false;           // Flag to display debug info.
    @api showSearch = false;        // Flag to display search box.
    @api showSelection = false;     // Flag to display selection box.
    @api showSort = false;          // Flag to display Sort button-menu.
    @api isSearchAuto = false;      // Flag to trigger automatic search upon search bar user entry 
    @api defaultSortedBy = null;    // API name of the field by which the list should be sorted by default (optional)
    @api isSingleSelect = false;    // Flag to enforce single selection (instead of multiple)

    // Internal fields for Selection
    @track isReady      = false;        // Controls initialisation of the component.
    @track displayItems = [];           // Display Items corresponding to recordList.
    fieldSetDesc        = [];           // fieldset description data fetched
    detailFieldsJson    = [];           // list of detail fields.
    selectHeader        = SELECT_LABEL; // Header label of the selected record section
    searchHeader        = SEARCH_LABEL; // Header label of the search section
    searchPlaceholder   = SEARCH_PLACEHOLDER; // Placeholder label of the search input
    listHeader          = LIST_LABEL;   // Header label of the record list selection section
    sortTitle           = SORT_LABEL;   // Label of the sort button menu.

    //RRA - ticket 1531 - 20062023
    @api isRefHazadBassin = false;        // Topic is only Ref HazardBassin for cardTitle 
    
    // Internal Fields for Sort
    @track sortFields = null;       // List of field sort options for List display mode (for the sort menu)
    @track sortDirection = 'asc';     // Current sorting direction (asc/desc)
    @track sortedBy = null;           // Field upon which the current sorting is done
    
    //RRA - ticket 1531 - 20062023 - SLDS for toolTip
    passwordHintClass = "slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground slds-hide"
    togglePasswordHint() {
        this.passwordHintClass = this.passwordHintClass == 'slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground slds-hide' ? "slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-rise-from-ground" : "slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground slds-hide"
    }

    // Internal Fields for Search
    searchScopes = [{'label':ALL_LABEL,'value':"ALL",'isChecked':true}] ; // possible scopes for Search ("All" + all fieldset fields)
    searchScope = {'label':ALL_LABEL,'value':"ALL",'isChecked':true};     // Selected search scope
    searchString = null;            // Search criteria entered by User

    //Option to hide select All
    @api hideSelectAllBtn = false;

    // Display mode getters
    get isTiles() {
        if (this.isDebug) console.log('connectedCallback: isTiles', this.displayMode === 'tiles');
        return this.displayMode === 'tiles';
    }
    get isTable() {
        if (this.isDebug) console.log('connectedCallback: isTable', this.displayMode === 'table');
        return this.displayMode === 'table';
    }
    get searchDivClass() {
        if (this.isDebug) console.log('connectedCallback: searchDivClass', (this.searchHeight == 0 ? '' :'slds-scrollable_y'));
        return "slds-box slds-box_xx-small " + (this.searchHeight == 0 ? '' :'slds-scrollable_y');
    }
    get searchDivStyle() {
        if (this.isDebug) console.log('connectedCallback: searchDivStyle', (this.searchHeight == 0 ? '' :'max-height:' + this.searchHeight + 'px'));
        return "min-height:36px; " + (this.searchHeight == 0 ? '' :'max-height:' + this.searchHeight + 'px;');
    }

    get isHeaderFilled(){
        return this.listHeader == null ? true : false;
    }

    // FieldSet Desc Loading
    @wire(getFieldSetDesc, {"name":"$fieldSetName"})
    wiredFieldSet({ error, data }) {
        if (this.isDebug) console.log('wiredFieldSet: START');
        if (data) {
            if (this.isDebug) console.log('wiredFieldSet: data fetch OK', JSON.stringify(data));
            this.fieldSetDesc = data;
            this.displayItems = [];
            this.sortFields = [];

            if (this.isDebug) console.log('wiredFieldSet: parsing fields desc ', JSON.stringify(data.fields));
            data.fields.forEach(eachField => {
                if (this.isDebug) console.log('wiredFieldSet: processing field ', eachField);
                this.detailFieldsJson.push(eachField);
                this.searchScopes.push({
                    'label':eachField.label,
                    'value':eachField.name,
                    'isChecked':false});
                this.sortFields.push({
                    'label':eachField.label,
                    'name':eachField.name,
                    'iconName': ((eachField.name === this.sortedBy) ? 'utility:arrowup' : null)});
            });
            if (this.isDebug) console.log('wiredFieldSet: nameField init ', this.nameField );
            if (this.isDebug) console.log('wiredFieldSet: detailFieldsJson init OK', JSON.stringify(this.detailFieldsJson));
            if (this.isDebug) console.log('wiredFieldSet: searchScopes init OK', JSON.stringify(this.searchScopes));

            this.recordList.forEach(eachRecord => {
                if (this.isDebug) console.log('wiredFieldSet: processing record ', JSON.stringify(eachRecord));

                let recordSelectIndex = this.preselectionList.findIndex(eachSelection => eachSelection.Id === eachRecord.Id);
                if (this.isDebug) console.log('wiredFieldSet: record selection index determined ', recordSelectIndex);
                let newItem = {
                    'label': eachRecord[this.nameField],
                    //'id': eachRecord.Id,
                    'id': eachRecord[this.keyField],
                    'isSelected': (recordSelectIndex != -1),
                    'isFiltered': true,
                    'class': 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default' + ((recordSelectIndex != -1) ? ' selectedItem' : ''),
                    'details': [],
                    'value': eachRecord
                };
                //'class': 'slds-box slds-box_x-small slds-var-m-around_xx-small ' + ((recordSelectIndex != -1) ? 'slds-theme_info' : 'slds-theme_default'),
                this.detailFieldsJson.forEach(eachField => {
                    //console.log('wiredFieldSet: adding detail field', eachField.name);
                    //console.log('wiredFieldSet: field type', eachField.type);

                    if(eachRecord[eachField.name]) {
                        switch (eachField.type) {
                            case 'BOOLEAN':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value": (eachRecord[eachField.name]?'☑︎':'☐')});
                                break;
                            case 'STRING':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value":eachRecord[eachField.name]});
                                break;
                            case 'DATE':
                            case 'DATETIME':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value": new Intl.DateTimeFormat(LOCALE).format(new Date(eachRecord[eachField.name]))});
                                break;
                            case 'CURRENCY':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value": CURRENCY_FMT.format(eachRecord[eachField.name])});
                                break;
                            case 'DOUBLE':
                            case 'INT':
                            case 'LONG':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value": NUMBER_FMT.format(eachRecord[eachField.name])});
                                break;
                            case 'PERCENT':
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value": PERCENT_FMT.format(eachRecord[eachField.name]/100)});
                                break;
                            default:
                                newItem.details.push({
                                    "label": eachField.label,
                                    "value":'' + eachRecord[eachField.name]});
                        }
                    } 
                    else {
                        if (this.isDebug) console.log('wiredFieldSet: no value');
                    } 
                });
                if (this.isDebug) console.log('wiredFieldSet: newItem init', JSON.stringify(newItem));
                this.displayItems.push(newItem);
                //this.searchItems.push(newItem);

                if (recordSelectIndex != -1) {
                    if (this.isDebug) console.log('wiredFieldSet: registering record in selection', JSON.stringify(eachRecord));
                    this.selectionList.push(eachRecord);
                }
            });
            if (this.isDebug) console.log('wiredFieldSet: display items init', JSON.stringify(this.displayItems));
            if (this.isDebug) console.log('wiredFieldSet: search items init', JSON.stringify(this.searchItems));

            if (this.sortedBy) {
                if (this.isDebug) console.log('wiredFieldSet: applying default sorting', this.sortedBy);
                this.doSort();
            }
            this.isReady = true;
        }
        else if (error) {
            console.warn('wiredFieldSet: data fetch KO', JSON.stringify(error));

            if (!this.fieldSetName) {
                if (this.isDebug) console.log('wiredFieldSet: no fieldSet to set');

                this.recordList.forEach(eachRecord => {
                    if (this.isDebug) console.log('wiredFieldSet: processing record ', JSON.stringify(eachRecord));

                    //let recordSelectIndex = this.preselectionList.findIndex(eachSelection => eachSelection.Id === eachRecord.Id);
                    let recordSelectIndex = this.preselectionList.findIndex(eachSelection => (eachSelection[this.keyField]) === (eachRecord[this.keyField]));
                    
                    if (this.isDebug) console.log('wiredFieldSet: record selection index determined ', recordSelectIndex);
                    let newItem = {
                        'label': eachRecord[this.nameField],
                        //'id': eachRecord.Id,
                        'id': eachRecord[this.keyField],
                        'isSelected': (recordSelectIndex != -1),
                        'isFiltered': true,
                        'class': 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default' + ((recordSelectIndex != -1) ? ' selectedItem' : ''),
                        'details': [],
                        'value':eachRecord
                    };
                    if (this.isDebug) console.log('wiredFieldSet: newItem init', JSON.stringify(newItem));
                    this.displayItems.push(newItem);

                    if (recordSelectIndex != -1) {
                        if (this.isDebug) console.log('wiredFieldSet: registering record in selection', JSON.stringify(eachRecord));
                        this.selectionList.push(eachRecord);
                    } 
                });
                if (this.isDebug) console.log('wiredFieldSet: items init', JSON.stringify(this.displayItems));
            }
            this.isReady = true;
        }
        else {
            if (this.isDebug) console.log('wiredFieldSet: no feedback provided');
        }
        if (this.isDebug) console.log('wiredFieldSet: END');
    }

    // Component Initialisation
    connectedCallback() {
        if (this.isDebug) console.log('connectedCallback: START');
        if (this.isDebug) console.log('connectedCallback: displayMode configured ', this.displayMode);
        if (this.isDebug) console.log('connectedCallback: nameField configured ', this.nameField);
        if (this.isDebug) console.log('connectedCallback: nameLabel configured ', this.nameLabel);
        if (this.isDebug) console.log('connectedCallback: selectName configured ', this.selectName);
        if (this.isDebug) console.log('connectedCallback: fieldSetName configured ', this.fieldSetName);
        if (this.isDebug) console.log('connectedCallback: recordList configured ', JSON.stringify(this.recordList));                            
        if (this.isDebug) console.log('connectedCallback: selectionList configured ', JSON.stringify(this.selectionList));
        if (this.isDebug) console.log('connectedCallback: defaultSortedBy configured ', this.defaultSortedBy);
        this.sortedBy = this.defaultSortedBy;
        if (this.isDebug) console.log('connectedCallback: sortedBy init ', this.sortedBy);
        
         //RRA - ticket 1531 - 20062023
         if (this.cardTitle == 'Referential Hazard Bassins'){
            this.isRefHazadBassin = true;
        }

        if ((this.nameField) && (this.nameLabel)) {
            if (this.isDebug) console.log('connectedCallback: registering name/title in search fields');

            if (this.selectName) {
                if (this.isDebug) console.log('connectedCallback: selecting name/title as default in search fields');
                this.searchScopes.push({'label':this.nameLabel,'value':this.nameField,'isChecked':true});
                this.searchScopes[0].isChecked = false; // resetting default value
                this.searchScope = {'label':this.nameLabel,'value':this.nameField,'isChecked':true};
            }
            else {
                if (this.isDebug) console.log('connectedCallback: keeping ALL as default in search fields');
                this.searchScopes.push({'label':this.nameLabel,'value':this.nameField,'isChecked':false});
            }
            if (this.isDebug) console.log('connectedCallback: search scopes init', JSON.stringify(this.searchScopes));
            if (this.isDebug) console.log('connectedCallback: selected search scope init', JSON.stringify(this.searchScope));
        }
        else {
            console.warn('connectedCallback: missing title name/label parameters');
        }

        console.log('connectedCallback: END');
    }

    // Component Rendering Handling
    renderedCallback() {
        if (this.isDebug) console.log('renderedCallback: START');
        if (this.isDebug) console.log('renderedCallback: END');
    }

    //#####################################
    // User Interaction Handling
    //#####################################
    // Record Selection handling


    //RRA - 20/07/2022 => All Record Selection/Unselection from checkbox - Projcet NEREE - Add checkBox to Seleted All the value of picklist
    //RRA - 20/07/2022 => All Record Selection/Unselection from checkbox - Project NEREE - Add checkBox to Seleted All the value of picklist
    handleSelectAllValue(event){
        //******
        // SELECT ALL VALUE ONLY
        //**** */
        this.isSingleSelectInAllSelection = true;
            let recordList = [];
            this.isAllValue = event.target.checked;   
            console.log("  this.isAllValue: ",   this.isAllValue);
            console.log("  this.recordList: ",   this.recordList);
    
            //Convert this.record list to record List array
            this.recordList.forEach(item => {
                recordList.push(item);
                console.log("  item: ",   recordList);
            });

            console.log("  recordList: ",   recordList);
    
            //Get list All Hazard Bassin display on UI
            if (recordList != null || recordList != undefined || recordList != 'undefined'){
                event.preventDefault();
                event.stopPropagation();
                //Set value to display on UI
                this.displayItems.push(recordList);
                this.selectionList = recordList;
                console.log("  selectionList: ",    this.selectionList);
                console.log("  displayItems: ",    this.displayItems);
                // Check if checkbox is ticked and Select All value
                if (this.isAllValue){
                    this.displayItems.forEach(item => {
                        if (item.isSelected != undefined && item.class != undefined){
                            item.isSelected = true;
                            item.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default selectedItem'
                        }
                    });
    
                    let selectEvent = new CustomEvent('select', {
                        "detail": {
                            "record": recordList,
                            "list": this.selectionList
                        }
                    });
                    this.dispatchEvent(selectEvent);
        
                // Check if checkbox is unticked and deselect All value
                }else{
                    this.selectionList = [];
                    this.displayItems.forEach(item => {
                        if (item.isSelected != undefined && item.class != undefined){
                            item.isSelected = false;
                            item.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default';
                        }
                    });
    
                    let unselectEvent = new CustomEvent('unselect', {
                        "detail": {
                            "record": recordList,
                            "list": this.selectionList
                        }
                    });
                    this.dispatchEvent(unselectEvent);
                }
            }
        //}
    }

    handleSelect(event) {
        //******
        //  RRA - 01/08/2022 - Project NEREE SELECT SINGLE VALUE IN AMONG LIST ALL SELECTION AFTER UNCHECK OR CHECK
        //**** */
        if (this.isSingleSelectInAllSelection){
            console.log("  this.isSingleSelectInAllSelection_TRUE: ",  this.isSingleSelectInAllSelection);
            let selectId = event.currentTarget.id;
            if (selectId) {
                event.preventDefault();
                event.stopPropagation();
                if (selectId.includes('-')) {
                    selectId = selectId.substring(0,selectId.indexOf('-'));
                }
                console.log("  selectId 22: ",  selectId);

                let selectedRecord = this.recordList.find(eachRecord => {
                    return ((eachRecord[this.keyField]) === selectId);
                });

                console.log("  selectedRecord: ",  selectedRecord);
                console.log("  this.selectionList: ",  this.selectionList);

                let selectedIndex = this.selectionList.findIndex(eachRecord => (eachRecord.Id === selectId));

                let selectedItem = this.displayItems.find(item => (item.id === selectId));

                // unselect previously selected tile
                if (selectedIndex != -1) {

                    this.selectionList.splice(selectedIndex, 1);
                    
                    // Uncheked the checkbox Select All
                    if(this.selectionList.length === 0){
                        this.template.querySelector('[data-id="selectAll"]').checked = false;
                    }

                    console.log(' this.selectionList == ', this.selectionList);

                    selectedItem.isSelected = false;
                    selectedItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default';
    
                    let unselectEvent = new CustomEvent('unselect', {
                        "detail": {
                            "record": selectedRecord,
                            "list": this.selectionList
                        }
                    });
                    this.dispatchEvent(unselectEvent);

                }else {
                    // unselect previously selected tile if single selection is enforced
                    if ((this.isSingleSelect) && (this.selectionList.length >0)) {
                        console.log('single select mode');
    
                        let currentSelection = this.selectionList.shift();
                        let currentId = currentSelection[this.keyField];
                        let currentItem = this.displayItems.find(item => (item.id === currentId));
                        currentItem.isSelected = false;
                        currentItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default';
                    }
    
                    this.selectionList.push(selectedRecord);          
                    selectedItem.isSelected = true;
                    selectedItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default selectedItem';
               
                    let selectEvent = new CustomEvent('select', {
                        "detail": {
                            "record": selectedRecord,
                            "list": this.selectionList
                        }
                    });
                    this.dispatchEvent(selectEvent);
                }
            }
        //******
        // RRA - 01/08/2022 - Project NEREE SELECT SINGLE VALUE ONLY 
        //**** */
        }else{
            console.log("  this.isSingleSelectInAllSelection_FALSE: ",  this.isSingleSelectInAllSelection);
            if (this.isDebug) console.log('handleSelection: START');
            let selectId = event.currentTarget.id;
            if (this.isDebug) console.log('handleSelection: selectId fetched', selectId);
                  
            if (selectId) {
                if (this.isDebug) console.log('handleSelection: processing event');
                event.preventDefault();
                event.stopPropagation();
                if (this.isDebug) console.log('handleSelection: propagation stopped');
    
                if (selectId.includes('-')) selectId = selectId.substring(0,selectId.indexOf('-'));
    
                if (this.isDebug) console.log('handleSelection: new selected ID',selectId);
    
                if (this.isDebug) console.log('handleSelection: recordList fetched',JSON.stringify(this.recordList)); 
                let selectedRecord = this.recordList.find(eachRecord => {
                    if (this.isDebug) console.log('handleSelection: processing record',JSON.stringify(eachRecord));
                    //if (this.isDebug) console.log('handleSelection: record Id',eachRecord.Id);
                    //if (this.isDebug) console.log('handleSelection: test ',(eachRecord.Id === selectId));
                    //return (eachRecord.Id === selectId);
                    //if (this.isDebug) console.log('handleSelection: record Key',eachRecord[this.keyField]);
                    //if (this.isDebug) console.log('handleSelection: test selection ',(eachRecord[this.keyField] === selectId));
                    return ((eachRecord[this.keyField]) === selectId);
                });
    
                if (this.isDebug) console.log('handleSelection: selectedRecord fetched',JSON.stringify(selectedRecord)); 
                //let selectedIndex = this.selectionList.findIndex(eachRecord => (eachRecord.Id === selectId));
                let selectedIndex = this.selectionList.findIndex(eachRecord => (eachRecord[this.keyField] === selectId));
    
                if (this.isDebug) console.log('handleSelection: selectedIndex evaluated',selectedIndex);
                let selectedItem = this.displayItems.find(item => (item.id === selectId));
                
                if (this.isDebug) console.log('handleSelection: selectedItem fetched',JSON.stringify(selectedItem));
    
                // unselect previously selected tile
                if (selectedIndex != -1) {
                    let selectedHB = this.recordList.find(eachRecord => {
                        return ((eachRecord[this.keyField]) === selectId);
                    });
                        
                    console.log('unselecting selectHB == ',selectedHB);
                    if (selectId.includes('a0y')){
                        this.lstUnSelectRecords.push(selectedHB); //RRA - ticket 1665 - 14122023
                    }
                    if (selectId.includes('a0w')){
                        this.lstUnSelectRecPS.push(selectedHB); //RRA - ticket 1665 - 14122023
                    }
                    console.log('lstUnSelectRecords selectedIndex == ',this.lstUnSelectRecords);
                    console.log('lstUnSelectRecPS selectedIndex == ',this.lstUnSelectRecPS);
                    if (this.isDebug) console.log('handleSelection: unselecting record',selectId);
    
                    this.selectionList.splice(selectedIndex,1);
                    if (this.isDebug) console.log('handleSelection: selectionList updated');          
    
                    selectedItem.isSelected = false;
                    selectedItem.class = 'slds-box sld  s-box_x-small slds-var-m-around_xx-small slds-theme_default';
                    if (this.isDebug) console.log('handleSelection: selectedItem updated',JSON.stringify(selectedItem));
                    console.log('unselecting selectedRecord == ',selectedRecord);
                    console.log('unselecting selectionList == ',this.selectionList);
                    let unselectEvent = new CustomEvent('unselect', {
                        "detail": {
                            "record": selectedRecord,
                            "list": this.selectionList
                        }
                    }); 
                    if (this.isDebug) console.log('handleSelection: unselectEvent init',JSON.stringify(unselectEvent));   
                    this.dispatchEvent(unselectEvent);
                    if (this.isDebug) console.log('handleSelection: unselectEvent dispatched'); 
                }
                // select new tile
                else {
                    console.log('selecting selectedIndex == ',selectId);
                    if (this.isDebug) console.log('handleSelection: selecting new record',selectId);
                    // unselect previously selected tile if single selection is enforced
                    if ((this.isSingleSelect) && (this.selectionList.length >0)) {
                        if (this.isDebug) console.log('handleSelection: unselecting previous selected record (single select mode)');
    
                        let currentSelection = this.selectionList.shift();
                        if (this.isDebug) console.log('handleSelection: current item removed from selection ',JSON.stringify(currentSelection));
                        let currentId = currentSelection[this.keyField];
                        if (this.isDebug) console.log('handleSelection: current record key ',currentId);
    
                        let currentItem = this.displayItems.find(item => (item.id === currentId));
                        currentItem.isSelected = false;
                        currentItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default';
                        if (this.isDebug) console.log('handleSelection: currentItem fetched and deselected ',JSON.stringify(currentItem));
                    }
    
                    this.selectionList.push(selectedRecord);
                    if (this.isDebug) console.log('handleSelection: selectionList updated');          
    
                    selectedItem.isSelected = true;
                    //selectedItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_info';
                    selectedItem.class = 'slds-box slds-box_x-small slds-var-m-around_xx-small slds-theme_default selectedItem';
                    if (this.isDebug) console.log('handleSelection: selectedItem updated',JSON.stringify(selectedItem));   
               
                    let selectEvent = new CustomEvent('select', {
                        "detail": {
                            "record": selectedRecord,
                            "list": this.selectionList
                        }
                    });
                    if (this.isDebug) console.log('handleSelection: selectEvent init',JSON.stringify(selectEvent));   
                    this.dispatchEvent(selectEvent);
                    if (this.isDebug) console.log('handleSelection: selectEvent dispatched');
                }
            }
            else {
                if (this.isDebug) console.log('handleSelection: ignoring event');
            } 
            if (this.isDebug) console.log('handleSelection: END');
        }
    }

    handleDeselect(event) {
        console.log('handleRemove: START');
        if (this.isDebug) console.log('handleRemove: START');
        if (this.isDebug) console.log('handleRemove: event',event);
        if (this.isDebug) console.log('handleRemove: detail',JSON.stringify(event.detail));

        if (this.isDebug) console.log('handleRemove: item removed',event.detail.item.name);
        if (this.isDebug) console.log('handleRemove: index removed',event.detail.index);

        if (this.displayItems.length > 1) {
            this.displayItems.splice(event.detail.index,1);
            if (this.isDebug) console.log('handleRemove: displayItems updated',JSON.stringify(this.displayItems)); 
        }

        if (this.displayItems.length == 1) {
            //this.selectedRecord = this.recordList.find(element => element.Id === this.displayItems[0].name);
            this.selectedRecord = this.recordList.find(element => ((element[this.keyField]) === (this.displayItems[0].name)));
            if (this.isDebug) console.log('handleRemove: selection set',JSON.stringify(this.selectedRecord)); 
        }
        if (this.isDebug) console.log('handleRemove: END');
    }

    // Selection Record Sorting
    handleSortSelect(event) {
        //if (this.isDebug) 
        if (this.isDebug) console.log('handleSortSelect: START with ',JSON.stringify(event.detail));

        if (this.isDebug) console.log('handleSortSelect: current direction ',this.sortDirection);
        if (this.isDebug) console.log('handleSortSelect: current sort field ',this.sortedBy);
        if (event.detail.value === this.sortedBy) {
            if (this.isDebug) console.log('handleSortSelect: inverting sort direction on current field');
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        }
        else {
            if (this.isDebug) console.log('handleSortSelect: sorting on new field (asc)');
            this.sortedBy = event.detail.value;
            this.sortDirection = 'asc';
        }
        if (this.isDebug) console.log('handleSortSelect: direction updated ',this.sortDirection);
        if (this.isDebug) console.log('handleSortSelect: new sort field ',this.sortedBy);
        
        this.doSort();
        if (this.isDebug) console.log('handleSortSelect: display list sorted ');

        let sortFields = [...this.sortFields];
        if (this.isDebug) console.log('handleSortSelect: current sortFields ',JSON.stringify(sortFields));
        sortFields.forEach(item => {
            if (item.name === this.sortedBy) {
                item.iconName = (this.sortDirection === 'asc' ? "utility:arrowup" : "utility:arrowdown");
            }
            else {
                item.iconName = null;
            }
        });
        if (this.isDebug) console.log('handleSortSelect: sortFields updated ',JSON.stringify(sortFields));
        this.sortFields = sortFields;

        if (this.isDebug) console.log('handleSortSelect: END');
    }
    doSort() {
        if (this.isDebug) console.log('doSort: START');
        if (this.isDebug) console.log('doSort: sortedBy field fetched ',this.sortedBy);
        if (this.isDebug) console.log('doSort: sortDirection fetched ',this.sortDirection);

        let results2sort = [...this.displayItems];
        if (this.isDebug) console.log('doSort: results2sort init ',JSON.stringify(results2sort));

        results2sort.sort(this.sortValueBy(this.sortedBy, this.sortDirection !== 'asc'));
        if (this.isDebug) console.log('doSort: results2sort sorted ',JSON.stringify(results2sort));

        this.displayItems = results2sort;
        if (this.isDebug) console.log('doSort: END');
    }

    // Selection Record Search
    handleScopeChange(event) {
        if (this.isDebug) console.log('handleScopeChange: START');
        if (this.isDebug) console.log('handleScopeChange: event',event);
        if (this.isDebug) console.log('handleScopeChange: event detail',JSON.stringify(event.detail));

        this.searchScope.isChecked = false;
        if (this.isDebug) console.log('handleScopeChange: previous scope ',JSON.stringify(this.searchScope));

        this.searchScope = Object.assign({}, event.detail.value);
        this.searchScope.isChecked = true;
        if (this.isDebug) console.log('handleScopeChange: new scope ',JSON.stringify(this.searchScope));

        if (this.searchString) {
            if (this.isDebug) console.log('handleScopeChange: reevaluating fillter ',this.searchString);
            this.doSearch();
        }

        if (this.isDebug) console.log('handleScopeChange: END');
    }
    handleSearchEntry(event) {
        if (this.isDebug) console.log('handleSearchEntry: START');
        if (this.isDebug) console.log('handleSearchEntry: event',event);
        if (this.isDebug) console.log('handleSearchEntry: event detail',JSON.stringify(event.detail));
        if (this.isDebug) console.log('handleSearchEntry: event keyCode',event.keyCode);
        if (this.isDebug) console.log('handleSearchEntry: searchString',JSON.stringify(this.searchString));

        if (this.isSearchAuto) {
            if (this.isDebug) console.log('handleSearchEntry: triggering auto-search');
            this.doSearch();
        }
        else if (event.keyCode === 13) {
            if (this.isDebug) console.log('handleSearchEntry: return pressed --> triggering search');
            this.doSearch();
        }
        if (this.isDebug) console.log('handleSearchEntry: END');
    }
    handleSearchChange(event) {
        if (this.isDebug) console.log('handleSearchChange: START');
        if (this.isDebug) console.log('handleSearchChange: event',event);
        if (this.isDebug) console.log('handleSearchChange: event detail',JSON.stringify(event.detail));
        this.searchString = event.detail.value;
        if (this.isDebug) console.log('handleSearchChange: searchString',JSON.stringify(this.searchString));

        if (!this.searchString) {
            if (this.isDebug) console.log('handleSearchChange: empty searchString --> triggering search');
            this.doSearch();
        }
        if (this.isDebug) console.log('handleSearchChange: END');
    }
    doSearch() {
        if (this.isDebug) console.log('doSearch: START');

        if (this.isDebug) console.log('doSearch: searchScope', JSON.stringify(this.searchScope));
        if (this.isDebug) console.log('doSearch: searchString',JSON.stringify(this.searchString));

        let isGlobalSearch = (this.searchScope.value === 'ALL');
        if (this.isDebug) console.log('doSearch: isGlobalSearch',isGlobalSearch);

        if (this.searchString) {
            this.displayItems.forEach(eachItem => {eachItem.isFiltered = false;});
            if (this.isDebug) console.log('doSearch: all items reset to filtered');
            
            let searchString = this.searchString.toLowerCase();
            if (this.isDebug) console.log("doSearch: filtering list with ",searchString);
            
            let searchTerms = searchString.split(' ');
            if (this.isDebug) console.log("doSearch: search terms extracted",searchTerms);
            
            if (isGlobalSearch) {
                if (this.isDebug) console.log("doSearch: global search requested");
                
                searchTerms.forEach(searchWord => {
                    if (this.isDebug) console.log("doSearch: processing searchWord",searchWord);
                    if ((searchWord) && (searchWord.trim())) {
                        searchWord = searchWord.trim();

                        this.displayItems.forEach(eachItem => {
                            if (this.isDebug) console.log("doSearch: processing item",JSON.stringify(eachItem));

                            eachItem.isFiltered = eachItem.isFiltered || this.match(eachItem.label,searchWord);
                            //console.log("doSearch: label processed ",eachItem.label);
                            if (!eachItem.isFiltered) {
                                //console.log("doSearch: searching in detail fields");
                                eachItem.details.forEach(item => {
                                    //console.log("doSearch: processing detail field",JSON.stringify(item));
                                    eachItem.isFiltered = eachItem.isFiltered || this.match(item.value,searchWord);
                                });
                            }
                            //for (let fieldName in eachItem.value) {
                            //    console.log("doSearch: processing fieldName",fieldName);
                            //    eachItem.isFiltered = eachItem.isFiltered || this.match(eachItem.value[fieldName],searchWord);
                            //}
                        });
                    }
                    else {
                        if (this.isDebug) console.log("doSearch: ignored searchWord",searchWord);
                    }
                });
            }
            else {
                if (this.isDebug) console.log("doSearch: scoped search requested",this.searchScope);
        
                let fieldName = this.searchScope.value;
                if (this.isDebug) console.log("doSearch: fieldName set",fieldName);
                
                if (fieldName === this.nameField) {
                    if (this.isDebug) console.log("doSearch: searching in title");
                    searchTerms.forEach(searchWord => {
                        if (this.isDebug) console.log("doSearch: processing searchWord",searchWord);
                        if ((searchWord) && (searchWord.trim())) {
                            searchWord = searchWord.trim();
                            this.displayItems.forEach(eachItem => {
                                if (this.isDebug) console.log("doSearch: processing item",JSON.stringify(eachItem));
                                eachItem.isFiltered = eachItem.isFiltered || this.match(eachItem.label,searchWord);
                            });
                        }
                        else {
                            if (this.isDebug) console.log("doSearch: ignored searchWord",searchWord);
                        }
                    });
                }
                else {
                    if (this.isDebug) console.log("doSearch: searching in details");
                    searchTerms.forEach(searchWord => {
                        if (this.isDebug) console.log("doSearch: processing searchWord",searchWord);
                        if ((searchWord) && (searchWord.trim())) {
                            searchWord = searchWord.trim();
                            this.displayItems.forEach(eachItem => {
                                if (this.isDebug) console.log("doSearch: processing item",JSON.stringify(eachItem));
                                let scopeItem = eachItem.details.find( item => item.label === this.searchScope.label);
                                eachItem.isFiltered = eachItem.isFiltered || (scopeItem ? this.match(scopeItem.value,searchWord) : false);
                            });
                        }
                        else {
                            if (this.isDebug) console.log("doSearch: ignored searchWord",searchWord);
                        }
                    });
                }
                /*searchTerms.forEach(searchWord => {
                    console.log("doSearch: processing searchWord",searchWord);
                    if ((searchWord) && (searchWord.trim())) {
                        searchWord = searchWord.trim();


                        this.displayItems.forEach(eachItem => {
                            console.log("doSearch: processing item",JSON.stringify(eachItem));
                            eachItem.isFiltered = this.match(eachItem.value[fieldName],searchWord);
                            
                        });
                    }
                    else {
                        console.log("doSearch: ignored searchWord",searchWord);
                    }
                });*/
            }
            if (this.isDebug) console.log("doSearch: items filtered",JSON.stringify(this.displayItems));
        }
        else {
            if (this.isDebug) console.log("doSearch: unfiltering items");   
            this.displayItems.forEach(eachItem => {eachItem.isFiltered = true;});
        }
        if (this.isDebug) console.log('doSearch: END');
    }

    // Utilities
    match = function(fieldValue,searchWord) {
        //console.log("match: START with ", searchWord);   

        if (typeof fieldValue == 'string') {
            if ((fieldValue.toLowerCase()).includes(searchWord)) {
                //console.log("match: match found (str) for ",fieldValue);
                return true;
            }
        }
        else if (typeof fieldValue == 'number') {
            if (('' + Math.round(fieldValue)).includes(searchWord)) {
                //console.log("match: END match found (nbr) for ",fieldValue);
                return true;
            }
        }
        else {
            //console.log("match: unsupported field type");
        }
        //console.log("match: END no match found for ", fieldValue);
        return false;
    }
    
    sortValueBy = (field, reverse, primer) => {
        var key = primer ?
            function(x) {return primer((x.value)[field])} :
            function(x) {return (x.value)[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = (key(a) || '');
            b = (key(b) || '');
            return reverse * ((a > b) - (b > a));
        }
    }
}