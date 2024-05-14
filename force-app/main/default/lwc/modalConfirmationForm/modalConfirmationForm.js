import {
    LightningElement
} from 'lwc';

import ModalTitle1 from '@salesforce/label/c.ModalTitle1';
import ModalContent1 from '@salesforce/label/c.ModalContent1';
import ModalButton1 from '@salesforce/label/c.ModalButton1';
import ModalButton2 from '@salesforce/label/c.ModalButton2';
import ModalButton3 from '@salesforce/label/c.ModalButton3';

export default class ModalConfirmationForm extends LightningElement {
    //exposed properties
    isLoading = false;
    buttonBtn1 = ModalButton1;
    buttonBtn2 = ModalButton2;
    buttonBtn3 = ModalButton3;

    //modal form title
    get modalName() {
        return `${ModalTitle1}`;
    }

    //modal content messaage
    get modalContent() {
        return `${ModalContent1}`;
    }

    //notify parent component to redirect to newly created program
    notifyParentForRedirection() {
        const progRenewed = new CustomEvent('progrenew');
        this.dispatchEvent(progRenewed);
    }

    //notify parent component to refresh current page
    refreshParentComponent() {
        const refreshParent = new CustomEvent('refreshcomp');
        this.dispatchEvent(refreshParent);
    }
}