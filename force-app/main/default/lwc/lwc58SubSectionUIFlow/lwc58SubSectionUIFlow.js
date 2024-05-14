import {LightningElement, track, api,wire} from 'lwc';
import getSubSection from '@salesforce/apex/LWC58_SubSectionUIFlow.getSubSection';
import delSelectedSubSection from '@salesforce/apex/LWC58_SubSectionUIFlow.delSelectedSubSection';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import SUBSECTION_OBJECT from '@salesforce/schema/SubSection__c';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import LIMIT_TYPE_FIELD from '@salesforce/schema/SubSection__c.LimitType__c';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';
import updateToastMessageOnFlow from '@salesforce/apex/flowCustFootUpdateToastMess.updateToastMessageOnFlow';
import updateSubSectionSelected from '@salesforce/apex/LWC58_SubSectionUIFlow.updateSubSectionSelected'; //RRA - ticket 1532 - 12062023
import {CurrentPageReference } from 'lightning/navigation';
import {fireEvent} from 'c/pubSub';

//import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
// row actions
const actions = [
    { label: 'Edit', name: 'Edit'}, 
    { label: 'Delete', name: 'Delete'}
];
// datatable columns with row actions
const columns = [
    { label: 'Principal SubSection', fieldName: 'PrincipalSubSection__c', type: 'boolean', initialWidth: 150, cellAttributes: { alignment: 'center'}},  //RRA - ticket 1532 - 12062023
    { label: 'LimitType', fieldName: 'LimitType__c', initialWidth: 120, type: 'Number' },
    { label: 'Limit', fieldName: 'Limit__c', initialWidth: 100, type: 'Number' }, 
    { label: 'Deductible', fieldName: 'Deductible__c', initialWidth: 130, type: 'Number'}, 
    { label: 'AAL', fieldName: 'AAL__c', initialWidth: 100, type: 'Number', cellAttributes: {
        class: '',
    },}, 
    { label: 'AAD', fieldName: 'AAD__c', initialWidth: 100, type: 'Number'  },
    { label: 'TAL', fieldName: 'TAL__c', initialWidth: 100, type: 'Number' }, 
    { label: 'Unlimited', fieldName: 'Unlimited', initialWidth: 120, type: 'text' }, 
    { label: 'List Referential HazardBassin', fieldName: 'lstNameReferentialHazardBassin__c',wrapText: true,  initialWidth: 440, type: 'text', fixedWidth: 440}, 
    { label: 'List PortFolioSegment', fieldName: 'lstPortFolioSegment__c',wrapText: true, initialWidth: 440, type: 'text', fixedWidth: 440 }, // wrapText: true => put text on each line (carriage return)
    /*{
        type: 'action', initialWidth: 200,
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'top', //Avoid <lightning:datatable> - action columns menu is "cut" by the bottom of table
        }
    },*/

    { type: 'button', fixedWidth: 130,typeAttributes: { label: 'Edit', name: 'Edit', variant: 'brand', iconName: 'action:edit', iconPosition: 'left', title: 'Edit'}, cellAttributes: { alignment: 'right'}},
    { type: 'button', fixedWidth: 130,typeAttributes: { label: 'Delete', variant: 'destructive',name: 'Delete', iconName: 'action:delete', iconPosition: 'left', title: 'Delete'} , cellAttributes: { alignment: 'left' }},
];
export default class lwc58SubSectionUIFlow extends LightningElement {
  // reactive variables
  @track columns = columns;
  @track showLoadingSpinner = false;
  @api recordId;
  @api action;
  @api subSection_RecordId;
  @api lstSubSection;

  // non-reactive variables
  selectedRecords = [];
  OptionOpt;
  refreshTable;
  visiblePS = true;
  visibleHB = true;
  error;
  mapLimitTypeLabelValue = new Map();
  mapLimitTypeLabelValueLabel = new Map();
  wiredPicklist;
  limiTypeOpt;
  allDataSubSecApiName;
  refreshTable;
  titleSubSection;
  disableHB=false;
  disablePS=false;
  preSelectedSubSection = [];

  @wire(getObjectInfo, { objectApiName: SUBSECTION_OBJECT })
  objectInfo;
  
  @wire(CurrentPageReference) pageRef;

  connectedCallback(){
    console.log('recordId == ' , this.recordId );
  }

  separateThousands(n) {
    var parts = n.toString().split(".");
    const numberPart = parts[0];
    const decimalPart = parts[1];
    const thousands = /\B(?=(\d{3})+(?!\d))/g;
    return numberPart.replace(thousands, " ") + (decimalPart ? "." + decimalPart : "");
}

