import { LightningElement, api } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
export default class LwcRefreshView extends LightningElement {
    connectedCallback(){
        this.dispatchEvent(new RefreshEvent());
    }
}