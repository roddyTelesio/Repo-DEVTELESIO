import { LightningElement, track } from 'lwc';
 
export default class Lwc01RefreshSubSection extends LightningElement {
    @track isLoading = false;
    @track numberSubSection;

    connectedCallback(){
    }

    refreshComponent(event){
        window.location.reload();
    }
    
}