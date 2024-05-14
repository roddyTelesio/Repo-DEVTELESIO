import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class FlowRedirectionCmp extends NavigationMixin(LightningElement) {

    @api recordId;
    @api timer;
    @api baseUrl; 

    connectedCallback() {
        if (this.recordId) {
            var recId = this.recordId; 
            setTimeout(function() {
                console.log('FlowRedirectionCmp: RecordId ', recId);
                console.log('FlowRedirectionCmp: Redirecting to : ', window.location.origin + '/' + recId );
                window.location.href = window.location.origin + '/' + recId; 

              }, this.timer);
              
            
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: this.recordId,
            //         actionName: 'view'
            //     }
            // });
        }
    }
}