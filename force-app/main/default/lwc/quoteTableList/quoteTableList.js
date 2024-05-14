import { LightningElement, wire } from 'lwc';
import getFileList from '@salesforce/apex/CreateClasseurs.getFileList';

export default class QuoteTableList extends LightningElement {


    classeurIds = [];

    exercise = 'inProgress';

    get exercises() {
        return [
            { label: '2019', value: '2019' },
            { label: '2020', value: '2020' },
            { label: '2021', value: '2021' },
        ];
    }

    handleChangeExercise(event) {
        this.exercise = event.detail.value;
    }

    handleNouveauClasseur(){
        console.log('handleNouveauClasseur : START');
        let THEURL= '/lightning/n/Quote_Table';
        window.open(THEURL, '_top')
        console.log('handleNouveauClasseur : END');
    }

    handleProgrammationMaj(){
        console.log('handleProgrammationMaj:');
    }

    handleClickExport(){
        console.log('handleClickExport: Start');
        let rowsSelected = this.template
            .querySelector("c-classeurs-list")
            .getRows();

        let classeurIds = rowsSelected.map((row) => {return row['Id']}); 
        if(classeurIds.length > 0){
            console.log('handleClickExport : at least 1 classeur Id selected' );
            this.classeurIds = classeurIds; 
        }else{
            console.log('handleClickExport : no classeur selected, throwing error to user' );
        }
        console.log('handleClickExport : rowsSelected ' , rowsSelected); 
        console.log('handleClickExport: End');
    }

    @wire(getFileList, { classeurIds: '$classeurIds'})
    getUrlExcelExport({error, data}) {
        if(data){
            console.log('getUrlExcelExport : data ' , data);
            window.open('/sfc/servlet.shepherd/version/download/'+data, '_blank').focus();
            
        }
        else{
            console.log('getUrlExcelExport : error ' , error);
            
        }
    }


}