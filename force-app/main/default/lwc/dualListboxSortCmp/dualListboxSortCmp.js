import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import dualListboxSortCmpCSS from '@salesforce/resourceUrl/dualListboxSortCmpCSS';


export default class DualListboxSortCmp extends LightningElement {

    @api recordList     = [];  
    @api isDebug; 
    @api selectionList = [];
    @api orderedList = [];
    mapContact = new Map();
    listOptions = []; 
    defaultOptions = [];
    requiredOptions = [];

    renderedCallback() {
        Promise.all([loadStyle(this, dualListboxSortCmpCSS)]);
    }

    connectedCallback() {
        console.log('component init :'+ JSON.stringify(this.recordList));
    
        this.recordList.forEach(eachRecord => {
            this.mapContact.set(eachRecord.Id, eachRecord);

            this.selectionList.push(eachRecord);

            console.log('initialising options', eachRecord );
            this.listOptions.push({
                value : eachRecord.Id,
                label : eachRecord.Name
            });
            this.defaultOptions.push(eachRecord.Id);
            this.requiredOptions.push(eachRecord.Id) 
            console.log('options initilised: ' , this.listOptions , this.defaultOptions, this.requiredOptions);
        });
        console.log('listOptions init :'+ JSON.stringify(this.listOptions));

    }

    handleChange(event) {
        // Get the list of the "value" attribute on all the selected options
        const selectedOptionsList = event.detail.value;
        this.orderedList = [] ;
        selectedOptionsList.forEach(eachRecord => {
            this.orderedList.push(this.mapContact.get(eachRecord)) ;
        }) ;
     
    }
}