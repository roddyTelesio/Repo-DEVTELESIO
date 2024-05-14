import { LightningElement, wire, track, api  } from 'lwc';
import { refreshApex } from '@salesforce/apex'; 
import sfpegJsonUtl from 'c/sfpegJsonUtl';
import {getPicklistValues , getObjectInfo} from 'lightning/uiObjectInfoApi';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
import { NavigationMixin } from 'lightning/navigation';

//labels 
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import QuoteTableUwYear from '@salesforce/label/c.QuoteTableUwYear';

// custom action imports
import getClasseurs from '@salesforce/apex/CreateClasseurs.getClasseurs';
import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import refreshClasseur from '@salesforce/apex/CreateClasseurs.refreshClasseur';

//platform event subscriptions
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';


const columns = [
    {
        label: 'Ceding Company',
        fieldName: 'Cedente__r.Name',
        sortable: true
    }, 
    {
        label: 'Name',
        fieldName: 'Name',
        sortable: true
    }, 
    {
        label: 'Version',
        fieldName: 'Version__c',
        sortable: true
    },
    {
        label: 'Last Modified Date',
        fieldName: 'LastModifiedDate',
        type: "date",
        typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        },
        sortable: true
    },
    {
        label: 'Last Modified By',
        fieldName: 'LastModifiedBy.Name',
        sortable: true
    }, 
    {
        type: "button", 
        typeAttributes: {  
            label: 'Refresh Excel',  
            name: 'refresh',  
            title: 'Refresh Excel',  
            disabled: false,  
            value: 'refresh',  
            iconPosition: 'center'  
        }
    } 
    // {
    //     type: "button", 
    //     typeAttributes: {  
    //         label: 'Open',  
    //         name: 'open',  
    //         title: 'Open',  
    //         disabled: false,  
    //         value: 'open',  
    //         iconPosition: 'center'  
    //     }
    // }
];


export default class ClasseursList extends NavigationMixin(LightningElement)  {


    //platform events
    channelName = '/event/QuoteTableResponse__e';
    isSubscribeDisabled = false;
    isUnsubscribeDisabled = !this.isSubscribeDisabled;

    subscription = {};
    loading = false; 
    // Handles subscribe button click
    handleSubscribe(recordId) {
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('New message received: ', JSON.stringify(response));
            console.log('handleSubscribe : RecordId ',  recordId);

            console.log("handleSubscribe : recordId ", recordId );
            console.log("handleSubscribe : response.data.payload.classeurId__c ", response.data.payload.classeurId__c );


            console.log("handleSubscribe : Success");
            console.log("handleSubscribe : recordId ", recordId );
            console.log("handleSubscribe : response.data.payload.classeurId__c ", response.data.payload.classeurId__c );
            // let THEURL= '/lightning/r/Classeur__c/'+response.data.payload.classeurId__c + '/view';
            // window.open(THEURL, '_top')

            if(recordId == response.data.payload.classeurId__c){
                setTimeout(function () {
                    console.log("handleSubscribe: opening quote table");
                    let THEURL= '/lightning/n/Quote_Table?c__tab=quotetablelist';
                    window.open(THEURL, '_top');
    
                }, 15000);
    
                window.open('/sfc/servlet.shepherd/version/download/'+response.data.payload.FileUrl__c, '_blank').focus();
            }
            console.log("handleSubscribe : redirected");

            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }


    // modal start
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    @track fileUploaded = false; 
    @track uploadedFile;
    selectedRecordId;
    // modal end

    // file uploads
    @api
    myRecordId;
    get acceptedFormats() {
        return ['.xls', '.xlsm'];
    }


    closeModal(){
        console.log('closeModal : START');
        this.isModalOpen = false; 
        this.uploadedFile = undefined; 
        this.fileUploaded = false;
        console.log('closeModal : END');
    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        this.uploadedFile = event.detail.files[0];
        console.log('uploadedFile : ' , this.uploadedFile);
        this.fileUploaded = true; 
    }

