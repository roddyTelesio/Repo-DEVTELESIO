import {LightningElement, track, wire, api} from 'lwc';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import deleteReinstatementSelected from '@salesforce/apex/lwc57ReinstatementUIFlow.deleteReinstatementSelected';
import REINSTATEMENT_OBJECT from '@salesforce/schema/Reinstatement__c';
import REINSTATEMENT_FIELD from '@salesforce/schema/Section__c.Reinstatements__c';
import PRORATA_REINS_FIELD from '@salesforce/schema/Reinstatement__c.Prorata__c';
import Reinstatements from '@salesforce/label/c.Reinstatements';
import Reinstatement from '@salesforce/label/c.Reinstatement';
import Reinstatement_Empty from '@salesforce/label/c.Reinstatement_Empty'; 
import {fireEvent, registerListener} from 'c/pubSub';
import {CurrentPageReference } from 'lightning/navigation';



const columnsReinstatements = [
    { label: 'Order', fieldName: 'Order__c'},
    { label: 'Percentage', fieldName: 'Percentage__c'},
    { label: 'Free', fieldName: 'FreeValue__c'},
    { label: 'Prorata', fieldName: 'ProrataValue__c'},
];
 
export default class Lwc59ReinstatementUIFlow extends LightningElement {

    label = {
        
        Reinstatements,Reinstatement,Reinstatement_Empty
     }
 
     wiredPicklist;wiredLob;
     reinstatementsEmpty = false;
     ReinstatementOpt;
     isLoadingReinstatement = false;
     @api lstReinstatement;
     @api preselectionList;
     @api allLstReinstatement = [];
     @api allDataReins = [];
     columnsReinstatements = columnsReinstatements;
     openNewReinstatementModal = false;
     selectedReinstatement;
     @api TypeOfReinstatement;
     @api refreshCondition;
     isNewReinstatementDisable = true;
     mapReinstatementType = new Map();
     mapLabelReinstatementType = new Map();
     mapProrataLabelValue = new Map();
     mapProrataValueLabel = new Map();
     titleReinstatement = 'Reinstatements (0)';
     disablePercentageReins = false;disableProrataReins = false;
     allDataReinstatements = [];
     insertToDBReins= [];
     @api percentageReins = 0; @api prorataReins;
     @api valTypeReinsRequired = false;
     @api recordId;
     @api Free;
     @api typeReinsFlow;
     @api idSubSection = null;
     @api disableRowData = false;
     OptionOpt;
     prorataReinsOpt;
     @api orderReins = 1;
     isFreeChecked = false;
     programId;
     @api outputList;
     isDeleteNotAllowed = false;

     @wire(CurrentPageReference) pageRef;
     connectedCallback (){
        registerListener('requiredFieldTypeReins', this.setValueRequiredType, this);
        registerListener('changeReins', this.valReinsType, this);
        registerListener('refreshCond', this.refreshCondition, this);
        this.valReinsType();
        console.log('this.selectedReinstatement  == ', this.selectedReinstatement);
        if (this.selectedReinstatement == undefined){
            this.isDeleteNotAllowed = true;
        }
        
     }
 
     @wire(getObjectInfo, { objectApiName: REINSTATEMENT_OBJECT })
     objectInfo;

