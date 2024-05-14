({
    showToastMessage :  function(component, messageTitle, messageType, messageText, messageMode) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": messageTitle,
            "type": messageType,
            "message": messageText,
            "mode": ( (messageType === 'error' && messageMode === null) ? 'sticky' : 'dismissible')
        });
        resultsToast.fire();

    }
});