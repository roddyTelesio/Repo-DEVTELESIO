({
    doInit: function(component, event, helper) {
        component.find('recordLoader').reloadRecord(true);
        var recId = component.get("v.recordId");

        var action = component.get("c.checkPCC");
        action.setParams({
            treatyId: recId
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                var results = response.getReturnValue();
                component.set("v.pccActive", results);

                if(results == false){
                    helper.showToastMessage(component, 'Info', 'info', 'The Principal Ceding Company is inactive', null);
                }
                else{
                    var actionCCC = component.get("c.checkCCC");
                    actionCCC.setParams({
                        treatyId: recId
                    });

                    actionCCC.setCallback(this, function(response){
                        var state = response.getState();
                        if(component.isValid() && state === "SUCCESS"){
                            var resultsCCC = response.getReturnValue();
//                            component.set("v.pccActive", resultsCCC);
//
//                            if(resultsCCC == false){
//                                helper.showToastMessage(component, 'Info', 'info', 'All Covered Ceding Companies are inactive', null);
//                            }
//                            else{
//
//                            }

                        }else{
                            helper.showToastMessage(component, 'Error', 'error', response.getError(), null);
                        }
                    });
                    $A.enqueueAction(actionCCC);
                }

            }else{
                helper.showToastMessage(component, 'Error', 'error', response.getError(), null);
            }
        });
        $A.enqueueAction(action);
    }
    ,closeModal: function(component, event, helper) {
        component.set("v.cmpRendered", false);
        window.history.back();
        return false;
    }
    ,handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            window.setTimeout(
                $A.getCallback(function() {
                    component.set("v.cmpRendered", true);
                }), 500
            );
        }
        else if(eventParams.changeType === "CHANGED") {
        }
        else if(eventParams.changeType === "REMOVED") {
        }
        else if(eventParams.changeType === "ERROR") {
        }
    }
});