     @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: REINSTATEMENT_OBJECT, fieldApiName: PRORATA_REINS_FIELD})
    setProrataReinsPicklistOpt({error, data}) {
        if(data){
            this.prorataReinsOpt = data.values;
            this.mapProrataLabelValue = new Map();
            this.mapProrataValueLabel = new Map();

            for(var i = 0; i < data.values.length; i++){
                this.mapProrataLabelValue.set(data.values[i].label, data.values[i].value);
                this.mapProrataValueLabel.set(data.values[i].value, data.values[i].label);
            }

            
            //Manage fields prorata / percent / Free on Reinstatements and  Display to UI unsing Label on Free__c;
            let lstUpdtData = [];
            console.log('this.lstReinstatement_setProrataReinsPicklistOpt == ', this.lstReinstatement);
            //console.log('this.lstReinstatementsize == ', this.lstReinstatement.length);
            // For UI
            if (this.lstReinstatement != undefined || this.lstReinstatement != null){
                this.isLoadingReinstatement = true;
                for(let i = 0; i < this.lstReinstatement.length; i++){
                    let rowData = { ...this.lstReinstatement[i]};
                    if (rowData.Key_Insert_Update_Reinstatement__c == null){
                        rowData.Prorata__c = this.lstReinstatement[i].Prorata__c;
                            if(rowData.Percentage__c != undefined){
                                rowData.Percentage__c = rowData.Percentage__c;
                            }else{
                                rowData.Percentage__c = null; // 23/08/2022 - Set 0 instead of ''
                            }
                        lstUpdtData.push(rowData);
                    }
                    
                }
    
                this.lstReinstatement = lstUpdtData;
                this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field

                console.log(' this.lstReinstatementLoadUi ==  ', lstUpdtData);

                if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                    this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                }else {
                    this.outputList = null;
                }

               
                console.log('outputListOldValues== ',  this.outputList);
                this.isLoadingReinstatement = false;
            }
            

            // Preselected Conditions when loading UI
            console.log(' this.preselectionList ==  ', this.preselectionList);
            let lstPreDisplay =[];
            var rowDataPreDisplay;
            if (this.preselectionList != null){
                this.isLoadingReinstatement = true;
                for(let i = 0; i < this.preselectionList.length; i++){
                     rowDataPreDisplay = { ...this.preselectionList[i]};
                    if (rowDataPreDisplay.Key_Insert_Update_Reinstatement__c == null){
                        lstUpdtData.push(rowDataPreDisplay);
                    }

                    // Don't display preselected values on the table reinstatement if FreeValue__c = No is only present 
                    if ((rowDataPreDisplay.Type__c == '3' || this.typeReinsFlow == '3') && rowDataPreDisplay.Free__c == false && rowDataPreDisplay.Prorata__c == undefined && rowDataPreDisplay.Percentage__c == undefined && rowDataPreDisplay.Order__c == undefined){
                        console.log('ok à vider 1');
                        lstUpdtData = [];
                        this.titleReinstatement = 'Reinstatements11 ('+ 0 +')';
                        this.outputList = null;
                    }
                    fireEvent (this.pageRef, 'typeOtherInDB',rowDataPreDisplay.Type__c);
                }

                console.log(' lstUpdtData ==  ', lstUpdtData);
                this.lstReinstatement = lstUpdtData;
                this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field

                if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                    this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                }else {
                    this.outputList = null;
                }

                console.log(' this.lstReinstatementPreselecetd ==  ', this.lstReinstatement);
                this.isLoadingReinstatement = false;
            }
        }else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', objectApiName: REINSTATEMENT_OBJECT, fieldApiName: REINSTATEMENT_FIELD})
    setReinstatemnetPicklistOpt({error, data}) {
        if(data){
            //this.isLoadingReinstatement =true;
            console.log('data== ', data.values);
            console.log('typeReinsFlow== ', this.typeReinsFlow);
            console.log('TypeOfReinstatement== ', this.TypeOfReinstatement);
            //console.log('typeReins== ', this.typeReins);
            this.ReinstatementOpt = data.values;
            this.mapReinstatementType = new Map();
            for(var i = 0; i < data.values.length; i++){
               this.mapReinstatementType.set(data.values[i].label, data.values[i].value);
               this.mapLabelReinstatementType.set(data.values[i].value, data.values[i].label);
            }
           //Manage field Type on Reinstatements;
           //***************/
           console.log('lstReinstatementERT == ' , this.lstReinstatement);

           if (this.lstReinstatement != undefined || this.lstReinstatement != null){
            if (this.lstReinstatement.length > 0){
                console.log('lstReinstatement is present ');
                if(this.lstReinstatement[0].Type__c != undefined){
                    console.log('labelType==', this.lstReinstatement[0].Type__c);
                    this.isLoadingReinstatement =true;
                    this.TypeOfReinstatement = this.lstReinstatement[0].Type__c; 
                    fireEvent(this.pageRef, 'changeReins', this.TypeOfReinstatement); //to send to footerCustomerpage
                    console.log('typeReinsFlow==', this.typeReinsFlow);
                        if(this.lstReinstatement[0].Type__c== '3'){
                            this.isNewReinstatementDisable = false;
                            //this.lstReinstatement = this.alllstReinstatement;
                            this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                            this.isLoadingReinstatement =false;
                        } else{
                            this.isNewReinstatementDisable = true;
                            this.lstReinstatement = [];
                            this.alllstReinstatement = [];
                            this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                            this.isLoadingReinstatement =false;
                        }
                    }
                    else if(this.TypeOfReinstatement == '3'){
                        this.isLoadingReinstatement =true;
                        this.isNewReinstatementDisable = false;
                        this.isLoadingReinstatement =false;
                    }
        
                    let lstUpdtData = [];
                    for(let i = 0; i < this.lstReinstatement.length; i++){
                        let rowData = { ...this.lstReinstatement[i]};
                        if (rowData.Key_Insert_Update_Reinstatement__c == null){
                            lstUpdtData.push(rowData);
                        }
                    }
                    this.lstReinstatement = lstUpdtData;
                    this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field

                    if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                        this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                    }else {
                        this.outputList = null;
                    }
                    console.log('this.lstReinstatement222== ', this.lstReinstatement);
                    
                    this.isLoadingReinstatement =false;
            }else{
            console.log('lstReinstatement is not present 1 ');
            //this.TypeOfReinstatement = this.typeReinsFlow.toString();
            //this.lstReinstatement = null;
            //this.outputList = null;
            //this.valReinsType();
            }
            //this.isLoadingReinstatement =false;
        }else{
            if (this.typeReinsFlow != null || this.typeReinsFlow != undefined){
                console.log('lstReinstatement is not present 2 ');
                this.TypeOfReinstatement = this.typeReinsFlow.toString();
                this.lstReinstatement = null;
                this.outputList = null;
                fireEvent(this.pageRef, 'typeExistingReinsInDB', this.TypeOfReinstatement); //to send to footerCustomerpage
                console.log(' this.TypeOfReinstatement is not present 2 ==  ' ,  this.typeReinsFlow);
                //this.valReinsType();
            }
        }

        //Manage Preselected Reinstatements on Type Field;
        //****************/
            if (this.preselectionList != null){
                if(this.preselectionList[0].Type__c != undefined){
                    this.isLoadingReinstatement =true;
                    this.TypeOfReinstatement =this.preselectionList[0].Type__c;
                    if(this.preselectionList[0].Type__c== '3'){
                        this.isNewReinstatementDisable = false;
                        this.titleReinstatement = 'Reinstatements ('+ this.preselectionList.length +')';
                        this.isLoadingReinstatement =false;
                    } else{
                        this.isNewReinstatementDisable = true;
                        this.preselectionList = [];
                        this.alllstReinstatement = [];
                        this.titleReinstatement = 'Reinstatements ('+ this.preselectionList.length +')';
                        this.isLoadingReinstatement =false;
                    }
                }
                else if(this.TypeOfReinstatement == '3'){
                    this.isLoadingReinstatement =true;
                    this.isNewReinstatementDisable = false;
                    this.isLoadingReinstatement =false;
                }
        
                let lstUpdDataPreselected = [];
                for(let i = 0; i < this.preselectionList.length; i++){
                    let rowDataPreselected = { ...this.preselectionList[i]};
                    if (rowDataPreselected.Key_Insert_Update_Reinstatement__c == null){
                        lstUpdDataPreselected.push(rowDataPreselected);
                    }
                        console.log('rowDataPreselected.Prorata__c == ', rowDataPreselected.Prorata__c);
                        console.log('rowDataPreselected.Percentage__c == ', rowDataPreselected.Percentage__c);
                        console.log('rowDataPreselected.Order__c == ', rowDataPreselected.Order__c);
                        console.log('rowDataPreselected.Type__c == ', rowDataPreselected.Type__c);
                        console.log('rowDataPreselected.Free__c == ', rowDataPreselected.Free__c);
                      // Don't display preselected values on the table reinstatement if FreeValue__c = No is only present 
                    if ((rowDataPreselected.Type__c == '3' || this.typeReinsFlow == '3') && rowDataPreselected.Free__c == false && rowDataPreselected.Prorata__c == undefined && rowDataPreselected.Percentage__c == undefined && rowDataPreselected.Order__c == undefined){
                        console.log('ok à vider 2');
                        lstUpdDataPreselected = [];
                        this.titleReinstatement = 'Reinstatements ('+ 0 +')';
                        this.outputList = null;
                    }
                    fireEvent (this.pageRef, 'typeOtherInDB',rowDataPreselected.Type__c);
                }
                this.lstReinstatement = lstUpdDataPreselected;
                this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field
            }

        }else{
           this.error = error;
        }
    }

    valReinsType(val){
        console.log('valReqType222 = ', val);
        this.TypeOfReinstatement = val;

    }

    refreshCondition(val){
        console.log('refreshConditions = ', val);
        this.refreshCondition = val;
    }

    setValueRequiredType(val){
        console.log('valReq = ', val);
        this.valTypeReinsRequired = val;

    }


    handleOpenReinstatementsModal(){
        this.openNewReinstatementModal = true;
        this.isFreeChecked = false;
        this.disablePercentageReins = false;
        this.disableProrataReins = false;
        this.percentageReins = null;
        this.prorataReins = null;
        let lengthReinstatement = this.lstReinstatement.length;
        this.orderReins = lengthReinstatement + 1;
    }

    handleDeleteReinstatements(){
        console.log('Delete Reins Begin at JS');
        //console.log('this.selectedReinstatement.length == ', this.selectedReinstatement.length);
        console.log('this.isDeleteNotAllowed == ', this.isDeleteNotAllowed);
        if (this.isDeleteNotAllowed){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Deletion not allowed',
                    message: 'Please Select at least one (01) Reinstatement',
                    variant: 'error'
                })
            );
        }
        
        let lstSelectedReinstatement = [];
       

        if (this.selectedReinstatement.length > 0) {
            for(let i = 0; i < this.selectedReinstatement.length; i++){
                let rowReins = this.selectedReinstatement[i];
                lstSelectedReinstatement.push(rowReins);
            }
    
            console.log('lstSelectedReinstatement == ', lstSelectedReinstatement);
            console.log('lstReinstatement == ', this.lstReinstatement);
    
            let filterReins = this.lstReinstatement.filter( function(e) { return this.indexOf(e) < 0; },lstSelectedReinstatement );
    
            console.log('filterReins == ', filterReins);
    
            let newDataReinstatements = [];
    
            // info data is listed on the tab reinstatement
            if(this.lstReinstatement.length == this.selectedReinstatement.length){
                this.lstReinstatement = [];
                this.allDataReinstatements = this.lstReinstatement;
                this.selectedReinstatement = [];
                this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                this.outputList = null;
            }else{
                this.lstReinstatement = [];
                for(let i = 0; i < filterReins.length; i++){
                    let newReins = filterReins[i];
                    let order;
                    if(i == 0){
                        order = 1;
                    }else{
                        order = i+1;
                    }
                    newReins['Order__c'] = order.toString();
                    newDataReinstatements.push(newReins);
                }
                console.log('newDataReinstatements == ', newDataReinstatements);
    
                this.lstReinstatement = newDataReinstatements;
    
                console.log('this.lstReinstatement == ', this.lstReinstatement);
    
                //this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field
    
                if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                    this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                }else {
                    this.outputList = null;
                }
    
                console.log('outputList== ',this.outputList);
    
                this.newRecord = Object.assign({},this.lstReinstatement);
                console.log('del lstReinstatement== ',this.lstReinstatement);
    
                this.allDataReinstatements = this.lstReinstatement;
                this.selectedReinstatement = [];
                this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
    
            }
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Deletion not allowed',
                    message: 'Please Select at least one (01) Reinstatement',
                    variant: 'error'
                })
            );
        }       
    }

    handleCloseReinstatementsModal(){
        this.openNewReinstatementModal = false;
    }


        /*handleDeleteReinstatements(){

        let lstSelectedReinstatement = [];
        let lsIdSelectedReinState = [];
        console.log('Delete Reins Begin');

        for(let i = 0; i < this.selectedReinstatement.length; i++){
            let rowReins = this.selectedReinstatement[i];
            lstSelectedReinstatement.push(rowReins);
            lsIdSelectedReinState.push(rowReins.Id);
        }
        deleteReinstatementSelected({ lstIdReins : lsIdSelectedReinState})
        .then(result => {
            //console.log('resultMessage == ', resultMessage);
            console.log('this.selectedReinstatement == ', this.selectedReinstatement);
           // if (resultMessage == null){
                let filterReins = this.lstReinstatement.filter( function(e) { return this.indexOf(e) < 0; },lstSelectedReinstatement );
                let newLstReinstatement = [];
        
                if(this.lstReinstatement.length == this.selectedReinstatement.length){
                    this.lstReinstatement = [];
                    this.allLstReinstatement = this.lstReinstatement;
                    this.selectedReinstatement = [];
                    this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                }else{
                    this.lstReinstatement = [];
                    for(let i = 0; i < filterReins.length; i++){
                        let newReins = filterReins[i];
                        let order;
                        if(i == 0){
                            order = 1;
                        }else{
                            order = i+1;
                        }
                        newReins['Order__c'] = order.toString();
                        newLstReinstatement.push(newReins);
                    }
        
                    console.log('newLstReinstatement== ',newLstReinstatement);
        
                    this.lstReinstatement = newLstReinstatement;
                    this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field

                    if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                        this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                    }else {
                        this.outputList = null;
                    }

                    //this.outputList = this.allDataReins.map(record => Object.assign({}, record));
                    this.newRecord = Object.assign({},this.lstReinstatement);
                    console.log('del lstReinstatement== ',this.lstReinstatement);
        
                    this.allLstReinstatement = this.lstReinstatement;
                    this.selectedReinstatement = [];
                    this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                }
           
            /*}else if (resultMessage = 'deletion_not_permit'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Deletion not allowed',
                        message: 'This reinstatement line is also available for Section',
                        variant: 'warning'
                    })
                );
            }*/
        /*})
        .catch(error => {
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }*/

    handleAddReinstatement(){
            console.log('lstReinstatementAdd reins==', this.lstReinstatement);

            let lstUpdtDataToDisplayOnUI = [];
            let lstUpdtDataToInsertDataBase = [];
            var newReinstatement = {};
            let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
            let dataInput = {};
            if (this.lstReinstatement != undefined || this.lstReinstatement != null){
                for(let i = 0; i < this.lstReinstatement.length; i++){
                    let rowData = { ...this.lstReinstatement[i]};
                    lstUpdtDataToDisplayOnUI.push(rowData);
                }
        
                console.log('lstUpdtDataToDisplayOnUI ==', lstUpdtDataToDisplayOnUI);
                console.log(' inputs ==  ', inputs);
                for(let input of inputs){
                    if (input.type == 'checkbox'){
                        dataInput[input.name] = input.checked;
                    }else{
                        dataInput[input.name] = input.value;
                    }
                }
                console.log(' dataInput ==  ', dataInput);
                // Get info to display in UI in put on outputList
                newReinstatement['Id'] = null;
                newReinstatement['Section__c'] = this.recordId; // required on Reins Object
                newReinstatement['Order__c'] = dataInput.orderReins;
                newReinstatement['Percentage__c'] = dataInput.percentageReins;
                newReinstatement['ProrataValue__c'] = this.mapProrataValueLabel.get(dataInput.prorataReins); //this.mapProrataValueLabel.get(
                newReinstatement['Free__c'] = dataInput.Free;
                if (dataInput.prorataReins == 0){
                    newReinstatement['Prorata__c'] = null;
                }else{
                    newReinstatement['Prorata__c'] = dataInput.prorataReins;
                }
                
                newReinstatement['FreeValue__c'] = dataInput.Free == true ? 'Yes' : 'No';
                newReinstatement['Type__c'] = dataInput.Reinstatements;
                newReinstatement['Sub_Section__c'] = null;
                newReinstatement['Key_Insert_Update_Reinstatement__c'] = null;
                
                lstUpdtDataToDisplayOnUI.push(newReinstatement);
        
                this.lstReinstatement = lstUpdtDataToDisplayOnUI;
                this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field
                console.log(' this.lstReinstatement ==  ', this.lstReinstatement);
                this.openNewReinstatementModal = false;

                if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                    this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                }else {
                    this.outputList = null;
                }
                
                this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
                /*this.newRecord = Object.assign({},this.lstReinstatement);
                console.log('newRecordAdd==', this.newRecord);
                this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';*/
            }else{
                console.log(' inputs ==  ', inputs);
                for(let input of inputs){
                    if (input.type == 'checkbox'){
                        dataInput[input.name] = input.checked;
                    }else{
                        dataInput[input.name] = input.value;
                    }
                }
                console.log(' dataInput ==  ', dataInput);
                //newReinstatement['Id'] = null;
                newReinstatement['Section__c'] = this.recordId; // required on Reins Object
                newReinstatement['Order__c'] = dataInput.orderReins;
                newReinstatement['Percentage__c'] = dataInput.percentageReins;
                newReinstatement['ProrataValue__c'] = this.mapProrataValueLabel.get(dataInput.prorataReins); //this.mapProrataValueLabel.get(
                newReinstatement['Free__c'] = dataInput.Free;
                if (dataInput.prorataReins == 0){
                    newReinstatement['Prorata__c'] = null;
                }else{
                    newReinstatement['Prorata__c'] = dataInput.prorataReins;
                }
                
                newReinstatement['FreeValue__c'] = dataInput.Free == true ? 'Yes' : 'No';
                newReinstatement['Type__c'] = dataInput.Reinstatements;
                newReinstatement['Sub_Section__c'] = null;
                newReinstatement['Key_Insert_Update_Reinstatement__c'] = null;
                console.log(' newReinstatement ==  ', newReinstatement);
                lstUpdtDataToInsertDataBase.push(newReinstatement);
                console.log(' lstUpdtDataToInsertDataBase ==  ', lstUpdtDataToInsertDataBase);
                this.lstReinstatement = lstUpdtDataToInsertDataBase;
                this.lstReinstatement = this.sortData('Order__c', 'asc', this.lstReinstatement); //sort by order field
                console.log(' this.lstReinstatementAdd0value ==  ', this.lstReinstatement);

                if (this.lstReinstatement != null || this.lstReinstatement != undefined){
                    this.outputList = this.lstReinstatement;
                }else {
                    this.outputList = null;
                }

                
                //this.outputList = this.lstReinstatement;
                this.openNewReinstatementModal = false;
                //this.outputList = this.lstReinstatement.map(record => Object.assign({}, record));
                console.log(' this.outputListAdd0value==', this.outputList);
                this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
            }
    }

    handleReinstatementsRowSelection(event){
        var allDatatable = this.template.querySelectorAll('lightning-datatable');
        for(var i = 0; i < allDatatable.length; i++){
            if(allDatatable[i].keyField == 'LstReinstatementtable'){
                this.selectedReinstatement = allDatatable[i].getSelectedRows();
                this.isDeleteNotAllowed = false;
            }
        }
    }

    handleChangeReinstatementValue(event){
        this.isLoadingReinstatement =true;
        this.TypeOfReinstatement = event.detail.value;
        fireEvent(this.pageRef, 'changeReins', this.TypeOfReinstatement);

        if(this.TypeOfReinstatement == '3'){
            this.isNewReinstatementDisable = false;
            this.isLoadingReinstatement =false;
        }else{
            this.isNewReinstatementDisable = true;
            this.lstReinstatement = [];
            this.allLstReinstatement = [];
            this.titleReinstatement = 'Reinstatements ('+ this.lstReinstatement.length +')';
            this.isLoadingReinstatement =false;
        }
    }

    handleChangeFreeCheck(event){
        this.isFreeChecked = event.detail.checked;

        if(this.isFreeChecked == true){
            this.disablePercentageReins = true;
            this.disableProrataReins = true;
            this.prorataReins = 0;
            //this.percentageReins = null;
            this.template.querySelector('[data-id="percentageReins"]').value = null;
        }else{
            this.disablePercentageReins = false;
            this.disableProrataReins = false;
        }
    }

    handleOnChangeValue(event){
        let fieldName = event.target.name;
         if(fieldName == 'prorataReins'){
            this.prorataReins = event.detail.value;
        }else if(fieldName == 'percentageReins'){
        }else if(fieldName == 'Deductible'){
            this.DeductibleValue = event.target.value;
        }
    }

    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        let lstSortedLstData = sortResult.sort(function(a,b){
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
        return lstSortedLstData;
    }
}