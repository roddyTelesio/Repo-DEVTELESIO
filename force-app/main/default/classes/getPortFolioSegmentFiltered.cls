public with sharing class getPortFolioSegmentFiltered {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Record Id Section' )
        public Id recordId; 
        @InvocableVariable(required=true label='List Code Region in CCC' )
        public String lstCCC;      

    }

    public class Result{
        @InvocableVariable(required=true label='list All PS  + PS with Code Region  ')
        public List<PortFolioSegment__c> lstPSAllFiltered;

        public Result(List<PortFolioSegment__c> lstPSAllFiltered){
            this.lstPSAllFiltered = lstPSAllFiltered;
        }
    }

    /***
    * @description	// 
    * @param	    NONE
    * @return		//
    * @exception   	None
    ***/   
    @InvocableMethod(label='List PortFolioSegment Filtered' description='' callout=false)
    public static List<Result> getPSAllFiltered(List<ObjectContext> objs){
            set<String> setAllCodeRegionCCC = new set<String>();
            List<PortFolioSegment__c> lstReferencePS = new List<PortFolioSegment__c>();
            set<PortFolioSegment__c> setPSWithCodeRegion  = new set<PortFolioSegment__c>();
            set<PortFolioSegment__c> setPSWithoutCodeRegion  = new set<PortFolioSegment__c>();
            set<PortFolioSegment__c> setPSAllCodeRegion = new set<PortFolioSegment__c>();
            String message;

        for (CoveredCedingCompany__c ccc : [SELECT Id, ExtractCodeRegion__c,Section__c FROM CoveredCedingCompany__c WHERE Section__c =: objs[0].recordId]){
            // All Code Region attached on (01) Section from CoveredCedingCompany 
            setAllCodeRegionCCC.add(ccc.ExtractCodeRegion__c); 
        }

        System.debug('setAllCodeRegionCCC: ' + setAllCodeRegionCCC);

        if (setAllCodeRegionCCC.size() > 0 ){
           if (setAllCodeRegionCCC.contains('All')){
                //Get All List PS Code Region 
                for (PortFolioSegment__c ps : [SELECT Id, Id__c, Entity__c, IsoCode__c, PortfolioSegment__c FROM PortFolioSegment__c WHERE isActive__c = true] ) {//RRA- ticket 1581 - 19092023
                    setPSAllCodeRegion.add(ps);
                }
           }else{
                 //Get List PS filtered by Code Region 
                 for (PortFolioSegment__c psFiltered :[SELECT Id, Id__c, Entity__c, IsoCode__c, PortfolioSegment__c FROM PortFolioSegment__c WHERE IsoCode__c IN :setAllCodeRegionCCC AND isActive__c = true]){ //MRA NEREE 24/08/2022 IN instead et RRA- ticket 1581 - 19092023
                    if (setAllCodeRegionCCC.contains(psFiltered.IsoCode__c)){
                        setPSWithCodeRegion.add(psFiltered);
                    }
                } 
           }
        }


        System.debug('setPSWithCodeRegion: ' + setPSWithCodeRegion);
        System.debug('setPSWithCodeRegion.SIZE: ' + setPSWithCodeRegion.size());
        System.debug('setPSAllCodeRegion: ' + setPSAllCodeRegion);
        System.debug('setPSAllCodeRegion.SIZE: ' + setPSAllCodeRegion.size());

       if (setPSAllCodeRegion.size() > 0){
        lstReferencePS.addAll(setPSAllCodeRegion);

       }else if(setPSWithCodeRegion.size () > 0){
        lstReferencePS.addAll(setPSWithCodeRegion);
       }


       System.debug('lstReferencePS: ' + lstReferencePS);

       Result r = new Result(lstReferencePS);
       return new List<Result>{r};
    }
}