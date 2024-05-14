import { LightningElement, track } from 'lwc';

const A4_WIDTH = 210; // Example A4 width in millimeters
const A4_HEIGHT = 297; // Example A4 height in millimeters

export default class Universign_PdfCoordinateCapture extends LightningElement {
    pdfUrl = 'https://actornewgen--devtabcota.sandbox.my.salesforce.com/sfc/p/#5E000000A5u4/a/5E000000keIi/jwNlel6cXE.yHLsUHk2H7.k0v1VbDCD7vibSz75c5Zs'; // Replace with actual PDF resource URL
    @track xCoordinate;
    @track yCoordinate;

    handlePdfClick(event) {
        const boundingRect = this.template.querySelector('.pdf-overlay').getBoundingClientRect();
        const offsetX = event.clientX - boundingRect.left;
        const offsetY = event.clientY - boundingRect.top;

        // Calculate relative coordinates based on PDF dimensions
        const pdfWidth = boundingRect.width;
        const pdfHeight = boundingRect.height;

        this.xCoordinate = (offsetX * A4_WIDTH) / pdfWidth;
        this.yCoordinate = (offsetY * A4_HEIGHT) / pdfHeight;
    }
}