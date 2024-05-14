({
    doInit: function(component, event, helper) {
        var recId = component.get("v.recordId");
        var objName = component.get("v.sObjectName");

        if(objName == 'Program__c'){
            component.set('v.deleteTitle', 'Delete Program');
            component.set('v.deleteMsg', 'You are going to delete the Program and all its related records. Do you want to continue?');
        }
        else if(objName == 'Treaty__c'){
            component.set('v.deleteTitle', 'Delete Treaty');
            component.set('v.deleteMsg', 'You are going to delete the Treaty and all its related records. Do you want to continue?');
        }
        else if(objName == 'Section__c'){
            component.set('v.deleteTitle', 'Delete Section');
            component.set('v.deleteMsg', 'You are going to delete the Section and all its related records. Do you want to continue?');
        }

        component.set('v.showSpinner', false);
    }

    ,handleCloseModal: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }

    ,handleAcceptDelete: function(component, event, helper){
        var recId = component.get("v.recordId");
        var objName = component.get("v.sObjectName");

        var lstObj = [];
        lstObj.push({'sobjectType': objName,'Id':recId});

        var action = component.get("c.deleteRecords");
        action.setParams({
            'lstRecords' : lstObj,
            'objectName' : objName
        });

        action.setCallback(this, function(response){
            component.set('v.showSpinner', true);
            var state = response.getState();
            var results;
            if(component.isValid() && state === "SUCCESS"){
                results = response.getReturnValue();
                if(results.hasOwnProperty("Error") && results.Error){
                    helper.showToastMessage(component, 'Error', 'error', results.Error);
                    component.set('v.showSpinner', false);
                }
                else{
                    helper.showToastMessage(component, 'Success', 'success', results.Success);
                    component.set('v.showSpinner', false);
                    window.history.back();
                    return false;
                }
            }
            else {
                helper.showToastMessage(component, 'Error', 'error', response.getError());
                component.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);
    }
});