  @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LIMIT_TYPE_FIELD})
  setLimitTypeSubSecPicklistOpt({error, data}) {
    console.log('data == ', data);
      if(data){
          this.limiTypeOpt = data.values;
          this.mapLimitTypeLabelValueLabel = new Map();
          this.mapLimitTypeValueLabel = new Map();

          for(var i = 0; i < data.values.length; i++){
              this.mapLimitTypeLabelValueLabel.set(data.values[i].value, data.values[i].label);
              this.mapLimitTypeValueLabel.set(data.values[i].label, data.values[i].value);
          }

          let lstUpdtData = [];
          //let lstUpdtDataUnique = []; //RRA - ticket 1665 - 23102023
          //let key; //RRA - ticket 1665 - 23102023
          console.log('this.lstSubSection.length == ', this.lstSubSection.length);
          for(let i = 0; i < this.lstSubSection.length; i++){
              let rowData = { ...this.lstSubSection[i]};
              //key =  rowData.lstIdPortFolioSegment__c  + '_' + rowData.lstIdReferentialHazardBassin__c;
              if ( rowData.Limit__c != null ||  rowData.Limit__c != undefined){
                rowData.Limit__c = this.separateThousands(rowData.Limit__c);
              }else{
                rowData.Limit__c= null;
              }

              if ( rowData.Deductible__c != null ||  rowData.Deductible__c != undefined){
                rowData.Deductible__c = this.separateThousands(rowData.Deductible__c);
              }else{
                rowData.Deductible__c= null;
              }

              if ( rowData.AAL__c != null ||  rowData.AAL__c != undefined){
                rowData.AAL__c = this.separateThousands(rowData.AAL__c);
              }else{
                rowData.AAL__c= null;
              }

              if ( rowData.AAD__c != null ||  rowData.AAD__c != undefined){
                rowData.AAD__c = this.separateThousands(rowData.AAD__c);
              }else{
                rowData.AAD__c= null;
              }

              if ( rowData.TAL__c != null ||  rowData.TAL__c != undefined){
                rowData.TAL__c = this.separateThousands(rowData.TAL__c);
              }else{
                rowData.TAL__c= null;
              }

              rowData.LimitType__c = this.mapLimitTypeLabelValueLabel.get(this.lstSubSection[i].LimitType__c);
              rowData.lstNameReferentialHazardBassin__c = rowData.lstNameReferentialHazardBassin__c + '\n' ;
              rowData.lstPortFolioSegment__c = rowData.lstPortFolioSegment__c + '\n' ;

                if (rowData.Unlimited__c == true ){
                    rowData.Unlimited = 'Yes';
                }else{
                    rowData.Unlimited = 'No';
                }
              lstUpdtData.push(rowData);
          }
          //lstUpdtDataUnique = this.getUniqueData(lstUpdtData, 'TECH_UniqueSubSectionView__c'); //RRA - ticket 1665 - 23102023
          console.log('lstUpdtData == ', lstUpdtData);
      
          //console.log('lstUpdtDataUnique == ', lstUpdtDataUnique);
          this.titleSubSection = 'Sub Sections ('+ this.lstSubSection.length +')';
          //this.lstSubSection = lstUpdtDataUnique; //RRA - ticket 1665 - 23102023
          this.lstSubSection = lstUpdtData;
          console.log('this.lstSubSection == ', this.lstSubSection);

         
      }else{
          this.error = error;
      }
  }
  
 //RRA - ticket 1665 - 23102023
  getUniqueData(arr, comp) {
    const unique = arr.map(e => e[comp])
                     .map((e, i, final) => final.indexOf(e) === i && i)
                     .filter(e => arr[e]).map(e => arr[e]);
    return unique;
}

  // Manage column ReferentialHazardBassin to display or no
  handleCheckboxChangeHB(e) {
        if(this.visibleHB){
            this.disablePS=true;
        }else{
            this.disablePS=false;
        }
        
        this.visibleHB = !this.visibleHB;
        if (this.visibleHB) {
            this.columns = [...columns];
        } else {
            // return every column but the one you want to hide
            this.columns = [...columns].filter(col => col.fieldName != 'lstNameReferentialHazardBassin__c' );
        }
    }

  // Manage column lstPortFolioSegment to display or no
  handleCheckboxChangePS(e) {
    if(this.visiblePS){
        this.disableHB=true;
    }else{
        this.disableHB=false;
    }
    
    this.visiblePS = !this.visiblePS;
    if (this.visiblePS) {
        this.columns = [...columns];
    } else {
        this.columns = [...columns].filter(col => col.fieldName != 'lstPortFolioSegment__c');
    }
 }
  
  //RRA - ticket 1532 - 12062023
  handleRowSelection(event) {
    this.showLoadingSpinner = true;
    let lstSelectedSubSection = this.template.querySelector('lightning-datatable').getSelectedRows(); 
    let lstSubSectionSelect = [];
    let lstUpdateSubSection = [];
    let lstIdSubSec = [];
  
      for (let i=0;i<lstSelectedSubSection.length;i++){
        let row = {...lstSelectedSubSection[i]};
        lstIdSubSec.push(row.Id);
        //convert label to value apiname
        row.LimitType__c = this.mapLimitTypeValueLabel.get(lstSelectedSubSection[i].LimitType__c);
        lstSubSectionSelect.push(row);
      }
      this.preSelectedSubSection = lstIdSubSec;
      
      //Operation to update PrincipalSubSection__c to true beside apex
      updateSubSectionSelected({lstSubSection: lstSubSectionSelect})
      .then(result => {           
          console.log('result ====> ', result);
          let updateSubSec = result;
          
          //Update the checkbox ticked on UI to each update on the record of subsection
          for (let i=0;i<this.lstSubSection.length;i++){
            let rowParent ={...this.lstSubSection[i]};
            for (let j=0;j<updateSubSec.length;j++){
              let rowChild ={...updateSubSec[j]};
              if (rowParent.Id == rowChild.Id){
                rowParent.PrincipalSubSection__c = rowChild.PrincipalSubSection__c; 
              }else{
                rowParent.PrincipalSubSection__c = false;
              }
              rowParent.LimitType__c = this.mapLimitTypeLabelValueLabel.get(rowChild.LimitType__c);
            }
            lstUpdateSubSection.push(rowParent);
          }
          console.log('lstUpdateSubSection ====> ', lstUpdateSubSection);
          this.lstSubSection = lstUpdateSubSection;
          
          fireEvent(this.pageRef, 'requiredFieldPrincipSubSec', this.lstSubSection);
          // showing success message 
          this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'SubSection updated Successfully',
            variant: 'success'
        }),);      
          this.showLoadingSpinner = false;
      })
      .catch(error => {
          console.log('Error ====> '+error);
          this.dispatchEvent(new ShowToastEvent({
              title: 'Error update SubSection', 
              message: error.message, 
              variant: 'error'
          }),);
      });
    //} 
  }

  handleRowActions(event) {
    let actionName = event.detail.action.name;
    console.log('actionName ====> ' + actionName);
    let row = event.detail.row;
    console.log('subSection_RecordId ====> ' + row.Id);
    console.log('RecordId ====> ' + this.recordId);
    // eslint-disable-next-line default-case
    switch (actionName) {
        case 'Edit':
            this.updateToastMessageOnFlow();
            this.showLoadingSpinner = true;
            this.action = 'Edit';
            this.subSection_RecordId = row.Id;
            // Navigate Event on flow to Edit
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
            //window.location.assign();
            break;
        case 'Delete':
          this.updateToastMessageOnFlow();
            this.action = 'Delete';
            this.subSection_RecordId = row.Id;
            // Navigate Event on flow to Delete
            const navigateDeletetEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateDeletetEvent);
            //this.deleteSubSection(row);
            break;
    }
 }

 deleteSubSection(currentRow) {
    let lstCurentIdRecordSubSec = [];
    lstCurentIdRecordSubSec.push(currentRow.Id);
    this.showLoadingSpinner = true;

    // calling apex class method to delete the selected subSection
    delSelectedSubSection({lstIdSubSec: lstCurentIdRecordSubSec})
    .then(result => {
        console.log('result ====> ' + result);
        this.showLoadingSpinner = false;

        // showing success message
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success!!',
            message: currentRow.Name +' SubSection deleted.',
            variant: 'success'
        }),);

        // refreshing table data using refresh apex
         return refreshApex(this.refreshTable);

    })
    .catch(error => {
        console.log('Error ====> '+error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error delete SubSection', 
            message: error.message, 
            variant: 'error'
        }),);
    });
 }

 updateToastMessageOnFlow (){
  console.log('recordId__FlowUpdate == ' , this.recordId );
    updateToastMessageOnFlow({ idSection : this.recordId})
    .then(result => {
      refreshApex (result);
      console.log('resultMess = ', result);
        console.log('Update SuccessErrorToastMessageOnFlow__c done')
    })
    .catch(error => {
        this.error = error;
        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
    });
  }
}