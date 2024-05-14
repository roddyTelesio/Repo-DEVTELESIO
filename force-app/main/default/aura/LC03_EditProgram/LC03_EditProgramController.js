({
    doInit: function(component, event, helper) {
//        console.log('## in doInit');
    }
    ,closeModal: function(component, event, helper) {
         window.history.back();
         return false;
    }
});