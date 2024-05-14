({
    showToastMessage :  function(component, messageTitle, messageType, messageText) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": messageTitle,
            "type": messageType,
            "message": messageText,
            "mode": (messageType === 'error' ? 'sticky':'dismissible')
        });
        resultsToast.fire();
    }
})