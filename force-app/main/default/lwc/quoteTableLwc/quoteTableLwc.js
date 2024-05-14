import { LightningElement, wire } from 'lwc';

import {
    CurrentPageReference,
    NavigationMixin
} from 'lightning/navigation';


export default class QuoteTableLwc extends LightningElement {

    currentPageReference = null;
    urlStateParameters = null;
    activetab;
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
        if(this.urlStateParameters.c__tab){this.activetab = 'list'}
        console.log('connectedCallback: end');
    }
}