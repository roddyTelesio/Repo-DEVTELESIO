import { LightningElement, wire, api} from 'lwc';

export default class LWC06_DeleteRecord extends LightningElement {
    @api objName;
    @api openModal;
    modalTitle;
    messageText;

    handleCloseModal() {
        this.openModal = false;
    }

    handleAcceptDelete() {
    }
}