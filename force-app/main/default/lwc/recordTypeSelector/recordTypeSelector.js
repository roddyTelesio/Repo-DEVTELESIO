// recordTypeSelector.js
import { LightningElement, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecordTypeSelector extends LightningElement {
    @api objectApiName; // Pass the object API name as a property when using the component
    @api selectedRecordTypeNames; // Pass a comma-separated string of record type developer names

    selectedRecordType = '';
    error;
    recordTypes = [];

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo({ error, data }) {
        if (data) {
            console.log('RT Selector Data: ' , data);
            console.log('selectedRecordTypeNames ' , this.selectedRecordTypeNames);
            const selectedDevNames = this.selectedRecordTypeNames
                ? this.selectedRecordTypeNames.split(',')
                : [];
            console.log('RT Selector : selectedDevNames ', selectedDevNames);
            this.recordTypes = Object.values(data.recordTypeInfos)
                .filter(rt => rt.available && selectedDevNames.includes(rt.name))
                .map(rt => ({ label: rt.name, value: rt.recordTypeId }));

            this.error = null;
        } else if (error) {
            this.error = error;
            this.recordTypes = null;
        }
    }

    get radioOptions() {
        return this.recordTypes;
    }

    handleRecordTypeChange(event) {
        this.selectedRecordType = event.detail.value;
        // Dispatch a custom event to notify the parent component or handle the selected record type
        this.dispatchEvent(new CustomEvent('recordtypechange', { detail: this.selectedRecordType }));
    }
}