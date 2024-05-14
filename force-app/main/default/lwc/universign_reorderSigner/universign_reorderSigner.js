import { LightningElement, api } from 'lwc';

export default class Universign_reorderSigner extends LightningElement {
    @api items = [];

    connectedCallback(){
        console.log(`connectedcallback start`);
        console.log('items' , this.items)
    }

    handleDragStart(event) {
        const sourceId = this.findSourceId(event);

        if (sourceId) {
            event.dataTransfer.setData('text/plain', sourceId);
            console.log(`Drag started for item with id: ${sourceId}`);
        }
    }

    handleDragEnd(event) {
        const sourceId = event.target.dataset.id;
        console.log(`Drag ended for item with id: ${sourceId}`);
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const sourceId = event.dataTransfer.getData('text/plain');
        const targetId = this.findTargetId(event);

        console.log(`Dropped item with id: ${sourceId} onto item with id: ${targetId}`);

        const sourceIndex = this.items.findIndex(item => item.Id === sourceId);
        console.log('sourceIndex', sourceIndex);
        const targetIndex = this.items.findIndex(item => item.Id === targetId);
        console.log('targetIndex', targetIndex);

        if (sourceIndex > -1 && targetIndex > -1) {
            console.log('Reordering items:');
            console.log('Before reorder:', this.items);
            
            const reorderedItems = [...this.items]; // Create a copy of the items array
            const movedItem = reorderedItems[sourceIndex]; // Get the item to move
            console.log('movedItem:', movedItem);

            // Remove the item from its original position
            reorderedItems.splice(sourceIndex, 1);
            console.log('reorderedItems:', reorderedItems);

            // Insert the item at the new position
            reorderedItems.splice(targetIndex, 0, movedItem);

            // Update the component's items with the reordered array
            this.items = reorderedItems;

            console.log('After reorder:', this.items);
        }

        // if (sourceIndex > -1 && targetIndex > -1) {
        //     console.log('xxx')
        //     const movedItem = this.items.splice(sourceIndex, 1)[0];
        //     console.log('movedItem', movedItem);

        //     this.items.splice(targetIndex, 0, movedItem);
        //     console.log('this.items', this.items);

        //     this.items = [...this.items];

        //     console.log('Reordered items:');
        //     this.items.forEach(item => {
        //         console.log(`Item ID: ${item.Id}, Name: ${item.name}`);
        //     });
        // }
    }

    findSourceId(event) {
        let sourceElement = event.target;
        while (sourceElement) {
            if (sourceElement.classList.contains('draggable-item')) {
                return sourceElement.dataset.id;
            }
            sourceElement = sourceElement.parentElement;
        }
        return undefined;
    }

    findTargetId(event) {
        let targetElement = event.target;
        while (targetElement) {
            if (targetElement.classList.contains('draggable-item')) {
                return targetElement.dataset.id;
            }
            targetElement = targetElement.parentElement;
        }
        return undefined;
    }
}