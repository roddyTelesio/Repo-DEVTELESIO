public with sharing class getListHazardBassinsFiltered {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Record Id Section' )
        public Id recordId;       

    }

    public class Result{
        @InvocableVariable(required=true label='list HB with Code Region + list HB with code region different + list HB without code region')
        public List<ReferentialHazardBassin__c> lstHBAllFiltered;
        @InvocableVariable(required=true label='Message for HB no Code Region')
        public String messageWithoutHB;    

        public Result(List<ReferentialHazardBassin__c> lstHBAllFiltered, String messageWithoutHB){
            this.lstHBAllFiltered = lstHBAllFiltered;
            this.messageWithoutHB = messageWithoutHB;
        }
    }

    /***
    * @description	// 
    * @param	    NONE
    * @return		//
    * @exception   	None
    ***/   
    @InvocableMethod(label='List Hazard Bassins Filtered' description='' callout=false)
    public static List<Result> getHBAllFiltered(List<ObjectContext> objs){
            set<String> setAllCodeRegionCCC = new set<String>();
            List<ReferentialHazardBassin__c> lstReferenceHB = new List<ReferentialHazardBassin__c>();
            set<ReferentialHazardBassin__c> setHBWithCodeRegion  = new set<ReferentialHazardBassin__c>();
            set<ReferentialHazardBassin__c> setHBWithoutCodeRegion  = new set<ReferentialHazardBassin__c>();
            set<ReferentialHazardBassin__c> setHBAllCodeRegion = new set<ReferentialHazardBassin__c>();
            String message;

        for (CoveredCedingCompany__c ccc : [SELECT Id, ExtractCodeRegion__c,Section__c FROM CoveredCedingCompany__c WHERE Section__c =: objs[0].recordId]){
            // All Code Region attached on (01) Section from CoveredCedingCompany 
            setAllCodeRegionCCC.add(ccc.ExtractCodeRegion__c); 
        }

        System.debug('setAllCodeRegionCCC: ' + setAllCodeRegionCCC);

        if (setAllCodeRegionCCC.size() > 0 ){
           if (setAllCodeRegionCCC.contains('All')){
                //Get All List HB Code Region when it's inexisting and not null in referential 
                // RRA - tickets 1531 et 1534 - 09062023 
                for (ReferentialHazardBassin__c refHB : [SELECT Id,CodeRegion__c, Label__c, isActive__c, CodeRegion2Characters__c, HazardCode__c, Id__c, Peril__c, Type__c FROM ReferentialHazardBassin__c WHERE isActive__c = true] ) { 
                    setHBAllCodeRegion.add(refHB);
                }
           }else{
                 //Get List HB filtered by Code Region 
                // RRA - tickets 1531 et 1534 - 09062023 
                 for (ReferentialHazardBassin__c refHB :[SELECT Id,CodeRegion__c, Label__c, isActive__c, CodeRegion2Characters__c, HazardCode__c, Id__c, Peril__c, Type__c FROM ReferentialHazardBassin__c WHERE CodeRegion2Characters__c IN :setAllCodeRegionCCC AND isActive__c = true]){
                    if (setAllCodeRegionCCC.contains(refHB.CodeRegion2Characters__c)){
                        setHBWithCodeRegion.add(refHB);
                    }
                    /*if (refHB.CodeRegion__c == null || refHB.CodeRegion__c ==''){
                        setHBWithoutCodeRegion.add(refHB);
                        message = 'Sorry, the Hazard Bassin don\'t exist for ' + lstReferenceHB;
                    }*/
                } 
           }
        }


        System.debug('setHBWithCodeRegion: ' + setHBWithCodeRegion);
        System.debug('setHBWithCodeRegion.SIZE: ' + setHBWithCodeRegion.size());
        System.debug('setHBAllCodeRegion: ' + setHBAllCodeRegion);
        System.debug('setHBAllCodeRegion.SIZE: ' + setHBAllCodeRegion.size());
        System.debug('setHBWithoutCodeRegion: ' + setHBWithoutCodeRegion);
        System.debug('setHBWithoutCodeRegion.SIZE: ' + setHBWithoutCodeRegion.size());

       if (setHBAllCodeRegion.size() > 0){
            lstReferenceHB.addAll(setHBAllCodeRegion);

       }else if(setHBWithCodeRegion.size () > 0){
            lstReferenceHB.addAll(setHBWithCodeRegion);
       }else{
            lstReferenceHB.addAll(setHBWithoutCodeRegion);
       }


       System.debug('lstReferenceHB: ' + lstReferenceHB);
       System.debug('lstReferenceHB.SIZE: ' + lstReferenceHB.size());
       System.debug('message: ' + message);

       Result r = new Result(lstReferenceHB,message);
       return new List<Result>{r};
    }
}