    handleExportRefresh(){
        console.log('handleExportRefresh : START With ' , this.selectedRecordId);
        // callout to DFP for excel refresh
        this.loading = true; 
        let param = {
            ClasseurId : this.selectedRecordId,
            fileId : this.uploadedFile.documentId
        };
        refreshClasseur(param)
            .then(
                (response) => {
                    console.log('handleExportRefresh : response received ' , response);
                    this.handleSubscribe(response.classeurId);
                }
            )
            .catch(
                (error) => {
                    console.log('handleExportRefresh : error received ', error);
                    sfpegJsonUtl.sfpegJsonUtl.showToast(this, {
                        mode : 'sticky', 
                        variant : 'error', 
                        message: this.label.QuoteTableApexError,
                        title: 'Error'
                    });
                    this.loading = false; 
                }
            );
        console.log('handleExportRefresh : END');
    }
    // modal end
    handleKeyUpSearch(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
        }
    }

    handleRowAction(e){

        console.log('handleRowAction : Start');
        let actionClicked = e.detail.action.name; 
        this.selectedRecordId = e.detail.row.Id;

        if(actionClicked == 'open'){
            this.openExcel(this.selectedRecordId); 
        }

        if(actionClicked == 'refresh'){
            this.isModalOpen = true; 
        }
        console.log('handleRowAction : End');
    }
    handleExportExcel(){
        console.log('handleExportExcel : Start');
        this.handleNavigateToExcel(); 
        console.log('handleExportExcel : End');
    }

    // datatable variables start
    @track value;
    @track error;
    @track data;
    @api sortedDirection = 'DESC';
    @api sortedBy = 'LastModifiedDate';
    @api searchKey = '';
    @api SOQL_FIELDS ='InitialClasseurRecord__c,Cedente__r.name,id, name, Version__c, LastModifiedDate, LastModifiedBy.name, Commentaire__c, Date_de_Prochain_MAJ__c, DerniereMajPar__r.name'; 
    result;
    @track allSelectedRows = [];
    @track page = 1; 
    @track items = []; 
    @track data = []; 
    @track columns; 
    @track startingRecord = 1;
    @track endingRecord = 0; 
    @track pageSize = 10; 
    @track totalRecountCount = 0;
    @track totalPage = 0;
    isPageChanged = false;
    initialLoad = true;
    mapoppNameVsOpp = new Map();;
    // datatable variables end

    // filter variables
    uwYearOpt;
    queryTerm;
    @api selectedUwYear = QuoteTableUwYear; 
    label = {PrincipalCedingCompany};
    selectedComp; 
    defaultCedingComps; 
    cedingAccOpt;
    @api cedingCompany = ''; 
    // filter variables end
  
    @wire(getClasseurs, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection', fields : '$SOQL_FIELDS', selectedUwYear : '$selectedUwYear', cedingCompany : '$cedingCompany', defaultCedingComps : '$defaultCedingComps'})
    wiredAccounts({ error, data }) {
        if (data) {
            console.log('data got: ' , data);
            this.processRecords(data);
            this.error = undefined;
            
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }


    @api getRows() {
        return this.template.querySelector("lightning-datatable")
          .getSelectedRows();
    }

    processRecords(data){
            this.items = data;
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            
            this.data = this.items.slice(0,this.pageSize);
            this.flattenData();
            this.endingRecord = this.pageSize;
            this.columns = columns;
            console.log("columns: " );
    }
    //clicking on previous button this method will be called
    previousHandler() {
        this.isPageChanged = true;
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
          var selectedIds = [];
          for(var i=0; i<this.allSelectedRows.length;i++){
            selectedIds.push(this.allSelectedRows[i].Id);
          }
        this.template.querySelector(
            '[data-id="table"]'
          ).selectedRows = selectedIds;
    }

    //clicking on next button this method will be called
    nextHandler() {
        this.isPageChanged = true;
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);            
        }
          var selectedIds = [];
          for(var i=0; i<this.allSelectedRows.length;i++){
            selectedIds.push(this.allSelectedRows[i].Id);
          }
        this.template.querySelector(
            '[data-id="table"]'
          ).selectedRows = selectedIds;
    }

    //this method displays records page by page
    displayRecordPerPage(page){

        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 

        this.data = this.items.slice(this.startingRecord, this.endingRecord);
        this.flattenData();
        this.startingRecord = this.startingRecord + 1;
    }    
    
    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.result);
        
    }
    
    onRowSelection(event){
        if(!this.isPageChanged || this.initialLoad){
            if(this.initialLoad) this.initialLoad = false;
            this.processSelectedRows(event.detail.selectedRows);
        }else{
            this.isPageChanged = false;
            this.initialLoad =true;
        }
        
    }
    processSelectedRows(selectedOpps){
        var newMap = new Map();
        for(var i=0; i<selectedOpps.length;i++){
            if(!this.allSelectedRows.includes(selectedOpps[i])){
                this.allSelectedRows.push(selectedOpps[i]);
            }
            this.mapoppNameVsOpp.set(selectedOpps[i].Name, selectedOpps[i]);
            newMap.set(selectedOpps[i].Name, selectedOpps[i]);
        }
        for(let [key,value] of this.mapoppNameVsOpp.entries()){
            if(newMap.size<=0 || (!newMap.has(key) && this.initialLoad)){
                const index = this.allSelectedRows.indexOf(value);
                if (index > -1) {
                    this.allSelectedRows.splice(index, 1); 
                }
            }
        }
    }

    flattenData(){
        let dataObj = JSON.parse(JSON.stringify(this.data));
        this.data  = sfpegJsonUtl.sfpegJsonUtl.flattenJsonList(dataObj , []);
    }
    
    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        var data = [];
        for(var i=0; i<this.items.length;i++){
            if(this.items[i]!= undefined && this.items[i].Name.includes(this.searchKey)){
                data.push(this.items[i]);
            }
        }
        this.processRecords(data);
    }

    // filtering devs start
    @wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            console.log('getPicklistValues : data ' , data);
            this.uwYearOpt = data.values;
        }
        else{
            console.log('getPicklistValues : error ' , error);
            this.error = error;
        }
    }

    
    @wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){            
            this.cedingAccOpt = data;    
            console.log('setAccPicklistOptions : data ' , data);
            this.defaultCedingComps = data.map((e) => {return "'" + e.value +"'"}).join(","); 
            
        }
        else{
            this.error = error;
        }
    }

    handleChangeCedingComp(event) {
        console.log('handleChangeCedingComp: Start');
        this.cedingCompany = event.detail.value; 
        console.log('handleChangeCedingComp: End');
    }

    handleChangeUWYr(event) {
        console.log('handleChangeUWYr : Start');
        this.selectedUwYear = event.detail.value;
        // console.log('handleChangeUWYr : this.selectedUwYear ' );

        // this.searchKey = event.target.value;

        // var data = [];
        // for(var i=0; i<this.items.length;i++){
        //     console.log('handleChangeUWYr : this.items ' , this.items[i]); 
        //     if(this.items[i]!= undefined && this.items[i].Name.includes(this.searchKey)){
        //         data.push(this.items[i]);
        //     }
        // }
        // this.processRecords(data);
        console.log('handleChangeUWYr : End');
    }
    //filtering devs end


    // event click events start
    handleNavigateToExcel(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        // This example passes true to the 'replace' argument on the navigate API
        // to change the page state without pushing a new history entry onto the
        // browser history stack. This prevents the user from having to press back
        // twice to return to the previous page.
        this.openExcel(); 
    }
    // event click events end

    openExcel(id) {
        console.log('openExcel: start'); 
        console.log('openExcel: Id ' , id); 
        let THEURL= '/lightning/n/ParametersSetup?c__id='+id;
        window.open(THEURL, '_top')

    }


    // Returns a page reference that matches the current page
    // but sets the 'c__showPanel' page state property to 'true'
    get showRecord() {
        return this.getUpdatedPageReference({
            c__showPanel: 'true' // Value must be a string
        });
    }

    // Utility function that returns a copy of the current page reference
    // after applying the stateChanges to the state on the new copy
    getUpdatedPageReference(stateChanges) {
        // The currentPageReference property is read-only.
        // To navigate to the same page with a modified state,
        // copy the currentPageReference and modify the copy.
        return Object.assign({}, this.currentPageReference, {
            // Copy the existing page state to preserve other parameters
            // If any property on stateChanges is present but has an undefined
            // value, that property in the page state is removed.
            state: Object.assign({}, this.currentPageReference.state, stateChanges)
        });
    }

}