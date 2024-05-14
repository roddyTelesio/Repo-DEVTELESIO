import { LightningElement,api } from 'lwc';

export default class Lwc18ConfirmationModal extends LightningElement {
    @api visible; 
    @api title; 
    @api name; 
    @api message; 
    @api confirmLabel; 
    @api cancelLabel; 
    @api originalMessage; 

    handleClick(event){
        let finalEvent = {
            originalMessage: this.originalMessage,
            status: event.target.name
        };
        this.dispatchEvent(new CustomEvent('click', {detail: finalEvent}));
    }
}